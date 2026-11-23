\set ON_ERROR_STOP on
SET search_path TO uniselecciones, public;

CREATE OR REPLACE FUNCTION fn_region_de_universidad(p_id_univ bigint)
RETURNS region_universitaria
LANGUAGE plpgsql
STABLE
SET search_path = uniselecciones, pg_catalog
AS $$
DECLARE
    v_region region_universitaria;
BEGIN
    SELECT u.region
      INTO v_region
      FROM universidad AS u
     WHERE u.id_univ = p_id_univ;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la universidad %', p_id_univ
            USING ERRCODE = '23503';
    END IF;

    RETURN v_region;
END;
$$;

CREATE OR REPLACE FUNCTION fn_puntos_jugador(p_id_jugador bigint)
RETURNS numeric
LANGUAGE sql
STABLE
SET search_path = uniselecciones, pg_catalog
AS $$
    SELECT COALESCE(SUM(e.valor), 0)::numeric
      FROM estadistica AS e
     WHERE e.id_jugador = p_id_jugador
       AND e.metrica = 'puntos';
$$;

CREATE OR REPLACE FUNCTION fn_asistencia_pct(
    p_id_jugador bigint,
    p_desde timestamp without time zone,
    p_hasta timestamp without time zone
)
RETURNS numeric(5, 2)
LANGUAGE sql
STABLE
SET search_path = uniselecciones, pg_catalog
AS $$
    SELECT COALESCE(
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE c.estado IN ('presente', 'tarde'))
            / NULLIF(COUNT(*), 0),
            2
        ),
        0
    )::numeric(5, 2)
      FROM jugador AS j
      JOIN entrenamiento AS e
        ON e.id_seleccion = j.id_seleccion
      LEFT JOIN checkin AS c
        ON c.id_entrenamiento = e.id_entrenamiento
       AND c.id_jugador = j.id_jugador
     WHERE j.id_jugador = p_id_jugador
       AND e.fecha_hora >= p_desde
       AND e.fecha_hora < p_hasta;
$$;

CREATE OR REPLACE FUNCTION fn_disponible(p_id_jugador bigint)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = uniselecciones, pg_catalog
AS $$
    SELECT COALESCE(
        (SELECT j.disponible FROM jugador AS j WHERE j.id_jugador = p_id_jugador),
        false
    );
$$;

CREATE OR REPLACE FUNCTION fn_replica_sincrona_disponible()
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = pg_catalog
AS $$
    SELECT EXISTS (
        SELECT 1
          FROM pg_stat_replication
         WHERE state = 'streaming'
           AND sync_state IN ('sync', 'quorum')
    );
$$;

CREATE OR REPLACE FUNCTION fn_cifrar(p_texto text)
RETURNS bytea
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_key text := NULLIF(current_setting('app.cripto_key', true), '');
BEGIN
    IF p_texto IS NULL THEN
        RETURN NULL;
    END IF;
    IF v_key IS NULL THEN
        RAISE EXCEPTION 'No se configuró app.cripto_key para esta conexión'
            USING ERRCODE = '55000';
    END IF;
    RETURN public.pgp_sym_encrypt(p_texto, v_key);
END;
$$;

CREATE OR REPLACE FUNCTION fn_descifrar(p_cifrado bytea)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_key text := NULLIF(current_setting('app.cripto_key', true), '');
BEGIN
    IF p_cifrado IS NULL THEN
        RETURN NULL;
    END IF;
    IF v_key IS NULL THEN
        RAISE EXCEPTION 'No se configuró app.cripto_key para esta conexión'
            USING ERRCODE = '55000';
    END IF;
    RETURN public.pgp_sym_decrypt(p_cifrado, v_key);
END;
$$;

CREATE OR REPLACE FUNCTION fn_hmac_matricula(p_id_univ bigint, p_matricula text)
RETURNS bytea
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_key text := NULLIF(current_setting('app.matricula_key', true), '');
BEGIN
    IF p_id_univ IS NULL OR p_matricula IS NULL OR btrim(p_matricula) = '' THEN
        RAISE EXCEPTION 'La matrícula no puede estar vacía'
            USING ERRCODE = '22023';
    END IF;
    IF v_key IS NULL THEN
        RAISE EXCEPTION 'No se configuró app.matricula_key para esta conexión'
            USING ERRCODE = '55000';
    END IF;
    RETURN public.hmac(
        convert_to(p_id_univ::text || ':' || lower(btrim(p_matricula)), 'UTF8'),
        convert_to(v_key, 'UTF8'),
        'sha256'
    );
