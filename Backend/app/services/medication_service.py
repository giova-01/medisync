from datetime import date

from aiomysql import Connection

from app.repositories import medication_repository
from app.schemas.medication import (
    CreateMedicationRequest,
    MedicamentoCreateResponse,
    MedicamentoDto,
    UpdateMedicationRequest,
)


def _row_to_dto(row: dict) -> MedicamentoDto:
    return MedicamentoDto(
        id=row["id_medicamento"],
        nombre=row["nombre"],
        dosis=row["dosis"],
        frecuencia_horas=row["frecuencia_horas"],
        fecha_inicio=row["fecha_inicio"],
        fecha_fin=row["fecha_fin"],
    )


async def list_medications(conn: Connection, id_paciente: int) -> list[MedicamentoDto]:
    rows = await medication_repository.list_active_for_patient(conn, id_paciente)
    return [_row_to_dto(row) for row in rows]


async def _check_overlap_warning(
    conn: Connection, id_paciente: int, horarios: list, exclude_id: int | None
) -> str | None:
    overlapping = await medication_repository.list_overlapping(conn, id_paciente, horarios, exclude_id)
    if overlapping:
        nombres = ", ".join(m["nombre"] for m in overlapping)
        return f"Este horario se superpone con: {nombres}."
    return None


async def add_medication(
    conn: Connection, *, id_paciente: int, id_profesional_creador: int, body: CreateMedicationRequest
) -> MedicamentoCreateResponse:
    horarios = medication_repository.build_schedule_times(body.frecuencia_horas)
    advertencia = await _check_overlap_warning(conn, id_paciente, horarios, exclude_id=None)

    id_medicamento = await medication_repository.create_medication(
        conn,
        id_paciente=id_paciente,
        id_profesional_creador=id_profesional_creador,
        nombre=body.nombre,
        dosis=body.dosis,
        frecuencia_horas=body.frecuencia_horas,
        fecha_inicio=body.fecha_inicio,
        fecha_fin=body.fecha_fin,
    )
    for hora in horarios:
        await medication_repository.create_schedule(conn, id_medicamento, hora)

    row = await medication_repository.find_by_id(conn, id_medicamento)
    dto = _row_to_dto(row)
    return MedicamentoCreateResponse(**dto.model_dump(), advertencia=advertencia)


async def update_medication(
    conn: Connection, *, id_medicamento: int, body: UpdateMedicationRequest
) -> MedicamentoCreateResponse:
    row = await medication_repository.find_by_id(conn, id_medicamento)
    horarios = medication_repository.build_schedule_times(body.frecuencia_horas)
    advertencia = await _check_overlap_warning(
        conn, row["id_paciente"], horarios, exclude_id=id_medicamento
    )

    await medication_repository.update_medication(
        conn,
        id_medicamento,
        nombre=body.nombre,
        dosis=body.dosis,
        frecuencia_horas=body.frecuencia_horas,
        fecha_inicio=body.fecha_inicio,
        fecha_fin=body.fecha_fin,
    )
    # Regenera los horarios activos: las tomas ya generadas en el pasado
    # quedan intactas porque tomas_medicacion no se borra al desactivar
    # un horario (FK ON DELETE CASCADE solo dispara si se borra el horario).
    await medication_repository.deactivate_schedules(conn, id_medicamento)
    for hora in horarios:
        await medication_repository.create_schedule(conn, id_medicamento, hora)

    row = await medication_repository.find_by_id(conn, id_medicamento)
    dto = _row_to_dto(row)
    return MedicamentoCreateResponse(**dto.model_dump(), advertencia=advertencia)


async def remove_medication(conn: Connection, *, id_medicamento: int, fecha_fin: date | None) -> None:
    fecha_fin = fecha_fin or date.today()
    await medication_repository.set_fecha_fin(conn, id_medicamento, fecha_fin)
    await medication_repository.deactivate_schedules(conn, id_medicamento)
