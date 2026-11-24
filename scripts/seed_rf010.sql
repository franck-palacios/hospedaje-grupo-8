-- Datos de demostracion para RF-010 (búsqueda de alojamientos).
-- Ejecución repetible: usa emails reservados para pruebas y títulos con prefijo.
-- Las contraseñas de estas cuentas son marcadores inutilizables; no iniciar sesión.
BEGIN;
SET LOCAL search_path = hospedaje, public;

INSERT INTO hospedaje.usuario (email, password_hash, nombre, rol, email_verificado_at)
VALUES
    ('rf010-admin@example.invalid', 'seed-only-not-a-password', 'Admin de pruebas RF010',
     'administrador'::hospedaje.rol_usuario, now()),
    ('rf010-publicador-a@example.invalid', 'seed-only-not-a-password', 'Publicador de pruebas A',
     'publicador'::hospedaje.rol_usuario, now()),
    ('rf010-publicador-b@example.invalid', 'seed-only-not-a-password', 'Publicador de pruebas B',
     'publicador'::hospedaje.rol_usuario, now()),
    ('rf010-arrendante@example.invalid', 'seed-only-not-a-password', 'Arrendante de pruebas',
     'arrendante'::hospedaje.rol_usuario, now())
ON CONFLICT (email) DO NOTHING;

SELECT set_config('app.usuario_id', u.id::text, true)
FROM hospedaje.usuario AS u
WHERE u.email = 'rf010-admin@example.invalid';

