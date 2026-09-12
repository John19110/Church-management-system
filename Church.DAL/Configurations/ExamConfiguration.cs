using Church.DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public sealed class ExamResultConfiguration : IEntityTypeConfiguration<ExamResult>
    {
        public void Configure(EntityTypeBuilder<ExamResult> builder)
        {
            builder.HasOne(er => er.Meeting)
                .WithMany()
                .HasForeignKey(er => er.MeetingId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(er => er.Member)
                .WithMany(m => m.ExamsResults)
                .HasForeignKey(er => er.MemberId)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}
