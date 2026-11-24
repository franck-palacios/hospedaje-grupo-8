from datetime import date
from decimal import Decimal
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import ValidationError
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.alojamiento import AlojamientoBusquedaFiltros, AlojamientoBusquedaResultado
from app.services.alojamiento import buscar_alojamientos

router = APIRouter()


def obtener_filtros(
    destino: str | None = Query(default=None, min_length=1, max_length=120),
    fecha_inicio: date | None = Query(default=None),
    fecha_fin: date | None = Query(default=None),
    huespedes: int | None = Query(default=None, gt=0, le=32767),
    precio_min: Decimal | None = Query(default=None, ge=0, max_digits=12, decimal_places=2),
    precio_max: Decimal | None = Query(default=None, ge=0, max_digits=12, decimal_places=2),
    limite: int = Query(default=20, ge=1, le=100),
    desplazamiento: int = Query(default=0, ge=0),
) -> AlojamientoBusquedaFiltros:
    try:
        return AlojamientoBusquedaFiltros(
            destino=destino,
            fecha_inicio=fecha_inicio,
            fecha_fin=fecha_fin,
            huespedes=huespedes,
            precio_min=precio_min,
            precio_max=precio_max,
            limite=limite,
            desplazamiento=desplazamiento,
        )
    except ValidationError as error:
        mensajes = [detalle["msg"] for detalle in error.errors()]
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=mensajes,
        ) from error


@router.get("", response_model=list[AlojamientoBusquedaResultado])
def buscar(
    filtros: Annotated[AlojamientoBusquedaFiltros, Depends(obtener_filtros)],
    db: Session = Depends(get_db),
) -> list[AlojamientoBusquedaResultado]:
    return buscar_alojamientos(db, filtros)
