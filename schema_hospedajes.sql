-- =====================================================================
-- Esquema PostgreSQL: MVP de hospedajes (publicación, reservas, pagos
-- PayPal, reembolsos, retroalimentación, moderación, disputas).
-- Objetivo: PostgreSQL 14+ (probar en 15/16; compatible con 17/18).
-- Extensiones: citext y btree_gist (ambas "trusted" desde PG13; disponibles
-- en RDS/Aurora, Cloud SQL y Azure Flexible Server).
-- Convención de aplicación: antes de operar, cada transacción debe hacer
--   SELECT set_config('app.usuario_id', '<id>', true);
-- para que historial y auditoría registren el actor.
-- Asumir READ COMMITTED (nivel por defecto) para los triggers de calendario.
-- =====================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS citext    WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;

CREATE SCHEMA IF NOT EXISTS hospedaje;
SET LOCAL search_path = hospedaje, public;

-- ---------------------------------------------------------------------
-- 1. Tipos enumerados
-- ---------------------------------------------------------------------
CREATE TYPE rol_usuario        AS ENUM ('publicador', 'arrendante', 'administrador');
CREATE TYPE estado_cuenta      AS ENUM ('activa', 'suspendida');
CREATE TYPE estado_aprobacion  AS ENUM ('pendiente', 'aprobada', 'rechazada');
CREATE TYPE estado_publicacion AS ENUM ('activa', 'pausada', 'eliminada');
CREATE TYPE estado_reserva     AS ENUM ('solicitada', 'aceptada', 'rechazada', 'pendiente_pago',
                                        'confirmada', 'cancelada', 'finalizada');
CREATE TYPE estado_pago        AS ENUM ('pendiente', 'aprobado', 'fallido');
CREATE TYPE estado_reembolso   AS ENUM ('pendiente', 'aprobado', 'completado', 'fallido');
-- visible al público = 'publicado' (pasó el filtro) o 'aprobado' (admin); oculto = en revisión
CREATE TYPE estado_moderacion  AS ENUM ('publicado', 'oculto', 'aprobado', 'rechazado');
CREATE TYPE origen_moderacion  AS ENUM ('automatica', 'administrador');
CREATE TYPE resultado_moderacion AS ENUM ('marcado', 'aprobado', 'rechazado');
CREATE TYPE tipo_disputa       AS ENUM ('reserva', 'pago', 'calificacion');
CREATE TYPE estado_disputa     AS ENUM ('abierta', 'en_revision', 'resuelta');
CREATE TYPE estado_correo      AS ENUM ('no_aplica', 'pendiente', 'enviado', 'fallido');
CREATE TYPE tipo_notificacion  AS ENUM (
    'publicacion_aprobada', 'publicacion_rechazada',
    'reserva_solicitada', 'reserva_aceptada', 'reserva_rechazada',
    'pago_aprobado', 'pago_fallido',
    'reserva_cancelada',
    'reembolso_aprobado', 'reembolso_completado',
    'reserva_finalizada',
    'nueva_calificacion',
    'comentario_oculto', 'decision_moderacion'
);

-- ---------------------------------------------------------------------
-- 2. Configuración de reglas de negocio (evita hardcodear la política)
-- ---------------------------------------------------------------------
CREATE TABLE configuracion (
    clave       text PRIMARY KEY,
    valor       numeric NOT NULL,
    descripcion text NOT NULL,
    updated_at  timestamptz NOT NULL DEFAULT now()
);

INSERT INTO configuracion (clave, valor, descripcion) VALUES
    ('reembolso_porcentaje',            70, 'Porcentaje reembolsable en cancelación anticipada'),
    ('reembolso_dias_anticipacion_min',  2, 'Días naturales mínimos antes del inicio para tener reembolso'),
    ('reembolso_plazo_dias_habiles',    15, 'Plazo máximo para procesar el reembolso (días hábiles)'),
    ('pago_plazo_horas',                24, 'SUPUESTO: plazo para pagar una reserva aceptada (pendiente de definir)');

