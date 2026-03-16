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

        public DbSet<Child> Children { get; set; }
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
            builder.Entity<Child>()
                .HasOne(c => c.Classroom)
                .WithMany(cl => cl.Children)
                .HasForeignKey(c => c.ClassroomId)
                .OnDelete(DeleteBehavior.Restrict);

            // Classroom seed data
            builder.Entity<Classroom>().HasData(
                new Classroom { Id = 1, Name = "الوداعه", AgeOfChildren = "حضانه و كيجي" },
                new Classroom { Id = 2, Name = "السلام", AgeOfChildren = "اولي و تانيه" },
                new Classroom { Id = 3, Name = "الأيمان", AgeOfChildren = "تالته ورابعه" },
                new Classroom { Id = 4, Name = "المحبه", AgeOfChildren = "خامسه و سادسه" }
            );

            // Prevent duplicate attendance records
            builder.Entity<AttendanceRecord>()
                .HasIndex(x => new { x.AttendanceSessionId, x.ChildId })
                .IsUnique();

            // Index for classroom lookup
            builder.Entity<Child>()
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
                        .GetMethod(nameof(SetChurchFilter), BindingFlags.NonPublic | BindingFlags.Instance)
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

        // Automatically enforce ChurchId when saving
        private void ApplyChurchId()
        {
            var churchId = _httpContextAccessor.HttpContext?.Items["ChurchId"];

            if (churchId == null)
                throw new Exception("ChurchId is missing from the request.");

            foreach (var entry in ChangeTracker.Entries<ChurchEntity>())
            {
                if (entry.State == EntityState.Added || entry.State == EntityState.Modified)
                {
                    entry.Entity.ChurchId = (int)churchId;
                }
            }
        }

        public override int SaveChanges()
        {
            ApplyChurchId();
            return base.SaveChanges();
        }

        public override async Task<int> SaveChangesAsync(
            CancellationToken cancellationToken = default)
        {
            ApplyChurchId();
            return await base.SaveChangesAsync(cancellationToken);
        }

        // Global filter for all ChurchEntity tables
        private void SetChurchFilter<TEntity>(ModelBuilder modelBuilder)
            where TEntity : ChurchEntity
        {
            modelBuilder.Entity<TEntity>()
                .HasQueryFilter(e => !CurrentChurchId.HasValue || e.ChurchId == CurrentChurchId);
        }

        private int? CurrentChurchId
        {
            get
            {
                return _httpContextAccessor.HttpContext?.Items["ChurchId"] as int?;
            }
        }
    }
}