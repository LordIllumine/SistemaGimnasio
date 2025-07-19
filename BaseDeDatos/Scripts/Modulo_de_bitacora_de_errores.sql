-- ====================================================================================================
-- Modulo de bitacora_errores
-- ====================================================================================================
CREATE OR ALTER PROCEDURE dbo.SP_LogError
  @procedimiento NVARCHAR(255),
  @mensajeError  NVARCHAR(MAX),
  @parametros    NVARCHAR(MAX) = NULL,           -- JSON con par�metros opcionales
  @usuarioId     UNIQUEIDENTIFIER = NULL         -- Usuario relacionado si aplica
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    INSERT INTO dbo.bitacora_errores (
      error_id,
      procedimiento,
      mensaje_error,
      fecha_error,
      parametros,
      usuario_id
    )
    VALUES (
      NEWID(),
      @procedimiento,
      @mensajeError,
      SYSDATETIME(),
      @parametros,
      @usuarioId
    );
  END TRY
  BEGIN CATCH
    -- En caso de fallo al registrar, no hacemos nada para evitar ciclos
    PRINT 'Error al insertar en bitacora_errores: ' + ERROR_MESSAGE();
  END CATCH
END;

GO

-- ====================================================
-- Secci�n de pruebas para SP_LogError
-- ====================================================
/*
BEGIN TRY
  -- Simulaci�n de error
  DECLARE @mensajeError NVARCHAR(MAX) = 'Simulando error de membres�a';
  DECLARE @membershipId UNIQUEIDENTIFIER = NEWID();
  DECLARE @userId UNIQUEIDENTIFIER = NEWID();

  -- Simular fallo: llamamos a un SP que no existe (por ejemplo)
  EXEC fake_sp_that_does_not_exist;
END TRY
BEGIN CATCH
  DECLARE @errorMsg NVARCHAR(MAX) = ERROR_MESSAGE();

  -- Crear JSON de par�metros (concatenaci�n v�lida)
  DECLARE @parametros NVARCHAR(MAX) = 
    N'{ "membershipId": "' + CAST(@membershipId AS NVARCHAR(36)) + '" }';

  -- Registrar el error en la bit�cora
  EXEC dbo.SP_LogError
    @procedimiento = N'SP_ActualizarMembresia',
    @mensajeError  = @errorMsg,
    @parametros    = @parametros,
    @usuarioId     = @userId;

  -- Opcional: propagar el error
  THROW;
END CATCH;
*/