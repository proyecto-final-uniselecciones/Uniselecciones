\set ON_ERROR_STOP on
SET search_path TO uniselecciones, public;

-- Datos sintéticos únicamente para desarrollo local. No usar en producción.
INSERT INTO universidad (id_univ, nombre, ciudad, region)
VALUES (1001, 'Universidad Autónoma de Aguascalientes', 'Aguascalientes', 'AGS')
ON CONFLICT (id_univ) DO NOTHING;

DO $demo$
DECLARE
    -- Argon2id de la contraseña temporal UniDemo#2026.
    v_hash text := '$argon2id$v=19$m=65536,t=4,p=1$cUFhWnlrcDNGTDFqcWdPZA$tTJM1uaxVvlmwcUdKvNNjcYEopwcxKWgATSZFbVBWv8';
BEGIN
    INSERT INTO usuario (id_univ, nombre_completo, correo, hash_clave, rol)
    VALUES
        (1001, 'Brayan (demo)', 'al999901@edu.uaa.mx', v_hash, 'institucion'),
        (1001, 'Gustavo (demo)', 'al999902@edu.uaa.mx', v_hash, 'entrenador'),
        (1001, 'Obed (demo)', 'al999903@edu.uaa.mx', v_hash, 'jugador')
    ON CONFLICT (lower(correo)) DO UPDATE
       SET id_univ = EXCLUDED.id_univ,
           nombre_completo = EXCLUDED.nombre_completo,
           hash_clave = EXCLUDED.hash_clave,
           rol = EXCLUDED.rol,
           activo = true;
END
$demo$;

SELECT id_usuario, nombre_completo, correo, rol
  FROM usuario
 WHERE lower(correo) IN (
     'al999901@edu.uaa.mx',
     'al999902@edu.uaa.mx',
     'al999903@edu.uaa.mx'
 )
 ORDER BY correo;
