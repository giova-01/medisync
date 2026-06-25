from pydantic import BaseModel, EmailStr, Field


class UserDto(BaseModel):
    id: int
    email: str
    nombre: str
    apellido: str
    tipo_perfil: str


class RegisterRequest(BaseModel):
    nombre: str
    apellido: str
    email: EmailStr
    password: str
    tipo_perfil: str = Field(pattern="^(paciente|cuidador|profesional_salud)$")


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RecoverPasswordRequest(BaseModel):
    email: EmailStr


class AuthResponse(BaseModel):
    user: UserDto
    token: str
