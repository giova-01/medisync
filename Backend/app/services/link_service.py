from aiomysql import Connection
from fastapi import HTTPException, status

from app.core.enums import (
    ESTADO_VINCULO_TO_API,
    TIPO_VINCULO_FROM_API,
    TIPO_VINCULO_TO_API,
)
from app.repositories import link_repository, user_repository
from app.schemas.links import VinculoDto
from app.services import alerts_service


def _row_to_vinculo_dto(row: dict) -> VinculoDto:
    return VinculoDto(
        id=row["id_vinculo"],
        id_paciente=row["id_paciente"],
        id_usuario_vinculado=row["id_usuario_vinculado"],
        email_usuario_vinculado=row["email_usuario_vinculado"],
        nombre_usuario_vinculado=row["nombre_usuario_vinculado"],
        apellido_usuario_vinculado=row["apellido_usuario_vinculado"],
        tipo_vinculo=TIPO_VINCULO_TO_API[row["tipo_vinculo"]],
        estado=ESTADO_VINCULO_TO_API[row["estado"]],
    )


async def list_links(conn: Connection, id_usuario: int, tipo_perfil_db: str) -> list[VinculoDto]:
    rows = await link_repository.list_for_user(conn, id_usuario, tipo_perfil_db)
    return [_row_to_vinculo_dto(row) for row in rows]


async def request_link(
    conn: Connection, *, id_solicitante: int, target_email: str, rol_api: str
) -> VinculoDto:
    paciente = await user_repository.find_by_email(conn, target_email)
    if paciente is None or paciente["tipo_perfil"] != "PACIENTE":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="EMAIL_NOT_FOUND")

    tipo_vinculo_db = TIPO_VINCULO_FROM_API[rol_api]
    id_vinculo = await link_repository.create_link(
        conn,
        id_paciente=paciente["id_usuario"],
        id_usuario_vinculado=id_solicitante,
        tipo_vinculo_db=tipo_vinculo_db,
    )

    await alerts_service.dispatch_alert(
        conn,
        id_paciente=paciente["id_usuario"],
        tipo_db="VINCULO_SOLICITADO",
        severidad_db="INFO",
        titulo="Solicitud de vínculo",
        mensaje="Recibiste una nueva solicitud de vínculo.",
        id_vinculo=id_vinculo,
        notify_patient=True,
    )

    row = await link_repository.find_by_id(conn, id_vinculo)
    solicitante = await user_repository.find_by_id(conn, id_solicitante)
    row["email_usuario_vinculado"] = solicitante["email"]
    row["nombre_usuario_vinculado"] = solicitante["nombre"]
    row["apellido_usuario_vinculado"] = solicitante["apellido"]
    return _row_to_vinculo_dto(row)


async def _enrich_with_vinculado(conn: Connection, row: dict) -> dict:
    vinculado = await user_repository.find_by_id(conn, row["id_usuario_vinculado"])
    row["email_usuario_vinculado"] = vinculado["email"]
    row["nombre_usuario_vinculado"] = vinculado["nombre"]
    row["apellido_usuario_vinculado"] = vinculado["apellido"]
    return row


async def respond_link(conn: Connection, *, id_vinculo: int, id_paciente: int, aceptar: bool) -> VinculoDto:
    row = await link_repository.find_by_id(conn, id_vinculo)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="VINCULO_NOT_FOUND")
    if row["id_paciente"] != id_paciente:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="NOT_LINK_OWNER")

    nuevo_estado = "ACEPTADO" if aceptar else "RECHAZADO"
    await link_repository.update_estado(conn, id_vinculo, nuevo_estado)

    row = await link_repository.find_by_id(conn, id_vinculo)
    row = await _enrich_with_vinculado(conn, row)
    return _row_to_vinculo_dto(row)


async def revoke_link(conn: Connection, *, id_vinculo: int, id_paciente: int) -> None:
    row = await link_repository.find_by_id(conn, id_vinculo)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="VINCULO_NOT_FOUND")
    if row["id_paciente"] != id_paciente:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="NOT_LINK_OWNER")
    await link_repository.update_estado(conn, id_vinculo, "REVOCADO")
