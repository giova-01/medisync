from aiomysql import Connection
from fastapi import HTTPException, status

from app.core.enums import TIPO_PERFIL_TO_API
from app.repositories import user_repository
from app.schemas.profile import ProfileResponse, UpdateProfileRequest


def _row_to_profile(row: dict) -> ProfileResponse:
    return ProfileResponse(
        id=row["id_usuario"],
        email=row["email"],
        nombre=row["nombre"],
        apellido=row["apellido"],
        tipo_perfil=TIPO_PERFIL_TO_API[row["tipo_perfil"]],
        fecha_nacimiento=row["fecha_nacimiento"],
        patologias=row["patologias"],
        parentesco=row["parentesco"],
        matricula=row["matricula"],
        especialidad=row["especialidad"],
    )


async def get_profile(conn: Connection, id_usuario: int) -> ProfileResponse:
    row = await user_repository.find_by_id(conn, id_usuario)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="USER_NOT_FOUND")
    return _row_to_profile(row)


async def update_profile(conn: Connection, id_usuario: int, body: UpdateProfileRequest) -> ProfileResponse:
    await user_repository.update_profile(
        conn,
        id_usuario,
        nombre=body.nombre,
        apellido=body.apellido,
        fecha_nacimiento=body.fecha_nacimiento,
        patologias=body.patologias,
        parentesco=body.parentesco,
        matricula=body.matricula,
        especialidad=body.especialidad,
    )
    return await get_profile(conn, id_usuario)
