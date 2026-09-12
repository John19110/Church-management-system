using Church.DAL.Models;
using Church.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public sealed class ClassroomConfiguration : IEntityTypeConfiguration<Classroom>
    {
        public void Configure(EntityTypeBuilder<Classroom> builder)
        {
            builder.HasOne(c => c.LeaderServant)
                .WithMany()
                .HasForeignKey(c => c.LeaderServantId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }

    public sealed class ClassroomServantConfiguration : IEntityTypeConfiguration<ClassroomServant>
    {
        public void Configure(EntityTypeBuilder<ClassroomServant> builder)
        {
            builder.HasKey(cs => new { cs.ServantId, cs.ClassroomId });

            builder.HasOne(cs => cs.Servant)
                .WithMany(s => s.ClassroomServants)
                .HasForeignKey(cs => cs.ServantId);

            builder.HasOne(cs => cs.Classroom)
                .WithMany(c => c.ClassroomServants)
                .HasForeignKey(cs => cs.ClassroomId);
        }
    }
}
