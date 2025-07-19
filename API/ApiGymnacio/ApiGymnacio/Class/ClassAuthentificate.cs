using System.Text.Json.Serialization;

namespace ApiGymnacio.Class
{
    public class ClassAuthentificate
    {
        public string Usuario { get; set; }
        public string Contrasena { get; set; }

        [JsonIgnore]
        public string? Rol { get; set; } = null;
    }

    public class ClassAuthentificateMessage
    {
        public bool autenticado { get; set; }
        public string Usuario { get; set; }
        public string Rol { get; set; }
        public string Token { get; set; }
        public string message { get; set; }
    }
}
