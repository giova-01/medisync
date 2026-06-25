from datetime import date, datetime, time, timedelta

from aiomysql import Connection
from fastapi import HTTPException, status

from app.core.config import settings
from app.repositories import intake_repository, medication_repository
from app.schemas.medication import TomaDto


def _as_time(valor: time | timedelta) -> time:
    """aiomysql decodifica las columnas TIME como `datetime.timedelta`
    (MySQL permite TIME > 24h), nunca como `datetime.time`. Convertimos
    explícitamente antes de cualquier `datetime.combine`."""
    if isinstance(valor, timedelta):
        total_segundos = int(valor.total_seconds())
        return time(
            (total_segundos // 3600) % 24,
            (total_segundos % 3600) // 60,
            total_segundos % 60,
        )
    return valor


def _row_to_dto(row: dict) -> TomaDto:
    return TomaDto(
        id=row["id_toma"],
        fecha_programada=row["fecha_programada"],
        fecha_confirmada=row["fecha_confirmada"],
        estado=row["estado"].lower(),
        horario_id=row["id_horario"],
        nombre_medicamento=row["nombre_medicamento"],
        dosis=row["dosis"],
    )


async def get_daily_intakes(conn: Connection, *, id_paciente: int, dia: date) -> list[TomaDto]:
    """Genera (si faltan) las tomas del día a partir de los horarios activos
    del paciente, de forma idempotente, y las devuelve ordenadas."""
    schedules = await medication_repository.list_active_schedules_for_patient(conn, id_paciente)
    for schedule in schedules:
        ya_existe = await intake_repository.exists_for_schedule_on_date(
            conn, schedule["id_horario"], dia
        )
        if not ya_existe:
            fecha_programada = datetime.combine(dia, _as_time(schedule["hora_del_dia"]))
            await intake_repository.create_intake(
                conn, id_horario=schedule["id_horario"], fecha_programada=fecha_programada, origen="AUTO_SISTEMA"
            )

    rows = await intake_repository.list_for_patient_on_date(conn, id_paciente, dia)
    return [_row_to_dto(row) for row in rows]


async def confirm_intake(conn: Connection, id_toma: int) -> TomaDto:
    row = await intake_repository.find_by_id(conn, id_toma)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="INTAKE_NOT_FOUND")
    if row["estado"] == "CONFIRMADA":
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="INTAKE_ALREADY_CONFIRMED")

    await intake_repository.confirm(conn, id_toma)
    row = await intake_repository.find_by_id(conn, id_toma)
    return _row_to_dto(row)


async def postpone_intake(conn: Connection, id_toma: int) -> TomaDto:
    row = await intake_repository.find_by_id(conn, id_toma)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="INTAKE_NOT_FOUND")
    if row["estado"] == "POSPUESTA":
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="INTAKE_ALREADY_POSTPONED")
    if row["estado"] == "CONFIRMADA":
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="INTAKE_ALREADY_CONFIRMED")

    await intake_repository.postpone(conn, id_toma, settings.intake_postpone_minutes)
    row = await intake_repository.find_by_id(conn, id_toma)
    return _row_to_dto(row)
