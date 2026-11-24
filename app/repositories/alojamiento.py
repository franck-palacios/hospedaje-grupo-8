from sqlalchemy import text
from sqlalchemy.orm import Session

from app.schemas.alojamiento import AlojamientoBusquedaFiltros


def buscar_disponibles(
    db: Session,
    filtros: AlojamientoBusquedaFiltros,
) -> list[dict[str, object]]:
    condiciones = [
        "a.estado_aprobacion = 'aprobada'",
        "a.estado_publicacion = 'activa'",
    ]
    parametros: dict[str, object] = {}

    if filtros.destino is not None:
        condiciones.append(
            "("
            "strpos(lower(a.ciudad), lower(:destino)) > 0 "
            "OR strpos(lower(coalesce(a.region, '')), lower(:destino)) > 0 "
            "OR strpos(lower(trim(a.pais)), lower(:destino)) > 0"
            ")"
        )
        parametros["destino"] = filtros.destino.strip()

    if filtros.huespedes is not None:
        condiciones.append("a.max_huespedes >= :huespedes")
        parametros["huespedes"] = filtros.huespedes

    if filtros.precio_min is not None:
        condiciones.append("a.precio_noche >= :precio_min")
        parametros["precio_min"] = filtros.precio_min

    if filtros.precio_max is not None:
        condiciones.append("a.precio_noche <= :precio_max")
        parametros["precio_max"] = filtros.precio_max

    if filtros.fecha_inicio is not None and filtros.fecha_fin is not None:
        parametros["fecha_inicio"] = filtros.fecha_inicio
        parametros["fecha_fin"] = filtros.fecha_fin
        rango_solicitado = (
            "daterange(CAST(:fecha_inicio AS date), CAST(:fecha_fin AS date), '[)')"
        )
        condiciones.extend(
            [
                "EXISTS ("
                "SELECT 1 FROM hospedaje.alojamiento_disponibilidad AS d "
                f"WHERE d.alojamiento_id = a.id AND d.periodo @> {rango_solicitado}"
                ")",
                "NOT EXISTS ("
                "SELECT 1 FROM hospedaje.alojamiento_bloqueo AS b "
                f"WHERE b.alojamiento_id = a.id AND b.periodo && {rango_solicitado}"
                ")",
                "NOT EXISTS ("
                "SELECT 1 FROM hospedaje.reserva AS r "
                f"WHERE r.alojamiento_id = a.id AND r.periodo && {rango_solicitado} "
                "AND r.estado IN ('confirmada', 'finalizada')"
                ")",
            ]
        )

    consulta = text(
        """
        SELECT
            a.id,
            a.titulo,
            a.descripcion,
            a.ciudad,
            a.region,
            trim(a.pais) AS pais,
            a.precio_noche,
            trim(a.moneda) AS moneda,
            a.max_huespedes,
            (
                SELECT i.url
                FROM hospedaje.alojamiento_imagen AS i
                WHERE i.alojamiento_id = a.id
                ORDER BY i.es_principal DESC, i.orden ASC, i.id ASC
                LIMIT 1
            ) AS imagen_principal
        FROM hospedaje.alojamiento AS a
        WHERE """
        + " AND ".join(condiciones)
        + """
        ORDER BY a.created_at DESC, a.id DESC
        LIMIT :limite OFFSET :desplazamiento
        """
    )
    parametros["limite"] = filtros.limite
    parametros["desplazamiento"] = filtros.desplazamiento

    filas = db.execute(consulta, parametros).mappings()
    return [dict(fila) for fila in filas]
