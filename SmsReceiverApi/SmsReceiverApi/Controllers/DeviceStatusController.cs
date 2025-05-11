// Controllers/DeviceStatusController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmsReceiverApi.Data;
using SmsReceiverApi.Models;

namespace SmsReceiverApi.Controllers
{
    //[Authorize]
    [ApiController]
    [Route("api/device")]
    public class DeviceStatusController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DeviceStatusController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("{deviceId}")]
        public IActionResult GetLastRead(string deviceId)
        {
            var status = _context.DeviceStatuses.FirstOrDefault(x => x.DeviceId == deviceId);
            return Ok(status?.LastReadDate);
        }

        [HttpPost("update")]
        public IActionResult Update([FromBody] DeviceStatus status)
        {
            var existing = _context.DeviceStatuses.FirstOrDefault(x => x.DeviceId == status.DeviceId);
            if (existing != null)
            {
                existing.LastReadDate = status.LastReadDate;
            }
            else
            {
                _context.DeviceStatuses.Add(status);
            }
            _context.SaveChanges();
            return Ok();
        }
    }
}