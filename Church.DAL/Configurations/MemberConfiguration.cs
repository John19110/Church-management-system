using Church.DAL.Models;
using Church.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public sealed class MemberConfiguration : IEntityTypeConfiguration<Member>
    {
        public void Configure(EntityTypeBuilder<Member> builder)
        {
            builder.HasOne(c => c.Classroom)
                .WithMany(cl => cl.Members)
                .HasForeignKey(c => c.ClassroomId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasIndex(c => c.ClassroomId);
        }
    }

    public sealed class MemberContactConfiguration : IEntityTypeConfiguration<MemberContact>
    {
        public void Configure(EntityTypeBuilder<MemberContact> builder)
        {
            builder.HasOne(mc => mc.Member)
                .WithMany(m => m.PhoneNumbers)
                .HasForeignKey(mc => mc.MemberId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }

    public sealed class PhoneCallConfiguration : IEntityTypeConfiguration<PhoneCall>
    {
        public void Configure(EntityTypeBuilder<PhoneCall> builder)
        {
            builder.HasOne(pc => pc.MemberContact)
                .WithMany(mc => mc.CallsHistory)
                .HasForeignKey(pc => pc.MemberContactId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
