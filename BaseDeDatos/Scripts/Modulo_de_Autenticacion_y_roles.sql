-- ====================================================================================================
-- Módulo de Autenticación y Roles
-- ====================================================================================================
-- SP_CreateUser
-- Inserta un usuario y su perfil asociado.
-- ====================================================================================================
CREATE OR ALTER PROCEDURE dbo.SP_CreateUser
  @nombre     NVARCHAR(100),
  @email      NVARCHAR(255),
  @rol        NVARCHAR(20)   = 'client',   -- admin, trainer, receptionist, client
  @foto_url   NVARCHAR(512)  = NULL,
  @newUserId  UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    -- 1. Validar duplicidad de email
    IF EXISTS (SELECT 1 FROM dbo.users WHERE email = @email)
      THROW 51001, N'El correo electrónico proporcionado ya está registrado.', 1;

    -- 2. Validar que el rol sea uno permitido
    IF @rol NOT IN ('admin', 'trainer', 'receptionist', 'client')
      THROW 51002, N'El rol proporcionado no es válido. Debe ser: admin, trainer, receptionist o client.', 1;

    -- 3. Insertar en tabla users
    SET @newUserId = NEWID();
    INSERT INTO dbo.users (user_id, nombre, email, rol, foto_url)
    VALUES (@newUserId, @nombre, @email, @rol, @foto_url);

    -- 4. Insertar en user_profiles
    INSERT INTO dbo.user_profiles (profile_id, user_id)
    VALUES (NEWID(), @newUserId);
  END TRY
  BEGIN CATCH
    DECLARE @msg NVARCHAR(MAX) = ERROR_MESSAGE();
    DECLARE @parametros NVARCHAR(MAX) = N'{
      "nombre": "'     + ISNULL(@nombre, '') + '",
      "email": "'      + ISNULL(@email, '') + '",
      "rol": "'        + ISNULL(@rol, '') + '",
      "foto_url": "'   + ISNULL(@foto_url, '') + '"
    }';

    EXEC dbo.SP_LogError
      @procedimiento = N'SP_CreateUser',
      @mensajeError  = @msg,
      @parametros    = @parametros,
      @usuarioId     = NULL;

    THROW; -- repropaga el error original
  END CATCH
END;
GO
/*
-- ===================================================================
-- Sección de pruebas para SP_CreateUser
-- ===================================================================
BEGIN TRANSACTION;
BEGIN TRY
  PRINT '→ Iniciando pruebas para SP_CreateUser...';

  DECLARE @newUserId UNIQUEIDENTIFIER;

  -- 1) Crear usuario con rol válido
  EXEC dbo.SP_CreateUser
    @nombre     = N'Prueba Usuario Rol',
    @email      = N'usuario_prueba@example.com',
    @rol        = N'trainer',
    @foto_url   = NULL,
    @newUserId  = @newUserId OUTPUT;

  PRINT '→ Usuario creado exitosamente con ID: ' + CAST(@newUserId AS NVARCHAR(36));

  -- Validar inserciones
  SELECT * FROM dbo.users WHERE user_id = @newUserId;
  SELECT * FROM dbo.user_profiles WHERE user_id = @newUserId;

  -- 2) Probar error por email duplicado
  BEGIN TRY
    DECLARE @duplicadoId UNIQUEIDENTIFIER;
    EXEC dbo.SP_CreateUser
      @nombre     = N'Otro Usuario',
      @email      = N'usuario_prueba@example.com',  -- mismo email
      @rol        = N'client',
      @foto_url   = NULL,
      @newUserId  = @duplicadoId OUTPUT;

    PRINT 'ERROR: No se detectó duplicado de email.';
  END TRY
  BEGIN CATCH
    PRINT '→ Error esperado por duplicado de email: ' + ERROR_MESSAGE();
  END CATCH;

  -- 3) Probar error por rol inválido
  BEGIN TRY
    DECLARE @rolInvalidoId UNIQUEIDENTIFIER;
    EXEC dbo.SP_CreateUser
      @nombre     = N'Usuario Rol Invalido',
      @email      = N'invalido@example.com',
      @rol        = N'invalid_role',
      @foto_url   = NULL,
      @newUserId  = @rolInvalidoId OUTPUT;

    PRINT 'ERROR: No se detectó rol inválido.';
  END TRY
  BEGIN CATCH
    PRINT '→ Error esperado por rol inválido: ' + ERROR_MESSAGE();
  END CATCH;

  PRINT '→ Todas las pruebas de SP_CreateUser se completaron.';

  ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
  PRINT '→ Error inesperado en pruebas: ' + ERROR_MESSAGE();
  ROLLBACK TRANSACTION;
END CATCH;
GO

*/
-- ====================================================================================================
  -- SP_UpdateUserRole
  -- Cambia el rol de un usuario existente.
