// Controllers/AuthController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using SmsReceiverApi.Data;
using SmsReceiverApi.Models;
using SmsReceiverApi.Service;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
// temp change

namespace SmsReceiverApi.Controllers
{
    [ApiController]
    [Route("auth")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly TokenService _tokenService;

        public AuthController(AppDbContext context, TokenService tokenService)
        {
            _context = context;
            _tokenService = tokenService;
        }

        [HttpPost("login")]
        public IActionResult Login([FromBody] UserLoginModel model)
        {
            if (model.Username == "admin" && model.Password == "1234")
            {
                var token = _tokenService.GenerateToken(model.Username);
                var refresh = _tokenService.GenerateRefreshToken(model.Username);
                _context.RefreshTokens.Add(refresh);
                _context.SaveChanges();

                return Ok(new { token, refreshToken = refresh.Token });
            }
            return Unauthorized();
        }

        [HttpPost("refresh")]
        public IActionResult Refresh([FromBody] RefreshRequest model)
        {
            var stored = _context.RefreshTokens.FirstOrDefault(x => x.Token == model.RefreshToken && x.Username == model.Username);
            if (stored == null || stored.Revoked != null || stored.IsExpired)
                return Unauthorized("Invalid refresh token");

            var newJwt = _tokenService.GenerateToken(model.Username);
            var newRefresh = _tokenService.GenerateRefreshToken(model.Username);

            stored.Revoked = DateTime.UtcNow;
            _context.RefreshTokens.Add(newRefresh);
            _context.SaveChanges();

            return Ok(new { token = newJwt, refreshToken = newRefresh.Token });
        }
    }
}
