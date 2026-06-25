from pydantic import BaseModel, EmailStr, Field


class VinculoDto(BaseModel):
    id: int
    id_paciente: int
    id_usuario_vinculado: int
    email_usuario_vinculado: str
    nombre_usuario_vinculado: str
    apellido_usuario_vinculado: str
    tipo_vinculo: str
    estado: str


class RequestLinkRequest(BaseModel):
    target_email: EmailStr
    rol: str = Field(pattern="^(cuidador|profesional_salud)$")


class RespondLinkRequest(BaseModel):
    aceptar: bool
