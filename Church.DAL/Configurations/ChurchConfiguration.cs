using Church.DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public sealed class ChurchConfiguration : IEntityTypeConfiguration<ChurchModel>
    {
        public void Configure(EntityTypeBuilder<ChurchModel> builder)
        {
            builder.HasOne(c => c.Pastor)
                .WithMany()
                .HasForeignKey(c => c.PastorId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Property(c => c.PublicId)
                .IsRequired()
                .HasMaxLength(16);

            builder.HasIndex(c => c.PublicId)
                .IsUnique();
        }
    }
}
