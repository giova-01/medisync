from datetime import date

from pydantic import BaseModel


class ProfileResponse(BaseModel):
    id: int
    email: str
    nombre: str
    apellido: str
    tipo_perfil: str
    fecha_nacimiento: date | None = None
    patologias: str | None = None
    parentesco: str | None = None
    matricula: str | None = None
    especialidad: str | None = None


class UpdateProfileRequest(BaseModel):
    nombre: str
    apellido: str
    fecha_nacimiento: date | None = None
    patologias: str | None = None
    parentesco: str | None = None
    matricula: str | None = None
    especialidad: str | None = None
