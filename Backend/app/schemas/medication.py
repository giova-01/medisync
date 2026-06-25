from datetime import date, datetime

from pydantic import BaseModel


class MedicamentoDto(BaseModel):
    id: int
    nombre: str
    dosis: str
    frecuencia_horas: int
    fecha_inicio: date
    fecha_fin: date | None = None


class MedicamentoCreateResponse(MedicamentoDto):
    """Mismas claves que MedicamentoDto más una `advertencia` opcional de
    superposición horaria (HU-006, criterio 4); se omite si no aplica
    (response_model_exclude_none=True en la ruta) para no romper el
    `fromJson` del frontend, que ignora claves desconocidas."""

    advertencia: str | None = None


class CreateMedicationRequest(BaseModel):
    nombre: str
    dosis: str
    frecuencia_horas: int
    fecha_inicio: date
    fecha_fin: date | None = None


class UpdateMedicationRequest(CreateMedicationRequest):
    pass


class TomaDto(BaseModel):
    id: int
    fecha_programada: datetime
    fecha_confirmada: datetime | None = None
    estado: str
    horario_id: int
    nombre_medicamento: str
    dosis: str
