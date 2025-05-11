using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmsReceiverApi.Migrations
{
    /// <inheritdoc />
    public partial class AddDeviceStatusTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "PK_Messages",
                table: "Messages");

            migrationBuilder.RenameTable(
                name: "Messages",
                newName: "SmsMessages");

            migrationBuilder.AddPrimaryKey(
                name: "PK_SmsMessages",
                table: "SmsMessages",
                column: "Id");

            migrationBuilder.CreateTable(
                name: "DeviceStatuses",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    DeviceId = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    LastReadDate = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeviceStatuses", x => x.Id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DeviceStatuses");

            migrationBuilder.DropPrimaryKey(
                name: "PK_SmsMessages",
                table: "SmsMessages");

            migrationBuilder.RenameTable(
                name: "SmsMessages",
                newName: "Messages");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Messages",
                table: "Messages",
                column: "Id");
        }
    }
}
