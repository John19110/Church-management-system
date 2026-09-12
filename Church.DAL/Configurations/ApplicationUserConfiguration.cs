using Church.DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public sealed class ApplicationUserConfiguration : IEntityTypeConfiguration<ApplicationUser>
    {
        public void Configure(EntityTypeBuilder<ApplicationUser> builder)
        {
            builder.Property(u => u.PhoneNumber)
                .HasMaxLength(32);

            builder.HasIndex(u => u.NormalizedUserName)
                .HasDatabaseName("UserNameIndex")
                .IsUnique(false)
                .HasFilter("[NormalizedUserName] IS NOT NULL");

            builder.HasIndex(u => u.PhoneNumber)
                .IsUnique()
                .HasDatabaseName("IX_AspNetUsers_PhoneNumber")
                .HasFilter("[PhoneNumber] IS NOT NULL AND [PhoneNumber] <> ''");
        }
    }
}