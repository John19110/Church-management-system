using System.Globalization;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Church.BLL.Abstractions;
using Church.BLL.Authorization;
using Church.BLL.DTOS.CustomFeatures;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services.CustomFields;
using Church.BLL.Services.CustomFeatures;
using Church.DAL.Abstractions;
using Church.DAL.Models.CustomFeatures;
using Church.DAL.Repository.Interfaces;

namespace Church.BLL.Manager.Implementations
{
    public class CustomFeatureManager : ICustomFeatureManager
    {
        public const int MaxFeaturesPerChurch = 20;
        public const int MaxEntitiesPerFeature = 15;
        public const int MaxFieldsPerEntity = 40;

        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        private readonly ICustomFeatureRepository _repository;
        private readonly ITenantContext _tenantContext;
        private readonly ICurrentUserContext _currentUser;

        public CustomFeatureManager(
            ICustomFeatureRepository repository,
            ITenantContext tenantContext,
            ICurrentUserContext currentUser)
        {
            _repository = repository;
            _tenantContext = tenantContext;
            _currentUser = currentUser;
        }

        public async Task<IReadOnlyList<CustomFeatureReadDto>> GetFeaturesAsync(bool includeInactive = false)
        {
            EnsureAuthenticated();
            var features = await _repository.GetFeaturesAsync(includeInactive);
            return features.Select(ToFeatureDto).ToList();
        }

        public async Task<CustomFeatureReadDto?> GetFeatureByIdAsync(int id)
        {
            EnsureAuthenticated();
            var feature = await _repository.GetFeatureByIdAsync(id);
            return feature == null ? null : ToFeatureDto(feature);
        }

        public async Task<CustomFeatureReadDto> CreateFeatureAsync(CustomFeatureCreateDto dto)
        {
            EnsureCanManageMetadata();
            EnsureDisplayName(dto.DisplayName);

            if (await _repository.CountFeaturesAsync() >= MaxFeaturesPerChurch)
            {
                throw FieldError("feature", "A church can have at most 20 custom features.");
            }

            var name = string.IsNullOrWhiteSpace(dto.Name)
                ? CustomFieldNameGenerator.GenerateBaseName(dto.DisplayName)
                : dto.Name.Trim();
            ValidateTechnicalName(name, "name");

            var existing = await _repository.GetFeatureByNameAsync(name);
            if (existing != null)
                throw FieldError("name", "A feature with this name already exists.");

            var feature = new CustomFeature
            {
                Name = name,
                DisplayName = dto.DisplayName.Trim(),
                DisplayNameAr = EmptyToNull(dto.DisplayNameAr),
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = _currentUser.UserId,
                ChurchId = RequireChurchId(),
                MeetingId = ResolveCreatedMeetingId()
            };

            await _repository.AddFeatureAsync(feature);
            await _repository.SaveChangesAsync();
            return ToFeatureDto(feature);
        }

        public async Task<CustomFeatureReadDto> UpdateFeatureAsync(int id, CustomFeatureUpdateDto dto)
        {
            EnsureCanManageMetadata();
            EnsureDisplayName(dto.DisplayName);

            var feature = await _repository.GetFeatureByIdAsync(id)
                ?? throw new NotFoundException("Feature not found.");

            feature.DisplayName = dto.DisplayName.Trim();
            feature.DisplayNameAr = EmptyToNull(dto.DisplayNameAr);
            if (dto.IsActive.HasValue)
                feature.IsActive = dto.IsActive.Value;
            feature.UpdatedAt = DateTime.UtcNow;
            await _repository.SaveChangesAsync();
            return ToFeatureDto(feature);
        }

        public async Task DeleteFeatureAsync(int id)
        {
            EnsureCanManageMetadata();
            var feature = await _repository.GetFeatureByIdAsync(id, includeEntities: false)
                ?? throw new NotFoundException("Feature not found.");
            await _repository.DeleteFeatureAsync(feature);
            await _repository.SaveChangesAsync();
        }

        public async Task<IReadOnlyList<CustomEntityReadDto>> GetEntitiesAsync(
            int featureId,
            bool includeInactive = false)
        {
            EnsureAuthenticated();
            var feature = await _repository.GetFeatureByIdAsync(featureId, includeEntities: false)
                ?? throw new NotFoundException("Feature not found.");
            _ = feature;
            var entities = await _repository.GetEntitiesByFeatureAsync(featureId, includeInactive);
            return entities.Select(ToEntityDto).ToList();
        }

