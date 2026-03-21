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
        public DbSet<ChildContact> ChildContacts { get; set; }
        public DbSet<PhoneCall> PhoneCalls { get; set; }
        public DbSet<Servant> Servants { get; set; }
        public DbSet<Classroom> Classrooms { get; set; }
        public DbSet<AttendanceSession> AttendanceSessions { get; set; }
        public DbSet<AttendanceRecord> AttendanceRecords { get; set; }
        public DbSet<Exam> Exams { get; set; }
        public DbSet<ExamResult> ExamResults { get; set; }
        public DbSet<SpiritualCurriculum> SpiritualCurriculums { get; set; }
        public DbSet<Tool> Tools { get; set; }

        public DbSet<Church> Churches { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Child ↔ Classroom relationship
            builder.Entity<Member>()
                .HasOne(c => c.Classroom)
                .WithMany(cl => cl.Members)
                .HasForeignKey(c => c.ClassroomId)
                .OnDelete(DeleteBehavior.Restrict);

            // Classroom seed data
            builder.Entity<Classroom>().HasData(
                new Classroom { Id = 1, Name = "الوداعه", AgeOfMembers = "حضانه و كيجي" },
                new Classroom { Id = 2, Name = "السلام", AgeOfMembers = "اولي و تانيه" },
                new Classroom { Id = 3, Name = "الأيمان", AgeOfMembers = "تالته ورابعه" },
                new Classroom { Id = 4, Name = "المحبه", AgeOfMembers = "خامسه و سادسه" }
            );

            // Prevent duplicate attendance records
            builder.Entity<AttendanceRecord>()
                .HasIndex(x => new { x.AttendanceSessionId, x.MemberId })
                .IsUnique();

            // Index for classroom lookup
            builder.Entity<Member>()
                .HasIndex(c => c.ClassroomId);

            // Servant ↔ ApplicationUser relationship
            builder.Entity<Servant>()
                .HasOne(s => s.ApplicationUser)
                .WithOne(u => u.ServantProfile)
                .HasForeignKey<Servant>(s => s.ApplicationUserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<Servant>()
                .HasIndex(s => s.ApplicationUserId)
                .IsUnique();

            // Apply multi-tenant filters automatically
            foreach (var entityType in builder.Model.GetEntityTypes())
            {
                if (typeof(ChurchEntity).IsAssignableFrom(entityType.ClrType))
                {
                    var method = typeof(ProgramContext)
                        .GetMethod(nameof(SetGlobalFilter), BindingFlags.NonPublic | BindingFlags.Instance)
                        ?.MakeGenericMethod(entityType.ClrType);

                    method?.Invoke(this, new object[] { builder });
                }
            }

            // Automatically index ChurchId for performance
            foreach (var entityType in builder.Model.GetEntityTypes())
            {
                if (typeof(ChurchEntity).IsAssignableFrom(entityType.ClrType))
                {
                    builder.Entity(entityType.ClrType)
                        .HasIndex("ChurchId");
                }
            }
        }

        private void ApplyChurchId()
        {
            var churchIdFromContext = _httpContextAccessor.HttpContext?.Items["ChurchId"];

            foreach (var entry in ChangeTracker.Entries<ChurchEntity>())
            {
                if (entry.State == EntityState.Added || entry.State == EntityState.Modified)
                {
                    // ✅ Case 1: already set manually (like in Register)
                    if (entry.Entity.ChurchId != null && entry.Entity.ChurchId != 0)
                        continue;

                    // ✅ Case 2: use HttpContext
                    if (churchIdFromContext != null)
                    {
                        entry.Entity.ChurchId = (int)churchIdFromContext;
                        continue;
                    }

                    // ❌ Case 3: no ChurchId at all
                    throw new Exception("ChurchId is missing from the request.");
                }
            }
        }



        // Global filter for all ChurchEntity tables
        private void SetGlobalFilter<TEntity>(ModelBuilder modelBuilder)
      where TEntity : ChurchEntity
        {
            modelBuilder.Entity<TEntity>()
                .HasQueryFilter(e =>
                    (!CurrentChurchId.HasValue || e.ChurchId == CurrentChurchId) &&
                    (!CurrentMeetingId.HasValue || e.MeetingId == CurrentMeetingId)
                );
        }

        private int? CurrentChurchId
        {
            get
            {
                return _httpContextAccessor.HttpContext?.Items["ChurchId"] as int?;
            }
        }



        private void ApplyMeetinghId()
        {
            var MeetingIdFromContext = _httpContextAccessor.HttpContext?.Items["MeetingId"];

            foreach (var entry in ChangeTracker.Entries<ChurchEntity>())
            {
                if (entry.State == EntityState.Added || entry.State == EntityState.Modified)
                {
                    // ✅ Case 1: already set manually (like in Register)
                    if (entry.Entity.MeetingId != null && entry.Entity.MeetingId != 0)
                        continue;

                    // ✅ Case 2: use HttpContext
                    if (MeetingIdFromContext != null)
                    {
                        entry.Entity.MeetingId = (int)MeetingIdFromContext;
                        continue;
                    }

                    // ❌ Case 3: no ChurchId at all
                    throw new Exception("MeetingId is missing from the request.");
                }
            }
        }

        // Global filter for all ChurchEntity tables (Meetings)

        private void SetMeetingFilter<TEntity>(ModelBuilder modelBuilder)
            where TEntity : ChurchEntity
        {
            modelBuilder.Entity<TEntity>()
                .HasQueryFilter(e => !CurrentMeetingId.HasValue || e.MeetingId == CurrentMeetingId);
        }

        private int? CurrentMeetingId
        {
            get
            {
                return _httpContextAccessor.HttpContext?.Items["MeetingId"] as int?;
            }
        }

        public override int SaveChanges()
        {
            ApplyChurchId();
            ApplyMeetinghId();
            return base.SaveChanges();
        }

        public override async Task<int> SaveChangesAsync(
            CancellationToken cancellationToken = default)
        {
            ApplyChurchId();
            ApplyMeetinghId();
            return await base.SaveChangesAsync(cancellationToken);
        }
    }
}