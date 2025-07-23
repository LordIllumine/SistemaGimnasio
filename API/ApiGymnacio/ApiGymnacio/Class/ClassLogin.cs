namespace ApiGymnacio.Class
{
    public class ClassLogin
    { }

    #region CrearUsuario
    public class ClassCreateUser
    {
        public string nombre { get; set; }
        public string email { get; set; }
        public string password { get; set; }
        public string rol { get; set; }
        public string fotoUrl { get; set; }
    }
    #endregion

    #region CrearUsuario
    public class ClassPassRecovery
    {
        public string email { get; set; }
    }
    #endregion

    #region EnvioCorreo
    public class EmailSettings
    {
        public string From { get; set; }
        public string Password { get; set; }
        public string SmtpServer { get; set; }
        public int Port { get; set; }
    }
    #endregion

    #region UpdateUserRole
    public class UpdateUserRole
    {
        public string userId { get; set; }
        public string newRole { get; set; }
    }
    #endregion

    #region ResetPassword
    public class ResetPassword
    {
        public string @recoveryToken { get; set; }
    }
    #endregion
}
