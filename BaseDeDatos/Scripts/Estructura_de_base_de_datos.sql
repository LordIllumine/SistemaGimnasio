USE gimnasioV1;
GO

-- ================================================
-- Tabla: users
-- ================================================
CREATE TABLE dbo.users (
    user_id          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    nombre           NVARCHAR(100)     NOT NULL,
    email            NVARCHAR(255)     NOT NULL UNIQUE,
    rol              NVARCHAR(20)      NOT NULL CHECK (rol IN ('admin','trainer','receptionist','client')),
    token            NVARCHAR(512)     NULL,
    foto_url         NVARCHAR(512)     NULL
);
GO
ALTER TABLE dbo.users
ADD password_hash NVARCHAR(512) NOT NULL;
GO
-- ================================================
-- Tabla: user_profiles
-- ================================================
CREATE TABLE dbo.user_profiles (
    profile_id       UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER NOT NULL UNIQUE
                       REFERENCES dbo.users(user_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    edad             INT               NULL,
    peso             DECIMAL(5,2)      NULL,
    altura           DECIMAL(5,2)      NULL,
    imc              DECIMAL(5,2)      NULL,
    historial_medico NVARCHAR(MAX)     NULL,
    fotos_progreso   NVARCHAR(MAX)     NULL  -- almacena JSON array de URLs
);
GO

-- ================================================
-- Tabla: memberships
-- ================================================
CREATE TABLE dbo.memberships (
    membership_id    UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER NOT NULL
                       REFERENCES dbo.users(user_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    tipo             NVARCHAR(50)      NOT NULL,
    fecha_inicio     DATE              NOT NULL,
    fecha_vencimiento DATE             NOT NULL,
    estado           NVARCHAR(20)      NOT NULL
                       CHECK (estado IN ('active','expired','pending'))
);
GO

-- ================================================
-- Tabla: attendance
-- ================================================
CREATE TABLE dbo.attendance (
    attendance_id    UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER NOT NULL
                       REFERENCES dbo.users(user_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    fecha            DATE              NOT NULL,
    hora_ingreso     TIME(0)           NOT NULL,
    hora_salida      TIME(0)           NULL
);
GO

-- ================================================
-- Tabla: capacity_configs
-- ================================================
CREATE TABLE dbo.capacity_configs (
    config_id        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    activo           BIT               NOT NULL DEFAULT 1,
    cupo_max         INT               NOT NULL,
    dia_semana       NVARCHAR(10)      NOT NULL
                       CHECK (dia_semana IN ('lunes','martes','miércoles','jueves','viernes','sábado','domingo')),
    hora             TIME(0)           NOT NULL
);
GO

-- ================================================
-- Tabla: training_plans
-- ================================================
CREATE TABLE dbo.training_plans (
    plan_id          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER NOT NULL
                       REFERENCES dbo.users(user_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    titulo           NVARCHAR(100)     NOT NULL,
    ejercicios       NVARCHAR(MAX)     NULL,  -- JSON array
    pdf_url          NVARCHAR(512)     NULL
);
GO

-- ================================================
-- Tabla: diet_plans
-- ================================================
CREATE TABLE dbo.diet_plans (
    diet_id          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER NOT NULL
                       REFERENCES dbo.users(user_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    objetivo         NVARCHAR(100)     NOT NULL,
    calorias         INT               NOT NULL,
    macros           NVARCHAR(MAX)     NULL  -- JSON object
);
GO

-- ================================================
-- Tabla: meal_records
-- ================================================
CREATE TABLE dbo.meal_records (
    record_id        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER NOT NULL
                       REFERENCES dbo.users(user_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    fecha            DATE              NOT NULL,
    comidas          NVARCHAR(MAX)     NULL  -- JSON array
);
GO

-- ================================================
-- Tabla: classes
-- ================================================
CREATE TABLE dbo.classes (
    class_id         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    nombre           NVARCHAR(100)     NOT NULL,
    tipo             NVARCHAR(50)      NOT NULL,
    horario          DATETIME2(0)      NOT NULL,
    cupo_max         INT               NOT NULL
);
GO

-- ================================================
-- Tabla: reservations
-- ================================================
CREATE TABLE dbo.reservations (
    reservation_id   UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER NOT NULL
                       REFERENCES dbo.users(user_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    class_id         UNIQUEIDENTIFIER NOT NULL
                       REFERENCES dbo.classes(class_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    fecha            DATE              NOT NULL,
    estado           NVARCHAR(20)      NOT NULL
                       CHECK (estado IN ('confirmed','cancelled','pending'))
);
GO

-- ================================================
-- Tabla: trainer_profiles
-- ================================================
CREATE TABLE dbo.trainer_profiles (
    trainer_id       UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER NOT NULL UNIQUE
                       REFERENCES dbo.users(user_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    evaluaciones     NVARCHAR(MAX)     NULL  -- JSON array
);
GO

-- --------------------------------------------------
-- Tabla: trainer_clients (asignación N:M entrenadores–clientes)
-- --------------------------------------------------
CREATE TABLE dbo.trainer_clients (
    id            UNIQUEIDENTIFIER NOT NULL 
                     CONSTRAINT PK_trainer_clients PRIMARY KEY 
                     DEFAULT NEWID(),
    trainer_id    UNIQUEIDENTIFIER NOT NULL,
    client_id     UNIQUEIDENTIFIER NOT NULL,

    CONSTRAINT FK_trainer_clients_trainer
      FOREIGN KEY (trainer_id)
      REFERENCES dbo.trainer_profiles(trainer_id)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION,

    CONSTRAINT FK_trainer_clients_client
      FOREIGN KEY (client_id)
      REFERENCES dbo.users(user_id)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION
);
GO


-- ================================================
-- Tabla: physical_evaluations
-- ================================================
CREATE TABLE dbo.physical_evaluations (
    eval_id          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER NOT NULL
                       REFERENCES dbo.users(user_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    fecha            DATE              NOT NULL,
    medidas          NVARCHAR(MAX)     NULL, -- JSON object
    notas            NVARCHAR(MAX)     NULL
);
GO

-- ================================================
-- Tabla: products
-- ================================================
CREATE TABLE dbo.products (
    product_id       UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    nombre           NVARCHAR(100)     NOT NULL,
    tipo             NVARCHAR(50)      NOT NULL,
    stock            INT               NOT NULL,
    precio           DECIMAL(10,2)     NOT NULL
);
GO

-- ================================================
-- Tabla: inventory
-- ================================================
CREATE TABLE dbo.inventory (
    inventory_id     UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    product_id       UNIQUEIDENTIFIER NOT NULL UNIQUE
                       REFERENCES dbo.products(product_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    cantidad         INT               NOT NULL
);
GO

-- ================================================
-- Tabla: notifications
-- ================================================
CREATE TABLE dbo.notifications (
    notification_id  UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER NOT NULL
                       REFERENCES dbo.users(user_id)
                         ON UPDATE CASCADE
                         ON DELETE NO ACTION,
    tipo             NVARCHAR(50)      NOT NULL,
    contenido        NVARCHAR(MAX)     NOT NULL,
    fecha            DATETIME2(0)      NOT NULL DEFAULT SYSDATETIME(),
    leido            BIT               NOT NULL DEFAULT 0
);
GO

-- ================================================
-- Tabla: kpis
-- ================================================
CREATE TABLE dbo.kpis (
    kpi_id                       UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    ingresos                     DECIMAL(14,2)     NOT NULL,
    asistencia_diaria            INT               NOT NULL,
    membresias_activas           INT               NOT NULL,
    estadisticas_demograficas    NVARCHAR(MAX)     NULL  -- JSON object
);
GO

USE gimnasioV1;
GO

-- ================================================
-- Tabla: bitacora_errores
-- ================================================
CREATE TABLE dbo.bitacora_errores (
    error_id        UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    procedimiento   NVARCHAR(255)     NOT NULL,
    mensaje_error   NVARCHAR(MAX)     NOT NULL,
    fecha_error     DATETIME2(0)      NOT NULL DEFAULT SYSDATETIME(),
    parametros      NVARCHAR(MAX)     NULL,       -- JSON con parámetros del SP (opcional)
    usuario_id      UNIQUEIDENTIFIER  NULL         -- FK opcional a dbo.users(user_id)
);
GO
