from aiomysql import Connection
from fastapi import HTTPException, status

from app.repositories import device_repository
from app.schemas.devices import DeviceDto, LinkDeviceRequest


def _row_to_dto(row: dict) -> DeviceDto:
    return DeviceDto(
        id=row["mac_address"],
        name=row["nombre"] or row["mac_address"],
        rssi=0,  # el RSSI es local a la sesión BLE del teléfono; no se persiste
        is_connected=row["id_paciente"] is not None,
    )


async def get_my_device(conn: Connection, id_paciente: int) -> DeviceDto | None:
    row = await device_repository.find_by_patient(conn, id_paciente)
    if row is None:
        return None
    return _row_to_dto(row)


async def link_device(conn: Connection, *, id_paciente: int, body: LinkDeviceRequest) -> DeviceDto:
    existing = await device_repository.find_by_mac(conn, body.mac_address)
    if existing is None:
        id_dispositivo = await device_repository.create_unlinked(
            conn,
            mac_address=body.mac_address,
            nombre=body.nombre,
            firmware_version=body.firmware_version,
            nivel_bateria=body.nivel_bateria,
        )
    else:
        if existing["id_paciente"] is not None and existing["id_paciente"] != id_paciente:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="DEVICE_ALREADY_LINKED")
        id_dispositivo = existing["id_dispositivo"]

    await device_repository.link_to_patient(
        conn,
        id_dispositivo,
        id_paciente,
        nombre=body.nombre,
        firmware_version=body.firmware_version,
        nivel_bateria=body.nivel_bateria,
    )
    row = await device_repository.find_by_id(conn, id_dispositivo)
    return _row_to_dto(row)


async def unlink_device(conn: Connection, id_paciente: int) -> None:
    await device_repository.unlink_patient(conn, id_paciente)