-- ---------------------------------------------------------------------
-- 3. Usuarios, roles y suspensiones
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email                citext      NOT NULL UNIQUE,
    password_hash        text        NOT NULL,           -- argon2id/bcrypt; nunca texto plano
    nombre               text        NOT NULL,
    telefono             text,
    rol                  rol_usuario NOT NULL,
    estado               estado_cuenta NOT NULL DEFAULT 'activa',
    email_verificado_at  timestamptz,                    -- pendiente de definir si es obligatorio
    ultimo_login_at      timestamptz,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE usuario_rol_historial (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id    bigint      NOT NULL REFERENCES usuario(id),
    rol_anterior  rol_usuario NOT NULL,
    rol_nuevo     rol_usuario NOT NULL,
    cambiado_por  bigint      NOT NULL REFERENCES usuario(id),
    motivo        text,
    created_at    timestamptz NOT NULL DEFAULT now(),
    CHECK (rol_anterior <> rol_nuevo),
    CHECK (cambiado_por <> usuario_id)                   -- el admin no se autobloquea (RF-004)
);
CREATE INDEX ON usuario_rol_historial (usuario_id);

CREATE TABLE usuario_suspension (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id      bigint      NOT NULL REFERENCES usuario(id),
    motivo          text        NOT NULL CHECK (btrim(motivo) <> ''),
    suspendido_por  bigint      NOT NULL REFERENCES usuario(id),
    suspendido_at   timestamptz NOT NULL DEFAULT now(),
    reactivado_por  bigint      REFERENCES usuario(id),
    reactivado_at   timestamptz,
    CHECK (suspendido_por <> usuario_id),
    CHECK ((reactivado_at IS NULL) = (reactivado_por IS NULL))
);
-- a lo sumo una suspensión vigente por usuario
CREATE UNIQUE INDEX usuario_suspension_vigente_uq
    ON usuario_suspension (usuario_id) WHERE reactivado_at IS NULL;

CREATE TABLE token_recuperacion (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id  bigint      NOT NULL REFERENCES usuario(id),
    token_hash  bytea       NOT NULL UNIQUE,             -- guardar sólo el hash (p. ej. SHA-256)
    expira_at   timestamptz NOT NULL,
    usado_at    timestamptz,                             -- un solo uso
    created_at  timestamptz NOT NULL DEFAULT now(),
    CHECK (expira_at > created_at)
);
CREATE INDEX ON token_recuperacion (usuario_id);

-- ---------------------------------------------------------------------
-- 4. Alojamientos
-- ---------------------------------------------------------------------
CREATE TABLE alojamiento (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    publicador_id       bigint      NOT NULL REFERENCES usuario(id),
    titulo              text        NOT NULL,
    descripcion         text        NOT NULL,
    direccion           text        NOT NULL,
    ciudad              text        NOT NULL,
    region              text,
    pais                char(2)     NOT NULL,            -- ISO 3166-1 alfa-2
    latitud             numeric(9,6) CHECK (latitud  BETWEEN  -90 AND  90),
    longitud            numeric(9,6) CHECK (longitud BETWEEN -180 AND 180),
    precio_noche        numeric(12,2) NOT NULL CHECK (precio_noche > 0),
    moneda              char(3)     NOT NULL DEFAULT 'USD',
    max_huespedes       smallint    NOT NULL CHECK (max_huespedes > 0),
    reglas              text,
    estado_aprobacion   estado_aprobacion  NOT NULL DEFAULT 'pendiente',
    estado_publicacion  estado_publicacion NOT NULL DEFAULT 'activa',
    eliminado_at        timestamptz,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),
    UNIQUE (id, publicador_id),
    CHECK ((latitud IS NULL) = (longitud IS NULL)),
    CHECK ((estado_publicacion = 'eliminada') = (eliminado_at IS NOT NULL))
);
CREATE INDEX ON alojamiento (publicador_id);
-- búsqueda: sólo aprobados y activos
CREATE INDEX alojamiento_busqueda_idx
    ON alojamiento (pais, lower(ciudad), precio_noche)
    WHERE estado_aprobacion = 'aprobada' AND estado_publicacion = 'activa';
CREATE INDEX alojamiento_pendientes_idx
    ON alojamiento (created_at) WHERE estado_aprobacion = 'pendiente';

