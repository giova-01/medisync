from aiomysql import Connection


async def find_by_email(conn: Connection, email: str) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute("SELECT * FROM usuarios WHERE email = %s", (email,))
        return await cur.fetchone()


async def find_by_id(conn: Connection, id_usuario: int) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute("SELECT * FROM usuarios WHERE id_usuario = %s", (id_usuario,))
        return await cur.fetchone()


async def create_user(
    conn: Connection,
    *,
    email: str,
    password_hash: str,
    nombre: str,
    apellido: str,
    tipo_perfil_db: str,
) -> int:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO usuarios (email, password_hash, nombre, apellido, tipo_perfil)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (email, password_hash, nombre, apellido, tipo_perfil_db),
        )
        return cur.lastrowid


async def register_failed_attempt(conn: Connection, id_usuario: int, *, lock_until_on_5th) -> int:
    """Incrementa intentos_fallidos; si llega a 5, fija bloqueado_hasta.
    Devuelve el nuevo valor de intentos_fallidos."""
    async with conn.cursor() as cur:
        await cur.execute(
            "SELECT intentos_fallidos FROM usuarios WHERE id_usuario = %s FOR UPDATE",
            (id_usuario,),
        )
        row = await cur.fetchone()
        nuevos_intentos = row["intentos_fallidos"] + 1
        if nuevos_intentos >= 5:
            await cur.execute(
                "UPDATE usuarios SET intentos_fallidos = %s, bloqueado_hasta = %s WHERE id_usuario = %s",
                (nuevos_intentos, lock_until_on_5th, id_usuario),
            )
        else:
            await cur.execute(
                "UPDATE usuarios SET intentos_fallidos = %s WHERE id_usuario = %s",
                (nuevos_intentos, id_usuario),
            )
        return nuevos_intentos


async def reset_failed_attempts(conn: Connection, id_usuario: int) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            "UPDATE usuarios SET intentos_fallidos = 0, bloqueado_hasta = NULL WHERE id_usuario = %s",
            (id_usuario,),
        )


async def update_profile(
    conn: Connection,
    id_usuario: int,
    *,
    nombre: str,
    apellido: str,
    fecha_nacimiento=None,
    patologias: str | None = None,
    parentesco: str | None = None,
    matricula: str | None = None,
    especialidad: str | None = None,
) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE usuarios
            SET nombre = %s, apellido = %s, fecha_nacimiento = %s, patologias = %s,
                parentesco = %s, matricula = %s, especialidad = %s
            WHERE id_usuario = %s
            """,
            (nombre, apellido, fecha_nacimiento, patologias, parentesco, matricula, especialidad, id_usuario),
        )
