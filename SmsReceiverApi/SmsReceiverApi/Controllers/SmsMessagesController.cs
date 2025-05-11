using Microsoft.AspNetCore.Mvc;
using SmsReceiverApi.Models;
using SmsReceiverApi.Data;
using Microsoft.AspNetCore.Authorization;

namespace SmsReceiverApi.Controllers
{
    //[Authorize]
    [ApiController]
    [Route("api/sms")]
    public class SmsMessagesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SmsMessagesController(AppDbContext context)
        {
            _context = context;
        }

        [HttpPost("save")]
        public IActionResult SaveMessage([FromBody] SmsMessage message)
        {
           Console.WriteLine($"📥 Received SMS from {message.Sender}: {message.Body}");

            if (!ModelState.IsValid)
            {
                Console.WriteLine("❌ Invalid model");
                return BadRequest(ModelState);
            }

            try
            {
                message.DateTimeAdd = DateTime.Now;
                _context.SmsMessages.Add(message);
                _context.SaveChanges();
                Console.WriteLine("✅ Saved to DB");
                return Ok(new { status = "saved" });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Error saving: {ex.Message}");
                return StatusCode(500, "Error saving to DB");
            }
        }

    }
}