CREATE TABLE alojamiento_imagen (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    alojamiento_id bigint   NOT NULL REFERENCES alojamiento(id) ON DELETE CASCADE,
    url            text     NOT NULL,                    -- objeto en almacenamiento externo (S3, etc.)
    texto_alt      text,
    orden          smallint NOT NULL DEFAULT 0,
    es_principal   boolean  NOT NULL DEFAULT false,
    created_at     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (alojamiento_id, orden)
);
CREATE UNIQUE INDEX alojamiento_imagen_principal_uq
    ON alojamiento_imagen (alojamiento_id) WHERE es_principal;

-- Historial de decisiones de aprobación (RF-008, RNF-006)
CREATE TABLE alojamiento_revision (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    alojamiento_id bigint NOT NULL REFERENCES alojamiento(id),
    decision       estado_aprobacion NOT NULL CHECK (decision <> 'pendiente'),
    motivo         text,
    administrador_id bigint NOT NULL REFERENCES usuario(id),
    decidido_at    timestamptz NOT NULL DEFAULT now(),
    CHECK (decision <> 'rechazada' OR btrim(coalesce(motivo, '')) <> '')
);
CREATE INDEX ON alojamiento_revision (alojamiento_id);

-- ---------------------------------------------------------------------
-- 5. Disponibilidad (RF-009)
--    Disponible = dentro de una ventana ofertada, sin bloqueo manual y
--    sin reserva confirmada/finalizada. Rangos [inicio, fin) por fechas.
-- ---------------------------------------------------------------------
CREATE TABLE alojamiento_disponibilidad (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    alojamiento_id bigint    NOT NULL REFERENCES alojamiento(id) ON DELETE CASCADE,
    periodo        daterange NOT NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    CHECK (NOT isempty(periodo) AND NOT lower_inf(periodo) AND NOT upper_inf(periodo)
           AND lower_inc(periodo) AND NOT upper_inc(periodo)),
    EXCLUDE USING gist (alojamiento_id WITH =, periodo WITH &&)
);

CREATE TABLE alojamiento_bloqueo (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    alojamiento_id bigint    NOT NULL REFERENCES alojamiento(id) ON DELETE CASCADE,
    periodo        daterange NOT NULL,
    motivo         text,
    created_at     timestamptz NOT NULL DEFAULT now(),
    CHECK (NOT isempty(periodo) AND NOT lower_inf(periodo) AND NOT upper_inf(periodo)
           AND lower_inc(periodo) AND NOT upper_inc(periodo)),
    EXCLUDE USING gist (alojamiento_id WITH =, periodo WITH &&)
);

-- ---------------------------------------------------------------------
-- 6. Reservas (RF-011..RF-017, RNF-004, RNF-007)
-- ---------------------------------------------------------------------
CREATE TABLE reserva (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    alojamiento_id  bigint  NOT NULL REFERENCES alojamiento(id),
    arrendante_id   bigint  NOT NULL REFERENCES usuario(id),
    fecha_inicio    date    NOT NULL,                    -- check-in
    fecha_fin       date    NOT NULL,                    -- check-out (exclusivo)
    periodo         daterange GENERATED ALWAYS AS (daterange(fecha_inicio, fecha_fin, '[)')) STORED,
    num_huespedes   smallint NOT NULL CHECK (num_huespedes > 0),
    precio_noche    numeric(12,2) NOT NULL CHECK (precio_noche > 0),   -- snapshot al solicitar
    monto_total     numeric(12,2) NOT NULL CHECK (monto_total > 0),
    moneda          char(3) NOT NULL,
    estado          estado_reserva NOT NULL DEFAULT 'solicitada',
    pago_limite_at  timestamptz,                         -- se fija al aceptar (plazo por definir)
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    CHECK (fecha_fin > fecha_inicio),
    UNIQUE (id, alojamiento_id, arrendante_id),
    -- RNF-004: nunca dos reservas confirmadas con fechas solapadas
    CONSTRAINT reserva_sin_solape
        EXCLUDE USING gist (alojamiento_id WITH =, periodo WITH &&)
        WHERE (estado IN ('confirmada', 'finalizada'))
);
CREATE INDEX ON reserva (arrendante_id, estado);
CREATE INDEX ON reserva (alojamiento_id, estado);
CREATE INDEX reserva_expiracion_pago_idx ON reserva (pago_limite_at) WHERE estado = 'pendiente_pago';
CREATE INDEX reserva_por_finalizar_idx   ON reserva (fecha_fin)      WHERE estado = 'confirmada';

