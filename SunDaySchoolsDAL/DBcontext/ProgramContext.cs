using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System.Reflection.Emit;

namespace SunDaySchoolsDAL.DBcontext
{
    public class ProgramContext : IdentityDbContext<ApplicationUser>
    {
        public ProgramContext(DbContextOptions<ProgramContext> options) : base(options)
        {
        }

        public DbSet<Child> Children { get; set; }
        public DbSet<Classroom> Classrooms { get; set; }
        public DbSet<Servant> Servants { get; set; }
        public DbSet<SpiritualCurriculum> SpiritualCurriculums { get; set; }
        public DbSet<Tool> Tools { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {

        base.OnModelCreating(builder);
        // the relation between Child and class
         builder.Entity<Child>()
        .HasOne(c => c.Classroom)
        .WithMany(cl => cl.Children)
        .HasForeignKey(c => c.ClassroomId)
        .OnDelete(DeleteBehavior.Restrict);



            // Classrooms data seeding 
            builder.Entity<Classroom>().HasData(
                new Classroom { Id = 1, Name = "الوداعه", AgeOfChildren = "حضانه و كيجي" },
                new Classroom { Id = 2, Name = "السلام", AgeOfChildren = "اولي و تانيه" },
                new Classroom { Id = 3, Name = "الأيمان", AgeOfChildren = "تالته ورابعه" },
                new Classroom { Id = 4, Name = "المحبه", AgeOfChildren = "خامسه و سادسه" });


            // Attendace appears just one time 
           builder.Entity<AttendanceRecord>()
            .HasIndex(x => new { x.AttendanceSessionId, x.ChildId })
            .IsUnique();

        }
    }
}
