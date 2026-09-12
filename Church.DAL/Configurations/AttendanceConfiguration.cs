using Church.DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public sealed class AttendanceSessionConfiguration : IEntityTypeConfiguration<AttendanceSession>
    {
        public void Configure(EntityTypeBuilder<AttendanceSession> builder)
        {
            builder.HasOne(s => s.Meeting)
                .WithMany(m => m.AttendanceSessions)
                .HasForeignKey(s => s.MeetingId)
                .OnDelete(DeleteBehavior.Restrict);

            // Optional — null for meeting-level attendance.
            builder.HasOne(s => s.Classroom)
                .WithMany(c => c.AttendanceHistory)
                .HasForeignKey(s => s.ClassroomId)
                .OnDelete(DeleteBehavior.Restrict)
                .IsRequired(false);
        }
    }

    public sealed class AttendanceRecordConfiguration : IEntityTypeConfiguration<AttendanceRecord>
    {
        public void Configure(EntityTypeBuilder<AttendanceRecord> builder)
        {
            builder.HasIndex(x => new { x.AttendanceSessionId, x.MemberId })
                .IsUnique();
        }
    }

    public sealed class AttendanceCriterionConfiguration : IEntityTypeConfiguration<AttendanceCriterion>
    {
        public void Configure(EntityTypeBuilder<AttendanceCriterion> builder)
        {
            builder.HasOne(c => c.Meeting)
                .WithMany(m => m.AttendanceCriteria)
                .HasForeignKey(c => c.MeetingId)
                .OnDelete(DeleteBehavior.Restrict)
                .IsRequired();

            builder.HasIndex(c => new { c.MeetingId, c.Name })
                .IsUnique()
                .HasFilter("[IsDeleted] = 0");
        }
    }

    public sealed class AttendanceCriterionResultConfiguration
        : IEntityTypeConfiguration<AttendanceCriterionResult>
    {
        public void Configure(EntityTypeBuilder<AttendanceCriterionResult> builder)
        {
            builder.HasOne(r => r.AttendanceRecord)
                .WithMany(ar => ar.CriterionResults)
                .HasForeignKey(r => r.AttendanceRecordId)
                .OnDelete(DeleteBehavior.Cascade)
                .IsRequired();

            builder.HasOne(r => r.AttendanceCriterion)
                .WithMany(c => c.Results)
                .HasForeignKey(r => r.AttendanceCriterionId)
                .OnDelete(DeleteBehavior.Restrict)
                .IsRequired();

            builder.HasIndex(r => new { r.AttendanceRecordId, r.AttendanceCriterionId })
                .IsUnique();
        }
    }
}
