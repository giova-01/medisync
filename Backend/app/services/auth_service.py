import re
from datetime import datetime, timedelta, timezone

from aiomysql import Connection
from fastapi import HTTPException, status

from app.core.enums import TIPO_PERFIL_FROM_API, TIPO_PERFIL_TO_API
from app.core.security import create_access_token, hash_password, verify_password
from app.repositories import user_repository
from app.schemas.auth import UserDto

PASSWORD_REGEX = re.compile(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{8,}$")

LOCKOUT_THRESHOLD = 5
LOCKOUT_MINUTES = 30


def _row_to_user_dto(row: dict) -> UserDto:
    return UserDto(
        id=row["id_usuario"],
        email=row["email"],
        nombre=row["nombre"],
        apellido=row["apellido"],
        tipo_perfil=TIPO_PERFIL_TO_API[row["tipo_perfil"]],
    )


def validate_password_policy(password: str) -> None:
    if not PASSWORD_REGEX.match(password):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="WEAK_PASSWORD: se requieren 8+ caracteres, una mayúscula, una minúscula, "
            "un dígito y un carácter especial.",
        )


async def register(
    conn: Connection, *, nombre: str, apellido: str, email: str, password: str, tipo_perfil_api: str
) -> tuple[UserDto, str]:
    validate_password_policy(password)

    existing = await user_repository.find_by_email(conn, email)
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="EMAIL_ALREADY_EXISTS")

    tipo_perfil_db = TIPO_PERFIL_FROM_API[tipo_perfil_api]
    password_hash = hash_password(password)
    id_usuario = await user_repository.create_user(
        conn,
        email=email,
        password_hash=password_hash,
        nombre=nombre,
        apellido=apellido,
        tipo_perfil_db=tipo_perfil_db,
    )
    row = await user_repository.find_by_id(conn, id_usuario)
    token = create_access_token(id_usuario, tipo_perfil_db)
    return _row_to_user_dto(row), token


async def login(conn: Connection, *, email: str, password: str) -> tuple[UserDto, str]:
    row = await user_repository.find_by_email(conn, email)
    if row is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="INVALID_CREDENTIALS")

    bloqueado_hasta = row["bloqueado_hasta"]
    if bloqueado_hasta is not None and bloqueado_hasta > datetime.now():
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="ACCOUNT_LOCKED")

    if not verify_password(password, row["password_hash"]):
        lock_until = datetime.now() + timedelta(minutes=LOCKOUT_MINUTES)
        nuevos_intentos = await user_repository.register_failed_attempt(
            conn, row["id_usuario"], lock_until_on_5th=lock_until
        )
        if nuevos_intentos >= LOCKOUT_THRESHOLD:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="ACCOUNT_LOCKED")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="INVALID_CREDENTIALS")

    await user_repository.reset_failed_attempts(conn, row["id_usuario"])
    token = create_access_token(row["id_usuario"], row["tipo_perfil"])
    return _row_to_user_dto(row), token


async def get_current_user_dto(conn: Connection, id_usuario: int) -> UserDto:
    row = await user_repository.find_by_id(conn, id_usuario)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="USER_NOT_FOUND")
    return _row_to_user_dto(row)


async def recover_password(conn: Connection, *, email: str) -> None:
    # El envío de email está fuera de alcance de esta iteración (no hay
    # proveedor SMTP configurado); el endpoint responde 204 sin filtrar
    # si el email existe o no, para no revelar cuentas registradas.
    return None
