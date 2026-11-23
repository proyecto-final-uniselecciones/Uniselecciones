\set ON_ERROR_STOP on

\if :{?id_inicio}
\else
\set id_inicio 1000000
\endif

-- Aplica el mismo esquema en los tres nodos y permite asignar rangos de ID
-- distintos con -v id_inicio=1000000, 2000000 o 3000000.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS uniselecciones;
SET search_path TO uniselecciones, public;

DO $types$
BEGIN
    BEGIN
        CREATE TYPE region_universitaria AS ENUM ('AGS', 'JAL', 'ZAC');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        CREATE TYPE rol_usuario AS ENUM ('institucion', 'entrenador', 'jugador');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        CREATE TYPE rama_seleccion AS ENUM ('M', 'F');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        CREATE TYPE posicion_basket AS ENUM
            ('base', 'escolta', 'alero', 'ala_pivot', 'pivot');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        CREATE TYPE estado_plantilla AS ENUM ('activo', 'inactivo');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        CREATE TYPE estado_checkin AS ENUM ('presente', 'tarde', 'ausente');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        CREATE TYPE estado_lesion AS ENUM ('activa', 'recuperada', 'cerrada');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        CREATE TYPE estado_torneo AS ENUM ('planificado', 'activo', 'finalizado', 'cancelado');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        CREATE TYPE estado_partido AS ENUM ('programado', 'finalizado', 'cancelado');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        CREATE TYPE metrica_estadistica AS ENUM
            ('minutos', 'puntos', 'rebotes', 'asistencias', 'robos', 'bloqueos', 'faltas');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END
$types$;

-- Los catálogos se replican con identificadores estables cargados en los tres nodos.
CREATE SEQUENCE IF NOT EXISTS seq_usuario AS bigint START WITH :id_inicio;
CREATE SEQUENCE IF NOT EXISTS seq_seleccion AS bigint START WITH :id_inicio;
CREATE SEQUENCE IF NOT EXISTS seq_jugador AS bigint START WITH :id_inicio;
CREATE SEQUENCE IF NOT EXISTS seq_entrenamiento AS bigint START WITH :id_inicio;
CREATE SEQUENCE IF NOT EXISTS seq_rutina AS bigint START WITH :id_inicio;
CREATE SEQUENCE IF NOT EXISTS seq_lesion AS bigint START WITH :id_inicio;
CREATE SEQUENCE IF NOT EXISTS seq_partido AS bigint START WITH :id_inicio;

CREATE TABLE IF NOT EXISTS universidad (
    id_univ bigint PRIMARY KEY,
    nombre varchar(160) NOT NULL,
    ciudad varchar(120) NOT NULL,
    region region_universitaria NOT NULL,
    CONSTRAINT uq_universidad_nombre_ciudad UNIQUE (nombre, ciudad)
);

CREATE TABLE IF NOT EXISTS sede (
    id_sede bigint PRIMARY KEY,
    id_univ bigint NOT NULL REFERENCES universidad (id_univ),
    nombre varchar(160) NOT NULL,
    tipo varchar(60) NOT NULL CHECK (btrim(tipo) <> ''),
    CONSTRAINT uq_sede_nombre_universidad UNIQUE (id_univ, nombre)
);