        public async Task<CustomEntityReadDto?> GetEntityByIdAsync(int id)
        {
            EnsureAuthenticated();
            var entity = await _repository.GetEntityByIdAsync(id);
            return entity == null ? null : ToEntityDto(entity);
        }

        public async Task<CustomEntityReadDto> CreateEntityAsync(int featureId, CustomEntityCreateDto dto)
        {
            EnsureCanManageMetadata();
            EnsureDisplayName(dto.DisplayName);

            var feature = await _repository.GetFeatureByIdAsync(featureId, includeEntities: false)
                ?? throw new NotFoundException("Feature not found.");

            if (await _repository.CountEntitiesAsync(featureId) >= MaxEntitiesPerFeature)
                throw FieldError("entity", "A feature can have at most 15 entities.");

            var name = string.IsNullOrWhiteSpace(dto.Name)
                ? CustomFieldNameGenerator.GenerateBaseName(dto.DisplayName)
                : dto.Name.Trim();
            ValidateTechnicalName(name, "name");

            var plural = string.IsNullOrWhiteSpace(dto.PluralDisplayName)
                ? dto.DisplayName.Trim() + "s"
                : dto.PluralDisplayName.Trim();

            var entity = new CustomEntity
            {
                FeatureId = feature.Id,
                Name = name,
                DisplayName = dto.DisplayName.Trim(),
                DisplayNameAr = EmptyToNull(dto.DisplayNameAr),
                PluralDisplayName = plural,
                PluralDisplayNameAr = EmptyToNull(dto.PluralDisplayNameAr),
                IsActive = true,
                SortOrder = dto.SortOrder,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = _currentUser.UserId,
                ChurchId = feature.ChurchId,
                MeetingId = feature.MeetingId
            };

            foreach (var permission in DefaultPermissions(entity))
                entity.Permissions.Add(permission);

            await _repository.AddEntityAsync(entity);
            await _repository.SaveChangesAsync();

            var created = await _repository.GetEntityByIdAsync(entity.Id);
            return ToEntityDto(created!);
        }

        public async Task<CustomEntityReadDto> UpdateEntityAsync(int id, CustomEntityUpdateDto dto)
        {
            EnsureCanManageMetadata();
            EnsureDisplayName(dto.DisplayName);
            if (string.IsNullOrWhiteSpace(dto.PluralDisplayName))
                throw FieldError("pluralDisplayName", "Plural display name is required.");

            var entity = await _repository.GetEntityByIdAsync(id)
                ?? throw new NotFoundException("Entity not found.");

            entity.DisplayName = dto.DisplayName.Trim();
            entity.DisplayNameAr = EmptyToNull(dto.DisplayNameAr);
            entity.PluralDisplayName = dto.PluralDisplayName.Trim();
            entity.PluralDisplayNameAr = EmptyToNull(dto.PluralDisplayNameAr);
            if (dto.IsActive.HasValue)
                entity.IsActive = dto.IsActive.Value;
            if (dto.SortOrder.HasValue)
                entity.SortOrder = dto.SortOrder.Value;
            entity.UpdatedAt = DateTime.UtcNow;
            await _repository.SaveChangesAsync();
            return ToEntityDto(entity);
        }

        public async Task DeleteEntityAsync(int id)
        {
            EnsureCanManageMetadata();
            var entity = await _repository.GetEntityByIdAsync(id, includeFields: false, includePermissions: false)
                ?? throw new NotFoundException("Entity not found.");
            await _repository.DeleteEntityAsync(entity);
            await _repository.SaveChangesAsync();
        }

