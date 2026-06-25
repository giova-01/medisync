from datetime import datetime

from aiomysql import Connection


async def create_reading(
    conn: Connection,
    *,
    id_paciente: int,
    id_dispositivo: int,
    frecuencia_cardiaca: int,
    spo2: float,
    calidad_senal: int,
    registrado_en: datetime,
) -> int:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO signos_vitales
                (id_paciente, id_dispositivo, frecuencia_cardiaca, spo2, calidad_senal, registrado_en)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (id_paciente, id_dispositivo, frecuencia_cardiaca, spo2, calidad_senal, registrado_en),
        )
        return cur.lastrowid


async def find_by_id(conn: Connection, id_signo: int) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute("SELECT * FROM signos_vitales WHERE id_signo = %s", (id_signo,))
        return await cur.fetchone()


async def find_latest(conn: Connection, id_paciente: int) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT * FROM signos_vitales WHERE id_paciente = %s
            ORDER BY registrado_en DESC LIMIT 1
            """,
            (id_paciente,),
        )
        return await cur.fetchone()


async def find_history(
    conn: Connection, id_paciente: int, *, desde: datetime, hasta: datetime
) -> list[dict]:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT * FROM signos_vitales
            WHERE id_paciente = %s AND registrado_en BETWEEN %s AND %s
            ORDER BY registrado_en ASC
            """,
            (id_paciente, desde, hasta),
        )
        return await cur.fetchall()


async def find_since(conn: Connection, id_paciente: int, *, since: datetime) -> list[dict]:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT * FROM signos_vitales
            WHERE id_paciente = %s AND registrado_en >= %s
            ORDER BY registrado_en ASC
            """,
            (id_paciente, since),
        )
        return await cur.fetchall()