END;
$$;

CREATE OR REPLACE FUNCTION fn_seudonimo_jugador(p_id_jugador bigint)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_key text := NULLIF(current_setting('app.seudonimo_key', true), '');
BEGIN
    IF p_id_jugador IS NULL THEN
        RAISE EXCEPTION 'El jugador es obligatorio'
            USING ERRCODE = '22023';
    END IF;
    IF v_key IS NULL THEN
        RAISE EXCEPTION 'No se configuró app.seudonimo_key para esta conexión'
            USING ERRCODE = '55000';
    END IF;
    RETURN encode(
        public.hmac(convert_to(p_id_jugador::text, 'UTF8'), convert_to(v_key, 'UTF8'), 'sha256'),
        'hex'
    );
END;
$$;

CREATE OR REPLACE FUNCTION fn_validar_region_seleccion()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
DECLARE
    v_region region_universitaria;
    v_region_nodo text := UPPER(NULLIF(current_setting('app.region_nodo', true), ''));
BEGIN
    IF v_region_nodo IS NULL THEN
        RAISE EXCEPTION 'Debe configurar app.region_nodo antes de guardar selecciones'
            USING ERRCODE = '55000';
    END IF;

    v_region := fn_region_de_universidad(NEW.id_univ);
    IF v_region::text <> v_region_nodo THEN
        RAISE EXCEPTION 'Este nodo (%) no almacena datos de la región %',
            v_region_nodo, v_region
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS seleccion_region ON seleccion;
CREATE TRIGGER seleccion_region
    BEFORE INSERT OR UPDATE OF id_univ ON seleccion
    FOR EACH ROW
    EXECUTE FUNCTION fn_validar_region_seleccion();

CREATE OR REPLACE FUNCTION fn_validar_entrenador_seleccion()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
DECLARE
    v_rol rol_usuario;
BEGIN
    SELECT u.rol
      INTO v_rol
      FROM usuario AS u
     WHERE u.id_usuario = NEW.id_entrenador
       AND u.id_univ = NEW.id_univ;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El entrenador debe pertenecer a la misma universidad'
            USING ERRCODE = '23503';
    END IF;
    IF v_rol <> 'entrenador' THEN
        RAISE EXCEPTION 'El usuario asignado a la selección debe tener rol entrenador'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS seleccion_entrenador_rol ON seleccion;
CREATE TRIGGER seleccion_entrenador_rol
    BEFORE INSERT OR UPDATE OF id_entrenador, id_univ ON seleccion
    FOR EACH ROW
    EXECUTE FUNCTION fn_validar_entrenador_seleccion();

CREATE OR REPLACE FUNCTION fn_validar_jugador_localidad()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
DECLARE
    v_univ_seleccion bigint;
    v_univ_usuario bigint;
    v_rol_usuario rol_usuario;
BEGIN
    SELECT s.id_univ
      INTO v_univ_seleccion
      FROM seleccion AS s
     WHERE s.id_seleccion = NEW.id_seleccion;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la selección %', NEW.id_seleccion
            USING ERRCODE = '23503';
    END IF;

    IF NEW.id_usuario IS NOT NULL THEN
        SELECT u.id_univ, u.rol
          INTO v_univ_usuario, v_rol_usuario
          FROM usuario AS u
         WHERE u.id_usuario = NEW.id_usuario;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No existe la cuenta del jugador %', NEW.id_usuario
                USING ERRCODE = '23503';
        END IF;
        IF v_univ_usuario <> v_univ_seleccion OR v_rol_usuario <> 'jugador' THEN
            RAISE EXCEPTION 'La cuenta del jugador debe tener rol jugador y pertenecer a su universidad'
                USING ERRCODE = '23514';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS jugador_localidad ON jugador;
CREATE TRIGGER jugador_localidad
    BEFORE INSERT OR UPDATE OF id_seleccion, id_usuario ON jugador
    FOR EACH ROW
    EXECUTE FUNCTION fn_validar_jugador_localidad();

