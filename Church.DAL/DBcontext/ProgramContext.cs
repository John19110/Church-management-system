using System.Reflection;
using Church.DAL.Abstractions;
using Church.DAL.Models;
using Church.DAL.Models.CustomFields;
using Church.DAL.Models.CustomFeatures;
using Church.Domain;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Church.DAL.DBcontext
{
    /// <summary>
    /// EF Core composition root for Identity + church domain entities.
    /// Entity shape (relationships, indexes, columns) lives in
    /// <c>Church.DAL.Configurations</c>; tenant isolation and SaveChanges
    /// assignment stay here because they depend on request-scoped
    /// <see cref="ITenantContext"/>.
    /// </summary>
    public class ProgramContext : IdentityDbContext<ApplicationUser>
    {
        private readonly ITenantContext _tenantContext;

        public ProgramContext(DbContextOptions<ProgramContext> options, ITenantContext tenantContext)
            : base(options)
        {
            _tenantContext = tenantContext;
        }

        public DbSet<Member> Members { get; set; }
        public DbSet<MemberContact> MemberContacts { get; set; }
        public DbSet<PhoneCall> PhoneCalls { get; set; }
        public DbSet<Servant> Servants { get; set; }
        public DbSet<Classroom> Classrooms { get; set; }
        public DbSet<ClassroomServant> ClassroomServants { get; set; }
        public DbSet<MeetingAllMembersViewer> MeetingAllMembersViewers { get; set; }
        public DbSet<AttendanceSession> AttendanceSessions { get; set; }
        public DbSet<AttendanceRecord> AttendanceRecords { get; set; }
        public DbSet<AttendanceCriterion> AttendanceCriteria { get; set; }
        public DbSet<AttendanceCriterionResult> AttendanceCriterionResults { get; set; }
        public DbSet<Exam> Exams { get; set; }
        public DbSet<ExamResult> ExamResults { get; set; }
        public DbSet<SpiritualCurriculum> SpiritualCurriculums { get; set; }
        public DbSet<Tool> Tools { get; set; }
        public DbSet<ChurchModel> Churches { get; set; }
        public DbSet<Meeting> Meetings { get; set; }

        public DbSet<CustomFieldDefinition> CustomFieldDefinitions { get; set; }
        public DbSet<CustomFieldOption> CustomFieldOptions { get; set; }
        public DbSet<CustomFieldValue> CustomFieldValues { get; set; }

        public DbSet<CustomFeature> CustomFeatures { get; set; }
        public DbSet<CustomEntity> CustomEntities { get; set; }
        public DbSet<CustomEntityField> CustomEntityFields { get; set; }
        public DbSet<CustomEntityFieldOption> CustomEntityFieldOptions { get; set; }
        public DbSet<CustomEntityPermission> CustomEntityPermissions { get; set; }
        public DbSet<CustomEntityRecord> CustomEntityRecords { get; set; }
        public DbSet<CustomEntityRecordReference> CustomEntityRecordReferences { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            builder.ApplyConfigurationsFromAssembly(typeof(ProgramContext).Assembly);

            ApplyTenantQueryFilters(builder);
            ApplyChurchIdIndexes(builder);
        }

        /// <summary>
        /// Tenant isolation is fail-closed: with no resolved ChurchId, tenant-owned rows
        /// are invisible. Login, registration, cascade deletes, and startup repair must
        /// opt out locally with <c>IgnoreQueryFilters()</c>.
        /// </summary>
        private void ApplyTenantQueryFilters(ModelBuilder builder)
        {
            // Dependents of filtered principals need their own filters (EF10622).
            builder.Entity<CustomFieldOption>()
                .HasQueryFilter(o =>
                    CurrentChurchId.HasValue &&
                    o.Definition!.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue ||
                     o.Definition!.MeetingId == null ||
                     o.Definition!.MeetingId == CurrentMeetingId));

            builder.Entity<CustomFieldValue>()
                .HasQueryFilter(v =>
                    CurrentChurchId.HasValue &&
                    v.Definition!.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue ||
                     v.Definition!.MeetingId == null ||
                     v.Definition!.MeetingId == CurrentMeetingId));

            builder.Entity<AttendanceCriterionResult>()
                .HasQueryFilter(r =>
                    CurrentChurchId.HasValue &&
                    r.AttendanceCriterion.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue || r.AttendanceCriterion.MeetingId == CurrentMeetingId));

            builder.Entity<MemberContact>()
                .HasQueryFilter(mc =>
                    CurrentChurchId.HasValue &&
                    mc.Member.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue || mc.Member.MeetingId == CurrentMeetingId) &&
                    (
                        !IsClassroomScoped ||
                        CurrentClassroomIds.Contains(EF.Property<int>(mc.Member, "ClassroomId"))
                    ));

            // Meeting-level sessions (ClassroomId null) are scoped via Meeting instead.
            builder.Entity<AttendanceSession>()
                .HasQueryFilter(s =>
                    CurrentChurchId.HasValue &&
                    (
                        (s.ClassroomId != null &&
                         s.Classroom!.ChurchId == CurrentChurchId &&
                         (!CurrentMeetingId.HasValue || s.Classroom!.MeetingId == CurrentMeetingId) &&
                         (
                             !IsClassroomScoped ||
                             (s.ClassroomId.HasValue && CurrentClassroomIds.Contains(s.ClassroomId.Value))
                         ))
                        ||
                        (s.ClassroomId == null &&
                         s.Meeting != null &&
                         s.Meeting.ChurchId == CurrentChurchId &&
                         (!CurrentMeetingId.HasValue || s.MeetingId == CurrentMeetingId) &&
                         !IsClassroomScoped)
                    ));

            builder.Entity<PhoneCall>()
                .HasQueryFilter(pc =>
                    CurrentChurchId.HasValue &&
                    pc.MemberContact.Member.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue || pc.MemberContact.Member.MeetingId == CurrentMeetingId) &&
                    (
                        !IsClassroomScoped ||
                        CurrentClassroomIds.Contains(EF.Property<int>(pc.MemberContact.Member, "ClassroomId"))
                    ));

            foreach (var entityType in builder.Model.GetEntityTypes())
            {
                if (!typeof(ChurchEntity).IsAssignableFrom(entityType.ClrType))
                    continue;

                var hasClassroomId = entityType.FindProperty("ClassroomId") != null;
                var method = typeof(ProgramContext)
                    .GetMethod(nameof(SetGlobalFilter), BindingFlags.NonPublic | BindingFlags.Instance)
                    ?.MakeGenericMethod(entityType.ClrType);

                method?.Invoke(this, new object[] { builder, hasClassroomId });
            }

            // Declared after the ChurchEntity loop so these replace the generic filter.
            // Church-wide custom field definitions (MeetingId null) must stay visible under meeting scope.
            builder.Entity<CustomFieldDefinition>()
                .HasQueryFilter(d =>
                    CurrentChurchId.HasValue &&
                    d.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue ||
                     d.MeetingId == null ||
                     d.MeetingId == CurrentMeetingId));

            // Church-wide custom features (MeetingId null) stay visible under meeting scope.
            builder.Entity<CustomFeature>()
                .HasQueryFilter(f =>
                    CurrentChurchId.HasValue &&
                    f.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue ||
                     f.MeetingId == null ||
                     f.MeetingId == CurrentMeetingId));

            builder.Entity<CustomEntity>()
                .HasQueryFilter(e =>
                    CurrentChurchId.HasValue &&
                    e.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue ||
                     e.MeetingId == null ||
                     e.MeetingId == CurrentMeetingId));

            builder.Entity<CustomEntityField>()
                .HasQueryFilter(f =>
                    CurrentChurchId.HasValue &&
                    f.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue ||
                     f.MeetingId == null ||
                     f.MeetingId == CurrentMeetingId));

            builder.Entity<CustomEntityPermission>()
                .HasQueryFilter(p =>
                    CurrentChurchId.HasValue &&
                    p.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue ||
                     p.MeetingId == null ||
                     p.MeetingId == CurrentMeetingId));

            builder.Entity<CustomEntityRecord>()
                .HasQueryFilter(r =>
                    CurrentChurchId.HasValue &&
                    r.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue ||
                     r.MeetingId == null ||
                     r.MeetingId == CurrentMeetingId));

            builder.Entity<CustomEntityFieldOption>()
                .HasQueryFilter(o =>
                    CurrentChurchId.HasValue &&
                    o.Field!.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue ||
                     o.Field!.MeetingId == null ||
                     o.Field!.MeetingId == CurrentMeetingId));

            builder.Entity<CustomEntityRecordReference>()
                .HasQueryFilter(r =>
                    CurrentChurchId.HasValue &&
                    r.Record!.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue ||
                     r.Record!.MeetingId == null ||
                     r.Record!.MeetingId == CurrentMeetingId));

            // Classroom's own key is Id, not ClassroomId — the generic filter cannot classroom-scope it.
            builder.Entity<Classroom>()
                .HasQueryFilter(c =>
                    CurrentChurchId.HasValue &&
                    c.ChurchId == CurrentChurchId &&
                    (!CurrentMeetingId.HasValue || c.MeetingId == CurrentMeetingId) &&
                    (!IsClassroomScoped || CurrentClassroomIds.Contains(c.Id)));

            // Meeting and Church are tenant roots and do not derive from ChurchEntity.
            builder.Entity<Meeting>()
                .HasQueryFilter(m =>
                    CurrentChurchId.HasValue &&
                    m.ChurchId == CurrentChurchId);

            builder.Entity<ChurchModel>()
                .HasQueryFilter(c =>
                    CurrentChurchId.HasValue &&
                    c.Id == CurrentChurchId);
        }

        private static void ApplyChurchIdIndexes(ModelBuilder builder)
        {
            foreach (var entityType in builder.Model.GetEntityTypes())
            {
                if (typeof(ChurchEntity).IsAssignableFrom(entityType.ClrType))
                {
                    builder.Entity(entityType.ClrType)
                        .HasIndex("ChurchId");
                }
            }
        }

        /// <summary>
        /// Generic ChurchEntity filter. Fail-closed when CurrentChurchId is unset.
        /// </summary>
        private void SetGlobalFilter<TEntity>(ModelBuilder modelBuilder, bool hasClassroomId)
            where TEntity : ChurchEntity
        {
            if (hasClassroomId)
            {
                modelBuilder.Entity<TEntity>()
                    .HasQueryFilter(e =>
                        CurrentChurchId.HasValue &&
                        e.ChurchId == CurrentChurchId &&
                        (!CurrentMeetingId.HasValue || e.MeetingId == CurrentMeetingId) &&
                        (
                            !IsClassroomScoped ||
                            CurrentClassroomIds.Contains(EF.Property<int>(e, "ClassroomId"))
                        ));
            }
            else
            {
                modelBuilder.Entity<TEntity>()
                    .HasQueryFilter(e =>
                        CurrentChurchId.HasValue &&
                        e.ChurchId == CurrentChurchId &&
                        (!CurrentMeetingId.HasValue || e.MeetingId == CurrentMeetingId));
            }
        }

        private int? CurrentChurchId => _tenantContext.ChurchId;

        private int? CurrentMeetingId => _tenantContext.MeetingId;

        private string? CurrentScope => _tenantContext.Scope;

        /// <summary>
        /// Servant-scoped callers with no classroom assignments see nothing (fail-closed),
        /// not the entire meeting.
        /// </summary>
        private bool IsClassroomScoped =>
            string.Equals(CurrentScope, TenantScopes.Classroom, StringComparison.OrdinalIgnoreCase);

        private List<int> CurrentClassroomIds =>
            _tenantContext.ClassroomIds?.ToList() ?? new List<int>();

        private void ApplyTenantValues()
        {
            ApplyChurchId();
            ApplyMeetingId();
        }

        private void ApplyChurchId()
        {
            var churchId = CurrentChurchId;

            foreach (var entry in ChangeTracker.Entries<ChurchEntity>())
            {
                if ((entry.State == EntityState.Added || entry.State == EntityState.Modified) &&
                    (!entry.Entity.ChurchId.HasValue || entry.Entity.ChurchId == 0))
                {
                    if (churchId.HasValue)
                        entry.Entity.ChurchId = churchId.Value;
                    else
                        throw new InvalidOperationException(
                            "ChurchId is missing from the request. Ensure the JWT includes a ChurchId claim.");
                }
            }
        }

        private void ApplyMeetingId()
        {
            var meetingId = CurrentMeetingId;

            foreach (var entry in ChangeTracker.Entries<ChurchEntity>())
            {
                if ((entry.State == EntityState.Added || entry.State == EntityState.Modified) &&
                    (!entry.Entity.MeetingId.HasValue || entry.Entity.MeetingId == 0))
                {
                    if (meetingId.HasValue)
                        entry.Entity.MeetingId = meetingId.Value;
                }
            }
        }

        public override int SaveChanges()
        {
            ApplyTenantValues();
            return base.SaveChanges();
        }

        public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            ApplyTenantValues();
            return await base.SaveChangesAsync(cancellationToken);
        }
    }
}
