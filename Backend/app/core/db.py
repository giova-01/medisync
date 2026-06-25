import aiomysql

from app.core.config import settings

_pool: aiomysql.Pool | None = None


async def init_pool() -> None:
    global _pool
    _pool = await aiomysql.create_pool(
        host=settings.db_host,
        port=settings.db_port,
        user=settings.db_user,
        password=settings.db_password,
        db=settings.db_name,
        autocommit=True,
        cursorclass=aiomysql.cursors.DictCursor,
        minsize=1,
        maxsize=10,
    )


async def close_pool() -> None:
    global _pool
    if _pool is not None:
        _pool.close()
        await _pool.wait_closed()
        _pool = None


def get_pool() -> aiomysql.Pool:
    if _pool is None:
        raise RuntimeError("El pool de conexiones no fue inicializado todavía.")
    return _pool


async def get_connection():
    pool = get_pool()
    async with pool.acquire() as conn:
        yield conn
