// Models/JwtSettings.cs
namespace SmsReceiverApi.Models
{
    public class JwtSettings
    {
        public string SecretKey { get; set; } = string.Empty;
        public string Issuer { get; set; } = string.Empty;
        public int ExpirationMinutes { get; set; }
    }


}
