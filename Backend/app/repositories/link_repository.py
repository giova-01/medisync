from aiomysql import Connection


async def find_by_id(conn: Connection, id_vinculo: int) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute("SELECT * FROM vinculos WHERE id_vinculo = %s", (id_vinculo,))
        return await cur.fetchone()


async def list_for_user(conn: Connection, id_usuario: int, tipo_perfil_db: str) -> list[dict]:
    """Vínculos visibles para este usuario: si es PACIENTE, los suyos como
    paciente; si es CUIDADOR/PROFESIONAL_SALUD, aquellos en los que figura
    como vinculado."""
    async with conn.cursor() as cur:
        if tipo_perfil_db == "PACIENTE":
            await cur.execute(
                """
                SELECT v.*, u.email AS email_usuario_vinculado, u.nombre AS nombre_usuario_vinculado,
                       u.apellido AS apellido_usuario_vinculado
                FROM vinculos v
                JOIN usuarios u ON u.id_usuario = v.id_usuario_vinculado
                WHERE v.id_paciente = %s
                ORDER BY v.creado_en DESC
                """,
                (id_usuario,),
            )
        else:
            await cur.execute(
                """
                SELECT v.*, u.email AS email_usuario_vinculado, u.nombre AS nombre_usuario_vinculado,
                       u.apellido AS apellido_usuario_vinculado
                FROM vinculos v
                JOIN usuarios u ON u.id_usuario = v.id_usuario_vinculado
                WHERE v.id_usuario_vinculado = %s
                ORDER BY v.creado_en DESC
                """,
                (id_usuario,),
            )
        return await cur.fetchall()


async def create_link(
    conn: Connection, *, id_paciente: int, id_usuario_vinculado: int, tipo_vinculo_db: str
) -> int:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO vinculos (id_paciente, id_usuario_vinculado, tipo_vinculo, estado)
            VALUES (%s, %s, %s, 'PENDIENTE')
            """,
            (id_paciente, id_usuario_vinculado, tipo_vinculo_db),
        )
        return cur.lastrowid


async def update_estado(conn: Connection, id_vinculo: int, estado_db: str) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            "UPDATE vinculos SET estado = %s WHERE id_vinculo = %s", (estado_db, id_vinculo)
        )


async def find_accepted_link(conn: Connection, id_paciente: int, id_usuario_vinculado: int) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT * FROM vinculos
            WHERE id_paciente = %s AND id_usuario_vinculado = %s AND estado = 'ACEPTADO'
            """,
            (id_paciente, id_usuario_vinculado),
        )
        return await cur.fetchone()


async def list_accepted_recipients(conn: Connection, id_paciente: int) -> list[int]:
    """IDs de Cuidadores/Profesionales con vínculo ACEPTADO sobre este paciente."""
    async with conn.cursor() as cur:
        await cur.execute(
            "SELECT id_usuario_vinculado FROM vinculos WHERE id_paciente = %s AND estado = 'ACEPTADO'",
            (id_paciente,),
        )
        rows = await cur.fetchall()
        return [r["id_usuario_vinculado"] for r in rows]