WITH datos (
    titulo, publicador_email, descripcion, direccion, ciudad, region, pais,
    precio_noche, moneda, max_huespedes, estado_aprobacion, estado_publicacion
) AS (
    VALUES
        ('[RF010 DEMO] Oaxaca - disponible', 'rf010-publicador-a@example.invalid',
         'Alojamiento de prueba disponible para las fechas del calendario.',
         'Calle Demo 100', 'Oaxaca', 'Oaxaca', 'MX', 1200.00, 'MXN', 4, 'aprobada', 'activa'),
        ('[RF010 DEMO] Oaxaca - fechas bloqueadas', 'rf010-publicador-a@example.invalid',
         'Alojamiento de prueba con bloqueo manual del 10 al 12 de enero de 2027.',
         'Calle Demo 101', 'Oaxaca', 'Oaxaca', 'MX', 950.00, 'MXN', 2, 'aprobada', 'activa'),
        ('[RF010 DEMO] Oaxaca - reserva confirmada', 'rf010-publicador-b@example.invalid',
         'Alojamiento de prueba con reserva confirmada del 10 al 12 de enero de 2027.',
         'Calle Demo 102', 'Oaxaca', 'Oaxaca', 'MX', 1800.00, 'MXN', 6, 'aprobada', 'activa'),
        ('[RF010 DEMO] Oaxaca - sin calendario', 'rf010-publicador-b@example.invalid',
         'Alojamiento aprobado sin ventanas de disponibilidad configuradas.',
         'Calle Demo 103', 'Oaxaca', 'Oaxaca', 'MX', 650.00, 'MXN', 2, 'aprobada', 'activa'),
        ('[RF010 DEMO] CDMX - disponible', 'rf010-publicador-a@example.invalid',
         'Alojamiento de prueba disponible en Ciudad de Mexico.',
         'Avenida Demo 200', 'Ciudad de Mexico', 'CDMX', 'MX', 1500.00, 'MXN', 4, 'aprobada', 'activa'),
        ('[RF010 DEMO] Guadalajara - economico', 'rf010-publicador-b@example.invalid',
         'Alojamiento economico para probar destino y rango de precio.',
         'Avenida Demo 300', 'Guadalajara', 'Jalisco', 'MX', 500.00, 'MXN', 2, 'aprobada', 'activa'),
        ('[RF010 DEMO] Estado pendiente activa', 'rf010-publicador-a@example.invalid',
         'No debe aparecer: aprobación pendiente y publicación activa.',
         'Calle Matriz 1', 'Oaxaca', 'Oaxaca', 'MX', 1100.00, 'MXN', 3, 'pendiente', 'activa'),
        ('[RF010 DEMO] Estado pendiente pausada', 'rf010-publicador-a@example.invalid',
         'No debe aparecer: aprobación pendiente y publicación pausada.',
         'Calle Matriz 2', 'Oaxaca', 'Oaxaca', 'MX', 1100.00, 'MXN', 3, 'pendiente', 'pausada'),
        ('[RF010 DEMO] Estado pendiente eliminada', 'rf010-publicador-a@example.invalid',
         'No debe aparecer: aprobación pendiente y publicación eliminada.',
         'Calle Matriz 3', 'Oaxaca', 'Oaxaca', 'MX', 1100.00, 'MXN', 3, 'pendiente', 'eliminada'),
        ('[RF010 DEMO] Estado aprobada pausada', 'rf010-publicador-b@example.invalid',
         'No debe aparecer: aprobada pero publicación pausada.',
         'Calle Matriz 4', 'Oaxaca', 'Oaxaca', 'MX', 1100.00, 'MXN', 3, 'aprobada', 'pausada'),
        ('[RF010 DEMO] Estado aprobada eliminada', 'rf010-publicador-b@example.invalid',
         'No debe aparecer: aprobada pero publicación eliminada.',
         'Calle Matriz 5', 'Oaxaca', 'Oaxaca', 'MX', 1100.00, 'MXN', 3, 'aprobada', 'eliminada'),
        ('[RF010 DEMO] Estado rechazada activa', 'rf010-publicador-a@example.invalid',
         'No debe aparecer: publicación rechazada y activa.',
         'Calle Matriz 6', 'Oaxaca', 'Oaxaca', 'MX', 1100.00, 'MXN', 3, 'rechazada', 'activa'),
        ('[RF010 DEMO] Estado rechazada pausada', 'rf010-publicador-a@example.invalid',
         'No debe aparecer: publicación rechazada y pausada.',
         'Calle Matriz 7', 'Oaxaca', 'Oaxaca', 'MX', 1100.00, 'MXN', 3, 'rechazada', 'pausada'),
        ('[RF010 DEMO] Estado rechazada eliminada', 'rf010-publicador-b@example.invalid',
         'No debe aparecer: publicación rechazada y eliminada.',
         'Calle Matriz 8', 'Oaxaca', 'Oaxaca', 'MX', 1100.00, 'MXN', 3, 'rechazada', 'eliminada')
)
INSERT INTO hospedaje.alojamiento (
    publicador_id, titulo, descripcion, direccion, ciudad, region, pais,
    precio_noche, moneda, max_huespedes, estado_aprobacion,
    estado_publicacion, eliminado_at
)
SELECT
    u.id,
    d.titulo,
    d.descripcion,
    d.direccion,
    d.ciudad,
    d.region,
    d.pais,
    d.precio_noche,
    d.moneda,
    d.max_huespedes,
    d.estado_aprobacion::hospedaje.estado_aprobacion,
    d.estado_publicacion::hospedaje.estado_publicacion,
    CASE WHEN d.estado_publicacion = 'eliminada' THEN now() END
FROM datos AS d
JOIN hospedaje.usuario AS u ON u.email = d.publicador_email
WHERE NOT EXISTS (
    SELECT 1
    FROM hospedaje.alojamiento AS existente
    WHERE existente.publicador_id = u.id
      AND existente.titulo = d.titulo
);

INSERT INTO hospedaje.alojamiento_revision (
    alojamiento_id, decision, motivo, administrador_id
)
SELECT a.id, a.estado_aprobacion, motivo.decision_motivo, admin.id
FROM hospedaje.alojamiento AS a
CROSS JOIN hospedaje.usuario AS admin
CROSS JOIN LATERAL (
    VALUES (
        CASE a.estado_aprobacion
            WHEN 'aprobada' THEN 'Aprobada para datos de demostracion RF-010.'
            WHEN 'rechazada' THEN 'Rechazada para probar que no aparezca en la búsqueda.'
        END
    )
) AS motivo(decision_motivo)
WHERE a.titulo LIKE '[RF010 DEMO]%'
  AND a.estado_aprobacion IN ('aprobada', 'rechazada')
  AND admin.email = 'rf010-admin@example.invalid'
  AND NOT EXISTS (
      SELECT 1
      FROM hospedaje.alojamiento_revision AS revision
      WHERE revision.alojamiento_id = a.id
        AND revision.decision = a.estado_aprobacion
  );

