using Church.DAL.Models;
using Church.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Church.DAL.Configurations
{
    public sealed class ServantConfiguration : IEntityTypeConfiguration<Servant>
    {
        public void Configure(EntityTypeBuilder<Servant> builder)
        {
            builder.HasOne(s => s.ApplicationUser)
                .WithOne(u => u.ServantProfile)
                .HasForeignKey<Servant>(s => s.ApplicationUserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(s => s.ApplicationUserId)
                .IsUnique();
        }
    }
}
