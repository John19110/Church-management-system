using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System.Reflection;
using System.Reflection.Emit;

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

            // Member ↔ Classroom relationship
            builder.Entity<Member>()
                .HasOne(c => c.Classroom)
                .WithMany(cl => cl.Members)
                .HasForeignKey(c => c.ClassroomId)
                .OnDelete(DeleteBehavior.Restrict);

            //Classroom seed data
            //builder.Entity<Classroom>().HasData(
            //   new Classroom { Id = 1, Name = "الوداعه", AgeOfMembers = "حضانه و كيجي" },
            //   new Classroom { Id = 2, Name = "السلام", AgeOfMembers = "اولي و تانيه" },
            //   new Classroom { Id = 3, Name = "الأيمان", AgeOfMembers = "تالته ورابعه" },
            //   new Classroom { Id = 4, Name = "المحبه", AgeOfMembers = "خامسه و سادسه" }
            //);

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


            // Church → Pastor relationship
            builder.Entity<Church>()
                .HasOne(c => c.Pastor)         // navigation property
                .WithMany()                     // the Pastor doesn't have a collection of Churches
                .HasForeignKey(c => c.PastorId) // foreign key
                .OnDelete(DeleteBehavior.Restrict); // optional, prevents cascade delete



            builder.Entity<Meeting>()
                .HasOne(m => m.LeaderServant)    // Meeting has one LeaderServant
                .WithMany()                       // Servant doesn’t have a collection of meetings as leader
                .HasForeignKey(m => m.LeaderServantId)
                .OnDelete(DeleteBehavior.Restrict);
            // Prevent cascading delete


            // Classroom → LeaderServant (optional)
            builder.Entity<Classroom>()
                .HasOne(c => c.LeaderServant)   // Classroom has one LeaderServant
                .WithMany()                     // Servant doesn't have a collection of classrooms they lead
                .HasForeignKey(c => c.LeaderServantId)
                .OnDelete(DeleteBehavior.Restrict);  // 

        }

        
        private void ApplyChurchId()
        {
            if (_httpContextAccessor.HttpContext == null)
                return; // skip for non-HTTP scenarios
            var churchIdFromContext = _httpContextAccessor.HttpContext?.Items["ChurchId"] as int?;

            foreach (var entry in ChangeTracker.Entries<ChurchEntity>())
            {

             
                if (entry.State == EntityState.Added || entry.State == EntityState.Modified)
                {
                    if (entry.Entity.ChurchId != null && entry.Entity.ChurchId != 0)
                        continue;

                    if (churchIdFromContext.HasValue)
                    {
                        entry.Entity.ChurchId = churchIdFromContext.Value;
                        continue;
                    }

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
                var value = _httpContextAccessor.HttpContext?.Items["ChurchId"];
                return value is int churchId ? churchId : null;
            }
        }


        private void ApplyMeetingId()
        {
            var meetingIdFromContext = _httpContextAccessor.HttpContext?.Items["MeetingId"] as int?;

            foreach (var entry in ChangeTracker.Entries<ChurchEntity>())
            {
                if (entry.State == EntityState.Added || entry.State == EntityState.Modified)
                {
                    if (entry.Entity.MeetingId != null && entry.Entity.MeetingId != 0)
                        continue;

                    if (meetingIdFromContext.HasValue)
                    {
                        entry.Entity.MeetingId = meetingIdFromContext.Value;
                    }

                    // no exception here
                    // because some users are church-level, not meeting-level
                }
            }
        }
        
        private int? CurrentMeetingId
        {
            get
            {
                var value = _httpContextAccessor.HttpContext?.Items["MeetingId"];
                return value is int meetingId ? meetingId : null;
            }
        }

        public override int SaveChanges()
        {
            ApplyChurchId();
            ApplyMeetingId();
            return base.SaveChanges();
        }

        public override async Task<int> SaveChangesAsync(
            CancellationToken cancellationToken = default)
        {
            ApplyChurchId();
            ApplyMeetingId();
            return await base.SaveChangesAsync(cancellationToken);
        }
    }
}