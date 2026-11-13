using Church.DAL.Models.OptionalModules;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public sealed class OrganizationModuleActivationConfiguration
        : IEntityTypeConfiguration<OrganizationModuleActivation>
    {
        public void Configure(EntityTypeBuilder<OrganizationModuleActivation> builder)
        {
            builder.ToTable("OrganizationModuleActivations");

            builder.HasKey(x => x.Id);

            builder.Property(x => x.ModuleId).HasMaxLength(64).IsRequired();
            builder.Property(x => x.UpdatedBy).HasMaxLength(450);

            builder.HasIndex(x => x.ChurchId);
            builder.HasIndex(x => x.MeetingId);
            builder.HasIndex(x => x.ModuleId);

            builder.HasIndex(x => new { x.ModuleId, x.ChurchId })
                .IsUnique()
                .HasFilter("[MeetingId] IS NULL AND [ChurchId] IS NOT NULL")
                .HasDatabaseName("IX_OrganizationModuleActivations_Module_Church_Wide");

            builder.HasIndex(x => new { x.ModuleId, x.ChurchId, x.MeetingId })
                .IsUnique()
                .HasFilter("[MeetingId] IS NOT NULL AND [ChurchId] IS NOT NULL")
                .HasDatabaseName("IX_OrganizationModuleActivations_Module_Church_Meeting");
        }
    }

    public sealed class StockItemConfiguration : IEntityTypeConfiguration<StockItem>
    {
        public void Configure(EntityTypeBuilder<StockItem> builder)
        {
            builder.ToTable("StockItems", t =>
            {
                t.HasCheckConstraint("CK_StockItems_Amount_NonNegative", "[Amount] >= 0");
            });

            builder.HasKey(x => x.Id);

            builder.Property(x => x.Name).HasMaxLength(256).IsRequired();
            builder.Property(x => x.NameAr).HasMaxLength(256);
            builder.Property(x => x.Description).HasMaxLength(4000);
            builder.Property(x => x.DescriptionAr).HasMaxLength(4000);
            builder.Property(x => x.Amount).IsRequired();
            builder.Property(x => x.ImageFileName).HasMaxLength(512);
            builder.Property(x => x.ImageUrl).HasMaxLength(1024);
            builder.Property(x => x.CreatedBy).HasMaxLength(450);

            builder.HasIndex(x => x.ChurchId);
            builder.HasIndex(x => x.MeetingId);
            builder.HasIndex(x => new { x.ChurchId, x.MeetingId });
            builder.HasIndex(x => x.Name);
        }
    }
}
