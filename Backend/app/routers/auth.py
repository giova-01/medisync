from fastapi import APIRouter, Depends, status

from app.core.db import get_connection
from app.core.security import CurrentUser, get_current_user
from app.schemas.auth import AuthResponse, LoginRequest, RecoverPasswordRequest, RegisterRequest, UserDto
from app.services import auth_service

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(body: RegisterRequest, conn=Depends(get_connection)):
    user, token = await auth_service.register(
        conn,
        nombre=body.nombre,
        apellido=body.apellido,
        email=body.email,
        password=body.password,
        tipo_perfil_api=body.tipo_perfil,
    )
    return AuthResponse(user=user, token=token)


@router.post("/login", response_model=AuthResponse)
async def login(body: LoginRequest, conn=Depends(get_connection)):
    user, token = await auth_service.login(conn, email=body.email, password=body.password)
    return AuthResponse(user=user, token=token)


@router.post("/recover-password", status_code=status.HTTP_204_NO_CONTENT)
async def recover_password(body: RecoverPasswordRequest, conn=Depends(get_connection)):
    await auth_service.recover_password(conn, email=body.email)


@router.get("/me", response_model=UserDto)
async def me(current_user: CurrentUser = Depends(get_current_user), conn=Depends(get_connection)):
    return await auth_service.get_current_user_dto(conn, current_user.id_usuario)
