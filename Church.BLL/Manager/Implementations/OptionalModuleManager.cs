using Church.BLL.Abstractions;
using Church.BLL.Authorization;
using Church.BLL.DTOS.OptionalModules;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.BLL.OptionalModules;
using Church.DAL.Abstractions;
using Church.DAL.Models.OptionalModules;
using Church.DAL.Repository.Interfaces;

namespace Church.BLL.Manager.Implementations
{
    public class OptionalModuleManager : IOptionalModuleManager
    {
        private readonly IOptionalModuleRepository _repository;
        private readonly ITenantContext _tenantContext;
        private readonly ICurrentUserContext _currentUser;

        public OptionalModuleManager(
            IOptionalModuleRepository repository,
            ITenantContext tenantContext,
            ICurrentUserContext currentUser)
        {
            _repository = repository;
            _tenantContext = tenantContext;
            _currentUser = currentUser;
        }

        public async Task<IReadOnlyList<OptionalModuleReadDto>> GetModulesAsync()
        {
            EnsureAuthenticated();
            RequireChurchId();

            var activations = await _repository.GetActivationsAsync();
            return PredefinedModules.All
                .Select(def => ToDto(def, ResolveIsEnabled(def.Id, activations)))
                .ToList();
        }

        public async Task<OptionalModuleReadDto> SetEnabledAsync(string moduleId, bool isEnabled)
        {
            EnsureCanManageActivation();
            var churchId = RequireChurchId();

            if (!PredefinedModules.TryGet(moduleId, out var definition))
                throw new NotFoundException($"Unknown optional module '{moduleId}'.");

            var scopeMeetingId = ResolveManagedMeetingId();
            var activation = await _repository.GetActivationForScopeAsync(definition.Id, scopeMeetingId);
            var now = DateTime.UtcNow;

            if (activation == null)
            {
                activation = new OrganizationModuleActivation
                {
                    ModuleId = definition.Id,
                    ChurchId = churchId,
                    MeetingId = scopeMeetingId,
                    IsEnabled = isEnabled,
                    EnabledAtUtc = isEnabled ? now : null,
                    DisabledAtUtc = isEnabled ? null : now,
                    UpdatedBy = _currentUser.UserId,
                    UpdatedAtUtc = now
                };
                await _repository.AddActivationAsync(activation);
            }
            else
            {
                activation.IsEnabled = isEnabled;
                activation.UpdatedBy = _currentUser.UserId;
                activation.UpdatedAtUtc = now;
                if (isEnabled)
                {
                    activation.EnabledAtUtc = now;
                    activation.DisabledAtUtc = null;
                }
                else
                {
                    activation.DisabledAtUtc = now;
                }

                await _repository.UpdateActivationAsync(activation);
            }

            await _repository.SaveChangesAsync();

            var activations = await _repository.GetActivationsAsync();
            return ToDto(definition, ResolveIsEnabled(definition.Id, activations));
        }

        public async Task<bool> IsModuleEnabledAsync(string moduleId)
        {
            if (!PredefinedModules.IsKnown(moduleId))
                return false;

            EnsureAuthenticated();
            RequireChurchId();

            var activations = await _repository.GetActivationsAsync();
            return ResolveIsEnabled(moduleId, activations);
        }

        public async Task EnsureModuleEnabledAsync(string moduleId)
        {
            if (!await IsModuleEnabledAsync(moduleId))
            {
                throw new UnauthorizedAccessException(
                    $"The '{moduleId}' optional module is not enabled for this organization.");
            }
        }

        /// <summary>
        /// Meeting-specific activation overrides church-wide when present;
        /// otherwise church-wide activation applies.
        /// </summary>
        private bool ResolveIsEnabled(
            string moduleId,
            IReadOnlyList<OrganizationModuleActivation> activations)
        {
            var forModule = activations
                .Where(a => string.Equals(a.ModuleId, moduleId, StringComparison.OrdinalIgnoreCase))
                .ToList();

            if (_tenantContext.MeetingId.HasValue)
            {
                var meetingScoped = forModule.FirstOrDefault(a => a.MeetingId == _tenantContext.MeetingId);
                if (meetingScoped != null)
                    return meetingScoped.IsEnabled;

                var churchWide = forModule.FirstOrDefault(a => a.MeetingId == null);
                return churchWide?.IsEnabled ?? false;
            }

            return forModule.Any(a => a.MeetingId == null && a.IsEnabled);
        }

        private int? ResolveManagedMeetingId() =>
            _currentUser.IsInRole(OptionalModuleRoles.SuperAdmin)
                ? null
                : _tenantContext.MeetingId;

        private OptionalModuleReadDto ToDto(PredefinedModuleDefinition def, bool isEnabled) =>
            new()
            {
                Id = def.Id,
                NameEn = def.NameEn,
                NameAr = def.NameAr,
                DescriptionEn = def.DescriptionEn,
                DescriptionAr = def.DescriptionAr,
                Icon = def.Icon,
                IsEnabled = isEnabled
            };

        private void EnsureAuthenticated()
        {
            if (!_currentUser.IsAuthenticated)
                throw new UnauthorizedAccessException("Authentication required.");
        }

        private void EnsureCanManageActivation()
        {
            EnsureAuthenticated();
            if (!_currentUser.IsInRole(OptionalModuleRoles.SuperAdmin) &&
                !_currentUser.IsInRole(OptionalModuleRoles.Admin))
            {
                throw new UnauthorizedAccessException(
                    "Only church or meeting administrators can enable or disable optional modules.");
            }
        }

        private int RequireChurchId() =>
            _tenantContext.ChurchId
            ?? throw new UnauthorizedAccessException("Church context is required.");
    }
}
