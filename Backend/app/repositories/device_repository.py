from aiomysql import Connection


async def find_by_mac(conn: Connection, mac_address: str) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute("SELECT * FROM dispositivos WHERE mac_address = %s", (mac_address,))
        return await cur.fetchone()


async def find_by_patient(conn: Connection, id_paciente: int) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute("SELECT * FROM dispositivos WHERE id_paciente = %s", (id_paciente,))
        return await cur.fetchone()


async def create_unlinked(
    conn: Connection, *, mac_address: str, nombre: str, firmware_version: str | None, nivel_bateria: int | None
) -> int:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO dispositivos (mac_address, nombre, firmware_version, nivel_bateria)
            VALUES (%s, %s, %s, %s)
            """,
            (mac_address, nombre, firmware_version, nivel_bateria),
        )
        return cur.lastrowid


async def link_to_patient(
    conn: Connection,
    id_dispositivo: int,
    id_paciente: int,
    *,
    nombre: str,
    firmware_version: str | None,
    nivel_bateria: int | None,
) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE dispositivos
            SET id_paciente = %s, fecha_vinculacion = NOW(), nombre = %s,
                firmware_version = %s, nivel_bateria = %s, ultima_sincronizacion = NOW()
            WHERE id_dispositivo = %s
            """,
            (id_paciente, nombre, firmware_version, nivel_bateria, id_dispositivo),
        )


async def unlink_patient(conn: Connection, id_paciente: int) -> None:
    async with conn.cursor() as cur:
        await cur.execute(
            "UPDATE dispositivos SET id_paciente = NULL, fecha_vinculacion = NULL WHERE id_paciente = %s",
            (id_paciente,),
        )


async def find_by_id(conn: Connection, id_dispositivo: int) -> dict | None:
    async with conn.cursor() as cur:
        await cur.execute("SELECT * FROM dispositivos WHERE id_dispositivo = %s", (id_dispositivo,))
        return await cur.fetchone()
