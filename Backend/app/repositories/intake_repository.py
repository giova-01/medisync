from datetime import date, datetime

from aiomysql import Connection


async def find_by_id(conn: Connection, id_toma: int) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT t.*, m.nombre AS nombre_medicamento, m.dosis AS dosis, m.id_paciente AS id_paciente
            FROM tomas_medicacion t
            JOIN horarios h ON h.id_horario = t.id_horario
            JOIN medicamentos m ON m.id_medicamento = h.id_medicamento
            WHERE t.id_toma = %s
            """,
            (id_toma,),
        )
        return await cur.fetchone()


async def exists_for_schedule_on_date(conn: Connection, id_horario: int, dia: date) -> bool:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT 1 FROM tomas_medicacion
            WHERE id_horario = %s AND DATE(fecha_programada) = %s
            LIMIT 1
            """,
            (id_horario, dia),
        )
        return await cur.fetchone() is not None


async def create_intake(
    conn: Connection, *, id_horario: int, fecha_programada: datetime, origen: str
) -> int:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO tomas_medicacion (id_horario, fecha_programada, estado, origen)
            VALUES (%s, %s, 'PENDIENTE', %s)
            """,
            (id_horario, fecha_programada, origen),
        )
        return cur.lastrowid


async def list_for_patient_on_date(conn: Connection, id_paciente: int, dia: date) -> list[dict]:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT t.*, m.nombre AS nombre_medicamento, m.dosis AS dosis
            FROM tomas_medicacion t
            JOIN horarios h ON h.id_horario = t.id_horario
            JOIN medicamentos m ON m.id_medicamento = h.id_medicamento
            WHERE m.id_paciente = %s AND DATE(t.fecha_programada) = %s
            ORDER BY t.fecha_programada ASC
            """,
            (id_paciente, dia),
        )
        return await cur.fetchall()


async def confirm(conn: Connection, id_toma: int) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE tomas_medicacion
            SET estado = 'CONFIRMADA', fecha_confirmada = NOW(), origen = 'APP_PACIENTE'
            WHERE id_toma = %s
            """,
            (id_toma,),
        )


async def postpone(conn: Connection, id_toma: int, minutos: int) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE tomas_medicacion
            SET estado = 'POSPUESTA', fecha_programada = fecha_programada + INTERVAL %s MINUTE
            WHERE id_toma = %s
            """,
            (minutos, id_toma),
        )


async def list_overdue(conn: Connection, *, older_than: datetime) -> list[dict]:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT t.*, m.id_paciente AS id_paciente
            FROM tomas_medicacion t
            JOIN horarios h ON h.id_horario = t.id_horario
            JOIN medicamentos m ON m.id_medicamento = h.id_medicamento
            WHERE t.estado IN ('PENDIENTE', 'POSPUESTA') AND t.fecha_programada < %s
            """,
            (older_than,),
        )
        return await cur.fetchall()


async def mark_omitted(conn: Connection, id_toma: int) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            "UPDATE tomas_medicacion SET estado = 'OMITIDA', origen = 'AUTO_SISTEMA' WHERE id_toma = %s",
            (id_toma,),
        )