        public async Task<CustomEntityFieldReadDto> CreateFieldAsync(int entityId, CustomEntityFieldCreateDto dto)
        {
            EnsureCanManageMetadata();
            EnsureDisplayName(dto.DisplayName);

            var entity = await _repository.GetEntityByIdAsync(entityId)
                ?? throw new NotFoundException("Entity not found.");

            if (await _repository.CountFieldsAsync(entityId) >= MaxFieldsPerEntity)
                throw FieldError("field", "An entity can have at most 40 fields.");

            var name = string.IsNullOrWhiteSpace(dto.Name)
                ? CustomFieldNameGenerator.GenerateBaseName(dto.DisplayName)
                : dto.Name.Trim();
            ValidateTechnicalName(name, "name");

            if (entity.Fields.Any(f => f.Name.Equals(name, StringComparison.OrdinalIgnoreCase)))
                throw FieldError("name", "A field with this name already exists for this entity.");

            await ValidateFieldType(dto, entity);

            var field = new CustomEntityField
            {
                EntityId = entity.Id,
                Name = name,
                DisplayName = dto.DisplayName.Trim(),
                DisplayNameAr = EmptyToNull(dto.DisplayNameAr),
                FieldType = dto.FieldType,
                IsRequired = dto.IsRequired,
                IsUnique = dto.IsUnique,
                IsSearchable = dto.IsSearchable,
                ShowOnList = dto.ShowOnList,
                ShowOnForm = dto.ShowOnForm,
                ShowOnDetails = dto.ShowOnDetails,
                DisplayOrder = dto.DisplayOrder,
                Placeholder = EmptyToNull(dto.Placeholder),
                ValidationRegex = EmptyToNull(dto.ValidationRegex),
                TargetEntityId = dto.TargetEntityId,
                CoreReference = CoreReferenceFor(dto.FieldType),
                CreatedAt = DateTime.UtcNow,
                CreatedBy = _currentUser.UserId,
                ChurchId = entity.ChurchId,
                MeetingId = entity.MeetingId
            };

            foreach (var option in MapOptions(dto.Options))
                field.Options.Add(option);

            await _repository.AddFieldAsync(field);
            await _repository.SaveChangesAsync();
            return ToFieldDto(field);
        }

        public async Task<CustomEntityFieldReadDto> UpdateFieldAsync(int id, CustomEntityFieldUpdateDto dto)
        {
            EnsureCanManageMetadata();
            EnsureDisplayName(dto.DisplayName);

            var field = await _repository.GetFieldByIdAsync(id)
                ?? throw new NotFoundException("Field not found.");

            field.DisplayName = dto.DisplayName.Trim();
            field.DisplayNameAr = EmptyToNull(dto.DisplayNameAr);
            if (dto.IsRequired.HasValue) field.IsRequired = dto.IsRequired.Value;
            if (dto.IsUnique.HasValue) field.IsUnique = dto.IsUnique.Value;
            if (dto.IsSearchable.HasValue) field.IsSearchable = dto.IsSearchable.Value;
            if (dto.ShowOnList.HasValue) field.ShowOnList = dto.ShowOnList.Value;
            if (dto.ShowOnForm.HasValue) field.ShowOnForm = dto.ShowOnForm.Value;
            if (dto.ShowOnDetails.HasValue) field.ShowOnDetails = dto.ShowOnDetails.Value;
            if (dto.DisplayOrder.HasValue) field.DisplayOrder = dto.DisplayOrder.Value;
            if (dto.Placeholder != null) field.Placeholder = EmptyToNull(dto.Placeholder);
            if (dto.ValidationRegex != null) field.ValidationRegex = EmptyToNull(dto.ValidationRegex);

            if (dto.Options != null)
            {
                if (RequiresOptions(field.FieldType) && dto.Options.Count == 0)
                    throw FieldError("options", "Select fields require at least one option.");

                field.Options.Clear();
                foreach (var option in MapOptions(dto.Options))
                    field.Options.Add(option);
            }

            field.UpdatedAt = DateTime.UtcNow;
            await _repository.SaveChangesAsync();
            return ToFieldDto(field);
        }

        public async Task DeleteFieldAsync(int id)
        {
            EnsureCanManageMetadata();
            var field = await _repository.GetFieldByIdAsync(id, includeOptions: false)
                ?? throw new NotFoundException("Field not found.");
            await _repository.DeleteFieldAsync(field);
            await _repository.SaveChangesAsync();
        }

        public async Task<IReadOnlyList<CustomEntityPermissionDto>> GetPermissionsAsync(int entityId)
        {
            EnsureCanManageMetadata();
            var entity = await _repository.GetEntityByIdAsync(entityId, includeFields: false)
                ?? throw new NotFoundException("Entity not found.");
            return entity.Permissions.Select(ToPermissionDto).ToList();
        }

