using Church.DAL.Models.CustomFeatures;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public class CustomFeatureConfiguration : IEntityTypeConfiguration<CustomFeature>
    {
        public void Configure(EntityTypeBuilder<CustomFeature> builder)
        {
            builder.ToTable("CustomFeatures");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.Name).HasMaxLength(128).IsRequired();
            builder.Property(x => x.DisplayName).HasMaxLength(256).IsRequired();
            builder.Property(x => x.DisplayNameAr).HasMaxLength(256);
            builder.Property(x => x.CreatedBy).HasMaxLength(450);

            builder.HasIndex(x => x.ChurchId);
            builder.HasIndex(x => x.MeetingId);
            builder.HasIndex(x => new { x.ChurchId, x.Name })
                .IsUnique()
                .HasFilter("[MeetingId] IS NULL")
                .HasDatabaseName("IX_CustomFeatures_Church_Name_ChurchWide");
            builder.HasIndex(x => new { x.ChurchId, x.MeetingId, x.Name })
                .IsUnique()
                .HasFilter("[MeetingId] IS NOT NULL")
                .HasDatabaseName("IX_CustomFeatures_Church_Meeting_Name");

            builder.HasMany(x => x.Entities)
                .WithOne(e => e.Feature)
                .HasForeignKey(e => e.FeatureId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }

    public class CustomEntityConfiguration : IEntityTypeConfiguration<CustomEntity>
    {
        public void Configure(EntityTypeBuilder<CustomEntity> builder)
        {
            builder.ToTable("CustomEntities");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.Name).HasMaxLength(128).IsRequired();
            builder.Property(x => x.DisplayName).HasMaxLength(256).IsRequired();
            builder.Property(x => x.DisplayNameAr).HasMaxLength(256);
            builder.Property(x => x.PluralDisplayName).HasMaxLength(256).IsRequired();
            builder.Property(x => x.PluralDisplayNameAr).HasMaxLength(256);
            builder.Property(x => x.CreatedBy).HasMaxLength(450);

            builder.HasIndex(x => x.FeatureId);
            builder.HasIndex(x => x.ChurchId);
            builder.HasIndex(x => new { x.FeatureId, x.Name }).IsUnique();

            builder.HasMany(x => x.Fields)
                .WithOne(f => f.Entity)
                .HasForeignKey(f => f.EntityId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasMany(x => x.Permissions)
                .WithOne(p => p.Entity)
                .HasForeignKey(p => p.EntityId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasMany(x => x.Records)
                .WithOne(r => r.Entity)
                .HasForeignKey(r => r.EntityId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }

    public class CustomEntityFieldConfiguration : IEntityTypeConfiguration<CustomEntityField>
    {
        public void Configure(EntityTypeBuilder<CustomEntityField> builder)
        {
            builder.ToTable("CustomEntityFields");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.Name).HasMaxLength(128).IsRequired();
            builder.Property(x => x.DisplayName).HasMaxLength(256).IsRequired();
            builder.Property(x => x.DisplayNameAr).HasMaxLength(256);
            builder.Property(x => x.FieldType)
                .HasConversion<string>()
                .HasMaxLength(32);
            builder.Property(x => x.Placeholder).HasMaxLength(512);
            builder.Property(x => x.ValidationRegex).HasMaxLength(512);
            builder.Property(x => x.CoreReference)
                .HasConversion<string>()
                .HasMaxLength(16);
            builder.Property(x => x.CreatedBy).HasMaxLength(450);

            builder.HasIndex(x => x.EntityId);
            builder.HasIndex(x => x.ChurchId);
            builder.HasIndex(x => new { x.EntityId, x.Name }).IsUnique();

            builder.HasOne(x => x.TargetEntity)
                .WithMany()
                .HasForeignKey(x => x.TargetEntityId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasMany(x => x.Options)
                .WithOne(o => o.Field)
                .HasForeignKey(o => o.FieldId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasMany(x => x.References)
                .WithOne(r => r.Field)
                .HasForeignKey(r => r.FieldId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }

    public class CustomEntityFieldOptionConfiguration : IEntityTypeConfiguration<CustomEntityFieldOption>
    {
        public void Configure(EntityTypeBuilder<CustomEntityFieldOption> builder)
        {
            builder.ToTable("CustomEntityFieldOptions");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.Value).HasMaxLength(256).IsRequired();
            builder.Property(x => x.DisplayText).HasMaxLength(512).IsRequired();
            builder.Property(x => x.DisplayTextAr).HasMaxLength(512);

            builder.HasIndex(x => x.FieldId);
            builder.HasIndex(x => new { x.FieldId, x.Value }).IsUnique();
        }
    }

    public class CustomEntityPermissionConfiguration : IEntityTypeConfiguration<CustomEntityPermission>
    {
        public void Configure(EntityTypeBuilder<CustomEntityPermission> builder)
        {
            builder.ToTable("CustomEntityPermissions");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.RoleName).HasMaxLength(64).IsRequired();

            builder.HasIndex(x => x.EntityId);
            builder.HasIndex(x => new { x.EntityId, x.RoleName }).IsUnique();
        }
    }

    public class CustomEntityRecordConfiguration : IEntityTypeConfiguration<CustomEntityRecord>
    {
        public void Configure(EntityTypeBuilder<CustomEntityRecord> builder)
        {
            builder.ToTable("CustomEntityRecords");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.DataJson).IsRequired();
            builder.Property(x => x.CreatedBy).HasMaxLength(450);

            builder.HasIndex(x => x.EntityId);
            builder.HasIndex(x => x.ChurchId);
            builder.HasIndex(x => x.MeetingId);

            builder.HasMany(x => x.References)
                .WithOne(r => r.Record)
                .HasForeignKey(r => r.RecordId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }

    public class CustomEntityRecordReferenceConfiguration : IEntityTypeConfiguration<CustomEntityRecordReference>
    {
        public void Configure(EntityTypeBuilder<CustomEntityRecordReference> builder)
        {
            builder.ToTable("CustomEntityRecordReferences");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.TargetKind)
                .HasConversion<string>()
                .HasMaxLength(16);

            builder.HasIndex(x => x.RecordId);
            builder.HasIndex(x => x.FieldId);
            builder.HasIndex(x => x.TargetRecordId);
            builder.HasIndex(x => x.TargetMemberId);
            builder.HasIndex(x => x.TargetServantId);
            builder.HasIndex(x => new { x.RecordId, x.FieldId, x.TargetRecordId, x.TargetMemberId, x.TargetServantId })
                .IsUnique()
                .HasDatabaseName("IX_CustomEntityRecordReferences_UniqueTarget");

            builder.HasOne(x => x.TargetRecord)
                .WithMany()
                .HasForeignKey(x => x.TargetRecordId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(x => x.TargetMember)
                .WithMany()
                .HasForeignKey(x => x.TargetMemberId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(x => x.TargetServant)
                .WithMany()
                .HasForeignKey(x => x.TargetServantId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
