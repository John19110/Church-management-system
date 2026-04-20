using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System.Reflection;

namespace SunDaySchoolsDAL.DBcontext
{
    public class ProgramContext : IdentityDbContext<ApplicationUser>
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public ProgramContext(
            DbContextOptions<ProgramContext> options,
            IHttpContextAccessor httpContextAccessor
        ) : base(options)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public DbSet<Member> Members { get; set; }
        public DbSet<MemberContact> MemberContacts { get; set; }
        public DbSet<PhoneCall> PhoneCalls { get; set; }
        public DbSet<Servant> Servants { get; set; }
        public DbSet<Classroom> Classrooms { get; set; }
        public DbSet<ClassroomServant> ClassroomServants { get; set; }
        public DbSet<AttendanceSession> AttendanceSessions { get; set; }
        public DbSet<AttendanceRecord> AttendanceRecords { get; set; }
        public DbSet<Exam> Exams { get; set; }
        public DbSet<ExamResult> ExamResults { get; set; }
        public DbSet<SpiritualCurriculum> SpiritualCurriculums { get; set; }
        public DbSet<Tool> Tools { get; set; }
        public DbSet<Church> Churches { get; set; }
        public DbSet<Meeting> Meetings { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Member ↔ Classroom
            builder.Entity<Member>()
                .HasOne(c => c.Classroom)
                .WithMany(cl => cl.Members)
                .HasForeignKey(c => c.ClassroomId)
                .OnDelete(DeleteBehavior.Restrict);

            // MemberContact ↔ Member (required)
            builder.Entity<MemberContact>()
                .HasOne(mc => mc.Member)
                .WithMany(m => m.PhoneNumbers)
                .HasForeignKey(mc => mc.MemberId)
                .OnDelete(DeleteBehavior.Cascade);

            // PhoneCall ↔ MemberContact (required)
            builder.Entity<PhoneCall>()
                .HasOne(pc => pc.MemberContact)
                .WithMany(mc => mc.CallsHistory)
                .HasForeignKey(pc => pc.MemberContactId)
                .OnDelete(DeleteBehavior.Cascade);

            // AttendanceSession ↔ Classroom (required)
            builder.Entity<AttendanceSession>()
                .HasOne(s => s.Classroom)
                .WithMany(c => c.AttendanceHistory)
                .HasForeignKey(s => s.ClassroomId)
                .OnDelete(DeleteBehavior.Restrict);

            // Many-to-Many ClassroomServant
            builder.Entity<ClassroomServant>()
                .HasKey(cs => new { cs.ServantId, cs.ClassroomId });

            builder.Entity<ClassroomServant>()
                .HasOne(cs => cs.Servant)
                .WithMany(s => s.ClassroomServants)
                .HasForeignKey(cs => cs.ServantId);

            builder.Entity<ClassroomServant>()
                .HasOne(cs => cs.Classroom)
                .WithMany(c => c.ClassroomServants)
                .HasForeignKey(cs => cs.ClassroomId);

            // Attendance uniqueness
            builder.Entity<AttendanceRecord>()
                .HasIndex(x => new { x.AttendanceSessionId, x.MemberId })
                .IsUnique();

            builder.Entity<Member>()
                .HasIndex(c => c.ClassroomId);

            // Servant ↔ User
            builder.Entity<Servant>()
                .HasOne(s => s.ApplicationUser)
                .WithOne(u => u.ServantProfile)
                .HasForeignKey<Servant>(s => s.ApplicationUserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<Servant>()
                .HasIndex(s => s.ApplicationUserId)
                .IsUnique();

            // Exam relations
            builder.Entity<ExamResult>()
                .HasOne(er => er.Meeting)
                .WithMany()
                .HasForeignKey(er => er.MeetingId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Entity<ExamResult>()
                .HasOne(er => er.Member)
                .WithMany(m => m.ExamsResults)
                .HasForeignKey(er => er.MemberId)
                .OnDelete(DeleteBehavior.NoAction);

            // Church → Pastor
            builder.Entity<Church>()
                .HasOne(c => c.Pastor)
                .WithMany()
                .HasForeignKey(c => c.PastorId)
                .OnDelete(DeleteBehavior.Restrict);

            // Meeting → Leader
            builder.Entity<Meeting>()
                .HasOne(m => m.LeaderServant)
                .WithMany()
                .HasForeignKey(m => m.LeaderServantId)
                .OnDelete(DeleteBehavior.Restrict);

            // Classroom → Leader
            builder.Entity<Classroom>()
                .HasOne(c => c.LeaderServant)
                .WithMany()
                .HasForeignKey(c => c.LeaderServantId)
                .OnDelete(DeleteBehavior.Restrict);

            // Keep query filters consistent across required relationships:
            // Member is globally filtered (ChurchEntity), so dependents that require Member must be filtered too.
            builder.Entity<MemberContact>()
                .HasQueryFilter(mc =>
                    (!CurrentChurchId.HasValue || mc.Member.ChurchId == CurrentChurchId) &&
                    (!CurrentMeetingId.HasValue || mc.Member.MeetingId == CurrentMeetingId) &&
                    (
                        !string.Equals(CurrentScope, "Classroom", StringComparison.OrdinalIgnoreCase) ||
                        (
                            CurrentClassroomIds.Count > 0 &&
                            CurrentClassroomIds.Contains(EF.Property<int>(mc.Member, "ClassroomId"))
                        )
                    )
                );

            // Classroom is globally filtered (ChurchEntity), so dependents that require Classroom must be filtered too.
            builder.Entity<AttendanceSession>()
                .HasQueryFilter(s =>
                    (!CurrentChurchId.HasValue || s.Classroom!.ChurchId == CurrentChurchId) &&
                    (!CurrentMeetingId.HasValue || s.Classroom!.MeetingId == CurrentMeetingId) &&
                    (
                        !string.Equals(CurrentScope, "Classroom", StringComparison.OrdinalIgnoreCase) ||
                        (
                            CurrentClassroomIds.Count > 0 &&
                            CurrentClassroomIds.Contains(s.ClassroomId)
                        )
                    )
                );

            // MemberContact is filtered, so dependents that require MemberContact must be filtered too.
            builder.Entity<PhoneCall>()
                .HasQueryFilter(pc =>
                    (!CurrentChurchId.HasValue || pc.MemberContact.Member.ChurchId == CurrentChurchId) &&
                    (!CurrentMeetingId.HasValue || pc.MemberContact.Member.MeetingId == CurrentMeetingId) &&
                    (
                        !string.Equals(CurrentScope, "Classroom", StringComparison.OrdinalIgnoreCase) ||
                        (
                            CurrentClassroomIds.Count > 0 &&
                            CurrentClassroomIds.Contains(EF.Property<int>(pc.MemberContact.Member, "ClassroomId"))
                        )
                    )
                );

            // 🔥 GLOBAL FILTERS (FIXED)
            foreach (var entityType in builder.Model.GetEntityTypes())
            {
                if (typeof(ChurchEntity).IsAssignableFrom(entityType.ClrType))
                {
                    var hasClassroomId = entityType.FindProperty("ClassroomId") != null;

                    var method = typeof(ProgramContext)
                        .GetMethod(nameof(SetGlobalFilter), BindingFlags.NonPublic | BindingFlags.Instance)
                        ?.MakeGenericMethod(entityType.ClrType);

                    method?.Invoke(this, new object[] { builder, hasClassroomId });
                }
            }

            // Index ChurchId
            foreach (var entityType in builder.Model.GetEntityTypes())
            {
                if (typeof(ChurchEntity).IsAssignableFrom(entityType.ClrType))
                {
                    builder.Entity(entityType.ClrType)
                        .HasIndex("ChurchId");
                }
            }
        }

        // ✅ SAFE GLOBAL FILTER (NO EF.Property CRASH)
        private void SetGlobalFilter<TEntity>(ModelBuilder modelBuilder, bool hasClassroomId)
            where TEntity : ChurchEntity
        {
            if (hasClassroomId)
            {
                modelBuilder.Entity<TEntity>()
                    .HasQueryFilter(e =>
                        (!CurrentChurchId.HasValue || e.ChurchId == CurrentChurchId) &&
                        (!CurrentMeetingId.HasValue || e.MeetingId == CurrentMeetingId) &&
                        (
                            !string.Equals(CurrentScope, "Classroom", StringComparison.OrdinalIgnoreCase) ||
                            (
                                CurrentClassroomIds.Count > 0 &&
                                CurrentClassroomIds.Contains(EF.Property<int>(e, "ClassroomId"))
                            )
                        )
                    );
            }
            else
            {
                // 🔥 IMPORTANT: no Classroom filter here
                modelBuilder.Entity<TEntity>()
                    .HasQueryFilter(e =>
                        (!CurrentChurchId.HasValue || e.ChurchId == CurrentChurchId) &&
                        (!CurrentMeetingId.HasValue || e.MeetingId == CurrentMeetingId)
                    );
            }
        }

        // ================= CONTEXT VALUES =================

        private int? CurrentChurchId =>
            _httpContextAccessor.HttpContext?.Items["ChurchId"] as int?;

        private int? CurrentMeetingId =>
            _httpContextAccessor.HttpContext?.Items["MeetingId"] as int?;

        private string? CurrentScope =>
            _httpContextAccessor.HttpContext?.Items["Scope"] as string;

        private List<int> CurrentClassroomIds =>
            _httpContextAccessor.HttpContext?.Items["ClassroomIds"] as List<int> ?? new List<int>();

        // ================= SAVE HOOKS =================

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
                        throw new Exception("ChurchId is missing from the request.");
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
            ApplyChurchId();
            ApplyMeetingId();
            return base.SaveChanges();
        }

        public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            ApplyChurchId();
            ApplyMeetingId();
            return await base.SaveChangesAsync(cancellationToken);
        }
    }
}