        public async Task<IReadOnlyList<CustomEntityPermissionDto>> UpdatePermissionsAsync(
            int entityId,
            IReadOnlyList<CustomEntityPermissionDto> permissions)
        {
            EnsureCanManageMetadata();
            var entity = await _repository.GetEntityByIdAsync(entityId, includeFields: false)
                ?? throw new NotFoundException("Entity not found.");

            var mapped = new List<CustomEntityPermission>();
            foreach (var role in CustomFeatureRoles.All)
            {
                var incoming = permissions.FirstOrDefault(p =>
                    p.RoleName.Equals(role, StringComparison.OrdinalIgnoreCase));
                mapped.Add(new CustomEntityPermission
                {
                    EntityId = entity.Id,
                    RoleName = role,
                    CanCreate = incoming?.CanCreate ?? false,
                    CanRead = incoming?.CanRead ?? role != CustomFeatureRoles.Servant,
                    CanUpdate = incoming?.CanUpdate ?? false,
                    CanDelete = incoming?.CanDelete ?? false,
                    ChurchId = entity.ChurchId,
                    MeetingId = entity.MeetingId
                });
            }

            await _repository.ReplacePermissionsAsync(entityId, mapped);
            await _repository.SaveChangesAsync();
            return mapped.Select(ToPermissionDto).ToList();
        }

