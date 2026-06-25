from aiomysql import Connection


async def create_alert(
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
) -> int:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO alertas (id_paciente, tipo, severidad, titulo, mensaje, id_toma, id_signo, id_vinculo)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (id_paciente, tipo_db, severidad_db, titulo, mensaje, id_toma, id_signo, id_vinculo),
        )
        return cur.lastrowid


async def add_recipients(conn: Connection, id_alerta: int, recipient_ids: list[int]) -> None:
    if not recipient_ids:
        return
    async with conn.cursor() as cur:
        await cur.executemany(
            "INSERT INTO alertas_destinatarios (id_alerta, id_usuario) VALUES (%s, %s)",
            [(id_alerta, uid) for uid in recipient_ids],
        )


async def find_by_id(conn: Connection, id_alerta: int) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute("SELECT * FROM alertas WHERE id_alerta = %s", (id_alerta,))
        return await cur.fetchone()


async def list_for_user(conn: Connection, id_usuario: int) -> list[dict]:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT a.*, ad.leida, ad.fecha_leida
            FROM alertas a
            JOIN alertas_destinatarios ad ON ad.id_alerta = a.id_alerta
            WHERE ad.id_usuario = %s
            ORDER BY a.creado_en DESC
            """,
            (id_usuario,),
        )
        return await cur.fetchall()


async def find_recipient_row(conn: Connection, id_alerta: int, id_usuario: int) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute(
            "SELECT * FROM alertas_destinatarios WHERE id_alerta = %s AND id_usuario = %s",
            (id_alerta, id_usuario),
        )
        return await cur.fetchone()


async def mark_read(conn: Connection, id_alerta: int, id_usuario: int) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE alertas_destinatarios SET leida = TRUE, fecha_leida = NOW()
            WHERE id_alerta = %s AND id_usuario = %s
            """,
            (id_alerta, id_usuario),
        )


async def mark_all_read(conn: Connection, id_usuario: int) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE alertas_destinatarios SET leida = TRUE, fecha_leida = NOW()
            WHERE id_usuario = %s AND leida = FALSE
            """,
            (id_usuario,),
        )


async def acknowledge(conn: Connection, id_alerta: int, id_usuario_reconocio: int) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE alertas SET id_usuario_reconocio = %s, fecha_reconocimiento = NOW()
            WHERE id_alerta = %s
            """,
            (id_usuario_reconocio, id_alerta),
        )
