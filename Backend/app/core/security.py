from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from app.core.config import settings
from app.core.db import get_connection
from app.core.enums import TIPO_PERFIL_TO_API

BCRYPT_COST = 12

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login", auto_error=False)


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(BCRYPT_COST)).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))


def create_access_token(id_usuario: int, tipo_perfil_db: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(id_usuario),
        "tipo_perfil": TIPO_PERFIL_TO_API[tipo_perfil_db],
        "iat": now,
        "exp": now + timedelta(hours=settings.jwt_expire_hours),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except jwt.PyJWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="INVALID_TOKEN",
        ) from exc


class CurrentUser:
    def __init__(self, id_usuario: int, tipo_perfil: str):
        self.id_usuario = id_usuario
        self.tipo_perfil = tipo_perfil  # valor API: paciente/cuidador/profesional_salud


async def get_current_user(
    token: str | None = Depends(oauth2_scheme),
    conn=Depends(get_connection),
) -> CurrentUser:
    if token is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="NOT_AUTHENTICATED")
    payload = decode_access_token(token)
    id_usuario = int(payload["sub"])
    async with conn.cursor() as cur:
        await cur.execute("SELECT id_usuario FROM usuarios WHERE id_usuario = %s", (id_usuario,))
        row = await cur.fetchone()
    if row is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="USER_NOT_FOUND")
    return CurrentUser(id_usuario=id_usuario, tipo_perfil=payload["tipo_perfil"])


def require_role(*roles: str):
    def checker(current_user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
        if current_user.tipo_perfil not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No autorizado para esta operación.",
            )
        return current_user

    return checker
