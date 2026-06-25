from datetime import datetime, timedelta

from app.core.config import settings
from app.core.db import get_pool
from app.repositories import intake_repository
from app.services import alerts_service


async def auto_omit_overdue_intakes() -> None:
    """Job en background (ver apscheduler en app/main.py): recorre tomas
    PENDIENTE/POSPUESTA vencidas hace más de `intake_auto_omit_minutes` y
    las marca OMITIDA, generando una alerta para el paciente y sus
    vinculados (HU-009, criterio 3)."""
    pool = get_pool()
    cutoff = datetime.now() - timedelta(minutes=settings.intake_auto_omit_minutes)
    async with pool.acquire() as conn:
        overdue = await intake_repository.list_overdue(conn, older_than=cutoff)
        for toma in overdue:
            await intake_repository.mark_omitted(conn, toma["id_toma"])
            await alerts_service.dispatch_alert(
                conn,
                id_paciente=toma["id_paciente"],
                tipo_db="TOMA_OMITIDA",
                severidad_db="WARNING",
                titulo="Toma omitida",
                mensaje="Una toma de medicación no fue confirmada a tiempo y se marcó como omitida.",
                id_toma=toma["id_toma"],
                notify_patient=True,
            )