CREATE OR REPLACE FUNCTION fn_validar_entrenamiento_localidad()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
DECLARE
    v_univ_seleccion bigint;
    v_univ_sede bigint;
BEGIN
    SELECT s.id_univ
      INTO v_univ_seleccion
      FROM seleccion AS s
     WHERE s.id_seleccion = NEW.id_seleccion;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la selección %', NEW.id_seleccion
            USING ERRCODE = '23503';
    END IF;

    SELECT sd.id_univ
      INTO v_univ_sede
      FROM sede AS sd
     WHERE sd.id_sede = NEW.id_sede;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la sede %', NEW.id_sede
            USING ERRCODE = '23503';
    END IF;

    IF v_univ_seleccion <> v_univ_sede THEN
        RAISE EXCEPTION 'El entrenamiento y la sede deben pertenecer a la misma universidad'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS entrenamiento_localidad ON entrenamiento;
CREATE TRIGGER entrenamiento_localidad
    BEFORE INSERT OR UPDATE OF id_seleccion, id_sede ON entrenamiento
    FOR EACH ROW
    EXECUTE FUNCTION fn_validar_entrenamiento_localidad();

CREATE OR REPLACE FUNCTION fn_validar_partido_localidad()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
DECLARE
    v_univ_local bigint;
    v_univ_sede bigint;
BEGIN
    SELECT s.id_univ
      INTO v_univ_local
      FROM seleccion AS s
     WHERE s.id_seleccion = NEW.id_sel_local;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la selección local %', NEW.id_sel_local
            USING ERRCODE = '23503';
    END IF;

    SELECT sd.id_univ
      INTO v_univ_sede
      FROM sede AS sd
     WHERE sd.id_sede = NEW.id_sede;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la sede %', NEW.id_sede
            USING ERRCODE = '23503';
    END IF;

    IF v_univ_local <> v_univ_sede THEN
        RAISE EXCEPTION 'El partido y la sede deben pertenecer a la universidad local'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS partido_localidad ON partido;
CREATE TRIGGER partido_localidad
    BEFORE INSERT OR UPDATE OF id_sel_local, id_sede ON partido
    FOR EACH ROW
    EXECUTE FUNCTION fn_validar_partido_localidad();

CREATE OR REPLACE FUNCTION fn_validar_checkin()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
DECLARE
    v_seleccion_entrenamiento bigint;
    v_seleccion_jugador bigint;
BEGIN
    SELECT e.id_seleccion
      INTO v_seleccion_entrenamiento
      FROM entrenamiento AS e
     WHERE e.id_entrenamiento = NEW.id_entrenamiento;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el entrenamiento %', NEW.id_entrenamiento
            USING ERRCODE = '23503';
    END IF;

    SELECT j.id_seleccion
      INTO v_seleccion_jugador
      FROM jugador AS j
     WHERE j.id_jugador = NEW.id_jugador;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el jugador %', NEW.id_jugador
            USING ERRCODE = '23503';
    END IF;

    IF v_seleccion_entrenamiento <> v_seleccion_jugador THEN
        RAISE EXCEPTION 'El jugador no pertenece a la selección del entrenamiento'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS checkin_misma_seleccion ON checkin;
CREATE TRIGGER checkin_misma_seleccion
    BEFORE INSERT OR UPDATE ON checkin
    FOR EACH ROW
    EXECUTE FUNCTION fn_validar_checkin();

CREATE OR REPLACE FUNCTION fn_sincronizar_disponibilidad_jugador()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
BEGIN
    NEW.disponible := NEW.estado = 'activo'
        AND NOT EXISTS (
            SELECT 1
              FROM lesion AS l
             WHERE l.id_jugador = NEW.id_jugador
               AND l.estado = 'activa'
        );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS jugador_disponibilidad_insert ON jugador;
CREATE TRIGGER jugador_disponibilidad_insert
    BEFORE INSERT ON jugador
    FOR EACH ROW
    EXECUTE FUNCTION fn_sincronizar_disponibilidad_jugador();

DROP TRIGGER IF EXISTS jugador_disponibilidad_estado ON jugador;
CREATE TRIGGER jugador_disponibilidad_estado
    BEFORE UPDATE OF estado, disponible ON jugador
    FOR EACH ROW
    EXECUTE FUNCTION fn_sincronizar_disponibilidad_jugador();