INSERT INTO hospedaje.alojamiento_imagen (
    alojamiento_id, url, texto_alt, orden, es_principal
)
SELECT
    a.id,
    'https://placehold.co/800x600?text=RF010+Demo',
    'Imagen de demostracion',
    0,
    true
FROM hospedaje.alojamiento AS a
WHERE a.titulo LIKE '[RF010 DEMO]%'
  AND a.estado_aprobacion = 'aprobada'
  AND a.estado_publicacion = 'activa'
  AND NOT EXISTS (
      SELECT 1
      FROM hospedaje.alojamiento_imagen AS imagen
      WHERE imagen.alojamiento_id = a.id
        AND imagen.orden = 0
  );

INSERT INTO hospedaje.alojamiento_disponibilidad (alojamiento_id, periodo)
SELECT a.id, daterange(DATE '2026-01-01', DATE '2031-01-01', '[)')
FROM hospedaje.alojamiento AS a
WHERE a.titulo IN (
    '[RF010 DEMO] Oaxaca - disponible',
    '[RF010 DEMO] Oaxaca - fechas bloqueadas',
    '[RF010 DEMO] Oaxaca - reserva confirmada',
    '[RF010 DEMO] CDMX - disponible',
    '[RF010 DEMO] Guadalajara - economico'
)
  AND NOT EXISTS (
      SELECT 1
      FROM hospedaje.alojamiento_disponibilidad AS d
      WHERE d.alojamiento_id = a.id
        AND d.periodo = daterange(DATE '2026-01-01', DATE '2031-01-01', '[)')
  );

INSERT INTO hospedaje.alojamiento_bloqueo (alojamiento_id, periodo, motivo)
SELECT a.id, daterange(DATE '2027-01-10', DATE '2027-01-12', '[)'), 'Bloqueo de demostracion RF-010'
FROM hospedaje.alojamiento AS a
WHERE a.titulo = '[RF010 DEMO] Oaxaca - fechas bloqueadas'
  AND NOT EXISTS (
      SELECT 1
      FROM hospedaje.alojamiento_bloqueo AS b
      WHERE b.alojamiento_id = a.id
        AND b.periodo = daterange(DATE '2027-01-10', DATE '2027-01-12', '[)')
  );

INSERT INTO hospedaje.reserva (
    alojamiento_id, arrendante_id, fecha_inicio, fecha_fin,
    num_huespedes, precio_noche, monto_total, moneda, estado
)
SELECT
    a.id,
    arrendante.id,
    DATE '2027-01-10',
    DATE '2027-01-12',
    2,
    a.precio_noche,
    a.precio_noche * 2,
    a.moneda,
    'confirmada'::hospedaje.estado_reserva
FROM hospedaje.alojamiento AS a
CROSS JOIN hospedaje.usuario AS arrendante
WHERE a.titulo = '[RF010 DEMO] Oaxaca - reserva confirmada'
  AND arrendante.email = 'rf010-arrendante@example.invalid'
  AND NOT EXISTS (
      SELECT 1
      FROM hospedaje.reserva AS r
      WHERE r.alojamiento_id = a.id
        AND r.fecha_inicio = DATE '2027-01-10'
        AND r.fecha_fin = DATE '2027-01-12'
        AND r.estado = 'confirmada'
  );

COMMIT;

-- Inventario de prueba: muestra todos los estados de aprobación/publicación.
SELECT
    a.id,
    a.titulo,
    a.estado_aprobacion,
    a.estado_publicacion,
    a.ciudad,
    a.precio_noche,
    a.max_huespedes
FROM hospedaje.alojamiento AS a
WHERE a.titulo LIKE '[RF010 DEMO]%'
ORDER BY a.estado_aprobacion, a.estado_publicacion, a.titulo;