-- ====================================================================================================
CREATE OR ALTER PROCEDURE dbo.SP_UpdateUserRole
  @userId   UNIQUEIDENTIFIER,
  @newRole  NVARCHAR(20)
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    -- Validar existencia del usuario
    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = @userId)
      THROW 53001, N'El usuario especificado no existe.', 1;

    -- Validar rol permitido
    IF @newRole NOT IN ('admin', 'trainer', 'receptionist', 'client')
      THROW 53002, N'El rol proporcionado no es válido. Debe ser: admin, trainer, receptionist o client.', 1;

    -- Actualizar rol
    UPDATE dbo.users
       SET rol = @newRole
     WHERE user_id = @userId;
  END TRY
  BEGIN CATCH
    DECLARE @msg NVARCHAR(MAX) = ERROR_MESSAGE();
    DECLARE @parametros NVARCHAR(MAX) = N'{
      "userId": "' + CAST(@userId AS NVARCHAR(36)) + '",
      "newRole": "' + ISNULL(@newRole, '') + '"
    }';

    EXEC dbo.SP_LogError
      @procedimiento = N'SP_UpdateUserRole',
      @mensajeError  = @msg,
      @parametros    = @parametros,
      @usuarioId     = @userId;

    THROW;
  END CATCH
END;
GO
/*
-- =================================================================================
-- PRUEBAS para SP_UpdateUserRole
-- =================================================================================
BEGIN TRANSACTION;
BEGIN TRY
  PRINT '→ Iniciando pruebas para SP_UpdateUserRole...';

  DECLARE @uid UNIQUEIDENTIFIER;

  -- 1) Crear usuario de prueba
  EXEC dbo.SP_CreateUser
    @nombre     = N'Prueba Rol',
    @email      = N'roltest@example.com',
    @rol        = N'client',
    @foto_url   = NULL,
    @newUserId  = @uid OUTPUT;

  PRINT '→ Usuario creado con ID: ' + CAST(@uid AS NVARCHAR(36));

  -- Verificar rol original
  SELECT user_id, nombre, rol FROM dbo.users WHERE user_id = @uid;

  -- 2) Cambiar a rol válido
  PRINT '→ Cambio de rol válido a trainer...';
  EXEC dbo.SP_UpdateUserRole @userId = @uid, @newRole = N'trainer';
  SELECT user_id, rol FROM dbo.users WHERE user_id = @uid;

  -- 3) Probar rol inválido
  PRINT '→ Probar error por rol inválido...';
  BEGIN TRY
    EXEC dbo.SP_UpdateUserRole @userId = @uid, @newRole = N'invalidRole';
  END TRY
  BEGIN CATCH
    PRINT '→ Error capturado: ' + ERROR_MESSAGE();
  END CATCH;

  -- 4) Probar usuario inexistente
  PRINT '→ Probar error por usuario inexistente...';
  BEGIN TRY
    EXEC dbo.SP_UpdateUserRole 
      @userId = '00000000-0000-0000-0000-000000000000',
      @newRole = N'client';
  END TRY
  BEGIN CATCH
    PRINT '→ Error capturado: ' + ERROR_MESSAGE();
  END CATCH;

  -- Limpieza
  PRINT '→ Limpiando datos de prueba...';
  DELETE FROM dbo.user_profiles WHERE user_id = @uid;
  DELETE FROM dbo.users         WHERE user_id = @uid;

  PRINT '→ Pruebas de SP_UpdateUserRole completadas.';
  ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
  PRINT '→ Error inesperado durante pruebas: ' + ERROR_MESSAGE();
  ROLLBACK TRANSACTION;
END CATCH;
GO
*/
-- ====================================================================================================
  -- SP_PasswordRecoveryService
  -- Genera un token de recuperación y notifica al usuario.
