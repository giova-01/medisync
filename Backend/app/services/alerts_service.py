from aiomysql import Connection
from fastapi import HTTPException, status

from app.core.enums import SEVERIDAD_ALERTA_TO_API, TIPO_ALERTA_TO_API
from app.core.ws import alerts_ws_manager
from app.repositories import alert_repository, link_repository
from app.schemas.alerts import AlertaDto


def _row_to_alerta_dto(row: dict, *, leida: bool = False) -> AlertaDto:
    return AlertaDto(
        id=row["id_alerta"],
        tipo=TIPO_ALERTA_TO_API[row["tipo"]],
        severidad=SEVERIDAD_ALERTA_TO_API[row["severidad"]],
        titulo=row["titulo"],
        mensaje=row["mensaje"],
        fecha_creacion=row["creado_en"],
        leida=leida,
    )


async def dispatch_alert(
    conn: Connection,
    *,
    id_paciente: int,
    tipo_db: str,
    severidad_db: str,
    titulo: str,
    mensaje: str,
    id_toma: int | None = None,
    id_signo: int | None = None,
    id_vinculo: int | None = None,
    notify_patient: bool = True,
) -> int:
    """Crea la alerta, la notifica al paciente y a sus Cuidadores/Profesionales
    con vínculo ACEPTADO, e intenta el push por WebSocket a los conectados."""
    id_alerta = await alert_repository.create_alert(
        conn,
        id_paciente=id_paciente,
        tipo_db=tipo_db,
        severidad_db=severidad_db,
        titulo=titulo,
        mensaje=mensaje,
        id_toma=id_toma,
        id_signo=id_signo,
        id_vinculo=id_vinculo,
    )

    recipient_ids = await link_repository.list_accepted_recipients(conn, id_paciente)
    if notify_patient:
        recipient_ids = [id_paciente] + recipient_ids
    await alert_repository.add_recipients(conn, id_alerta, recipient_ids)

    row = await alert_repository.find_by_id(conn, id_alerta)
    dto = _row_to_alerta_dto(row, leida=False)
    await alerts_ws_manager.send_to_users(recipient_ids, dto.model_dump(mode="json"))

    return id_alerta


async def get_alerts(conn: Connection, id_usuario: int) -> list[AlertaDto]:
    rows = await alert_repository.list_for_user(conn, id_usuario)
    return [_row_to_alerta_dto(row, leida=bool(row["leida"])) for row in rows]


async def mark_as_read(conn: Connection, id_alerta: int, id_usuario: int) -> None:
    recipient_row = await alert_repository.find_recipient_row(conn, id_alerta, id_usuario)
    if recipient_row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="ALERT_NOT_FOUND")
    await alert_repository.mark_read(conn, id_alerta, id_usuario)


async def mark_all_as_read(conn: Connection, id_usuario: int) -> None:
    await alert_repository.mark_all_read(conn, id_usuario)


async def acknowledge_alert(conn: Connection, id_alerta: int, id_usuario_reconocio: int) -> AlertaDto:
    row = await alert_repository.find_by_id(conn, id_alerta)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="ALERT_NOT_FOUND")
    await alert_repository.acknowledge(conn, id_alerta, id_usuario_reconocio)
    row = await alert_repository.find_by_id(conn, id_alerta)
    recipient_row = await alert_repository.find_recipient_row(conn, id_alerta, id_usuario_reconocio)
    leida = bool(recipient_row["leida"]) if recipient_row else False
    return _row_to_alerta_dto(row, leida=leida)