CREATE OR REPLACE FUNCTION fn_actualizar_disponibilidad_por_lesion()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
DECLARE
    v_id_jugador bigint;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_id_jugador := OLD.id_jugador;
    ELSE
        v_id_jugador := NEW.id_jugador;
    END IF;

    UPDATE jugador AS j
       SET disponible = j.estado = 'activo'
           AND NOT EXISTS (
               SELECT 1
                 FROM lesion AS l
                WHERE l.id_jugador = v_id_jugador
                  AND l.estado = 'activa'
           )
     WHERE j.id_jugador = v_id_jugador;

    IF TG_OP = 'UPDATE' AND OLD.id_jugador IS DISTINCT FROM NEW.id_jugador
    THEN
        UPDATE jugador AS j
           SET disponible = j.estado = 'activo'
               AND NOT EXISTS (
                   SELECT 1
                     FROM lesion AS l
                    WHERE l.id_jugador = OLD.id_jugador
                      AND l.estado = 'activa'
               )
         WHERE j.id_jugador = OLD.id_jugador;
    END IF;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS lesion_disponibilidad ON lesion;
CREATE TRIGGER lesion_disponibilidad
    AFTER INSERT OR UPDATE OR DELETE ON lesion
    FOR EACH ROW
    EXECUTE FUNCTION fn_actualizar_disponibilidad_por_lesion();

CREATE OR REPLACE PROCEDURE sp_registrar_checkin(
    p_id_entrenamiento bigint,
    p_id_jugador bigint,
    p_estado estado_checkin
)
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
DECLARE
    v_seleccion_entrenamiento bigint;
    v_seleccion_jugador bigint;
BEGIN
    SELECT e.id_seleccion
      INTO v_seleccion_entrenamiento
      FROM entrenamiento AS e
     WHERE e.id_entrenamiento = p_id_entrenamiento;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el entrenamiento %', p_id_entrenamiento
            USING ERRCODE = '23503';
    END IF;

    SELECT j.id_seleccion
      INTO v_seleccion_jugador
      FROM jugador AS j
     WHERE j.id_jugador = p_id_jugador;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el jugador %', p_id_jugador
            USING ERRCODE = '23503';
    END IF;

    IF v_seleccion_entrenamiento <> v_seleccion_jugador THEN
        RAISE EXCEPTION 'El jugador no pertenece a la selección del entrenamiento'
            USING ERRCODE = '23514';
    END IF;

    INSERT INTO checkin (id_entrenamiento, id_jugador, estado)
    VALUES (p_id_entrenamiento, p_id_jugador, p_estado)
    ON CONFLICT (id_entrenamiento, id_jugador)
    DO UPDATE SET hora_registro = now(), estado = EXCLUDED.estado;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_programar_partido(
    p_id_torneo bigint,
    p_id_sel_local bigint,
    p_id_sel_visita bigint,
    p_id_sede bigint,
    p_fecha_hora timestamp without time zone
)
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
DECLARE
    v_univ_local bigint;
    v_univ_sede bigint;
