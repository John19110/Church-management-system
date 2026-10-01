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

            builder.Property(c => c.SupportedLanguages)
                .IsRequired()
                .HasMaxLength(16)
                .HasDefaultValue("en,ar");

            builder.Property(c => c.DefaultLanguage)
                .IsRequired()
                .HasMaxLength(8)
                .HasDefaultValue("en");

            builder.Property(c => c.IsCustomizationLanguagesConfigured)
                .IsRequired()
                .HasDefaultValue(false);

            builder.HasIndex(c => c.PublicId)
                .IsUnique();
        }
    }
}
