\set ON_ERROR_STOP on
SET search_path TO uniselecciones, public;

-- Catálogo inicial basado en las instituciones afiliadas a ANUIES por entidad:
-- Aguascalientes (7), Jalisco (7) y Zacatecas (2). IDs iguales en cada nodo.
INSERT INTO universidad (id_univ, nombre, ciudad, region)
VALUES
    (1001, 'Universidad Autónoma de Aguascalientes', 'Aguascalientes', 'AGS'),
    (1002, 'Instituto Tecnológico de Aguascalientes', 'Aguascalientes', 'AGS'),
    (1003, 'Universidad Politécnica de Aguascalientes', 'Aguascalientes', 'AGS'),
    (1004, 'Universidad Tecnológica de Aguascalientes', 'Aguascalientes', 'AGS'),
    (1005, 'Universidad Tecnológica de Calvillo', 'Calvillo', 'AGS'),
    (1006, 'Universidad Tecnológica del Norte de Aguascalientes', 'Rincón de Romos', 'AGS'),
    (1007, 'Universidad Tecnológica El Retoño', 'El Llano', 'AGS'),
    (2001, 'Centro de Enseñanza Técnica Industrial', 'Guadalajara', 'JAL'),
    (2002, 'Instituto Tecnológico de Ciudad Guzmán', 'Ciudad Guzmán', 'JAL'),
    (2003, 'Instituto Tecnológico y de Estudios Superiores de Occidente, A.C.', 'Tlaquepaque', 'JAL'),
    (2004, 'Universidad Autónoma de Guadalajara', 'Zapopan', 'JAL'),
    (2005, 'Universidad de Guadalajara', 'Guadalajara', 'JAL'),
    (2006, 'Universidad del Valle de Atemajac', 'Zapopan', 'JAL'),
    (2007, 'Universidad Tecnológica de Jalisco', 'Zapopan', 'JAL'),
    (3001, 'Instituto Tecnológico de Zacatecas', 'Zacatecas', 'ZAC'),
    (3002, 'Universidad Autónoma de Zacatecas Francisco García Salinas', 'Zacatecas', 'ZAC')
ON CONFLICT (id_univ) DO UPDATE
   SET nombre = EXCLUDED.nombre,
       ciudad = EXCLUDED.ciudad,
       region = EXCLUDED.region;
