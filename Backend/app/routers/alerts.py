from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect, status

from app.core.db import get_connection
from app.core.security import CurrentUser, decode_access_token, get_current_user, require_role
from app.core.ws import alerts_ws_manager
from app.schemas.alerts import AlertaDto
from app.services import alerts_service

router = APIRouter(prefix="/api/v1/alerts", tags=["alerts"])


@router.get("", response_model=list[AlertaDto])
async def get_alerts(current_user: CurrentUser = Depends(get_current_user), conn=Depends(get_connection)):
    return await alerts_service.get_alerts(conn, current_user.id_usuario)


@router.post("/{id_alerta}/read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_as_read(
    id_alerta: int,
    current_user: CurrentUser = Depends(get_current_user),
    conn=Depends(get_connection),
):
    await alerts_service.mark_as_read(conn, id_alerta, current_user.id_usuario)


@router.post("/read-all", status_code=status.HTTP_204_NO_CONTENT)
async def mark_all_as_read(
    current_user: CurrentUser = Depends(get_current_user), conn=Depends(get_connection)
):
    await alerts_service.mark_all_as_read(conn, current_user.id_usuario)


@router.post("/{id_alerta}/acknowledge", response_model=AlertaDto)
async def acknowledge(
    id_alerta: int,
    current_user: CurrentUser = Depends(require_role("profesional_salud")),
    conn=Depends(get_connection),
):
    return await alerts_service.acknowledge_alert(conn, id_alerta, current_user.id_usuario)


@router.websocket("/live")
async def alerts_live(websocket: WebSocket, token: str):
    try:
        payload = decode_access_token(token)
    except Exception:
        await websocket.close(code=4401)
        return
    id_usuario = int(payload["sub"])
    await alerts_ws_manager.connect(id_usuario, websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        alerts_ws_manager.disconnect(id_usuario, websocket)