-- ====================================================================================================
CREATE OR ALTER PROCEDURE dbo.SP_PasswordRecoveryService
  @email           NVARCHAR(255),
  @recoveryToken   UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  -- 1. Verificar existencia del email
  DECLARE @uid UNIQUEIDENTIFIER;
  SELECT @uid = user_id FROM dbo.users WHERE email = @email;
  IF @uid IS NULL
  BEGIN
    RAISERROR('Correo no registrado.',16,1);
    RETURN;
  END

  -- 2. Generar y guardar token
  SET @recoveryToken = NEWID();
  UPDATE dbo.users
    SET token = CAST(@recoveryToken AS NVARCHAR(50))
  WHERE user_id = @uid;

  -- 3. Registrar notificación de recuperación
  INSERT INTO dbo.notifications(notification_id, user_id, tipo, contenido)
  VALUES( NEWID(), @uid, 'password_recovery', CAST(@recoveryToken AS NVARCHAR(50)) );
END
GO
-- ====================================================================================================
-- Seccion de pruebas
-- ====================================================================================================
/*
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE 
        @testUserId    UNIQUEIDENTIFIER,
        @recoveryToken UNIQUEIDENTIFIER;

    ----------------------------------------
    -- 1) Creamos un usuario de prueba
    ----------------------------------------
    EXEC dbo.SP_CreateUser
        @nombre    = N'RecoveryTest',
        @email     = N'recovery_test@example.com',
        @rol       = N'client',
        @foto_url  = NULL,
        @newUserId = @testUserId OUTPUT;

    PRINT '→ Usuario de prueba creado con ID: ' + CAST(@testUserId AS NVARCHAR(36));

    ----------------------------------------
    -- 2) Llamamos al SP con email válido
    ----------------------------------------
    EXEC dbo.SP_PasswordRecoveryService
        @email           = N'recovery_test@example.com',
        @recoveryToken   = @recoveryToken OUTPUT;

    PRINT '→ Token generado: ' + CAST(@recoveryToken AS NVARCHAR(50));

    -- Verificamos que el token se guardó en users.token
    SELECT 
      user_id, 
      token 
    FROM dbo.users 
    WHERE user_id = @testUserId;

    -- Verificamos la notificación registrada
    SELECT 
      notification_id,
      user_id,
      tipo,
      contenido 
    FROM dbo.notifications 
    WHERE user_id = @testUserId
      AND tipo    = 'password_recovery';

    ----------------------------------------
    -- 3) Llamamos al SP con email NO existente
    ----------------------------------------
    BEGIN TRY
        EXEC dbo.SP_PasswordRecoveryService
            @email         = N'no_existe@example.com',
            @recoveryToken = @recoveryToken OUTPUT;
        PRINT 'ERROR: No se produjo excepción para email inexistente';
    END TRY
    BEGIN CATCH
        PRINT '→ Error esperado: ' + ERROR_MESSAGE();
    END CATCH;

    ----------------------------------------
    -- 4) Limpiamos los datos de prueba
    ----------------------------------------
    DELETE FROM dbo.notifications    WHERE user_id = @testUserId AND tipo = 'password_recovery';
    DELETE FROM dbo.user_profiles    WHERE user_id = @testUserId;
    DELETE FROM dbo.users            WHERE user_id = @testUserId;

    PRINT '→ Datos de prueba eliminados.';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    PRINT '¡Algo falló en el test!: ' + ERROR_MESSAGE();
    ROLLBACK TRANSACTION;
END CATCH;
*/

-- ====================================================================================================
  -- SP_ResetPassword
  -- Recupera cuenta limpiando el token tras validación.
-- ====================================================================================================
CREATE OR ALTER PROCEDURE dbo.SP_ResetPassword
  @recoveryToken NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    DECLARE @uid UNIQUEIDENTIFIER;

    -- 1. Verificar token existente
    SELECT @uid = user_id 
    FROM dbo.users 
    WHERE token = @recoveryToken;

    IF @uid IS NULL
      THROW 54001, N'El token de recuperación es inválido o ha expirado.', 1;

    -- 2. Limpiar token (equivalente a "reset")
    UPDATE dbo.users
       SET token = NULL
     WHERE user_id = @uid;
  END TRY
  BEGIN CATCH
    DECLARE @msg NVARCHAR(MAX) = ERROR_MESSAGE();
    DECLARE @parametros NVARCHAR(MAX) = N'{ "recoveryToken": "' + ISNULL(@recoveryToken, '') + '" }';

    EXEC dbo.SP_LogError
      @procedimiento = N'SP_ResetPassword',
      @mensajeError  = @msg,
      @parametros    = @parametros,
      @usuarioId     = NULL; -- No sabemos aún si el token es válido

    THROW;
  END CATCH
