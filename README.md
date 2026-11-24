# API de hospedajes

Backend inicial con FastAPI para implementar RF-010 — Búsqueda de hospedajes.

## Requisitos

- Python 3.10 o posterior.
- PostgreSQL 14 o posterior, con el esquema de `schema_hospedajes.sql` aplicado.

## Instalación en Windows

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-dev.txt
Copy-Item .env.example .env
```

Completa en `.env` `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` y `DB_PASSWORD` con tus datos de conexión. No compartas ni confirmes el archivo `.env`.

## Ejecutar la API

```powershell
python -m uvicorn app.main:app --reload
```

Documentación interactiva: <http://127.0.0.1:8000/docs>

## Endpoint RF-010

`GET /api/v1/alojamientos`

Parámetros opcionales:

| Parámetro | Uso |
|---|---|
| `destino` | Busca coincidencias parciales en ciudad, región o código de país. |
| `fecha_inicio`, `fecha_fin` | Filtra fechas de entrada y salida. Deben enviarse juntas; la salida es exclusiva. |
| `huespedes` | Cantidad de huéspedes; filtra por capacidad máxima. |
| `precio_min`, `precio_max` | Rango de precio por noche. |
| `limite`, `desplazamiento` | Paginación; el límite máximo es 100. |

Ejemplo:

```text
GET /api/v1/alojamientos?destino=Oaxaca&fecha_inicio=2027-01-10&fecha_fin=2027-01-14&huespedes=2&precio_min=500&precio_max=2500
```

Los resultados incluyen alojamientos aprobados y activos. Cuando se proporcionan fechas, sólo incluyen rangos de disponibilidad que cubren toda la estancia y excluyen bloqueos y reservas confirmadas o finalizadas que se solapen. Las fechas usan intervalos `[entrada, salida)`, de acuerdo con el esquema PostgreSQL.

## Datos de demostración para RF-010

El script `scripts/seed_rf010.sql` inserta 14 alojamientos de prueba de forma repetible: todas las combinaciones de aprobación (`pendiente`, `aprobada`, `rechazada`) y publicación (`activa`, `pausada`, `eliminada`), además de ejemplos disponibles, bloqueados, reservados y sin calendario. Usa usuarios con correos `example.invalid` y contraseñas que no sirven para iniciar sesión.

Para ejecutarlo con `psql` en Windows:

```powershell
psql -h <DB_HOST> -p <DB_PORT> -U <DB_USER> -d <DB_NAME> -W -f .\scripts\seed_rf010.sql
```

`-W` solicita la contraseña de forma interactiva. El script requiere haber aplicado antes `schema_hospedajes.sql`.

Sin filtros, el endpoint devuelve los seis alojamientos de demostración aprobados y activos. Para comprobar disponibilidad, el rango del 10 al 12 de enero de 2027 devuelve sólo el alojamiento libre en Oaxaca:

```text
GET /api/v1/alojamientos?destino=Oaxaca&fecha_inicio=2027-01-10&fecha_fin=2027-01-12&huespedes=2&precio_min=500&precio_max=2000
```

Esta primera entrega cubre la búsqueda y no implementa autenticación. Antes de exponerla en producción, integra la autenticación y autorización por rol previstas en RF-002 y RNF-002.

## Pruebas

```powershell
python -m pytest
```