        public async Task<CustomEntityRecordPageDto> GetRecordsAsync(
            int entityId,
            string? search,
            string? sort,
            bool descending,
            int page,
            int pageSize)
        {
            var entity = await RequireActiveEntityForRecordAsync(entityId, requireRead: true);
            page = page < 1 ? 1 : page;
            pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

            var (items, total) = await _repository.GetRecordsAsync(
                entity.Id,
                search,
                sort,
                descending,
                page,
                pageSize);

            var dtos = new List<CustomEntityRecordReadDto>();
            foreach (var record in items)
                dtos.Add(await ToRecordDtoAsync(entity, record));

            return new CustomEntityRecordPageDto
            {
                Items = dtos,
                Total = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<CustomEntityRecordReadDto?> GetRecordByIdAsync(int entityId, int recordId)
        {
            var entity = await RequireActiveEntityForRecordAsync(entityId, requireRead: true);
            var record = await _repository.GetRecordByIdAsync(recordId);
            if (record == null || record.EntityId != entity.Id)
                return null;
            return await ToRecordDtoAsync(entity, record);
        }

        public async Task<CustomEntityRecordReadDto> CreateRecordAsync(
            int entityId,
            CustomEntityRecordWriteDto dto)
        {
            var entity = await RequireActiveEntityForRecordAsync(entityId, requireCreate: true);
            var (json, references) = await BuildRecordPayloadAsync(entity, dto.Values, excludeRecordId: null);

            var record = new CustomEntityRecord
            {
                EntityId = entity.Id,
                DataJson = json,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = _currentUser.UserId,
                ChurchId = entity.ChurchId,
                MeetingId = entity.MeetingId
            };

            await _repository.AddRecordAsync(record);
            await _repository.SaveChangesAsync();

            foreach (var reference in references)
                reference.RecordId = record.Id;
            await _repository.ReplaceRecordReferencesAsync(record.Id, references);
            await _repository.SaveChangesAsync();

            var created = await _repository.GetRecordByIdAsync(record.Id);
            return await ToRecordDtoAsync(entity, created!);
        }

        public async Task<CustomEntityRecordReadDto> UpdateRecordAsync(
            int entityId,
            int recordId,
            CustomEntityRecordWriteDto dto)
        {
            var entity = await RequireActiveEntityForRecordAsync(entityId, requireUpdate: true);
            var record = await _repository.GetRecordByIdAsync(recordId)
                ?? throw new NotFoundException("Record not found.");
            if (record.EntityId != entity.Id)
                throw new NotFoundException("Record not found.");

            var (json, references) = await BuildRecordPayloadAsync(entity, dto.Values, record.Id);
            record.DataJson = json;
            record.UpdatedAt = DateTime.UtcNow;
            foreach (var reference in references)
                reference.RecordId = record.Id;
            await _repository.ReplaceRecordReferencesAsync(record.Id, references);
            await _repository.SaveChangesAsync();

            var updated = await _repository.GetRecordByIdAsync(record.Id);
            return await ToRecordDtoAsync(entity, updated!);
        }

        public async Task DeleteRecordAsync(int entityId, int recordId)
        {
            var entity = await RequireActiveEntityForRecordAsync(entityId, requireDelete: true);
            var record = await _repository.GetRecordByIdAsync(recordId, includeReferences: false)
                ?? throw new NotFoundException("Record not found.");
            if (record.EntityId != entity.Id)
                throw new NotFoundException("Record not found.");

            await _repository.DeleteRecordAsync(record);
            await _repository.SaveChangesAsync();
        }

        private async Task<(string Json, List<CustomEntityRecordReference> References)> BuildRecordPayloadAsync(
            CustomEntity entity,
            Dictionary<string, object?> values,
            int? excludeRecordId)
        {
            var scalars = new Dictionary<string, object?>();
            var references = new List<CustomEntityRecordReference>();
            var errors = new Dictionary<string, string[]>();

            foreach (var field in entity.Fields.Where(f => f.ShowOnForm || f.IsRequired))
            {
                values.TryGetValue(field.Name, out var raw);
                if (IsReferenceType(field.FieldType))
                {
                    var ids = CustomEntityRecordValidator.ParseIdList(raw);
                    if (field.IsRequired && ids.Count == 0)
                    {
                        errors[field.Name] = new[] { $"{field.DisplayName} is required." };
                        continue;
                    }

                    if (field.FieldType is CustomEntityFieldType.MemberReference
                        or CustomEntityFieldType.ServantReference
                        or CustomEntityFieldType.EntityReference
                        && ids.Count > 1)
                    {
                        errors[field.Name] = new[] { $"{field.DisplayName} accepts one value." };
                        continue;
                    }

                    try
                    {
                        references.AddRange(await BuildReferencesAsync(entity, field, ids));
                    }
                    catch (ValidationException ex)
                    {
                        foreach (var pair in ex.Errors)
                            errors[pair.Key] = pair.Value;
                    }

                    continue;
                }

                if (!CustomEntityRecordValidator.TryValidateScalar(field, raw, out var normalized, out var error))
                {
                    errors[field.Name] = new[] { error };
                    continue;
                }

                if (field.IsUnique && normalized != null)
                {
                    var exists = await _repository.ScalarValueExistsAsync(
                        entity.Id,
                        field.Name,
                        normalized,
                        excludeRecordId);
                    if (exists)
                        errors[field.Name] = new[] { $"{field.DisplayName} must be unique." };
                }

                if (normalized != null)
                    scalars[field.Name] = UnwrapScalar(field.FieldType, normalized);
            }

            if (errors.Count > 0)
                throw new ValidationException(errors);

            var json = JsonSerializer.Serialize(scalars, JsonOptions);
            if (Encoding.UTF8.GetByteCount(json) > CustomEntityRecordValidator.MaxJsonBytes)
                throw FieldError("values", "Record payload is too large.");

            return (json, references);
        }

        private async Task<List<CustomEntityRecordReference>> BuildReferencesAsync(
            CustomEntity entity,
            CustomEntityField field,
            IReadOnlyList<int> ids)
        {
            var references = new List<CustomEntityRecordReference>();

            if (field.FieldType == CustomEntityFieldType.MemberReference)
            {
                foreach (var id in ids)
                {
                    if (!await _repository.MemberExistsAsync(id))
                        throw FieldError(field.Name, "Referenced member was not found.");
                    references.Add(new CustomEntityRecordReference
                    {
                        FieldId = field.Id,
                        TargetKind = CustomEntityReferenceTargetKind.Member,
                        TargetMemberId = id
                    });
                }

                return references;
            }

            if (field.FieldType == CustomEntityFieldType.ServantReference)
            {
                foreach (var id in ids)
                {
                    if (!await _repository.ServantExistsAsync(id))
                        throw FieldError(field.Name, "Referenced servant was not found.");
                    references.Add(new CustomEntityRecordReference
                    {
                        FieldId = field.Id,
                        TargetKind = CustomEntityReferenceTargetKind.Servant,
                        TargetServantId = id
                    });
                }

                return references;
            }

            if (field.TargetEntityId is not int targetEntityId)
                throw FieldError(field.Name, "Entity reference is missing a target entity.");

            var target = await _repository.GetEntityByIdAsync(targetEntityId, includeFields: false, includePermissions: false)
                ?? throw FieldError(field.Name, "Referenced entity was not found.");
            if (target.FeatureId != entity.FeatureId)
                throw FieldError(field.Name, "Referenced entity must belong to the same feature.");

            var existing = await _repository.GetRecordsByIdsAsync(target.Id, ids);
            if (existing.Count != ids.Count)
                throw FieldError(field.Name, "One or more referenced records were not found.");

            foreach (var id in ids)
            {
                references.Add(new CustomEntityRecordReference
                {
                    FieldId = field.Id,
                    TargetKind = CustomEntityReferenceTargetKind.CustomRecord,
                    TargetRecordId = id
                });
            }

            return references;
        }

        private async Task<CustomEntityRecordReadDto> ToRecordDtoAsync(
            CustomEntity entity,
            CustomEntityRecord record)
        {
            var values = ParseJson(record.DataJson);
            var memberIds = record.References
                .Where(r => r.TargetMemberId.HasValue)
                .Select(r => r.TargetMemberId!.Value)
                .Distinct()
                .ToList();
            var servantIds = record.References
                .Where(r => r.TargetServantId.HasValue)
                .Select(r => r.TargetServantId!.Value)
                .Distinct()
                .ToList();
            var memberNames = await _repository.GetMemberNamesAsync(memberIds);
            var servantNames = await _repository.GetServantNamesAsync(servantIds);

            foreach (var field in entity.Fields.Where(IsReferenceType))
            {
                var fieldRefs = record.References.Where(r => r.FieldId == field.Id).ToList();
                if (field.FieldType is CustomEntityFieldType.EntityMultiReference
                    or CustomEntityFieldType.MultiSelect)
                {
                    values[field.Name] = fieldRefs.Select(ReferenceValue).ToList();
                }
                else if (fieldRefs.Count > 0)
                {
                    var first = fieldRefs[0];
                    values[field.Name] = ReferenceValue(first);
                    if (first.TargetMemberId is int memberId && memberNames.TryGetValue(memberId, out var memberName))
                        values[field.Name + "Label"] = memberName;
                    if (first.TargetServantId is int servantId && servantNames.TryGetValue(servantId, out var servantName))
                        values[field.Name + "Label"] = servantName;
                }
            }

            return new CustomEntityRecordReadDto
            {
                Id = record.Id,
                EntityId = record.EntityId,
                Values = values,
                CreatedAt = record.CreatedAt,
                UpdatedAt = record.UpdatedAt
            };
        }

        private static object? ReferenceValue(CustomEntityRecordReference reference) =>
            reference.TargetKind switch
            {
                CustomEntityReferenceTargetKind.Member => reference.TargetMemberId,
                CustomEntityReferenceTargetKind.Servant => reference.TargetServantId,
                _ => reference.TargetRecordId
            };

        private async Task<CustomEntity> RequireActiveEntityForRecordAsync(
            int entityId,
            bool requireRead = false,
            bool requireCreate = false,
            bool requireUpdate = false,
            bool requireDelete = false)
        {
            EnsureAuthenticated();
            var entity = await _repository.GetEntityByIdAsync(entityId)
                ?? throw new NotFoundException("Entity not found.");

            if (entity.Feature == null || !entity.Feature.IsActive || !entity.IsActive)
                throw new NotFoundException("Entity not found.");

            var permission = PermissionForCaller(entity);
            if (permission == null)
                throw new UnauthorizedAccessException("You do not have access to this entity.");

            if (requireRead && !permission.CanRead)
                throw new UnauthorizedAccessException("Read permission is required.");
            if (requireCreate && !permission.CanCreate)
                throw new UnauthorizedAccessException("Create permission is required.");
            if (requireUpdate && !permission.CanUpdate)
                throw new UnauthorizedAccessException("Update permission is required.");
            if (requireDelete && !permission.CanDelete)
                throw new UnauthorizedAccessException("Delete permission is required.");

            return entity;
        }

        private CustomEntityPermission? PermissionForCaller(CustomEntity entity)
        {
            foreach (var role in CustomFeatureRoles.All)
            {
                if (!_currentUser.IsInRole(role))
                    continue;
                return entity.Permissions.FirstOrDefault(p =>
                    p.RoleName.Equals(role, StringComparison.OrdinalIgnoreCase));
            }

            return null;
        }

        private async Task ValidateFieldType(CustomEntityFieldCreateDto dto, CustomEntity entity)
        {
            if (RequiresOptions(dto.FieldType) && (dto.Options == null || dto.Options.Count == 0))
                throw FieldError("options", "Select fields require at least one option.");

            if (dto.FieldType is CustomEntityFieldType.EntityReference or CustomEntityFieldType.EntityMultiReference)
            {
                if (dto.TargetEntityId is not int targetId)
                    throw FieldError("targetEntityId", "Entity reference requires a target entity.");

                var target = await _repository.GetEntityByIdAsync(targetId, includeFields: false, includePermissions: false)
                    ?? throw FieldError("targetEntityId", "Target entity was not found.");
                if (target.FeatureId != entity.FeatureId)
                    throw FieldError("targetEntityId", "Target entity must belong to the same feature.");
            }
            else if (dto.TargetEntityId.HasValue)
            {
                throw FieldError("targetEntityId", "Only entity reference fields may set a target entity.");
            }
        }

        private IEnumerable<CustomEntityPermission> DefaultPermissions(CustomEntity entity)
        {
            yield return new CustomEntityPermission
            {
                RoleName = CustomFeatureRoles.SuperAdmin,
                CanCreate = true,
                CanRead = true,
                CanUpdate = true,
                CanDelete = true,
                ChurchId = entity.ChurchId,
                MeetingId = entity.MeetingId
            };
            yield return new CustomEntityPermission
            {
                RoleName = CustomFeatureRoles.Admin,
                CanCreate = true,
                CanRead = true,
                CanUpdate = true,
                CanDelete = true,
                ChurchId = entity.ChurchId,
                MeetingId = entity.MeetingId
            };
            yield return new CustomEntityPermission
            {
                RoleName = CustomFeatureRoles.Servant,
                CanCreate = false,
                CanRead = true,
                CanUpdate = false,
                CanDelete = false,
                ChurchId = entity.ChurchId,
                MeetingId = entity.MeetingId
            };
        }

        private int RequireChurchId() =>
            _tenantContext.ChurchId
            ?? throw new UnauthorizedAccessException("ChurchId claim is missing.");

        private int? ResolveCreatedMeetingId() =>
            _currentUser.IsInRole(CustomFeatureRoles.SuperAdmin)
                ? null
                : _tenantContext.MeetingId;

        private void EnsureCanManageMetadata()
        {
            EnsureAuthenticated();
            if (!CustomFeatureRoles.MetadataManagers.Any(_currentUser.IsInRole))
                throw new UnauthorizedAccessException("Only Admin or SuperAdmin can manage custom features.");
        }

        private void EnsureAuthenticated()
        {
            if (!_currentUser.IsAuthenticated)
                throw new UnauthorizedAccessException("User is not authenticated.");
        }

        private static void EnsureDisplayName(string? displayName)
        {
            if (string.IsNullOrWhiteSpace(displayName))
                throw FieldError("displayName", "Display name is required.");
        }

        private static void ValidateTechnicalName(string name, string field)
        {
            if (name.Length > 128 || !Regex.IsMatch(name, @"^[a-zA-Z][a-zA-Z0-9_]*$"))
            {
                throw FieldError(
                    field,
                    "Name must start with a letter and contain only letters, numbers, and underscores.");
            }
        }

        private static ValidationException FieldError(string field, string message) =>
            new(new Dictionary<string, string[]> { [field] = new[] { message } });

        private static string? EmptyToNull(string? value) =>
            string.IsNullOrWhiteSpace(value) ? null : value.Trim();

        private static bool RequiresOptions(CustomEntityFieldType type) =>
            type is CustomEntityFieldType.Dropdown or CustomEntityFieldType.MultiSelect;

        private static bool IsReferenceType(CustomEntityField field) =>
            IsReferenceType(field.FieldType);

        private static bool IsReferenceType(CustomEntityFieldType type) =>
            type is CustomEntityFieldType.MemberReference
                or CustomEntityFieldType.ServantReference
                or CustomEntityFieldType.EntityReference
                or CustomEntityFieldType.EntityMultiReference;

        private static CustomEntityCoreReference CoreReferenceFor(CustomEntityFieldType type) =>
            type switch
            {
                CustomEntityFieldType.MemberReference => CustomEntityCoreReference.Member,
                CustomEntityFieldType.ServantReference => CustomEntityCoreReference.Servant,
                _ => CustomEntityCoreReference.None
            };

        private static IEnumerable<CustomEntityFieldOption> MapOptions(
            IEnumerable<CustomEntityFieldOptionDto>? options)
        {
            if (options == null)
                yield break;

            var index = 0;
            foreach (var option in options)
            {
                var value = string.IsNullOrWhiteSpace(option.Value)
                    ? CustomFieldNameGenerator.GenerateBaseName(option.DisplayText)
                    : option.Value.Trim();
                yield return new CustomEntityFieldOption
                {
                    Value = value,
                    DisplayText = string.IsNullOrWhiteSpace(option.DisplayText) ? value : option.DisplayText.Trim(),
                    DisplayTextAr = EmptyToNull(option.DisplayTextAr),
                    SortOrder = option.SortOrder != 0 ? option.SortOrder : index
                };
                index++;
            }
        }

        private static Dictionary<string, object?> ParseJson(string json)
        {
            if (string.IsNullOrWhiteSpace(json))
                return new Dictionary<string, object?>();

            try
            {
                return JsonSerializer.Deserialize<Dictionary<string, object?>>(json, JsonOptions)
                    ?? new Dictionary<string, object?>();
            }
            catch (JsonException)
            {
                return new Dictionary<string, object?>();
            }
        }

        private static object? UnwrapScalar(CustomEntityFieldType type, string value)
        {
            return type switch
            {
                CustomEntityFieldType.Number when int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var n) => n,
                CustomEntityFieldType.Decimal when decimal.TryParse(value, NumberStyles.Number, CultureInfo.InvariantCulture, out var d) => d,
                CustomEntityFieldType.Boolean when bool.TryParse(value, out var b) => b,
                CustomEntityFieldType.MultiSelect => JsonSerializer.Deserialize<List<string>>(value) ?? new List<string>(),
                _ => value
            };
        }

        private static CustomFeatureReadDto ToFeatureDto(CustomFeature feature) =>
            new()
            {
                Id = feature.Id,
                Name = feature.Name,
                DisplayName = feature.DisplayName,
                DisplayNameAr = feature.DisplayNameAr,
                IsActive = feature.IsActive,
                MeetingId = feature.MeetingId,
                CreatedAt = feature.CreatedAt,
                Entities = feature.Entities?.Select(ToEntityDto).ToList() ?? new List<CustomEntityReadDto>()
            };

        private static CustomEntityReadDto ToEntityDto(CustomEntity entity) =>
            new()
            {
                Id = entity.Id,
                FeatureId = entity.FeatureId,
                Name = entity.Name,
                DisplayName = entity.DisplayName,
                DisplayNameAr = entity.DisplayNameAr,
                PluralDisplayName = entity.PluralDisplayName,
                PluralDisplayNameAr = entity.PluralDisplayNameAr,
                IsActive = entity.IsActive,
                SortOrder = entity.SortOrder,
                Fields = entity.Fields?
                    .OrderBy(f => f.DisplayOrder)
                    .Select(ToFieldDto)
                    .ToList() ?? new List<CustomEntityFieldReadDto>(),
                Permissions = entity.Permissions?.Select(ToPermissionDto).ToList()
                    ?? new List<CustomEntityPermissionDto>()
            };

        private static CustomEntityFieldReadDto ToFieldDto(CustomEntityField field) =>
            new()
            {
                Id = field.Id,
                EntityId = field.EntityId,
                Name = field.Name,
                DisplayName = field.DisplayName,
                DisplayNameAr = field.DisplayNameAr,
                FieldType = field.FieldType,
                IsRequired = field.IsRequired,
                IsUnique = field.IsUnique,
                IsSearchable = field.IsSearchable,
                ShowOnList = field.ShowOnList,
                ShowOnForm = field.ShowOnForm,
                ShowOnDetails = field.ShowOnDetails,
                DisplayOrder = field.DisplayOrder,
                Placeholder = field.Placeholder,
                ValidationRegex = field.ValidationRegex,
                TargetEntityId = field.TargetEntityId,
                CoreReference = field.CoreReference,
                Options = field.Options?
                    .OrderBy(o => o.SortOrder)
                    .Select(o => new CustomEntityFieldOptionDto
                    {
                        Id = o.Id,
                        Value = o.Value,
                        DisplayText = o.DisplayText,
                        DisplayTextAr = o.DisplayTextAr,
                        SortOrder = o.SortOrder
                    })
                    .ToList() ?? new List<CustomEntityFieldOptionDto>()
            };

        private static CustomEntityPermissionDto ToPermissionDto(CustomEntityPermission permission) =>
            new()
            {
                RoleName = permission.RoleName,
                CanCreate = permission.CanCreate,
                CanRead = permission.CanRead,
                CanUpdate = permission.CanUpdate,
                CanDelete = permission.CanDelete
            };
    }
}
