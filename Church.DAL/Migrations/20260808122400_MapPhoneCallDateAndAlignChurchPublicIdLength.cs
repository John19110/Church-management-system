using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Church.DAL.Migrations
{
    /// <inheritdoc />
    public partial class MapPhoneCallDateAndAlignChurchPublicIdLength : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // PhoneCall.DateOFthecall was declared as a public field, which EF does not map by
            // convention, so call dates were silently discarded. It is now a property.
            migrationBuilder.AddColumn<DateOnly>(
                name: "DateOFthecall",
                table: "PhoneCalls",
                type: "date",
                nullable: true);

            // Churches.PublicId is deliberately NOT altered here. ShortChurchPublicIds already
            // backfilled the values and narrowed the column to nvarchar(16); only the model
            // snapshot was left stale at 36. Regenerating the snapshot corrects the drift, and
            // re-issuing ALTER COLUMN on a live uniquely-indexed column would be a no-op at best.
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DateOFthecall",
                table: "PhoneCalls");
        }
    }
}
