// Models/UserModel.cs
namespace SmsReceiverApi.Models
{
    public class UserLoginModel
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}
