from fastapi.testclient import TestClient

from app.api.v1.endpoints import alojamientos
from app.db.session import get_db
from app.main import app


def test_busqueda_devuelve_informacion_principal(monkeypatch):
    app.dependency_overrides[get_db] = lambda: object()
    filtros_recibidos = {}

    def buscar_falso(db, filtros):
        filtros_recibidos["valor"] = filtros
        return [
            {
                "id": 7,
                "titulo": "Cabaña junto al lago",
                "descripcion": "Hospedaje familiar",
                "ciudad": "Valle",
                "region": "Norte",
                "pais": "MX",
                "precio_noche": "1250.00",
                "moneda": "MXN",
                "max_huespedes": 4,
                "imagen_principal": "https://example.com/cabana.jpg",
            }
        ]

    monkeypatch.setattr(alojamientos, "buscar_alojamientos", buscar_falso)

    try:
        response = TestClient(app).get(
            "/api/v1/alojamientos",
            params={"destino": "Valle", "huespedes": 2, "precio_max": "1500.00"},
        )
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json()[0]["id"] == 7
    assert response.json()[0]["precio_noche"] == "1250.00"
    assert response.json()[0]["imagen_principal"] == "https://example.com/cabana.jpg"
    assert filtros_recibidos["valor"].destino == "Valle"
    assert filtros_recibidos["valor"].huespedes == 2


def test_busqueda_requiere_ambas_fechas():
    response = TestClient(app).get(
        "/api/v1/alojamientos",
        params={"fecha_inicio": "2027-01-10"},
    )

    assert response.status_code == 422


def test_busqueda_rechaza_rango_de_fechas_invertido():
    response = TestClient(app).get(
        "/api/v1/alojamientos",
        params={"fecha_inicio": "2027-01-12", "fecha_fin": "2027-01-10"},
    )

    assert response.status_code == 422