CREATE TABLE reserva_historial_estado (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reserva_id      bigint NOT NULL REFERENCES reserva(id),
    estado_anterior estado_reserva,
    estado_nuevo    estado_reserva NOT NULL,
    cambiado_por    bigint REFERENCES usuario(id),       -- NULL = sistema
    created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON reserva_historial_estado (reserva_id, created_at);

CREATE TABLE reserva_cancelacion (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reserva_id           bigint NOT NULL UNIQUE REFERENCES reserva(id),
    cancelado_por        bigint NOT NULL REFERENCES usuario(id),
    cancelado_at         timestamptz NOT NULL DEFAULT now(),
    motivo               text   NOT NULL CHECK (btrim(motivo) <> ''),
    dias_anticipacion    integer NOT NULL,               -- días naturales hasta fecha_inicio
    porcentaje_reembolso numeric(5,2) NOT NULL CHECK (porcentaje_reembolso BETWEEN 0 AND 100)
);

-- ---------------------------------------------------------------------
-- 7. Pagos PayPal y reembolsos (RF-013, RF-016, RNF-003)
--    No se almacena ningún dato de tarjeta.
-- ---------------------------------------------------------------------
CREATE TABLE pago (
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reserva_id         bigint NOT NULL REFERENCES reserva(id),
    monto              numeric(12,2) NOT NULL CHECK (monto > 0),
    moneda             char(3) NOT NULL,
    estado             estado_pago NOT NULL DEFAULT 'pendiente',
    paypal_order_id    text NOT NULL UNIQUE,
    paypal_capture_id  text UNIQUE,
    paypal_estado      text,                             -- estado crudo reportado por PayPal
    paypal_payer_id    text,
    paypal_respuesta   jsonb,                            -- guardar sólo lo necesario (puede traer PII)
    motivo_fallo       text,
    aprobado_at        timestamptz,
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now(),
    UNIQUE (id, reserva_id),
    CHECK (estado <> 'aprobado' OR (paypal_capture_id IS NOT NULL AND aprobado_at IS NOT NULL))
);
CREATE INDEX ON pago (reserva_id);
CREATE UNIQUE INDEX pago_un_aprobado_por_reserva_uq ON pago (reserva_id) WHERE estado = 'aprobado';

-- Idempotencia de webhooks de PayPal
CREATE TABLE paypal_evento (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    paypal_event_id  text NOT NULL UNIQUE,
    tipo             text NOT NULL,
    payload          jsonb NOT NULL,
    recibido_at      timestamptz NOT NULL DEFAULT now(),
    procesado_at     timestamptz,
    error            text
);

CREATE TABLE reembolso (
    id                      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pago_id                 bigint NOT NULL REFERENCES pago(id),
    reserva_cancelacion_id  bigint NOT NULL UNIQUE REFERENCES reserva_cancelacion(id),
    monto_base              numeric(12,2) NOT NULL CHECK (monto_base > 0),   -- monto pagado
    porcentaje              numeric(5,2)  NOT NULL CHECK (porcentaje BETWEEN 0 AND 100),
    monto                   numeric(12,2) NOT NULL CHECK (monto >= 0),
    moneda                  char(3) NOT NULL,
    estado                  estado_reembolso NOT NULL DEFAULT 'pendiente',
    fecha_limite            date NOT NULL,               -- 15 días hábiles desde la cancelación
    aprobado_por            bigint REFERENCES usuario(id),                  -- NULL = sistema
    aprobado_at             timestamptz,
    completado_at           timestamptz,
    paypal_refund_id        text UNIQUE,
    paypal_estado           text,
    motivo_fallo            text,
    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now(),
    CHECK (monto <= monto_base),
    CHECK (monto = round(monto_base * porcentaje / 100, 2)),
    CHECK (estado NOT IN ('aprobado', 'completado') OR aprobado_at IS NOT NULL),
    CHECK (estado <> 'completado' OR completado_at IS NOT NULL)
);
CREATE INDEX reembolso_vencimiento_idx ON reembolso (fecha_limite) WHERE estado IN ('pendiente', 'aprobado');

-- ---------------------------------------------------------------------
-- 8. Retroalimentación y moderación (RF-018..RF-023)
-- ---------------------------------------------------------------------
CREATE TABLE calificacion (
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reserva_id         bigint NOT NULL UNIQUE,           -- una calificación por reserva
    alojamiento_id     bigint NOT NULL,
    arrendante_id      bigint NOT NULL,
    puntuacion         smallint NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
    comentario         text NOT NULL CHECK (btrim(comentario) <> ''),
    anonima            boolean NOT NULL DEFAULT false,
    estado_moderacion  estado_moderacion NOT NULL DEFAULT 'publicado',
    created_at         timestamptz NOT NULL DEFAULT now(),
    -- garantiza que la reserva sea del mismo arrendante y alojamiento
    FOREIGN KEY (reserva_id, alojamiento_id, arrendante_id)
        REFERENCES reserva (id, alojamiento_id, arrendante_id),
    UNIQUE (id, alojamiento_id),
    UNIQUE (id, reserva_id)
);
CREATE INDEX calificacion_publica_idx
    ON calificacion (alojamiento_id) WHERE estado_moderacion IN ('publicado', 'aprobado');
CREATE INDEX calificacion_ocultas_idx
    ON calificacion (created_at) WHERE estado_moderacion = 'oculto';

CREATE TABLE calificacion_respuesta (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    calificacion_id  bigint NOT NULL,
    alojamiento_id   bigint NOT NULL,
    publicador_id    bigint NOT NULL,
    comentario       text   NOT NULL CHECK (btrim(comentario) <> ''),
    estado_moderacion estado_moderacion NOT NULL DEFAULT 'publicado',
    created_at       timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (calificacion_id, alojamiento_id) REFERENCES calificacion (id, alojamiento_id),
    -- sólo el publicador propietario del alojamiento puede responder
    FOREIGN KEY (alojamiento_id, publicador_id)   REFERENCES alojamiento (id, publicador_id)
);
CREATE INDEX ON calificacion_respuesta (calificacion_id);
CREATE INDEX calificacion_respuesta_ocultas_idx
    ON calificacion_respuesta (created_at) WHERE estado_moderacion = 'oculto';

-- Detecciones automáticas y decisiones del administrador (calificación O respuesta)
CREATE TABLE moderacion_evento (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    calificacion_id  bigint REFERENCES calificacion(id),
    respuesta_id     bigint REFERENCES calificacion_respuesta(id),
    origen           origen_moderacion    NOT NULL,
    resultado        resultado_moderacion NOT NULL,
    administrador_id bigint REFERENCES usuario(id),
    motivo           text,
    detalle          jsonb,                              -- criterios/score del detector automático
    created_at       timestamptz NOT NULL DEFAULT now(),
    CHECK (num_nonnulls(calificacion_id, respuesta_id) = 1),
    CHECK ((origen = 'administrador') = (administrador_id IS NOT NULL)),
    CHECK (origen <> 'automatica' OR resultado = 'marcado')
);
CREATE INDEX ON moderacion_evento (calificacion_id) WHERE calificacion_id IS NOT NULL;
CREATE INDEX ON moderacion_evento (respuesta_id)    WHERE respuesta_id    IS NOT NULL;

-- Vistas: la identidad nunca se expone en anónimas (RNF-005). Ver nota de privilegios al final.
CREATE VIEW vista_calificacion_publica WITH (security_barrier = true) AS
SELECT c.id, c.alojamiento_id, c.puntuacion, c.comentario, c.created_at,
       CASE WHEN c.anonima THEN NULL ELSE u.nombre END AS autor_nombre
FROM calificacion c
JOIN usuario u ON u.id = c.arrendante_id
WHERE c.estado_moderacion IN ('publicado', 'aprobado');

CREATE VIEW vista_alojamiento_puntuacion AS
SELECT alojamiento_id, count(*) AS total, round(avg(puntuacion), 2) AS promedio
FROM calificacion
WHERE estado_moderacion IN ('publicado', 'aprobado')
GROUP BY alojamiento_id;

-- ---------------------------------------------------------------------
-- 9. Disputas (RF-025)
-- ---------------------------------------------------------------------
CREATE TABLE disputa (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo             tipo_disputa   NOT NULL,
    reserva_id       bigint NOT NULL REFERENCES reserva(id),
    pago_id          bigint,
    calificacion_id  bigint,
    estado           estado_disputa NOT NULL DEFAULT 'abierta',
    responsable_id   bigint NOT NULL REFERENCES usuario(id),   -- administrador a cargo
    descripcion      text   NOT NULL,
    resolucion       text,
    resuelta_at      timestamptz,
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    -- pago / calificación deben pertenecer a la misma reserva
    FOREIGN KEY (pago_id, reserva_id)         REFERENCES pago (id, reserva_id),
    FOREIGN KEY (calificacion_id, reserva_id) REFERENCES calificacion (id, reserva_id),
    CHECK (tipo <> 'pago'         OR pago_id         IS NOT NULL),
    CHECK (tipo <> 'calificacion' OR calificacion_id IS NOT NULL),
    CHECK (estado <> 'resuelta' OR (btrim(coalesce(resolucion, '')) <> '' AND resuelta_at IS NOT NULL))
);
CREATE INDEX ON disputa (reserva_id);
CREATE INDEX ON disputa (responsable_id, estado);
CREATE INDEX disputa_abiertas_idx ON disputa (created_at) WHERE estado <> 'resuelta';

CREATE TABLE disputa_historial (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    disputa_id      bigint NOT NULL REFERENCES disputa(id),
    estado_anterior estado_disputa,
    estado_nuevo    estado_disputa NOT NULL,
    nota            text,
    usuario_id      bigint NOT NULL REFERENCES usuario(id),
    created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON disputa_historial (disputa_id, created_at);

-- ---------------------------------------------------------------------
-- 10. Notificaciones internas + outbox de correo (RF-026, RNF-009)
-- ---------------------------------------------------------------------
CREATE TABLE notificacion (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id        bigint NOT NULL REFERENCES usuario(id),
    tipo              tipo_notificacion NOT NULL,
    titulo            text NOT NULL,
    mensaje           text NOT NULL,
    entidad_tipo      text,                              -- 'reserva', 'pago', 'calificacion', ...
    entidad_id        bigint,
    estado_referencia text,                              -- estado relevante del proceso
    datos             jsonb,
    leida_at          timestamptz,
    created_at        timestamptz NOT NULL DEFAULT now(),
    enviar_correo     boolean NOT NULL DEFAULT false,
    estado_correo     estado_correo NOT NULL DEFAULT 'no_aplica',
    correo_intentos   smallint NOT NULL DEFAULT 0,
    correo_enviado_at timestamptz,
    correo_error      text,
    CHECK (enviar_correo = (estado_correo <> 'no_aplica'))
);
CREATE INDEX ON notificacion (usuario_id, created_at DESC);
CREATE INDEX notificacion_no_leidas_idx ON notificacion (usuario_id) WHERE leida_at IS NULL;
CREATE INDEX notificacion_outbox_idx    ON notificacion (id)         WHERE estado_correo = 'pendiente';

-- ---------------------------------------------------------------------
-- 11. Auditoría genérica (RNF-006)
-- ---------------------------------------------------------------------
CREATE TABLE auditoria (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tabla             text   NOT NULL,
    registro_id       bigint NOT NULL,
    operacion         char(1) NOT NULL CHECK (operacion IN ('I', 'U', 'D')),
    usuario_id        bigint,                            -- sin FK a propósito
    datos_anteriores  jsonb,
    datos_nuevos      jsonb,
    created_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON auditoria (tabla, registro_id);
CREATE INDEX ON auditoria (created_at);

-- ---------------------------------------------------------------------
-- 12. Funciones y triggers
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_actor_actual() RETURNS bigint
LANGUAGE sql STABLE AS $$
    SELECT nullif(current_setting('app.usuario_id', true), '')::bigint
$$;

CREATE FUNCTION fn_set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END $$;

DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['usuario', 'alojamiento', 'reserva', 'pago', 'reembolso', 'disputa'] LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%1$s_updated_at BEFORE UPDATE ON %1$I
             FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at()', t);
    END LOOP;
END $$;

-- Tablas de solo inserción (historiales/auditoría). No cubre TRUNCATE: revocar el privilegio.
CREATE FUNCTION fn_solo_insercion() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'La tabla % es de solo inserción', TG_TABLE_NAME
        USING ERRCODE = 'restrict_violation';
END $$;

DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['auditoria', 'reserva_historial_estado', 'moderacion_evento',
                             'alojamiento_revision', 'usuario_rol_historial'] LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%1$s_inmutable BEFORE UPDATE OR DELETE ON %1$I
             FOR EACH ROW EXECUTE FUNCTION fn_solo_insercion()', t);
    END LOOP;
END $$;

-- Auditoría de pagos y reembolsos
CREATE FUNCTION fn_auditar() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO auditoria (tabla, registro_id, operacion, usuario_id, datos_anteriores, datos_nuevos)
    VALUES (
        TG_TABLE_NAME,
        CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END,
        left(TG_OP, 1),
        fn_actor_actual(),
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END
    );
    RETURN NULL;
END $$;

CREATE TRIGGER trg_pago_auditoria      AFTER INSERT OR UPDATE OR DELETE ON pago
    FOR EACH ROW EXECUTE FUNCTION fn_auditar();
CREATE TRIGGER trg_reembolso_auditoria AFTER INSERT OR UPDATE OR DELETE ON reembolso
    FOR EACH ROW EXECUTE FUNCTION fn_auditar();

-- Disponibilidad de un alojamiento para un periodo [inicio, fin)
CREATE FUNCTION fn_alojamiento_disponible(
    p_alojamiento_id bigint,
    p_periodo        daterange,
    p_excluir_reserva bigint DEFAULT NULL
) RETURNS boolean
LANGUAGE sql STABLE AS $$
    SELECT EXISTS (SELECT 1 FROM alojamiento_disponibilidad d
                   WHERE d.alojamiento_id = p_alojamiento_id AND d.periodo @> p_periodo)
       AND NOT EXISTS (SELECT 1 FROM alojamiento_bloqueo b
                   WHERE b.alojamiento_id = p_alojamiento_id AND b.periodo && p_periodo)
       AND NOT EXISTS (SELECT 1 FROM reserva r
                   WHERE r.alojamiento_id = p_alojamiento_id
                     AND r.estado IN ('confirmada', 'finalizada')
                     AND r.periodo && p_periodo
                     AND r.id IS DISTINCT FROM p_excluir_reserva)
$$;

-- Reserva: transiciones válidas + validación de calendario al confirmar.
-- (NO usar NEW.periodo aquí: las columnas generadas se calculan después de los BEFORE triggers.)
CREATE FUNCTION fn_reserva_validar() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT (
        (OLD.estado = 'solicitada'      AND NEW.estado IN ('aceptada', 'rechazada')) OR
        (OLD.estado = 'aceptada'        AND NEW.estado IN ('pendiente_pago', 'cancelada')) OR
        (OLD.estado = 'pendiente_pago'  AND NEW.estado IN ('confirmada', 'cancelada')) OR
        (OLD.estado = 'confirmada'      AND NEW.estado IN ('cancelada', 'finalizada'))
    ) THEN
        RAISE EXCEPTION 'Transición de estado de reserva inválida: % -> %', OLD.estado, NEW.estado
            USING ERRCODE = 'check_violation';
    END IF;

    IF NEW.estado = 'confirmada' THEN
        -- serializa confirmaciones y bloqueos del mismo alojamiento (NO KEY UPDATE no choca con FKs)
        PERFORM 1 FROM alojamiento WHERE id = NEW.alojamiento_id FOR NO KEY UPDATE;
        IF NOT fn_alojamiento_disponible(NEW.alojamiento_id,
                                         daterange(NEW.fecha_inicio, NEW.fecha_fin, '[)'),
                                         NEW.id) THEN
            RAISE EXCEPTION 'Fechas no disponibles para el alojamiento %', NEW.alojamiento_id
                USING ERRCODE = 'exclusion_violation';
        END IF;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_reserva_validar
    BEFORE UPDATE OF estado ON reserva
    FOR EACH ROW WHEN (OLD.estado IS DISTINCT FROM NEW.estado)
    EXECUTE FUNCTION fn_reserva_validar();

-- Historial automático de estados (RNF-007)
CREATE FUNCTION fn_reserva_historial() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO reserva_historial_estado (reserva_id, estado_anterior, estado_nuevo, cambiado_por)
        VALUES (NEW.id, NULL, NEW.estado, fn_actor_actual());
    ELSIF NEW.estado <> OLD.estado THEN
        INSERT INTO reserva_historial_estado (reserva_id, estado_anterior, estado_nuevo, cambiado_por)
        VALUES (NEW.id, OLD.estado, NEW.estado, fn_actor_actual());
    END IF;
    RETURN NULL;
END $$;

CREATE TRIGGER trg_reserva_historial
    AFTER INSERT OR UPDATE OF estado ON reserva
    FOR EACH ROW EXECUTE FUNCTION fn_reserva_historial();

-- Bloqueo manual no puede pisar reservas confirmadas/finalizadas
CREATE FUNCTION fn_bloqueo_validar() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM 1 FROM alojamiento WHERE id = NEW.alojamiento_id FOR NO KEY UPDATE;
    IF EXISTS (SELECT 1 FROM reserva r
               WHERE r.alojamiento_id = NEW.alojamiento_id
                 AND r.estado IN ('confirmada', 'finalizada')
                 AND r.periodo && NEW.periodo) THEN
        RAISE EXCEPTION 'El periodo % ya tiene una reserva confirmada', NEW.periodo
            USING ERRCODE = 'exclusion_violation';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_bloqueo_validar
    BEFORE INSERT OR UPDATE OF periodo, alojamiento_id ON alojamiento_bloqueo
    FOR EACH ROW EXECUTE FUNCTION fn_bloqueo_validar();

-- Sólo se califica una reserva finalizada (RF-017 -> RF-018)
CREATE FUNCTION fn_calificacion_validar() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM reserva WHERE id = NEW.reserva_id AND estado = 'finalizada') THEN
        RAISE EXCEPTION 'Sólo se puede calificar una reserva finalizada'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER trg_calificacion_validar
    BEFORE INSERT ON calificacion
    FOR EACH ROW EXECUTE FUNCTION fn_calificacion_validar();

COMMIT;

-- =====================================================================
-- Ejemplo de búsqueda (RF-010)
-- =====================================================================
-- SELECT a.id, a.titulo, a.precio_noche
-- FROM hospedaje.alojamiento a
-- WHERE a.estado_aprobacion = 'aprobada' AND a.estado_publicacion = 'activa'
--   AND a.pais = $1 AND lower(a.ciudad) = lower($2)
--   AND a.max_huespedes >= $3
--   AND a.precio_noche BETWEEN $4 AND $5
--   AND hospedaje.fn_alojamiento_disponible(a.id, daterange($6::date, $7::date, '[)'));

-- =====================================================================
-- Privilegios sugeridos (ajustar nombres de rol; no se ejecutan aquí)
-- =====================================================================
-- Roles: app_rw (aplicación), app_ro (reportes). El rol de la app NO debe ser dueño de los objetos.
-- REVOKE ALL ON ALL TABLES IN SCHEMA hospedaje FROM PUBLIC;
-- GRANT USAGE ON SCHEMA hospedaje TO app_rw;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA hospedaje TO app_rw;
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA hospedaje TO app_rw;
-- REVOKE TRUNCATE ON ALL TABLES IN SCHEMA hospedaje FROM app_rw;
-- Anonimato (RNF-005): para los flujos de publicador/público, otorgar sólo
--   GRANT SELECT ON hospedaje.vista_calificacion_publica TO <rol_publico>;
-- y no SELECT sobre hospedaje.calificacion (la vista corre con los privilegios de su dueño).
-- Alternativa más fuerte: RLS en calificacion/reserva por usuario_id.
