using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.ClsssroomDtos;
using SunDaySchools.BLL.DTOS.CustomFields;
using SunDaySchools.BLL.DTOS.MeetingDtos;
using SunDaySchools.BLL.DTOS.UnifiedForms;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.BLL.Services.UnifiedForms;
using SunDaySchools.DAL.Models.CustomFields;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class UnifiedEntityFormManager : IUnifiedEntityFormManager
    {
        private readonly ICustomFieldRepository _customFieldRepository;
        private readonly ICustomFieldManager _customFieldManager;
        private readonly IMemberManager _memberManager;
        private readonly IMemberRepository _memberRepository;
        private readonly IServantManager _servantManager;
        private readonly IServantRepository _servantRepository;
        private readonly IClassroomManager _classroomManager;
        private readonly IClassroomRepository _classroomRepository;
        private readonly IMeetingManager _meetingManager;
        private readonly IMeetingRepository _meetingRepository;
        private readonly IMapper _mapper;
        private readonly ILogger<UnifiedEntityFormManager> _logger;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public UnifiedEntityFormManager(
            ICustomFieldRepository customFieldRepository,
            ICustomFieldManager customFieldManager,
            IMemberManager memberManager,
            IMemberRepository memberRepository,
            IServantManager servantManager,
            IServantRepository servantRepository,
            IClassroomManager classroomManager,
            IClassroomRepository classroomRepository,
            IMeetingManager meetingManager,
            IMeetingRepository meetingRepository,
            IMapper mapper,
            ILogger<UnifiedEntityFormManager> logger,
            IHttpContextAccessor httpContextAccessor)
        {
            _customFieldRepository = customFieldRepository;
            _customFieldManager = customFieldManager;
            _memberManager = memberManager;
            _memberRepository = memberRepository;
            _servantManager = servantManager;
            _servantRepository = servantRepository;
            _classroomManager = classroomManager;
            _classroomRepository = classroomRepository;
            _meetingManager = meetingManager;
            _meetingRepository = meetingRepository;
            _mapper = mapper;
            _logger = logger;
            _httpContextAccessor = httpContextAccessor;
        }

        public async Task<EntityFormSchemaDto> GetFormSchemaAsync(
            string entityName,
            EntityFormMode mode = EntityFormMode.Edit)
        {
            EnsureEntity(entityName);

            try
            {
                await EntityDefaultFieldProvisioner.EnsureDefaultsAsync(
                    _customFieldRepository,
                    entityName,
                    _logger,
                    _httpContextAccessor);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Default field provisioning failed for {Entity}; continuing with existing definitions.",
                    entityName);
            }

            var custom = await _customFieldRepository.GetDefinitionsByEntityAsync(entityName)
                ?? Array.Empty<CustomFieldDefinition>();

            var fields = EntityFormSchemaRegistry.FilterForMode(
                custom
                    .Where(d => d.IsActive && !d.IsHidden)
                    .Select(SafeToUnifiedField)
                    .Where(f => f != null)
                    .Cast<UnifiedFieldDefinitionDto>()
                    .OrderBy(f => f.SortOrder)
                    .ThenBy(f => f.DisplayName)
                    .ToList(),
                entityName,
                mode).ToList();

            return new EntityFormSchemaDto
            {
                EntityName = entityName,
                FormMode = mode.ToString(),
                Fields = fields,
                ConfigurationHint = fields.Count == 0
                    ? "No attributes configured yet. An admin can add fields or restore defaults under Manage custom fields."
                    : null,
                RecommendedSyncFieldKeys = EntityColumnSyncRegistry.GetRecommendedFieldKeys(entityName).ToList()
            };
        }

        public async Task<EntityFormDataDto> GetFormDataAsync(string entityName, int entityId)
        {
            EnsureEntity(entityName);
            if (entityId <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["entityId"] = new[] { "Entity id must be positive." }
                });

            _logger.LogInformation(
                "GetFormData starting for {Entity} id={EntityId}",
                entityName,
                entityId);

            try
            {
                var schema = await GetFormSchemaAsync(entityName, EntityFormMode.Edit);
                var activeDefIds = schema.Fields
                    .Where(f => f.CustomFieldDefinitionId.HasValue)
                    .Select(f => f.CustomFieldDefinitionId!.Value)
                    .ToHashSet();

                var customValues = await _customFieldRepository.GetValuesAsync(entityName, entityId);
                var customByDefId = FormCustomValuesLookup.FromValues(
                    customValues.Where(v => activeDefIds.Contains(v.CustomFieldDefinitionId)));

                IReadOnlyDictionary<string, string?> builtInValues;
                try
                {
                    builtInValues = await LoadBuiltInValuesAsync(entityName, entityId);
                }
                catch (NotFoundException)
                {
                    throw;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(
                        ex,
                        "Built-in SQL values unavailable for {Entity} id={EntityId}; returning custom fields only.",
                        entityName,
                        entityId);
                    builtInValues = new Dictionary<string, string?>();
                }

                var fields = schema.Fields.Select(def =>
                {
                    string? value = null;
                    if (def.CustomFieldDefinitionId is int defId)
                        customByDefId.TryGetValue(defId, out value);

                    if (string.IsNullOrWhiteSpace(value)
                        && builtInValues.TryGetValue(def.FieldKey, out var sqlValue))
                    {
                        value = sqlValue;
                    }

                    return new UnifiedFieldDto
                    {
                        FieldKey = def.FieldKey,
                        DisplayName = def.DisplayName,
                        Description = def.Description,
                        DataType = def.DataType,
                        IsRequired = def.IsRequired,
                        IsBuiltIn = def.IsBuiltIn,
                        IsReadOnly = def.IsReadOnly,
                        IsHidden = def.IsHidden,
                        SortOrder = def.SortOrder,
                        AllowMultipleValues = def.AllowMultipleValues,
                        DefaultValue = def.DefaultValue,
                        Placeholder = def.Placeholder,
                        ValidationRegex = def.ValidationRegex,
                        LookupEndpoint = def.LookupEndpoint,
                        CustomFieldDefinitionId = def.CustomFieldDefinitionId,
                        Options = def.Options ?? new List<UnifiedFieldOptionDto>(),
                        Value = value
                    };
                }).Where(f => !f.IsHidden).ToList();

                _logger.LogInformation(
                    "GetFormData completed for {Entity} id={EntityId} fieldCount={Count}",
                    entityName,
                    entityId,
                    fields.Count);

                return new EntityFormDataDto
                {
                    EntityName = entityName,
                    EntityId = entityId,
                    Fields = fields
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "GetFormData failed for {Entity} id={EntityId}. Message={Message}",
                    entityName,
                    entityId,
                    ex.Message);
                throw;
            }
        }

        public async Task SaveFormDataAsync(string entityName, int entityId, SaveEntityFormDto dto)
        {
            EnsureEntity(entityName);
            if (entityId <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["entityId"] = new[] { "Entity id must be positive." }
                });

            if (dto.Fields == null || dto.Fields.Count == 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["fields"] = new[] { "At least one field must be provided." }
                });
            }

            var schema = await GetFormSchemaAsync(entityName, EntityFormMode.Edit);
            var fieldMap = schema.Fields.ToDictionary(f => f.FieldKey, StringComparer.OrdinalIgnoreCase);
            var submitted = FormValueNormalizer.BuildSubmittedMap(
                dto.Fields.Select(f => (f.FieldKey, f.Value)));

            _logger.LogInformation(
                "SaveFormData {Entity} id={EntityId} submittedKeys={Keys}",
                entityName,
                entityId,
                string.Join(", ", submitted.Keys));

            var validationErrors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);
            var customItems = new List<CustomFieldValueItemDto>();
            var columnSyncValues = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);

            foreach (var (key, value) in submitted)
            {
                if (!fieldMap.TryGetValue(key, out var meta))
                {
                    _logger.LogWarning(
                        "SaveFormData rejected unknown field key '{FieldKey}' for {Entity} id={EntityId}",
                        key,
                        entityName,
                        entityId);
                    validationErrors[key] = new[]
                    {
                        "Unknown field. Add it under Custom Fields for this entity type first."
                    };
                    continue;
                }

                if (meta.IsReadOnly)
                    continue;

                if (meta.IsRequired && string.IsNullOrWhiteSpace(value))
                {
                    validationErrors[key] = new[] { $"{meta.DisplayName} is required." };
                    continue;
                }

                if (meta.CustomFieldDefinitionId.HasValue)
                {
                    customItems.Add(new CustomFieldValueItemDto
                    {
                        CustomFieldDefinitionId = meta.CustomFieldDefinitionId.Value,
                        Value = value
                    });

                    if (EntityColumnSyncRegistry.CanSyncToEntityTable(entityName, key))
                        columnSyncValues[key] = value;
                }
            }

            if (validationErrors.Count > 0)
            {
                _logger.LogWarning(
                    "SaveFormData validation failed for {Entity} id={EntityId}. Errors={@Errors}",
                    entityName,
                    entityId,
                    validationErrors);
                throw new ValidationException(validationErrors);
            }

            try
            {
                if (customItems.Count > 0)
                {
                    await _customFieldManager.SaveEntityValuesAsync(
                        new SaveCustomFieldValuesDto
                        {
                            EntityName = entityName,
                            EntityId = entityId,
                            Values = customItems
                        },
                        requireAllRequiredFields: false);
                }

                if (columnSyncValues.Count > 0)
                    await ApplyBuiltInValuesAsync(entityName, entityId, columnSyncValues);
            }
            catch (ValidationException ex)
            {
                _logger.LogWarning(
                    ex,
                    "SaveFormData persistence validation failed for {Entity} id={EntityId}. Errors={@Errors}",
                    entityName,
                    entityId,
                    ex.Errors);
                throw;
            }
        }

        public async Task<int> CreateEntityWithFormDataAsync(
            string entityName,
            SaveEntityFormDto dto,
            int? classroomIdForMember = null)
        {
            EnsureEntity(entityName);

            var entityId = entityName switch
            {
                CustomFieldEntityNames.Member => await CreateMemberShellAsync(dto, classroomIdForMember),
                CustomFieldEntityNames.Classroom => await CreateClassroomShellAsync(dto),
                _ => throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["entityName"] = new[] { $"Create-from-form is not supported for '{entityName}'." }
                })
            };

            await SaveFormDataAsync(entityName, entityId, dto);
            return entityId;
        }

        private async Task<int> CreateMemberShellAsync(SaveEntityFormDto dto, int? classroomId)
        {
            if (!classroomId.HasValue || classroomId.Value <= 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["classroomId"] = new[] { "Classroom is required to create a member." }
                });
            }

            var displayName = ExtractFirstTextValue(dto) ?? "Member";
            var addDto = new MemberAddDTO { Name1 = displayName };
            return await _memberManager.AddAsync(addDto, classroomId.Value);
        }

        private async Task<int> CreateClassroomShellAsync(SaveEntityFormDto dto)
        {
            var name = ExtractFirstTextValue(dto) ?? "Classroom";
            var addDto = new ClassroomAddDTO
            {
                Name = name,
                AgeOfMembers = "-"
            };

            return await _classroomManager.AddAsync(addDto);
        }

        private static string? ExtractFirstTextValue(SaveEntityFormDto dto)
        {
            foreach (var item in dto.Fields)
            {
                if (!string.IsNullOrWhiteSpace(item.Value))
                    return item.Value!.Trim();
            }
            return null;
        }

        private async Task<IReadOnlyDictionary<string, string?>> LoadBuiltInValuesAsync(
            string entityName,
            int entityId)
        {
            return entityName switch
            {
                CustomFieldEntityNames.Member => await LoadMemberValuesAsync(entityId),
                CustomFieldEntityNames.Classroom => await LoadClassroomValuesAsync(entityId),
                CustomFieldEntityNames.Servant => await LoadServantValuesAsync(entityId),
                CustomFieldEntityNames.Meeting => await LoadMeetingValuesAsync(entityId),
                _ => new Dictionary<string, string?>()
            };
        }

        private Task<IReadOnlyDictionary<string, string?>> LoadMemberValuesAsync(int id) =>
            MemberFormBuiltInValuesLoader.LoadAsync(_memberRepository, id);

        private async Task<IReadOnlyDictionary<string, string?>> LoadClassroomValuesAsync(int id)
        {
            var c = await _classroomRepository.GetByIdAsync(id)
                ?? throw new NotFoundException($"Classroom with id {id} not found.");

            return new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase)
            {
                ["name"] = c.Name,
                ["ageOfMembers"] = c.AgeOfMembers,
                ["leaderServantId"] = c.LeaderServantId?.ToString()
            };
        }

        private async Task<IReadOnlyDictionary<string, string?>> LoadServantValuesAsync(int id)
        {
            var s = await _servantRepository.GetByIdAsync(id)
                ?? throw new NotFoundException($"Servant with id {id} not found.");

            return new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase)
            {
                ["name"] = s.Name,
                ["phoneNumber"] = s.PhoneNumber,
                ["birthDate"] = s.BirthDate?.ToString("yyyy-MM-dd"),
                ["joiningDate"] = s.JoiningDate?.ToString("yyyy-MM-dd"),
                ["classroomId"] = s.ClassroomServants?.FirstOrDefault()?.ClassroomId.ToString(),
                ["imageUrl"] = s.ImageUrl
            };
        }

        private async Task<IReadOnlyDictionary<string, string?>> LoadMeetingValuesAsync(int id)
        {
            var m = await _meetingRepository.GetByIdAsync(id)
                ?? throw new NotFoundException($"Meeting with id {id} not found.");

            return new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase)
            {
                ["name"] = m.Name,
                ["dayOfWeek"] = m.DayOfWeek,
                ["weeklyAppointment"] = m.Weekly_appointment.ToString("HH:mm:ss"),
                ["leaderServantId"] = m.LeaderServantId?.ToString()
            };
        }

        private async Task ApplyBuiltInValuesAsync(
            string entityName,
            int entityId,
            IReadOnlyDictionary<string, string?> values)
        {
            switch (entityName)
            {
                case CustomFieldEntityNames.Member:
                    await ApplyMemberValuesAsync(entityId, values);
                    break;
                case CustomFieldEntityNames.Classroom:
                    await ApplyClassroomValuesAsync(entityId, values);
                    break;
                case CustomFieldEntityNames.Servant:
                    await ApplyServantValuesAsync(entityId, values);
                    break;
                case CustomFieldEntityNames.Meeting:
                    await ApplyMeetingValuesAsync(entityId, values);
                    break;
            }
        }

        private async Task ApplyMemberValuesAsync(int id, IReadOnlyDictionary<string, string?> values)
        {
            var update = new MemberUpdateDTO { Id = id };

            if (values.TryGetValue("name1", out var v)) update.Name1 = v;
            if (values.TryGetValue("name2", out v)) update.Name2 = v;
            if (values.TryGetValue("name3", out v)) update.Name3 = v;
            if (values.TryGetValue("gender", out v)) update.Gender = v;
            if (values.TryGetValue("address", out v)) update.Address = v;
            if (values.TryGetValue("dateOfBirth", out v)) update.DateOfBirth = EntityFormValueSerializer.ParseDate(v);
            if (values.TryGetValue("joiningDate", out v)) update.JoiningDate = EntityFormValueSerializer.ParseDate(v);
            if (values.TryGetValue("spiritualDateOfBirth", out v)) update.SpiritualDateOfBirth = EntityFormValueSerializer.ParseDate(v);
            if (values.TryGetValue("lastAttendanceDate", out v)) update.LastAttendanceDate = EntityFormValueSerializer.ParseDate(v);
            if (values.TryGetValue("isDiscipline", out v)) update.IsDiscipline = EntityFormValueSerializer.ParseBool(v);
            if (values.TryGetValue("totalNumberOfDaysAttended", out v)) update.TotalNumberOfDaysAttended = EntityFormValueSerializer.ParseInt(v);
            if (values.TryGetValue("haveBrothers", out v)) update.HaveBrothers = EntityFormValueSerializer.ParseBool(v);
            if (values.TryGetValue("brothersNames", out v)) update.BrothersNames = EntityFormValueSerializer.ParseStringList(v);
            if (values.TryGetValue("notes", out v)) update.Notes = EntityFormValueSerializer.ParseStringList(v);
            if (values.TryGetValue("phoneNumbers", out v)) update.PhoneNumbers = EntityFormValueSerializer.ParsePhoneNumbers(v);
            if (values.TryGetValue("classroomId", out v)) update.ClassroomId = EntityFormValueSerializer.ParseInt(v);

            await _memberManager.UpdateAsync(update);
        }

        private async Task ApplyClassroomValuesAsync(int id, IReadOnlyDictionary<string, string?> values)
        {
            var update = new ClassroomUpdateDTO { Id = id };
            if (values.TryGetValue("name", out var v)) update.Name = v;
            if (values.TryGetValue("ageOfMembers", out v)) update.AgeOfMembers = v;
            if (values.TryGetValue("leaderServantId", out v)) update.LeaderServantId = EntityFormValueSerializer.ParseInt(v);

            await _classroomManager.UpdateAsync(id, update);
        }

        private async Task ApplyServantValuesAsync(int id, IReadOnlyDictionary<string, string?> values)
        {
            var update = new ServantUpdateDTO { Id = id };
            if (values.TryGetValue("name", out var v)) update.Name = v;
            if (values.TryGetValue("phoneNumber", out v)) update.PhoneNumber = v;
            if (values.TryGetValue("birthDate", out v)) update.BirthDate = EntityFormValueSerializer.ParseDate(v);
            if (values.TryGetValue("joiningDate", out v)) update.JoiningDate = EntityFormValueSerializer.ParseDate(v);
            if (values.TryGetValue("classroomId", out v)) update.ClassroomId = EntityFormValueSerializer.ParseInt(v);

            await _servantManager.UpdateAsync(update);
        }

        private async Task ApplyMeetingValuesAsync(int id, IReadOnlyDictionary<string, string?> values)
        {
            var update = new MeetingUpdateDto();
            if (values.TryGetValue("name", out var v)) update.Name = v;
            if (values.TryGetValue("dayOfWeek", out v)) update.DayOfWeek = v;
            if (values.TryGetValue("weeklyAppointment", out v) &&
                TimeOnly.TryParse(v, out var time))
                update.WeeklyAppointment = time;
            if (values.TryGetValue("leaderServantId", out v)) update.LeaderServantId = EntityFormValueSerializer.ParseInt(v);

            await _meetingManager.UpdateMeeting(id, update);
        }

        private UnifiedFieldDefinitionDto? SafeToUnifiedField(CustomFieldDefinition def)
        {
            try
            {
                return CustomFieldDefinitionMapper.ToUnifiedField(def);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Skipping invalid custom field definition id={DefinitionId} name={Name}",
                    def.Id,
                    def.Name);
                return null;
            }
        }

        private static void EnsureEntity(string entityName)
        {
            if (!CustomFieldEntityNames.IsSupported(entityName))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["entityName"] = new[] { $"Entity '{entityName}' is not supported." }
                });
            }
        }
    }
}