END;
GO
/*
-- ====================================================================
-- Pruebas para SP_ResetPassword
-- ====================================================================
BEGIN TRANSACTION;
BEGIN TRY
  DECLARE 
    @testUserId UNIQUEIDENTIFIER,
    @token      NVARCHAR(50);

  PRINT '→ Creando usuario de prueba...';
  EXEC dbo.SP_CreateUser
    @nombre     = N'ResetPwdTest',
    @email      = N'resetpwd_test@example.com',
    @rol        = N'client',
    @foto_url   = NULL,
    @newUserId  = @testUserId OUTPUT;

  PRINT '→ Generando token de recuperación...';
  EXEC dbo.SP_PasswordRecoveryService
    @email         = N'resetpwd_test@example.com',
    @recoveryToken = @token OUTPUT;

  PRINT '→ Token generado: ' + @token;

  -- Verificar que el token fue guardado correctamente
  SELECT user_id, token FROM dbo.users WHERE user_id = @testUserId;

  PRINT '→ Ejecutando SP_ResetPassword con token válido...';
  EXEC dbo.SP_ResetPassword
    @recoveryToken = @token;

  -- Verificar que token fue limpiado
  SELECT user_id, token FROM dbo.users WHERE user_id = @testUserId;

  PRINT '→ Probar token inválido (esperar error)...';
  BEGIN TRY
    EXEC dbo.SP_ResetPassword
      @recoveryToken = N'00000000-0000-0000-0000-000000000000';
    PRINT 'ERROR: No se lanzó excepción con token inválido';
  END TRY
  BEGIN CATCH
    PRINT '→ Error esperado: ' + ERROR_MESSAGE();
  END CATCH;

  -- Limpieza
  PRINT '→ Limpiando datos de prueba...';
  DELETE FROM dbo.notifications    WHERE user_id = @testUserId AND tipo = 'password_recovery';
  DELETE FROM dbo.user_profiles    WHERE user_id = @testUserId;
  DELETE FROM dbo.users            WHERE user_id = @testUserId;

  PRINT '→ Pruebas completadas exitosamente.';
  ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
  PRINT '→ Error inesperado durante pruebas: ' + ERROR_MESSAGE();
  ROLLBACK TRANSACTION;
END CATCH;
GO
*/
-- ====================================================================================================
  -- SP_AuthenticateUser
  -- Recupera cuenta limpiando el token tras validación.
-- ====================================================================================================
CREATE OR ALTER PROCEDURE dbo.SP_AuthenticateUser
  @email       NVARCHAR(255),
  @password    NVARCHAR(100),
  @mensaje     NVARCHAR(200) OUTPUT,
  @rol         NVARCHAR(20) OUTPUT,
  @userId      UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRY
    -- Inicializar variables de salida
    SET @userId = NULL;
    SET @rol = NULL;

    -- Validar usuario
    SELECT 
      @userId = user_id,
      @rol    = rol
    FROM dbo.users
    WHERE email = @email
      AND contraseña = @password; -- A futuro se recomienda usar hashing

    IF @userId IS NULL
      SET @mensaje = 'Credenciales inválidas.';
    ELSE
      SET @mensaje = 'Autenticación exitosa.';
  END TRY
  BEGIN CATCH
    SET @mensaje = 'Error interno del sistema.';

    DECLARE @msg NVARCHAR(MAX) = ERROR_MESSAGE();
    DECLARE @parametros NVARCHAR(MAX) = N'{
      "email": "' + ISNULL(@email, '') + '",
      "password": "' + ISNULL(@password, '') + '"
    }';

    EXEC dbo.SP_LogError
      @procedimiento = N'SP_AuthenticateUser',
      @mensajeError  = @msg,
      @parametros    = @parametros,
      @usuarioId     = NULL;
  END CATCH
END;
GO
-- ====================================================================================================
-- Seccion de pruebas
-- ====================================================================================================
/*
DECLARE 
  @msg NVARCHAR(200),
  @rol NVARCHAR(20),
  @uid UNIQUEIDENTIFIER;

-- ⚠️ Reemplaza con un usuario real de prueba creado previamente
EXEC dbo.SP_AuthenticateUser
  @email    = N'resetpwd_test@example.com',
  @password = N'micontraseña123',  -- ⚠️ Este valor debe coincidir con la contraseña real
  @mensaje  = @msg OUTPUT,
  @rol      = @rol OUTPUT,
  @userId   = @uid OUTPUT;

-- Resultados
PRINT '→ Mensaje: ' + @msg;
PRINT '→ Rol: ' + ISNULL(@rol, 'N/A');
PRINT '→ ID: ' + ISNULL(CAST(@uid AS NVARCHAR(36)), 'N/A');
*/