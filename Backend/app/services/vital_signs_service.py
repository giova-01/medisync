from datetime import datetime, timedelta

from aiomysql import Connection
from fastapi import HTTPException, status

from app.core.config import settings
from app.core.enums import (
    TIPO_SIGNO_VITAL_FRECUENCIA_CARDIACA,
    TIPO_SIGNO_VITAL_SATURACION_OXIGENO,
)
from app.core.ws import vital_signs_ws_manager
from app.repositories import device_repository, link_repository, vital_signs_repository
from app.schemas.vital_signs import CreateVitalSignRequest, SignoVitalDto
from app.services import alerts_service

HR_SUSTAINED_WINDOW_MINUTES = 10
HR_MIN_NORMAL = 60
HR_MAX_NORMAL = 100


def decompose_row(row: dict) -> list[SignoVitalDto]:
    """Una fila de `signos_vitales` (FC + SpO2 del mismo muestreo PPG) se
    expone como dos SignoVitalDto separados, tal como espera el frontend.
    Ambos comparten `id` (el id_signo de origen) ya que provienen del
    mismo evento de medición; se distinguen por `tipo`."""
    return [
        SignoVitalDto(
            id=row["id_signo"],
            tipo=TIPO_SIGNO_VITAL_FRECUENCIA_CARDIACA,
            valor=float(row["frecuencia_cardiaca"]),
            fecha_medicion=row["registrado_en"],
        ),
        SignoVitalDto(
            id=row["id_signo"],
            tipo=TIPO_SIGNO_VITAL_SATURACION_OXIGENO,
            valor=float(row["spo2"]),
            fecha_medicion=row["registrado_en"],
        ),
    ]


async def get_latest(conn: Connection, id_paciente: int) -> list[SignoVitalDto]:
    row = await vital_signs_repository.find_latest(conn, id_paciente)
    if row is None:
        return []
    return decompose_row(row)


async def get_history(
    conn: Connection, id_paciente: int, *, tipo: str | None, desde: datetime, hasta: datetime
) -> list[SignoVitalDto]:
    rows = await vital_signs_repository.find_history(conn, id_paciente, desde=desde, hasta=hasta)
    readings: list[SignoVitalDto] = []
    for row in rows:
        readings.extend(decompose_row(row))
    if tipo is not None:
        readings = [r for r in readings if r.tipo == tipo]
    return readings


async def _evaluate_spo2_threshold(conn: Connection, id_paciente: int, id_signo: int, spo2: float) -> None:
    if spo2 < 90:
        await alerts_service.dispatch_alert(
            conn,
            id_paciente=id_paciente,
            tipo_db="SIGNO_VITAL_CRITICO",
            severidad_db="CRITICAL",
            titulo="Saturación de oxígeno crítica",
            mensaje=f"Se registró una saturación de oxígeno de {spo2}%, por debajo del rango seguro.",
            id_signo=id_signo,
        )
    elif spo2 < 94:
        await alerts_service.dispatch_alert(
            conn,
            id_paciente=id_paciente,
            tipo_db="SIGNO_VITAL_CRITICO",
            severidad_db="WARNING",
            titulo="Saturación de oxígeno baja",
            mensaje=f"Se registró una saturación de oxígeno de {spo2}%, por debajo del rango normal.",
            id_signo=id_signo,
        )


async def _evaluate_heart_rate_sustained(
    conn: Connection, id_paciente: int, id_signo: int, registrado_en: datetime
) -> None:
    since = registrado_en - timedelta(minutes=HR_SUSTAINED_WINDOW_MINUTES)
    recientes = await vital_signs_repository.find_since(conn, id_paciente, since=since)
    if len(recientes) < 2:
        return
    fuera_de_rango = all(
        r["frecuencia_cardiaca"] < HR_MIN_NORMAL or r["frecuencia_cardiaca"] > HR_MAX_NORMAL
        for r in recientes
    )
    if fuera_de_rango:
        await alerts_service.dispatch_alert(
            conn,
            id_paciente=id_paciente,
            tipo_db="SIGNO_VITAL_CRITICO",
            severidad_db="WARNING",
            titulo="Frecuencia cardíaca fuera de rango",
            mensaje=(
                f"La frecuencia cardíaca se mantuvo fuera del rango normal "
                f"(60-100 lpm) por más de {HR_SUSTAINED_WINDOW_MINUTES} minutos."
            ),
            id_signo=id_signo,
        )


async def record_reading(
    conn: Connection, *, id_paciente: int, body: CreateVitalSignRequest
) -> list[SignoVitalDto]:
    if body.calidad_senal < settings.vital_sign_min_quality:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="LOW_SIGNAL_QUALITY")

    device = await device_repository.find_by_patient(conn, id_paciente)
    if device is None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="NO_DEVICE_LINKED")

    id_signo = await vital_signs_repository.create_reading(
        conn,
        id_paciente=id_paciente,
        id_dispositivo=device["id_dispositivo"],
        frecuencia_cardiaca=body.frecuencia_cardiaca,
        spo2=body.spo2,
        calidad_senal=body.calidad_senal,
        registrado_en=body.registrado_en,
    )

    await _evaluate_spo2_threshold(conn, id_paciente, id_signo, body.spo2)
    await _evaluate_heart_rate_sustained(conn, id_paciente, id_signo, body.registrado_en)

    row = await vital_signs_repository.find_by_id(conn, id_signo)
    readings = decompose_row(row)

    recipient_ids = [id_paciente] + await link_repository.list_accepted_recipients(conn, id_paciente)
    for reading in readings:
        await vital_signs_ws_manager.send_to_users(recipient_ids, reading.model_dump(mode="json"))

    return readings
