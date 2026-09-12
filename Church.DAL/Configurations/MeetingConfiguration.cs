using Church.DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public sealed class MeetingConfiguration : IEntityTypeConfiguration<Meeting>
    {
        public void Configure(EntityTypeBuilder<Meeting> builder)
        {
            builder.HasOne(m => m.LeaderServant)
                .WithMany()
                .HasForeignKey(m => m.LeaderServantId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Property(m => m.PublicId)
                .IsRequired()
                .HasMaxLength(16);

            builder.HasIndex(m => m.PublicId)
                .IsUnique();
        }
    }
}
