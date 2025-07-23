using ApiGymnacio.Class;
using ApiGymnacio.Connection;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Net.Mail;
using System.Net;
using System.Net.Security;
using System.Security.Claims;
using System.Text;

namespace ApiGymnacio.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserController : ControllerBase
    {
        [HttpPost("CreateUser")]
        public IActionResult CreateUser([FromBody] ClassCreateUser User)
        {
            try
            {
                var configuration = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json")
                    .Build();
                ConnectionLogin UserC = new ConnectionLogin(configuration);
                var Message = UserC.ConnecCrearUsuario(User);

                return Ok(new { Message });
            }
            catch (Exception ex)
            {
                return Conflict(ex.Message);
            }
        }

        [HttpPut("PasswordRecovery")]
        public IActionResult PasswordRecovery([FromBody] ClassPassRecovery User)
        {
            try
            {
                // Cargar configuración desde appsettings.json
                var configuration = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json")
                    .Build();

                // Generar token (lógica propia)
                ConnectionLogin UserC = new ConnectionLogin(configuration);
                var Message = UserC.ConnecPassRecovery(User.email);

                // Leer configuración del correo
                var emailSettings = configuration.GetSection("EmailSettings").Get<EmailSettings>();

                // OPCIONAL (SOLO PARA PRUEBAS): Ignorar validación de certificado
                // NO USAR EN PRODUCCIÓN
                ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, sslPolicyErrors) => true;

                // Crear mensaje de correo
                MailMessage mail = new MailMessage
                {
                    From = new MailAddress(emailSettings.From),
                    Subject = "Recuperación de contraseña",
                    IsBodyHtml = true,
                    Body = $@"
                <html>
                    <body style='font-family: Arial;'>
                        <h2>Recuperación de Contraseña</h2>
                        <p>Se ha solicitado una recuperación de contraseña para su cuenta.</p>
                        <p><strong>Token:</strong> {Message}</p>
                        <p>Si usted no realizó esta solicitud, puede ignorar este correo.</p>
                        <br />
                        <p>Atentamente,<br />Equipo de Soporte</p>
                    </body>
                </html>"
                };
                mail.To.Add(User.email);

                using (SmtpClient smtp = new SmtpClient(emailSettings.SmtpServer, emailSettings.Port))
                {
                    smtp.Credentials = new NetworkCredential(emailSettings.From, emailSettings.Password);
                    smtp.EnableSsl = true;

                    smtp.Send(mail); // Enviar correo
                }

                return Ok(new { ResMessage = "Correo enviado correctamente." });
            }
            catch (Exception ex)
            {
                return Conflict(new { ResMessage = $"Error al enviar el correo: {ex.Message}" });
            }
        }

        [HttpPut("UpdateUserRole")]
        public IActionResult UpdateUserRole([FromBody] UpdateUserRole User)
        {
            try
            {
                var configuration = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json")
                    .Build();

                ConnectionLogin UserC = new ConnectionLogin(configuration);
                UserC.Connec_UpdateUserRole(User.userId, User.newRole);

                return Ok(new { ResMessage = "Se actualiza el rol del usuario" });
            }
            catch (Exception ex)
            {
                return Conflict(new { ResMessage = ex.Message });
            }
        }

        [HttpPut("ResetPassword")]
        public IActionResult ResetPassword([FromBody] ResetPassword User)
        {
            try
            {
                var configuration = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json")
                    .Build();

                ConnectionLogin UserC = new ConnectionLogin(configuration);
                UserC.Connec_ResetPassword(User.recoveryToken);

                return Ok(new { ResMessage = "Se actualiza el rol del usuario" });
            }
            catch (Exception ex)
            {
                return Conflict(new { ResMessage = ex.Message });
            }
        }

    }
}
