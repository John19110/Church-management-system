using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SunDaySchools.DAL.Models.CustomFields;

namespace SunDaySchoolsDAL.Configurations
{
    public class CustomFieldDefinitionConfiguration : IEntityTypeConfiguration<CustomFieldDefinition>
    {
        public void Configure(EntityTypeBuilder<CustomFieldDefinition> builder)
        {
            builder.ToTable("CustomFieldDefinitions");

            builder.HasKey(x => x.Id);

            builder.Property(x => x.Name).HasMaxLength(128).IsRequired();
            builder.Property(x => x.DisplayName).HasMaxLength(256).IsRequired();
            builder.Property(x => x.Description).HasMaxLength(2000);
            builder.Property(x => x.EntityName).HasMaxLength(64).IsRequired();
            builder.Property(x => x.DataType)
                .HasConversion<string>()
                .HasMaxLength(32);
            builder.Property(x => x.DefaultValue).HasMaxLength(4000);
            builder.Property(x => x.Placeholder).HasMaxLength(512);
            builder.Property(x => x.ValidationRegex).HasMaxLength(512);
            builder.Property(x => x.CreatedBy).HasMaxLength(450);

            builder.HasIndex(x => x.EntityName);
            builder.HasIndex(x => x.ChurchId);
            builder.HasIndex(x => x.MeetingId);
            builder.HasIndex(x => new { x.EntityName, x.ChurchId, x.MeetingId });
            builder.HasIndex(x => new { x.EntityName, x.Name, x.ChurchId, x.MeetingId })
                .IsUnique();

            builder.HasMany(x => x.Options)
                .WithOne(o => o.Definition)
                .HasForeignKey(o => o.CustomFieldDefinitionId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasMany(x => x.Values)
                .WithOne(v => v.Definition)
                .HasForeignKey(v => v.CustomFieldDefinitionId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }

    public class CustomFieldOptionConfiguration : IEntityTypeConfiguration<CustomFieldOption>
    {
        public void Configure(EntityTypeBuilder<CustomFieldOption> builder)
        {
            builder.ToTable("CustomFieldOptions");

            builder.HasKey(x => x.Id);
            builder.Property(x => x.Value).HasMaxLength(256).IsRequired();
            builder.Property(x => x.DisplayText).HasMaxLength(512).IsRequired();

            builder.HasIndex(x => x.CustomFieldDefinitionId);
            builder.HasIndex(x => new { x.CustomFieldDefinitionId, x.Value }).IsUnique();
        }
    }

    public class CustomFieldValueConfiguration : IEntityTypeConfiguration<CustomFieldValue>
    {
        public void Configure(EntityTypeBuilder<CustomFieldValue> builder)
        {
            builder.ToTable("CustomFieldValues");

            builder.HasKey(x => x.Id);
            builder.Property(x => x.EntityName).HasMaxLength(64).IsRequired();
            builder.Property(x => x.Value).HasMaxLength(8000);
            builder.Property(x => x.CreatedBy).HasMaxLength(450);

            builder.HasIndex(x => x.EntityName);
            builder.HasIndex(x => x.EntityId);
            builder.HasIndex(x => x.CustomFieldDefinitionId);
            builder.HasIndex(x => new { x.EntityName, x.EntityId });
            builder.HasIndex(x => new { x.EntityName, x.EntityId, x.CustomFieldDefinitionId })
                .IsUnique();
        }
    }
}
