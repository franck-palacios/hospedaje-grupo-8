from datetime import date
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class AlojamientoBusquedaFiltros(BaseModel):
    model_config = ConfigDict(extra="forbid")

    destino: str | None = Field(default=None, min_length=1, max_length=120)
    fecha_inicio: date | None = None
    fecha_fin: date | None = None
    huespedes: int | None = Field(default=None, gt=0, le=32767)
    precio_min: Decimal | None = Field(default=None, ge=0, max_digits=12, decimal_places=2)
    precio_max: Decimal | None = Field(default=None, ge=0, max_digits=12, decimal_places=2)
    limite: int = Field(default=20, ge=1, le=100)
    desplazamiento: int = Field(default=0, ge=0)

    @field_validator("destino")
    @classmethod
    def normalizar_destino(cls, valor: str | None) -> str | None:
        if valor is None:
            return None
        valor = valor.strip()
        if not valor:
            raise ValueError("destino no puede estar vacío.")
        return valor

    @model_validator(mode="after")
    def validar_filtros(self) -> "AlojamientoBusquedaFiltros":
        if (self.fecha_inicio is None) != (self.fecha_fin is None):
            raise ValueError("fecha_inicio y fecha_fin deben proporcionarse juntas.")
        if (
            self.fecha_inicio is not None
            and self.fecha_fin is not None
            and self.fecha_fin <= self.fecha_inicio
        ):
            raise ValueError("fecha_fin debe ser posterior a fecha_inicio.")
        if (
            self.precio_min is not None
            and self.precio_max is not None
            and self.precio_min > self.precio_max
        ):
            raise ValueError("precio_min no puede ser mayor que precio_max.")
        return self


class AlojamientoBusquedaResultado(BaseModel):
    id: int
    titulo: str
    descripcion: str
    ciudad: str
    region: str | None
    pais: str
    precio_noche: Decimal
    moneda: str
    max_huespedes: int
    imagen_principal: str | None
