from collections import defaultdict

from fastapi import WebSocket


class ConnectionManager:
    """Registro en memoria de conexiones WebSocket activas por id_usuario.
    Server único (sin múltiples réplicas), por eso no se necesita un
    bus externo (Redis pub/sub, etc.) para esta iteración."""

    def __init__(self) -> None:
        self._connections: dict[int, set[WebSocket]] = defaultdict(set)

    async def connect(self, id_usuario: int, websocket: WebSocket) -> None:
        await websocket.accept()
        self._connections[id_usuario].add(websocket)

    def disconnect(self, id_usuario: int, websocket: WebSocket) -> None:
        self._connections[id_usuario].discard(websocket)
        if not self._connections[id_usuario]:
            del self._connections[id_usuario]

    async def send_to_user(self, id_usuario: int, payload: dict) -> None:
        for websocket in list(self._connections.get(id_usuario, ())):
            try:
                await websocket.send_json(payload)
            except Exception:
                self.disconnect(id_usuario, websocket)

    async def send_to_users(self, ids_usuario: list[int], payload: dict) -> None:
        for id_usuario in ids_usuario:
            await self.send_to_user(id_usuario, payload)


alerts_ws_manager = ConnectionManager()
vital_signs_ws_manager = ConnectionManager()
