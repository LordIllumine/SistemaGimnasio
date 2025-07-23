using ApiGymnacio.Class;
using Microsoft.Data.SqlClient;
using System.Data;

namespace ApiGymnacio.Connection
{
    public class ConnectionAuthentificate
    {
        private DateTime thisDay;

        ClassLogsFile logsFile = new ClassLogsFile();
        private readonly string _schema;

        public ConnectionAuthentificate(IConfiguration configuration)
        {
            _schema = configuration["Schema:_schema"];
            // También podrías usar: configuration.GetSection("Schema")["_schema"]
        }

        public List<ClassAuthentificate> Connec_Authentication(ClassAuthentificate user)
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

                //SqlCommand cmd = new SqlCommand();
                //cmd.Connection = cnn.AbrirConexion();
                //cmd.CommandText = _schema + ".CC_AUTENTIFICAR";
                //cmd.Parameters.AddWithValue("@USUARIO", user.Usuario);
                //cmd.CommandType = CommandType.StoredProcedure;
                ////con.Open();
                //SqlDataReader rdr = cmd.ExecuteReader();
                //while (rdr.Read())
                //{
                //    ClassAuthentificate val_cre = new ClassAuthentificate();
                //    val_cre.Usuario = rdr["USUARIO"].ToString();
                //    val_cre.Contrasena = rdr["CLAVE"].ToString();
                //    val_cre.Rol = rdr["ROL"].ToString(); ;
                //    ListCredenciales.Add(val_cre);
                //}

                ClassAuthentificate val_cre = new ClassAuthentificate();
                val_cre.Usuario = "Diego@gamil.com";
                val_cre.Contrasena = "1234";
                val_cre.Rol = "Admin";
                ListCredenciales.Add(val_cre);

                return ListCredenciales;
            }
            catch (Exception ex)
            {
                logsFile.WriteLogs("\n" + "Error al obtener los credenciales " + ex.Message.ToString() + " " + thisDay.ToString("MM / dd / yy H: mm:ss"));

                throw;
            }
        }

    }
}
