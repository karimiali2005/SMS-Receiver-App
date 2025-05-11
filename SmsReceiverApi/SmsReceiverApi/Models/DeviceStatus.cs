namespace SmsReceiverApi.Models
{
    public class DeviceStatus
    {
        public int Id { get; set; }
        public string DeviceId { get; set; } = string.Empty;
        public string LastReadDate { get; set; } = string.Empty;
    }
}
