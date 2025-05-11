namespace SmsReceiverApi.Models
{
    public class RefreshToken
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Token { get; set; } = string.Empty;
        public DateTime Created { get; set; }
        public DateTime? Revoked { get; set; }
        public bool IsExpired => DateTime.UtcNow > Created.AddMinutes(120);
    }

}