CREATE TABLE IF NOT EXISTS torneo (
    id_torneo bigint PRIMARY KEY,
    nombre varchar(160) NOT NULL CHECK (btrim(nombre) <> ''),
    temporada varchar(40) NOT NULL CHECK (btrim(temporada) <> ''),
    fecha_inicio date,
    fecha_fin date,
    estado estado_torneo NOT NULL DEFAULT 'planificado',
    CONSTRAINT uq_torneo_nombre_temporada UNIQUE (nombre, temporada),
    CONSTRAINT ck_torneo_rango_fechas
        CHECK (fecha_inicio IS NULL OR fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

CREATE TABLE IF NOT EXISTS usuario (
    id_usuario bigint PRIMARY KEY DEFAULT nextval('seq_usuario'),
    id_univ bigint NOT NULL REFERENCES universidad (id_univ),
    nombre_completo varchar(160) NOT NULL CHECK (btrim(nombre_completo) <> ''),
    correo varchar(254) NOT NULL CHECK (correo ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'),
    hash_clave text NOT NULL CHECK (hash_clave LIKE '$argon2id$%'),
    rol rol_usuario NOT NULL,
    activo boolean NOT NULL DEFAULT true,
    creado_en timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_usuario_id_universidad UNIQUE (id_usuario, id_univ)
);

CREATE TABLE IF NOT EXISTS seleccion (
    id_seleccion bigint PRIMARY KEY DEFAULT nextval('seq_seleccion'),
    id_univ bigint NOT NULL REFERENCES universidad (id_univ),
    id_entrenador bigint NOT NULL,
    rama rama_seleccion NOT NULL,
    nombre varchar(120) NOT NULL DEFAULT 'Selección de baloncesto',
    activa boolean NOT NULL DEFAULT true,
    CONSTRAINT fk_seleccion_entrenador_universidad
        FOREIGN KEY (id_entrenador, id_univ)
        REFERENCES usuario (id_usuario, id_univ),
    CONSTRAINT uq_seleccion_universidad_rama UNIQUE (id_univ, rama)
);

CREATE TABLE IF NOT EXISTS jugador (
    id_jugador bigint PRIMARY KEY DEFAULT nextval('seq_jugador'),
    id_seleccion bigint NOT NULL,
    id_usuario bigint UNIQUE,
    nombre varchar(160) NOT NULL CHECK (btrim(nombre) <> ''),
    posicion posicion_basket NOT NULL,
    numero smallint NOT NULL CHECK (numero BETWEEN 0 AND 99),
    estado estado_plantilla NOT NULL DEFAULT 'activo',
    disponible boolean NOT NULL DEFAULT true,
    -- HMAC para detectar duplicados sin guardar la matrícula legible.
    matricula_hmac bytea NOT NULL UNIQUE,
    -- Los datos privados se cifran desde la API con fn_cifrar.
    matricula_cif bytea NOT NULL,
    fecha_nac_cif bytea,
    telefono_cif bytea,
    contacto_emergencia_cif bytea,
    tipo_sangre_cif bytea,
    alergias_cif bytea,
    CONSTRAINT fk_jugador_seleccion
        FOREIGN KEY (id_seleccion) REFERENCES seleccion (id_seleccion),
    CONSTRAINT fk_jugador_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    CONSTRAINT uq_jugador_numero_seleccion UNIQUE (id_seleccion, numero)
);

CREATE TABLE IF NOT EXISTS entrenamiento (
    id_entrenamiento bigint PRIMARY KEY DEFAULT nextval('seq_entrenamiento'),
    id_seleccion bigint NOT NULL,
    id_sede bigint NOT NULL,
    fecha_hora timestamp without time zone NOT NULL,
    tipo varchar(100) NOT NULL CHECK (btrim(tipo) <> ''),
    duracion_min smallint NOT NULL CHECK (duracion_min BETWEEN 1 AND 600),
    CONSTRAINT fk_entrenamiento_seleccion
        FOREIGN KEY (id_seleccion) REFERENCES seleccion (id_seleccion),
    CONSTRAINT fk_entrenamiento_sede
        FOREIGN KEY (id_sede) REFERENCES sede (id_sede)
);

CREATE TABLE IF NOT EXISTS checkin (
    id_entrenamiento bigint NOT NULL,
    id_jugador bigint NOT NULL,
    hora_registro timestamptz NOT NULL DEFAULT now(),
    estado estado_checkin NOT NULL,
    CONSTRAINT pk_checkin PRIMARY KEY (id_entrenamiento, id_jugador),
    CONSTRAINT fk_checkin_entrenamiento
        FOREIGN KEY (id_entrenamiento) REFERENCES entrenamiento (id_entrenamiento),
    CONSTRAINT fk_checkin_jugador
        FOREIGN KEY (id_jugador) REFERENCES jugador (id_jugador)
);

CREATE TABLE IF NOT EXISTS rutina (
    id_rutina bigint PRIMARY KEY DEFAULT nextval('seq_rutina'),
    id_jugador bigint NOT NULL,
    descripcion text NOT NULL CHECK (btrim(descripcion) <> ''),
    carga smallint NOT NULL CHECK (carga BETWEEN 1 AND 10),
    fecha_inicio date NOT NULL,
    fecha_fin date,
    CONSTRAINT fk_rutina_jugador
        FOREIGN KEY (id_jugador) REFERENCES jugador (id_jugador),
    CONSTRAINT ck_rutina_rango_fechas
        CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

CREATE TABLE IF NOT EXISTS lesion (
    id_lesion bigint PRIMARY KEY DEFAULT nextval('seq_lesion'),
    id_jugador bigint NOT NULL,
    tipo varchar(100) NOT NULL CHECK (btrim(tipo) <> ''),
    fecha date NOT NULL,
    dias_baja smallint NOT NULL CHECK (dias_baja > 0),
    estado estado_lesion NOT NULL DEFAULT 'activa',
    observacion_cif bytea,
    CONSTRAINT fk_lesion_jugador
        FOREIGN KEY (id_jugador) REFERENCES jugador (id_jugador)
);

CREATE TABLE IF NOT EXISTS partido (
    id_partido bigint PRIMARY KEY DEFAULT nextval('seq_partido'),
    id_torneo bigint NOT NULL REFERENCES torneo (id_torneo),
    id_sel_local bigint NOT NULL,
    -- La selección visitante puede vivir en otro nodo; su existencia la valida la API.
    id_sel_visita bigint NOT NULL,
    id_sede bigint NOT NULL,
    fecha_hora timestamp without time zone NOT NULL,
    marcador_local smallint,
    marcador_visita smallint,
    estado estado_partido NOT NULL DEFAULT 'programado',
    CONSTRAINT ck_partido_selecciones_distintas CHECK (id_sel_local <> id_sel_visita),
    CONSTRAINT ck_partido_marcadores_no_negativos
        CHECK ((marcador_local IS NULL OR marcador_local >= 0)
           AND (marcador_visita IS NULL OR marcador_visita >= 0)),
    CONSTRAINT ck_partido_estado_marcador
        CHECK ((estado = 'finalizado') =
               (marcador_local IS NOT NULL AND marcador_visita IS NOT NULL)),
    CONSTRAINT fk_partido_seleccion_local
        FOREIGN KEY (id_sel_local) REFERENCES seleccion (id_seleccion),
    CONSTRAINT fk_partido_sede
        FOREIGN KEY (id_sede) REFERENCES sede (id_sede)
);

CREATE TABLE IF NOT EXISTS estadistica (
    id_partido bigint NOT NULL,
    -- Un jugador visitante puede pertenecer a otro nodo, por eso no hay FK aquí.
    id_jugador bigint NOT NULL,
    metrica metrica_estadistica NOT NULL,
    valor numeric(8, 2) NOT NULL CHECK (valor >= 0),
    CONSTRAINT pk_estadistica PRIMARY KEY (id_partido, id_jugador, metrica),
    CONSTRAINT fk_estadistica_partido
        FOREIGN KEY (id_partido) REFERENCES partido (id_partido)
);

ALTER SEQUENCE seq_usuario OWNED BY usuario.id_usuario;
ALTER SEQUENCE seq_seleccion OWNED BY seleccion.id_seleccion;
ALTER SEQUENCE seq_jugador OWNED BY jugador.id_jugador;
ALTER SEQUENCE seq_entrenamiento OWNED BY entrenamiento.id_entrenamiento;
ALTER SEQUENCE seq_rutina OWNED BY rutina.id_rutina;
ALTER SEQUENCE seq_lesion OWNED BY lesion.id_lesion;
ALTER SEQUENCE seq_partido OWNED BY partido.id_partido;

-- Índices de acceso frecuente; las restricciones PK/UNIQUE crean los suyos propios.
CREATE UNIQUE INDEX IF NOT EXISTS uq_usuario_correo_ci
    ON usuario (lower(correo));
CREATE INDEX IF NOT EXISTS ix_jugador_seleccion_activo
    ON jugador (id_seleccion, numero)
    WHERE estado = 'activo';
CREATE INDEX IF NOT EXISTS ix_entrenamiento_seleccion_fecha
    ON entrenamiento (id_seleccion, fecha_hora);
CREATE INDEX IF NOT EXISTS ix_entrenamiento_sede_fecha
    ON entrenamiento (id_sede, fecha_hora);
CREATE INDEX IF NOT EXISTS ix_checkin_jugador
    ON checkin (id_jugador, id_entrenamiento);
CREATE INDEX IF NOT EXISTS ix_rutina_jugador_fechas
    ON rutina (id_jugador, fecha_inicio, fecha_fin);
CREATE INDEX IF NOT EXISTS ix_lesion_jugador_activa
    ON lesion (id_jugador, fecha DESC)
    WHERE estado = 'activa';
CREATE INDEX IF NOT EXISTS ix_partido_local_fecha
    ON partido (id_sel_local, fecha_hora);
CREATE INDEX IF NOT EXISTS ix_partido_visita_fecha
    ON partido (id_sel_visita, fecha_hora);
CREATE INDEX IF NOT EXISTS ix_estadistica_jugador_metrica
    ON estadistica (id_jugador, metrica, id_partido);

-- Impide duplicar el mismo enfrentamiento en la misma fecha, aunque cambie localía.
CREATE UNIQUE INDEX IF NOT EXISTS uq_partido_pareja_fecha
    ON partido (
        LEAST(id_sel_local, id_sel_visita),
        GREATEST(id_sel_local, id_sel_visita),
        (fecha_hora::date)
    );

COMMENT ON TABLE jugador IS
    'Datos deportivos y ciphertexts privados; el plaintext nunca se guarda.';
COMMENT ON COLUMN partido.id_sel_visita IS
    'Sin FK local porque la selección visitante puede residir en otro nodo.';
COMMENT ON COLUMN estadistica.id_jugador IS
    'Sin FK local porque el jugador puede residir en otro nodo.';
