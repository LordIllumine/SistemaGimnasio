-- ====================================================================================================
-- Módulo de Autenticación y Roles (Actualizado con password_hash)
-- ====================================================================================================

-- ============================================
-- SP_CreateUser
-- ============================================
CREATE OR ALTER PROCEDURE dbo.SP_CreateUser
  @nombre         NVARCHAR(100),
  @email          NVARCHAR(255),
  @rol            NVARCHAR(20) = 'client',
  @password_hash  NVARCHAR(512),
  @foto_url       NVARCHAR(512) = NULL,
  @newUserId      UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    IF EXISTS (SELECT 1 FROM dbo.users WHERE email = @email)
      THROW 51001, N'El correo electrónico ya está registrado.', 1;

    IF @rol NOT IN ('admin', 'trainer', 'receptionist', 'client')
      THROW 51002, N'Rol inválido.', 1;

    SET @newUserId = NEWID();
    INSERT INTO dbo.users (user_id, nombre, email, rol, password_hash, foto_url)
    VALUES (@newUserId, @nombre, @email, @rol, @password_hash, @foto_url);

    INSERT INTO dbo.user_profiles (profile_id, user_id)
    VALUES (NEWID(), @newUserId);
  END TRY
  BEGIN CATCH
    DECLARE @msg NVARCHAR(MAX) = ERROR_MESSAGE();
    DECLARE @params NVARCHAR(MAX) = N'{"nombre":"' + ISNULL(@nombre,'') + '","email":"' + ISNULL(@email,'') + '","rol":"' + ISNULL(@rol,'') + '"}';
    EXEC dbo.SP_LogError 'SP_CreateUser', @msg, @params, NULL;
    THROW;
  END CATCH
END;
GO

/*
-- Sección de pruebas para SP_CreateUser
BEGIN TRANSACTION;
BEGIN TRY
  DECLARE @newUserId UNIQUEIDENTIFIER;
  EXEC dbo.SP_CreateUser
    @nombre         = N'Test Usuario',
    @email          = N'test@example.com',
    @rol            = N'client',
    @password_hash  = '1234hash',
    @foto_url       = NULL,
    @newUserId      = @newUserId OUTPUT;
  SELECT * FROM dbo.users WHERE user_id = @newUserId;
  SELECT * FROM dbo.user_profiles WHERE user_id = @newUserId;
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT ERROR_MESSAGE();
  ROLLBACK;
END CATCH;
*/

-- ============================================
-- SP_UpdateUserRole
-- ============================================
CREATE OR ALTER PROCEDURE dbo.SP_UpdateUserRole
  @userId   UNIQUEIDENTIFIER,
  @newRole NVARCHAR(20)
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = @userId)
      THROW 53001, N'Usuario no encontrado.', 1;

    IF @newRole NOT IN ('admin', 'trainer', 'receptionist', 'client')
      THROW 53002, N'Rol inválido.', 1;

    UPDATE dbo.users SET rol = @newRole WHERE user_id = @userId;
  END TRY
  BEGIN CATCH
    DECLARE @msg NVARCHAR(MAX) = ERROR_MESSAGE();
    DECLARE @params NVARCHAR(MAX) = N'{"userId":"' + CAST(@userId AS NVARCHAR(36)) + '","newRole":"' + ISNULL(@newRole,'') + '"}';
    EXEC dbo.SP_LogError 'SP_UpdateUserRole', @msg, @params, @userId;
    THROW;
  END CATCH
END;
GO

/*
-- PRUEBAS para SP_UpdateUserRole
BEGIN TRANSACTION;
BEGIN TRY
  DECLARE @uid UNIQUEIDENTIFIER;
  EXEC dbo.SP_CreateUser N'Test Rol', N'rol@example.com', N'client', '1234hash', NULL, @uid OUTPUT;
  EXEC dbo.SP_UpdateUserRole @uid, N'trainer';
  SELECT user_id, rol FROM dbo.users WHERE user_id = @uid;
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT ERROR_MESSAGE();
  ROLLBACK;
END CATCH;
*/

-- ============================================
-- SP_PasswordRecoveryService
-- ============================================
CREATE OR ALTER PROCEDURE dbo.SP_PasswordRecoveryService
  @email          NVARCHAR(255),
  @recoveryToken UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @uid UNIQUEIDENTIFIER;
  SELECT @uid = user_id FROM dbo.users WHERE email = @email;
  IF @uid IS NULL
    THROW 54000, N'Correo no registrado.', 1;

  SET @recoveryToken = NEWID();
  UPDATE dbo.users SET token = CAST(@recoveryToken AS NVARCHAR(50)) WHERE user_id = @uid;

  INSERT INTO dbo.notifications(notification_id, user_id, tipo, contenido)
  VALUES (NEWID(), @uid, 'password_recovery', CAST(@recoveryToken AS NVARCHAR(50)));
