from fastapi import APIRouter

from app.api.v1.endpoints.alojamientos import router as alojamientos_router

api_router = APIRouter()
api_router.include_router(alojamientos_router, prefix="/alojamientos", tags=["Alojamientos"])
