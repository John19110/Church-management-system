using AutoMapper;
using Microsoft.AspNetCore.Identity;
using SunDaySchools.BLL.Abstractions;
using SunDaySchools.DAL.Abstractions;
using Microsoft.Extensions.Logging;
using SunDaySchools.BLL.Authorization;
using SunDaySchools.BLL.DTOS.CustomFields;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.BLL.Services.CustomFields;
using SunDaySchools.BLL.Services.UnifiedForms;
using SunDaySchools.DAL.Models.CustomFields;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchoolsDAL.Models;
using System.Text.RegularExpressions;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class CustomFieldManager : ICustomFieldManager
    {
        private readonly ICustomFieldRepository _repository;
        private readonly ICustomFieldValidator _validator;
        private readonly IMapper _mapper;
        private readonly ITenantContext _tenantContext;
        private readonly ICurrentUserContext _currentUser;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ILogger<CustomFieldManager> _logger;

        public CustomFieldManager(
            ICustomFieldRepository repository,
            ICustomFieldValidator validator,
            IMapper mapper,
            ITenantContext tenantContext,
            ICurrentUserContext currentUser,
            UserManager<ApplicationUser> userManager,
            ILogger<CustomFieldManager> logger)
        {
            _repository = repository;
            _validator = validator;
            _mapper = mapper;
            _tenantContext = tenantContext;
            _currentUser = currentUser;
            _userManager = userManager;
            _logger = logger;
        }

        public async Task<IReadOnlyList<CustomFieldDefinitionReadDto>> GetDefinitionsByEntityAsync(
            string entityName, bool includeInactive = false)
        {
            EnsureEntityName(entityName);

            try
            {
                await EntityDefaultFieldProvisioner.EnsureDefaultsAsync(
                    _repository,
                    entityName,
                    _logger,
                    _tenantContext,
                    _currentUser);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Default field provisioning failed for {EntityName}; continuing with existing definitions.",
                    entityName);
            }

            try
            {
                var definitions = await _repository.GetDefinitionsByEntityAsync(entityName, includeInactive)
                    ?? Array.Empty<CustomFieldDefinition>();
                var dtos = CustomFieldDefinitionReadMapper.ToReadDtoList(definitions);
                var merged = EntityDefaultFieldTemplates.MergeDefinitionDtos(entityName, dtos);

                if (merged.Any(d => d.IsBuiltIn && d.Id <= 0))
                {
                    await EntityDefaultFieldProvisioner.EnsureDefaultsAsync(
                        _repository,
                        entityName,
                        _logger,
                        _tenantContext,
                        _currentUser);

                    definitions = await _repository.GetDefinitionsByEntityAsync(entityName, includeInactive)
                        ?? Array.Empty<CustomFieldDefinition>();
                    dtos = CustomFieldDefinitionReadMapper.ToReadDtoList(definitions);
                    merged = EntityDefaultFieldTemplates.MergeDefinitionDtos(entityName, dtos);
                }

                return merged;
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "GetDefinitionsByEntityAsync failed for {EntityName}",
                    entityName);
                throw;
            }
        }

        public async Task<CustomFieldDefinitionReadDto?> GetDefinitionByIdAsync(int id)
        {
            var definition = await _repository.GetDefinitionByIdAsync(id);
            return definition == null ? null : _mapper.Map<CustomFieldDefinitionReadDto>(definition);
        }

        public async Task<CustomFieldDefinitionReadDto> CreateDefinitionAsync(CustomFieldDefinitionCreateDto dto)
        {
            EnsureCanManageDefinitions();
            EnsureEntityName(dto.EntityName);

            if (string.IsNullOrWhiteSpace(dto.DisplayName))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["displayName"] = new[] { "Display name is required." }
                });
            }

            var fieldName = string.IsNullOrWhiteSpace(dto.Name)
                ? await GenerateUniqueFieldNameAsync(dto.EntityName, dto.DisplayName)
                : dto.Name.Trim();
            ValidateDefinitionName(fieldName);

            if (RequiresOptions(dto.DataType) &&
                (dto.Options == null || dto.Options.Count == 0))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["options"] = new[] { "Select fields require at least one option." }
                });
            }

            if (!string.IsNullOrWhiteSpace(dto.DefaultValue))
            {
                var temp = BuildTempDefinition(dto);
                if (!_validator.TryValidateValue(temp, dto.DefaultValue, out _, out var err))
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["defaultValue"] = new[] { err }
                    });
                }
            }

            var existing = await _repository.GetDefinitionByNameAsync(dto.EntityName, fieldName);
            if (existing != null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["name"] = new[] { "A field with this name already exists for this entity." }
                });
            }

            if (EntityDefaultFieldTemplates.IsBuiltInField(dto.EntityName, fieldName))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["name"] = new[] { "This name is reserved for a system field." }
                });
            }

            var entity = _mapper.Map<CustomFieldDefinition>(dto);
            entity.Name = fieldName;
            entity.DisplayName = dto.DisplayName.Trim();
            entity.EntityName = dto.EntityName.Trim();
            entity.CreatedAt = DateTime.UtcNow;
            entity.CreatedBy = await GetCurrentUserIdAsync();
            entity.IsActive = true;

            if (dto.Options != null)
            {
                foreach (var opt in dto.Options)
                {
                    entity.Options.Add(new CustomFieldOption
                    {
                        Value = opt.Value.Trim(),
                        DisplayText = opt.DisplayText.Trim(),
                        SortOrder = opt.SortOrder
                    });
                }
            }

            await _repository.AddDefinitionAsync(entity);
            return _mapper.Map<CustomFieldDefinitionReadDto>(
                await _repository.GetDefinitionByIdAsync(entity.Id)!);
        }

        public async Task<CustomFieldDefinitionReadDto> UpdateDefinitionAsync(
            int id, CustomFieldDefinitionUpdateDto dto)
        {
            EnsureCanManageDefinitions();

            var definition = await _repository.GetDefinitionByIdAsync(id, includeOptions: true)
                ?? throw new NotFoundException($"Custom field definition {id} was not found.");

            if (EntityDefaultFieldTemplates.IsBuiltInField(definition.EntityName, definition.Name)
                && dto.DataType.HasValue
                && dto.DataType.Value != definition.DataType)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["dataType"] = new[] { "System field data types cannot be changed." }
                });
            }

            if (dto.DataType.HasValue && dto.DataType.Value != definition.DataType)
            {
                var check = await CheckDataTypeChangeAsync(id, dto.DataType.Value);
                if (!check.CanChange)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["dataType"] = new[] { check.Message ?? "Cannot change data type due to incompatible existing values." }
                    });
                }

                definition.DataType = dto.DataType.Value;
            }

            if (!string.IsNullOrWhiteSpace(dto.DisplayName))
                definition.DisplayName = dto.DisplayName.Trim();

            if (dto.Description != null)
                definition.Description = dto.Description;

            if (dto.IsRequired.HasValue)
                definition.IsRequired = dto.IsRequired.Value;

            if (dto.IsActive.HasValue)
                definition.IsActive = dto.IsActive.Value;

            if (dto.IsReadOnly.HasValue)
                definition.IsReadOnly = dto.IsReadOnly.Value;

            if (dto.IsHidden.HasValue)
                definition.IsHidden = dto.IsHidden.Value;

            if (dto.AllowMultipleValues.HasValue)
                definition.AllowMultipleValues = dto.AllowMultipleValues.Value;

            if (dto.DefaultValue != null)
                definition.DefaultValue = dto.DefaultValue;

            if (dto.Placeholder != null)
                definition.Placeholder = dto.Placeholder;

            if (dto.ValidationRegex != null)
                definition.ValidationRegex = dto.ValidationRegex;

            if (dto.SortOrder.HasValue)
                definition.SortOrder = dto.SortOrder.Value;

            if (dto.Options != null)
            {
                SyncOptions(definition, dto.Options);
            }

            definition.UpdatedAt = DateTime.UtcNow;
            await _repository.UpdateDefinitionAsync(definition);

            var refreshed = await _repository.GetDefinitionByIdAsync(id);
            return _mapper.Map<CustomFieldDefinitionReadDto>(refreshed);
        }

        public async Task DeactivateDefinitionAsync(int id)
        {
            EnsureCanManageDefinitions();

            var definition = await _repository.GetDefinitionByIdAsync(id, includeOptions: false)
                ?? throw new NotFoundException($"Custom field definition {id} was not found.");

            if (EntityDefaultFieldTemplates.IsCriticalField(definition.EntityName, definition.Name))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["name"] = new[] { "Critical system fields cannot be deactivated." }
                });
            }

            definition.IsActive = false;
            definition.UpdatedAt = DateTime.UtcNow;
            await _repository.UpdateDefinitionAsync(definition);
        }

        public async Task<CustomFieldTypeChangeCheckDto> CheckDataTypeChangeAsync(int id, CustomFieldDataType newDataType)
        {
            var definition = await _repository.GetDefinitionByIdAsync(id)
                ?? throw new NotFoundException($"Custom field definition {id} was not found.");

            if (definition.DataType == newDataType)
            {
                return new CustomFieldTypeChangeCheckDto { CanChange = true };
            }

            if (RequiresOptions(newDataType) && definition.Options.Count == 0)
            {
                return new CustomFieldTypeChangeCheckDto
                {
                    CanChange = false,
                    Message = "Add select options before changing to a select type."
                };
            }

            var rawValues = await _repository.GetDistinctRawValuesAsync(id);
            var allowed = _validator.GetAllowedOptionValues(definition);
            var invalid = new List<string>();

            foreach (var raw in rawValues)
            {
                if (!_validator.CanParseAsType(newDataType, raw, allowed))
                    invalid.Add(raw);
            }

            var count = await _repository.CountValuesForDefinitionAsync(id);

            return new CustomFieldTypeChangeCheckDto
            {
                CanChange = invalid.Count == 0,
                ExistingValueCount = count,
                InvalidValueCount = invalid.Count,
                SampleInvalidValues = invalid.Take(10).ToList(),
                Message = invalid.Count == 0
                    ? null
                    : $"{invalid.Count} distinct stored value(s) cannot be converted to {newDataType}. Update or clear them first."
            };
        }

        public async Task<EntityCustomFieldsReadDto> GetEntityFieldsAsync(string entityName, int entityId)
        {
            EnsureEntityName(entityName);

            if (!await _repository.EntityExistsAsync(entityName, entityId))
                throw new NotFoundException($"{entityName} with id {entityId} was not found.");

            var definitions = await _repository.GetDefinitionsByEntityAsync(entityName, includeInactive: false);
            var values = await _repository.GetValuesAsync(entityName, entityId);

            var valueDtos = values
                .Where(v => v.Definition != null && v.Definition.IsActive)
                .Select(v => new CustomFieldValueReadDto
                {
                    CustomFieldDefinitionId = v.CustomFieldDefinitionId,
                    Name = v.Definition!.Name,
                    DisplayName = v.Definition.DisplayName,
                    DataType = v.Definition.DataType,
                    Value = v.Value,
                    IsReadOnly = v.Definition.IsReadOnly,
                    IsHidden = v.Definition.IsHidden
                })
                .ToList();

            return new EntityCustomFieldsReadDto
            {
                EntityName = entityName,
                EntityId = entityId,
                Definitions = _mapper.Map<List<CustomFieldDefinitionReadDto>>(definitions),
                Values = valueDtos
            };
        }

        public async Task SaveEntityValuesAsync(
            SaveCustomFieldValuesDto dto,
            bool requireAllRequiredFields = true)
        {
            EnsureAuthenticated();
            EnsureEntityName(dto.EntityName);

            if (dto.EntityId <= 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["entityId"] = new[] { "EntityId must be greater than zero." }
                });
            }

            if (!await _repository.EntityExistsAsync(dto.EntityName, dto.EntityId))
                throw new NotFoundException($"{dto.EntityName} with id {dto.EntityId} was not found.");

            var definitions = (await _repository.GetDefinitionsByEntityAsync(dto.EntityName))
                .ToDictionary(d => d.Id);

            var errors = new Dictionary<string, string[]>();
            var userId = await GetCurrentUserIdAsync();
            var rows = new List<CustomFieldValue>();

            foreach (var item in dto.Values)
            {
                if (!definitions.TryGetValue(item.CustomFieldDefinitionId, out var definition))
                {
                    errors[$"values[{item.CustomFieldDefinitionId}]"] = new[] { "Unknown field definition." };
                    continue;
                }

                if (definition.IsReadOnly && !CanManageDefinitions())
                {
                    errors[definition.Name] = new[] { "Field is read-only." };
                    continue;
                }

                if (!_validator.TryValidateValue(definition, item.Value, out var normalized, out var msg))
                {
                    errors[definition.Name] = new[] { msg };
                    continue;
                }

                rows.Add(new CustomFieldValue
                {
                    EntityName = dto.EntityName,
                    EntityId = dto.EntityId,
                    CustomFieldDefinitionId = definition.Id,
                    Value = normalized,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    CreatedBy = userId
                });
            }

            var submittedDefinitionIds = dto.Values
                .Select(v => v.CustomFieldDefinitionId)
                .ToHashSet();

            if (requireAllRequiredFields)
            {
                foreach (var definition in definitions.Values.Where(d => d.IsRequired && !d.IsHidden))
                {
                    var submitted = submittedDefinitionIds.Contains(definition.Id);
                    var existing = await _repository.GetValueAsync(definition.Id, dto.EntityName, dto.EntityId);
                    var hasValue = existing?.Value != null && existing.Value != "";

                    if (!submitted && !hasValue && string.IsNullOrWhiteSpace(definition.DefaultValue))
                    {
                        errors[definition.Name] = new[] { $"{definition.DisplayName} is required." };
                    }
                }
            }
            else
            {
                foreach (var item in dto.Values)
                {
                    if (!definitions.TryGetValue(item.CustomFieldDefinitionId, out var definition))
                        continue;

                    if (!definition.IsRequired || definition.IsHidden)
                        continue;

                    if (string.IsNullOrWhiteSpace(item.Value) &&
                        string.IsNullOrWhiteSpace(definition.DefaultValue))
                    {
                        errors[definition.Name] = new[] { $"{definition.DisplayName} is required." };
                    }
                }
            }

            if (errors.Count > 0)
            {
                _logger.LogWarning(
                    "Custom field validation failed for {Entity} id={EntityId}. Errors={@Errors}",
                    dto.EntityName,
                    dto.EntityId,
                    errors);
                throw new ValidationException(errors);
            }

            if (rows.Count > 0)
                await _repository.UpsertValuesAsync(rows);
        }

        private void SyncOptions(CustomFieldDefinition definition, List<CustomFieldOptionDto> incoming)
        {
            if (!RequiresOptions(definition.DataType))
                return;

            var existingById = definition.Options.ToDictionary(o => o.Id);
            var keptIds = new HashSet<int>();

            foreach (var dto in incoming)
            {
                if (dto.Id.HasValue && existingById.TryGetValue(dto.Id.Value, out var existing))
                {
                    existing.Value = dto.Value.Trim();
                    existing.DisplayText = dto.DisplayText.Trim();
                    existing.SortOrder = dto.SortOrder;
                    keptIds.Add(existing.Id);
                }
                else
                {
                    definition.Options.Add(new CustomFieldOption
                    {
                        Value = dto.Value.Trim(),
                        DisplayText = dto.DisplayText.Trim(),
                        SortOrder = dto.SortOrder
                    });
                }
            }

            // Soft approach: remove options not in payload only when no values reference removed option values
            var toRemove = definition.Options
                .Where(o => o.Id > 0 && !keptIds.Contains(o.Id))
                .ToList();

            foreach (var opt in toRemove)
                definition.Options.Remove(opt);
        }

        private static CustomFieldDefinition BuildTempDefinition(CustomFieldDefinitionCreateDto dto)
        {
            var def = new CustomFieldDefinition
            {
                DataType = dto.DataType,
                IsRequired = false,
                ValidationRegex = dto.ValidationRegex
            };

            if (dto.Options != null)
            {
                foreach (var o in dto.Options)
                {
                    def.Options.Add(new CustomFieldOption { Value = o.Value, DisplayText = o.DisplayText });
                }
            }

            return def;
        }

        private static bool RequiresOptions(CustomFieldDataType dataType) =>
            dataType is CustomFieldDataType.SingleSelect or CustomFieldDataType.MultiSelect;

        private static void EnsureEntityName(string entityName)
        {
            if (!CustomFieldEntityNames.IsSupported(entityName))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["entityName"] = new[] { $"Entity '{entityName}' is not supported for custom fields." }
                });
            }
        }

        private async Task<string> GenerateUniqueFieldNameAsync(string entityName, string displayName)
        {
            var definitions = await _repository.GetDefinitionsByEntityAsync(entityName, includeInactive: true);
            var existing = definitions.Select(d => d.Name).ToHashSet(StringComparer.OrdinalIgnoreCase);
            var baseName = CustomFieldNameGenerator.GenerateBaseName(displayName);
            return CustomFieldNameGenerator.EnsureUnique(baseName, existing);
        }

        private static void ValidateDefinitionName(string name)
        {
            if (string.IsNullOrWhiteSpace(name) || name.Length > 128)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["name"] = new[] { "Name is required and must be at most 128 characters." }
                });
            }

            if (!Regex.IsMatch(name, @"^[a-zA-Z][a-zA-Z0-9_]*$"))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["name"] = new[] { "Name must start with a letter and contain only letters, numbers, and underscores." }
                });
            }
        }

        private void EnsureCanManageDefinitions()
        {
            if (!CanManageDefinitions())
                throw new UnauthorizedAccessException("Only Admin or SuperAdmin can manage custom field definitions.");
        }

        private void EnsureAuthenticated()
        {
            if (!_currentUser.IsAuthenticated)
                throw new UnauthorizedAccessException("User is not authenticated.");
        }

        private bool CanManageDefinitions() =>
            CustomFieldRoles.DefinitionManagers.Any(_currentUser.IsInRole);

        private Task<string?> GetCurrentUserIdAsync() =>
            Task.FromResult(_currentUser.UserId);
    }
}
