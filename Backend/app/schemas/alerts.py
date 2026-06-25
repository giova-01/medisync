from datetime import datetime

from pydantic import BaseModel


class AlertaDto(BaseModel):
    id: int
    tipo: str
    severidad: str
    titulo: str
    mensaje: str
    fecha_creacion: datetime
    leida: bool = False
