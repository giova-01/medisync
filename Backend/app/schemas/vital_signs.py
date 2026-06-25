from datetime import datetime

from pydantic import BaseModel, Field


class SignoVitalDto(BaseModel):
    id: int
    tipo: str
    valor: float
    fecha_medicion: datetime


class CreateVitalSignRequest(BaseModel):
    frecuencia_cardiaca: int = Field(ge=0, le=300)
    spo2: float = Field(ge=0, le=100)
    calidad_senal: int = Field(ge=0, le=100)
    registrado_en: datetime
