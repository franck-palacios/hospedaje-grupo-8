from sqlalchemy.orm import Session

from app.repositories.alojamiento import buscar_disponibles
from app.schemas.alojamiento import AlojamientoBusquedaFiltros, AlojamientoBusquedaResultado


def buscar_alojamientos(
    db: Session,
    filtros: AlojamientoBusquedaFiltros,
) -> list[AlojamientoBusquedaResultado]:
    resultados = buscar_disponibles(db, filtros)
    return [AlojamientoBusquedaResultado.model_validate(resultado) for resultado in resultados]