BEGIN
    IF p_id_sel_local = p_id_sel_visita THEN
        RAISE EXCEPTION 'Una selección no puede jugar contra sí misma'
            USING ERRCODE = '23514';
    END IF;

    PERFORM 1 FROM torneo WHERE id_torneo = p_id_torneo;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el torneo %', p_id_torneo
            USING ERRCODE = '23503';
    END IF;

    SELECT s.id_univ INTO v_univ_local
      FROM seleccion AS s
     WHERE s.id_seleccion = p_id_sel_local;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la selección local %', p_id_sel_local
            USING ERRCODE = '23503';
    END IF;

    SELECT sd.id_univ INTO v_univ_sede
      FROM sede AS sd
     WHERE sd.id_sede = p_id_sede;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe la sede %', p_id_sede
            USING ERRCODE = '23503';
    END IF;
    IF v_univ_sede <> v_univ_local THEN
        RAISE EXCEPTION 'La sede debe pertenecer a la universidad local'
            USING ERRCODE = '23514';
    END IF;

    -- Serializa altas para la sede y evita dos reservas simultáneas.
    PERFORM pg_advisory_xact_lock(p_id_sede);
    IF EXISTS (
        SELECT 1
          FROM partido AS p
         WHERE p.id_sede = p_id_sede
           AND p.estado = 'programado'
           AND p.fecha_hora BETWEEN p_fecha_hora - INTERVAL '2 hours'
                                 AND p_fecha_hora + INTERVAL '2 hours'
    ) THEN
        RAISE EXCEPTION 'La sede % ya está ocupada en esa ventana de horario', p_id_sede
            USING ERRCODE = '23P01';
    END IF;

    INSERT INTO partido (
        id_torneo, id_sel_local, id_sel_visita, id_sede, fecha_hora
    ) VALUES (
        p_id_torneo, p_id_sel_local, p_id_sel_visita, p_id_sede, p_fecha_hora
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_cerrar_partido(
    p_id_partido bigint,
    p_marcador_local smallint,
    p_marcador_visita smallint
)
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
BEGIN
    IF p_marcador_local < 0 OR p_marcador_visita < 0 THEN
        RAISE EXCEPTION 'Los marcadores no pueden ser negativos'
            USING ERRCODE = '23514';
    END IF;

    UPDATE partido
       SET marcador_local = p_marcador_local,
           marcador_visita = p_marcador_visita,
           estado = 'finalizado'
     WHERE id_partido = p_id_partido
       AND estado = 'programado';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El partido % no existe o ya fue cerrado', p_id_partido
            USING ERRCODE = 'P0002';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_registrar_lesion(
    p_id_jugador bigint,
    p_tipo varchar,
    p_fecha date,
    p_dias_baja smallint,
    p_observacion text DEFAULT NULL
)
LANGUAGE plpgsql
SET search_path = uniselecciones, pg_catalog
AS $$
DECLARE
    v_exigir_cp boolean := COALESCE(
        NULLIF(current_setting('app.enforce_cp', true), '')::boolean,
        false
    );
BEGIN
    PERFORM 1
      FROM jugador AS j
     WHERE j.id_jugador = p_id_jugador;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el jugador %', p_id_jugador
            USING ERRCODE = '23503';
    END IF;
    IF p_dias_baja <= 0 OR btrim(p_tipo) = '' THEN
        RAISE EXCEPTION 'El tipo de lesión y los días de baja deben ser válidos'
            USING ERRCODE = '23514';
    END IF;

    IF v_exigir_cp THEN
        IF NOT fn_replica_sincrona_disponible() THEN
            RAISE EXCEPTION 'Operación rechazada (CP): no hay réplica síncrona disponible'
                USING ERRCODE = '57P03';
        END IF;
        PERFORM set_config('synchronous_commit', 'remote_apply', true);
    END IF;

    INSERT INTO lesion (
        id_jugador, tipo, fecha, dias_baja, estado, observacion_cif
    ) VALUES (
        p_id_jugador, p_tipo, p_fecha, p_dias_baja, 'activa',
        CASE WHEN p_observacion IS NULL THEN NULL ELSE fn_cifrar(p_observacion) END
    );
END;
$$;

CREATE OR REPLACE VIEW v_plantilla AS
SELECT s.id_univ,
       j.id_seleccion,
       j.id_jugador,
       j.nombre,
       j.posicion,
       j.numero,
       j.disponible
  FROM jugador AS j
  JOIN seleccion AS s ON s.id_seleccion = j.id_seleccion
 WHERE j.estado = 'activo';

CREATE OR REPLACE VIEW v_jugador_seudonimo AS
SELECT s.id_univ,
       j.id_seleccion,
       fn_seudonimo_jugador(j.id_jugador) AS seudonimo,
       j.posicion,
       j.numero,
       j.disponible
  FROM jugador AS j
  JOIN seleccion AS s ON s.id_seleccion = j.id_seleccion;

CREATE OR REPLACE VIEW v_estadistica_analitica AS
SELECT s.id_univ,
       e.id_partido,
       fn_seudonimo_jugador(e.id_jugador) AS jugador_seudonimo,
       e.metrica,
       e.valor
  FROM estadistica AS e
  JOIN partido AS p ON p.id_partido = e.id_partido
  JOIN seleccion AS s ON s.id_seleccion = p.id_sel_local;
