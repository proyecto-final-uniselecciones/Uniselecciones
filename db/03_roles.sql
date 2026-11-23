\set ON_ERROR_STOP on
SET search_path TO uniselecciones, public;

-- Roles de privilegios sin credenciales embebidas. El despliegue crea los
-- roles LOGIN con secretos externos y les concede el rol correspondiente.
DO $roles$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'uni_admin') THEN
        CREATE ROLE uni_admin NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'u_api') THEN
        CREATE ROLE u_api NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'u_analitica') THEN
        CREATE ROLE u_analitica NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
END
$roles$;

REVOKE ALL ON SCHEMA uniselecciones FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA uniselecciones FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA uniselecciones FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA uniselecciones FROM PUBLIC;
REVOKE EXECUTE ON ALL PROCEDURES IN SCHEMA uniselecciones FROM PUBLIC;

GRANT USAGE ON SCHEMA uniselecciones TO uni_admin, u_api, u_analitica;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA uniselecciones TO uni_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA uniselecciones TO uni_admin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA uniselecciones TO uni_admin;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA uniselecciones TO uni_admin;

-- La API no recibe DELETE ni permisos DDL. Datos médicos permanecen cifrados.
GRANT SELECT, INSERT, UPDATE ON
    universidad,
    sede,
    torneo,
    usuario,
    seleccion,
    jugador,
    entrenamiento,
    checkin,
    rutina,
    lesion,
    partido,
    estadistica
TO u_api;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA uniselecciones TO u_api;

GRANT EXECUTE ON FUNCTION fn_region_de_universidad(bigint) TO u_api;
GRANT EXECUTE ON FUNCTION fn_puntos_jugador(bigint) TO u_api;
GRANT EXECUTE ON FUNCTION fn_asistencia_pct(bigint, timestamp, timestamp) TO u_api;
GRANT EXECUTE ON FUNCTION fn_disponible(bigint) TO u_api;
GRANT EXECUTE ON FUNCTION fn_replica_sincrona_disponible() TO u_api;
GRANT EXECUTE ON FUNCTION fn_cifrar(text) TO u_api;
GRANT EXECUTE ON FUNCTION fn_descifrar(bytea) TO u_api;
GRANT EXECUTE ON FUNCTION fn_hmac_matricula(bigint, text) TO u_api;
GRANT EXECUTE ON FUNCTION fn_seudonimo_jugador(bigint) TO u_analitica;
GRANT EXECUTE ON PROCEDURE sp_registrar_checkin(bigint, bigint, estado_checkin) TO u_api;
GRANT EXECUTE ON PROCEDURE sp_programar_partido(bigint, bigint, bigint, bigint, timestamp) TO u_api;
GRANT EXECUTE ON PROCEDURE sp_cerrar_partido(bigint, smallint, smallint) TO u_api;
GRANT EXECUTE ON PROCEDURE sp_registrar_lesion(bigint, varchar, date, smallint, text) TO u_api;

-- Analítica no recibe nombres ni columnas cifradas de jugadores.
GRANT SELECT ON v_jugador_seudonimo, v_estadistica_analitica TO u_analitica;
GRANT SELECT ON torneo, partido TO u_analitica;
GRANT EXECUTE ON FUNCTION fn_puntos_jugador(bigint) TO u_analitica;

-- Los usuarios LOGIN se crean fuera de este archivo; después se asigna:
--   GRANT u_api TO api_login;
--   GRANT u_analitica TO analitica_login;
