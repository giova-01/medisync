from datetime import date, time

from aiomysql import Connection

HORA_BASE = time(8, 0, 0)


def build_schedule_times(frecuencia_horas: int) -> list[time]:
    """Reparte las tomas diarias cada `frecuencia_horas`, comenzando a las
    08:00 (criterio elegido y documentado en README.md del backend)."""
    cantidad = max(1, 24 // frecuencia_horas)
    horarios = []
    base_minutes = HORA_BASE.hour * 60 + HORA_BASE.minute
    for i in range(cantidad):
        total_minutes = (base_minutes + i * frecuencia_horas * 60) % (24 * 60)
        horarios.append(time(total_minutes // 60, total_minutes % 60))
    return horarios


async def list_active_for_patient(conn: Connection, id_paciente: int) -> list[dict]:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT * FROM medicamentos
            WHERE id_paciente = %s AND (fecha_fin IS NULL OR fecha_fin >= CURDATE())
            ORDER BY creado_en DESC
            """,
            (id_paciente,),
        )
        return await cur.fetchall()


async def find_by_id(conn: Connection, id_medicamento: int) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute("SELECT * FROM medicamentos WHERE id_medicamento = %s", (id_medicamento,))
        return await cur.fetchone()


async def list_overlapping(conn: Connection, id_paciente: int, horarios: list[time], exclude_id: int | None = None) -> list[dict]:
    async with conn.cursor() as cur:
        query = """
            SELECT DISTINCT m.* FROM medicamentos m
            JOIN horarios h ON h.id_medicamento = m.id_medicamento AND h.activo = TRUE
            WHERE m.id_paciente = %s AND (m.fecha_fin IS NULL OR m.fecha_fin >= CURDATE())
              AND h.hora_del_dia IN ({})
        """.format(",".join(["%s"] * len(horarios)))
        params = [id_paciente, *horarios]
        if exclude_id is not None:
            query += " AND m.id_medicamento != %s"
            params.append(exclude_id)
        await cur.execute(query, params)
        return await cur.fetchall()


async def create_medication(
    conn: Connection,
    *,
    id_paciente: int,
    id_profesional_creador: int,
    nombre: str,
    dosis: str,
    frecuencia_horas: int,
    fecha_inicio: date,
    fecha_fin: date | None,
) -> int:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO medicamentos
                (id_paciente, id_profesional_creador, nombre, dosis, frecuencia_horas, fecha_inicio, fecha_fin)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (id_paciente, id_profesional_creador, nombre, dosis, frecuencia_horas, fecha_inicio, fecha_fin),
        )
        return cur.lastrowid


async def update_medication(
    conn: Connection,
    id_medicamento: int,
    *,
    nombre: str,
    dosis: str,
    frecuencia_horas: int,
    fecha_inicio: date,
    fecha_fin: date | None,
) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE medicamentos
            SET nombre = %s, dosis = %s, frecuencia_horas = %s, fecha_inicio = %s, fecha_fin = %s
            WHERE id_medicamento = %s
            """,
            (nombre, dosis, frecuencia_horas, fecha_inicio, fecha_fin, id_medicamento),
        )


async def set_fecha_fin(conn: Connection, id_medicamento: int, fecha_fin: date) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            "UPDATE medicamentos SET fecha_fin = %s WHERE id_medicamento = %s",
            (fecha_fin, id_medicamento),
        )


async def deactivate_schedules(conn: Connection, id_medicamento: int) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            "UPDATE horarios SET activo = FALSE WHERE id_medicamento = %s", (id_medicamento,)
        )


async def create_schedule(conn: Connection, id_medicamento: int, hora_del_dia: time) -> int:
    async with conn.cursor() as cur:
        await cur.execute(
            "INSERT INTO horarios (id_medicamento, hora_del_dia, activo) VALUES (%s, %s, TRUE)",
            (id_medicamento, hora_del_dia),
        )
        return cur.lastrowid


async def list_active_schedules(conn: Connection, id_medicamento: int) -> list[dict]:
    async with conn.cursor() as cur:
        await cur.execute(
            "SELECT * FROM horarios WHERE id_medicamento = %s AND activo = TRUE", (id_medicamento,)
        )
        return await cur.fetchall()


async def list_active_schedules_for_patient(conn: Connection, id_paciente: int) -> list[dict]:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT h.*, m.nombre AS nombre_medicamento, m.dosis AS dosis
            FROM horarios h
            JOIN medicamentos m ON m.id_medicamento = h.id_medicamento
            WHERE h.activo = TRUE AND m.id_paciente = %s
              AND (m.fecha_fin IS NULL OR m.fecha_fin >= CURDATE())
            """,
            (id_paciente,),
        )
        return await cur.fetchall()
