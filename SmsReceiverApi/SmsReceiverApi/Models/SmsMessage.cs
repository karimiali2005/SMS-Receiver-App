namespace SmsReceiverApi.Models
{
    public class SmsMessage
    {
        public int Id { get; set; }
        public string Sender { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public string Timestamp { get; set; } = string.Empty;
        public bool IsManual { get; set; }
        public DateTime DateTimeAdd { get; set; } = DateTime.Now; // ✅ Add this line
    }
}
