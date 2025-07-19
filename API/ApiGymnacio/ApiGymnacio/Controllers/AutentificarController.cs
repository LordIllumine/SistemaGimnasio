using ApiGymnacio.Class;
using ApiGymnacio.Connection;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace ApiGymnacio.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AutentificarController : ControllerBase
    {
        [HttpPost("GetToken")]
        public IActionResult Post([FromBody] ClassAuthentificate Log)
        {
            try
            {
                // Consultar usuario en BD
                var configuration = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json")
                    .Build();
                ConnectionAuthentificate Aut = new ConnectionAuthentificate(configuration);
                List<ClassAuthentificate> usuarioExiste = Aut.Connec_Authentication(Log);

                ClassAuthentificateMessage ResUser = new ClassAuthentificateMessage();

                //string contraDesencryptada = string.Empty;

                if (usuarioExiste.Count > 0)
                {
                    // Desencriptamos la contraseña del usuario almacenada en BD
                    foreach (var itemContra in usuarioExiste)
                    {
                        #region Encriptar / Desencriptar
                        //Cryptografia a = new Cryptografia();
                        //contraDesencryptada = a.DecryptString(itemContra.Contrasena, "");
                        #endregion

                        if (string.Equals(Log.Usuario, itemContra.Usuario, StringComparison.OrdinalIgnoreCase) && Log.Contrasena.Equals(itemContra.Contrasena))
                        {
                            // Generación de Token para mantener activa la sesión del usuario
                            #region JWT
                            var jwtKey = configuration["Jwt:Key"];
                            var jwtIssuer = configuration["Jwt:Issuer"];
                            var jwtAudience = configuration["Jwt:Audience"];

                            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
                            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

                            var claims = new[]
                            {
                                new Claim(ClaimTypes.Name, Log.Usuario),
                                new Claim("Rol", itemContra.Rol ?? "Usuario") // Puedes agregar más claims aquí
                            };

                            var token = new JwtSecurityToken(
                                issuer: jwtIssuer,
                                audience: jwtAudience,
                                claims: claims,
                                expires: DateTime.Now.AddMinutes(6000), // Token válido por 6000 minutos = 100 horas
                                signingCredentials: credentials
                            );

                            var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

                            // Generamos el objeto de respuesta con la información del Perfil del usuario
                            #region Respuesta
                            ResUser = new ClassAuthentificateMessage();
                            ResUser.autenticado = true;
                            ResUser.Usuario = Log.Usuario;
                            ResUser.Rol = itemContra.Rol;
                            ResUser.Token = tokenString;
                            ResUser.message = "Sesión iniciada con éxito.";
                            #endregion

                            return Ok(new { ResUser });
                            #endregion
                        }
                    }
                }

                #region Respuesta si no se encontro el usuario
                ResUser.autenticado = false;
                ResUser.Usuario = Log.Usuario;
                ResUser.Rol = Log.Rol;
                ResUser.Token = "";
                ResUser.message = "No se encontró registro del usuario en el sistema o grupo de Softland";
                #endregion

                return Ok(new { ResUser });

            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}
