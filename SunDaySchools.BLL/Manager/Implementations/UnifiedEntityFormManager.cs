using AutoMapper;
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
            ILogger<UnifiedEntityFormManager> logger)
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
        }

        public async Task<EntityFormSchemaDto> GetFormSchemaAsync(
            string entityName,
            EntityFormMode mode = EntityFormMode.Edit)
        {
            EnsureEntity(entityName);

            var builtIn = EntityFormSchemaRegistry.GetBuiltInFields(entityName, mode);
            var custom = await _customFieldRepository.GetDefinitionsByEntityAsync(entityName);

            var fields = new List<UnifiedFieldDefinitionDto>(builtIn);
            foreach (var def in custom.Where(d => !d.IsHidden))
            {
                fields.Add(new UnifiedFieldDefinitionDto
                {
                    FieldKey = def.Name,
                    DisplayName = def.DisplayName,
                    Description = def.Description,
                    DataType = def.DataType,
                    IsRequired = def.IsRequired,
                    IsBuiltIn = false,
                    IsReadOnly = def.IsReadOnly,
                    IsHidden = def.IsHidden,
                    SortOrder = def.SortOrder + 1000,
                    AllowMultipleValues = def.AllowMultipleValues,
                    DefaultValue = def.DefaultValue,
                    Placeholder = def.Placeholder,
                    ValidationRegex = def.ValidationRegex,
                    CustomFieldDefinitionId = def.Id,
                    Options = def.Options.Select(o => new UnifiedFieldOptionDto
                    {
                        Value = o.Value,
                        DisplayText = o.DisplayText,
                        SortOrder = o.SortOrder
                    }).ToList()
                });
            }

            return new EntityFormSchemaDto
            {
                EntityName = entityName,
                FormMode = mode.ToString(),
                Fields = fields.OrderBy(f => f.SortOrder).ThenBy(f => f.DisplayName).ToList()
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

            var schema = await GetFormSchemaAsync(entityName, EntityFormMode.Edit);
            var valuesByKey = await LoadBuiltInValuesAsync(entityName, entityId);
            var customValues = await _customFieldRepository.GetValuesAsync(entityName, entityId);
            var customByDefId = customValues.ToDictionary(v => v.CustomFieldDefinitionId, v => v.Value);

            var fields = schema.Fields.Select(def =>
            {
                var field = new UnifiedFieldDto
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
                    Options = def.Options
                };

                if (def.IsBuiltIn)
                    field.Value = valuesByKey.GetValueOrDefault(def.FieldKey);
                else if (def.CustomFieldDefinitionId.HasValue)
                    field.Value = customByDefId.GetValueOrDefault(def.CustomFieldDefinitionId.Value);

                return field;
            }).Where(f => !f.IsHidden).ToList();

            return new EntityFormDataDto
            {
                EntityName = entityName,
                EntityId = entityId,
                Fields = fields
            };
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
            var builtInValues = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);
            var customItems = new List<CustomFieldValueItemDto>();

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
                        "Unknown field. Define it in custom field definitions or use a built-in field key from form-schema."
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

                if (meta.IsBuiltIn)
                    builtInValues[key] = value;
                else if (meta.CustomFieldDefinitionId.HasValue)
                    customItems.Add(new CustomFieldValueItemDto
                    {
                        CustomFieldDefinitionId = meta.CustomFieldDefinitionId.Value,
                        Value = value
                    });
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
                if (builtInValues.Count > 0)
                    await ApplyBuiltInValuesAsync(entityName, entityId, builtInValues);

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

        private async Task<Dictionary<string, string?>> LoadBuiltInValuesAsync(string entityName, int entityId)
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

        private async Task<Dictionary<string, string?>> LoadMemberValuesAsync(int id)
        {
            var m = await _memberRepository.GetByIdAsync(id)
                ?? throw new NotFoundException($"Member with id {id} not found.");

            return new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase)
            {
                ["name1"] = m.Name1,
                ["name2"] = m.Name2,
                ["name3"] = m.Name3,
                ["gender"] = m.Gender,
                ["address"] = m.Address,
                ["dateOfBirth"] = m.DateOfBirth.ToString("yyyy-MM-dd"),
                ["joiningDate"] = m.JoiningDate.ToString("yyyy-MM-dd"),
                ["spiritualDateOfBirth"] = m.SpiritualDateOfBirth?.ToString("yyyy-MM-dd"),
                ["lastAttendanceDate"] = m.LastAttendanceDate.ToString("yyyy-MM-dd"),
                ["isDiscipline"] = m.IsDiscipline.ToString().ToLowerInvariant(),
                ["totalNumberOfDaysAttended"] = m.TotalNumberOfDaysAttended.ToString(),
                ["haveBrothers"] = (m.HaveBrothers ?? false).ToString().ToLowerInvariant(),
                ["brothersNames"] = EntityFormValueSerializer.ToJson(m.BrothersNames),
                ["notes"] = EntityFormValueSerializer.ToJson(m.Notes),
                ["phoneNumbers"] = EntityFormValueSerializer.ToJson(
                    m.PhoneNumbers?.Select(p => new MemberContactDTO
                    {
                        Relation = p.Relation,
                        PhoneNumber = p.PhoneNumber
                    }).ToList()),
                ["classroomId"] = m.ClassroomId?.ToString(),
                ["imageUrl"] = m.ImageUrl
            };
        }

        private async Task<Dictionary<string, string?>> LoadClassroomValuesAsync(int id)
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

        private async Task<Dictionary<string, string?>> LoadServantValuesAsync(int id)
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

        private async Task<Dictionary<string, string?>> LoadMeetingValuesAsync(int id)
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
