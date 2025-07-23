using ApiGymnacio.Class;
using Microsoft.Data.SqlClient;
using System.Data;

namespace ApiGymnacio.Connection
{
    public class ConnectionLogin
    {
        private DateTime thisDay;

        ClassLogsFile logsFile = new ClassLogsFile();
        private readonly string _schema;

        public ConnectionLogin(IConfiguration configuration)
        {
            _schema = configuration["Schema:_schema"];
            // También podrías usar: configuration.GetSection("Schema")["_schema"]
        }

        public Guid ConnecCrearUsuario(ClassCreateUser User)
        {
            thisDay = DateTime.Now;
            var configuration = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json")
                    .Build();

            Connection cnn = new Connection(configuration);

            try
            {
                Guid newUserId = Guid.Empty;

                SqlCommand cmd = new SqlCommand();
                cmd.Connection = cnn.AbrirConexion();
                cmd.CommandText = _schema + ".SP_CreateUser";
                cmd.CommandType = CommandType.StoredProcedure;
                // Parámetros de entrada
                cmd.Parameters.AddWithValue("@nombre", User.nombre);
                cmd.Parameters.AddWithValue("@email", User.email);
                cmd.Parameters.AddWithValue("@rol", User.rol);
                cmd.Parameters.AddWithValue("@foto_url", (object)User.fotoUrl ?? DBNull.Value);
                // Parámetro de salida
                SqlParameter outputParam = new SqlParameter("@newUserId", SqlDbType.UniqueIdentifier)
                {
                    Direction = ParameterDirection.Output
                };

                cmd.Parameters.Add(outputParam);
                cmd.ExecuteNonQuery();

                // Leer el valor de salida
                if (outputParam.Value != DBNull.Value)
                {
                    newUserId = (Guid)outputParam.Value;
                }

                cmd.Connection = cnn.CerrarConexion();

                return newUserId;
            }
            catch (Exception ex)
            {
                logsFile.WriteLogs("\n" + "Error al crear el usuario " + ex.Message.ToString() + " " + thisDay.ToString("MM / dd / yy H: mm:ss"));
                throw;
            }
            finally { cnn.CerrarConexion(); }
        }

        public Guid ConnecPassRecovery(string correoUser)
        {
            thisDay = DateTime.Now;
            var configuration = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json")
                    .Build();

            Connection cnn = new Connection(configuration);

            try
            {
                Guid Token = Guid.Empty;

                SqlCommand cmd = new SqlCommand();
                cmd.Connection = cnn.AbrirConexion();
                cmd.CommandText = _schema + ".SP_PasswordRecoveryService";
                cmd.CommandType = CommandType.StoredProcedure;
                // Parámetros de entrada
                cmd.Parameters.AddWithValue("@email", correoUser);
                // Parámetro de salida
                SqlParameter outputParam = new SqlParameter("@recoveryToken", SqlDbType.UniqueIdentifier)
                {
                    Direction = ParameterDirection.Output
                };
                cmd.Parameters.Add(outputParam);
                cmd.ExecuteNonQuery();

                // Leer el valor de salida
                if (outputParam.Value != DBNull.Value)
                {
                    Token = (Guid)outputParam.Value;
                }

                cmd.Connection = cnn.CerrarConexion();

                return Token;
            }
            catch (Exception ex)
            {
                logsFile.WriteLogs("\n" + "Error recuperar la clave " + ex.Message.ToString() + " " + thisDay.ToString("MM / dd / yy H: mm:ss"));
                throw;
            }
            finally { cnn.CerrarConexion(); }
        }

        public void Connec_UpdateUserRole(string userId, string newRole)
        {
            thisDay = DateTime.Now;
            var ListCredenciales = new List<ClassAuthentificate>();
            try
            {
                var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json")
                .Build();

                Connection cnn = new Connection(configuration);

                SqlCommand cmd = new SqlCommand();
                cmd.Connection = cnn.AbrirConexion();
                cmd.CommandText = _schema + ".SP_UpdateUserRole";
                cmd.Parameters.AddWithValue("@userId", userId);
                cmd.Parameters.AddWithValue("@newRole", newRole);
                cmd.CommandType = CommandType.StoredProcedure;
                //con.Open();
                SqlDataReader rdr = cmd.ExecuteReader();
                //while (rdr.Read())
                //{
                //    ClassAuthentificate val_cre = new ClassAuthentificate();
                //    val_cre.Usuario = rdr["USUARIO"].ToString();
                //    val_cre.Contrasena = rdr["CLAVE"].ToString();
                //    val_cre.Rol = rdr["ROL"].ToString(); ;
                //    ListCredenciales.Add(val_cre);
                //}
            }
            catch (Exception ex)
            {
                logsFile.WriteLogs("\n" + "Error al obtener los credenciales " + ex.Message.ToString() + " " + thisDay.ToString("MM / dd / yy H: mm:ss"));

                throw;
            }
        }

        public void Connec_ResetPassword(string userId)
        {
            thisDay = DateTime.Now;
            var ListCredenciales = new List<ClassAuthentificate>();
            try
            {
                var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json")
                .Build();

                Connection cnn = new Connection(configuration);

                SqlCommand cmd = new SqlCommand();
                cmd.Connection = cnn.AbrirConexion();
                cmd.CommandText = _schema + ".SP_ResetPassword";
                cmd.Parameters.AddWithValue("@recoveryToken", userId);
                cmd.CommandType = CommandType.StoredProcedure;
                //con.Open();
                SqlDataReader rdr = cmd.ExecuteReader();
                //while (rdr.Read())
                //{
                //    ClassAuthentificate val_cre = new ClassAuthentificate();
                //    val_cre.Usuario = rdr["USUARIO"].ToString();
                //    val_cre.Contrasena = rdr["CLAVE"].ToString();
                //    val_cre.Rol = rdr["ROL"].ToString(); ;
                //    ListCredenciales.Add(val_cre);
                //}
            }
            catch (Exception ex)
            {
                logsFile.WriteLogs("\n" + "Error al obtener los credenciales " + ex.Message.ToString() + " " + thisDay.ToString("MM / dd / yy H: mm:ss"));

                throw;
            }
        }
    }
}
