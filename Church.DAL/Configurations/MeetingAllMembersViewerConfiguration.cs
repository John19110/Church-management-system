using Church.DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public sealed class MeetingAllMembersViewerConfiguration
        : IEntityTypeConfiguration<MeetingAllMembersViewer>
    {
        public void Configure(EntityTypeBuilder<MeetingAllMembersViewer> builder)
        {
            builder.HasKey(v => new { v.MeetingId, v.ServantId });

            builder.Property(v => v.MeetingId)
                .IsRequired();

            builder.Property(v => v.ServantId)
                .IsRequired();

            builder.HasOne(v => v.Meeting)
                .WithMany(m => m.AllMembersViewers)
                .HasForeignKey(v => v.MeetingId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(v => v.Servant)
                .WithMany(s => s.AllMembersMeetingViews)
                .HasForeignKey(v => v.ServantId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(v => v.ServantId);
        }
    }
}