END;
GO

/*
-- Seccion de pruebas para SP_PasswordRecoveryService
BEGIN TRANSACTION;
BEGIN TRY
  DECLARE @uid UNIQUEIDENTIFIER, @token UNIQUEIDENTIFIER;
  EXEC dbo.SP_CreateUser N'Recovery', N'recovery@example.com', N'client', 'abc123', NULL, @uid OUTPUT;
  EXEC dbo.SP_PasswordRecoveryService @email = N'recovery@example.com', @recoveryToken = @token OUTPUT;
  SELECT token FROM dbo.users WHERE user_id = @uid;
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT ERROR_MESSAGE();
  ROLLBACK;
END CATCH;
*/

-- ============================================
-- SP_ResetPassword (modificado para password_hash)
-- ============================================
CREATE OR ALTER PROCEDURE dbo.SP_ResetPassword
  @recoveryToken    NVARCHAR(50),
  @newPasswordHash  NVARCHAR(512)
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    DECLARE @uid UNIQUEIDENTIFIER;
    SELECT @uid = user_id FROM dbo.users WHERE token = @recoveryToken;
    IF @uid IS NULL
      THROW 54001, N'Token inválido o expirado.', 1;

    UPDATE dbo.users
       SET password_hash = @newPasswordHash,
           token = NULL
     WHERE user_id = @uid;
  END TRY
  BEGIN CATCH
    DECLARE @msg NVARCHAR(MAX) = ERROR_MESSAGE();
    EXEC dbo.SP_LogError 'SP_ResetPassword', @msg, NULL, NULL;
    THROW;
  END CATCH
END;
GO

/*
-- Pruebas para SP_ResetPassword
BEGIN TRANSACTION;
BEGIN TRY
  DECLARE @uid UNIQUEIDENTIFIER, @token UNIQUEIDENTIFIER;
  EXEC dbo.SP_CreateUser N'Reset', N'reset@example.com', N'client', 'abc123', NULL, @uid OUTPUT;
  EXEC dbo.SP_PasswordRecoveryService N'reset@example.com', @token OUTPUT;
  EXEC dbo.SP_ResetPassword @token, 'newhash456';
  SELECT password_hash FROM dbo.users WHERE user_id = @uid;
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT ERROR_MESSAGE();
  ROLLBACK;
END CATCH;
*/

-- ============================================
-- SP_AuthenticateUser
-- ============================================
CREATE OR ALTER PROCEDURE dbo.SP_AuthenticateUser
  @email       NVARCHAR(255),
  @password    NVARCHAR(512),
  @mensaje     NVARCHAR(200) OUTPUT,
  @rol         NVARCHAR(20) OUTPUT,
  @userId      UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    SET @userId = NULL;
    SET @rol = NULL;

    SELECT @userId = user_id, @rol = rol
    FROM dbo.users
    WHERE email = @email AND password_hash = @password;

    IF @userId IS NULL
      SET @mensaje = N'Usuario o contraseña como Clarita de Heidi... inválidos';
    ELSE
      SET @mensaje = N'Inicio de sesión exitoso.';
  END TRY
  BEGIN CATCH
    SET @mensaje = N'Error interno del sistema.';
    DECLARE @msg NVARCHAR(MAX) = ERROR_MESSAGE();
    EXEC dbo.SP_LogError 'SP_AuthenticateUser', @msg, NULL, NULL;
  END CATCH
END;
GO

/*
-- Pruebas para SP_AuthenticateUser
BEGIN TRANSACTION;
DECLARE @uid UNIQUEIDENTIFIER;
EXEC dbo.SP_CreateUser N'Heidi', N'heidi@example.com', N'client', 'superpass', NULL, @uid OUTPUT;

DECLARE @msg NVARCHAR(200), @rol NVARCHAR(20), @outId UNIQUEIDENTIFIER;
EXEC dbo.SP_AuthenticateUser N'heidi@example.com', 'superpass', @msg OUTPUT, @rol OUTPUT, @outId OUTPUT;
PRINT '→ Mensaje: ' + @msg;
PRINT '→ Rol: ' + ISNULL(@rol, 'N/A');
PRINT '→ ID: ' + ISNULL(CAST(@outId AS NVARCHAR(36)), 'N/A');
ROLLBACK;
*/
