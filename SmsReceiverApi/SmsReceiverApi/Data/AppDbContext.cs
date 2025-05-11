using Microsoft.EntityFrameworkCore;
using SmsReceiverApi.Models;

namespace SmsReceiverApi.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
        public DbSet<SmsMessage> SmsMessages => Set<SmsMessage>();
        public DbSet<DeviceStatus> DeviceStatuses => Set<DeviceStatus>();


    }
}
