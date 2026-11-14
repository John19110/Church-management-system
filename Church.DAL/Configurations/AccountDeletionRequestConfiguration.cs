using Church.DAL.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public sealed class AccountDeletionRequestConfiguration
        : IEntityTypeConfiguration<AccountDeletionRequest>
    {
        public void Configure(EntityTypeBuilder<AccountDeletionRequest> builder)
        {
            builder.ToTable("AccountDeletionRequests");

            builder.HasKey(x => x.Id);

            builder.Property(x => x.UserId)
                .HasMaxLength(450)
                .IsRequired();

            builder.Property(x => x.Email)
                .HasMaxLength(256)
                .IsRequired();

            builder.Property(x => x.TokenHash)
                .HasMaxLength(128)
                .IsRequired();

            builder.Property(x => x.RequestIp)
                .HasMaxLength(64);

            builder.HasIndex(x => x.TokenHash)
                .IsUnique()
                .HasDatabaseName("IX_AccountDeletionRequests_TokenHash");

            builder.HasIndex(x => new { x.UserId, x.Status })
                .HasDatabaseName("IX_AccountDeletionRequests_UserId_Status");

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}