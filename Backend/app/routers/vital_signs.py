from datetime import datetime

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect, status

from app.core.db import get_connection
from app.core.security import CurrentUser, decode_access_token, get_current_user, require_role
from app.core.ws import vital_signs_ws_manager
from app.schemas.vital_signs import CreateVitalSignRequest, SignoVitalDto
from app.services import access_control, vital_signs_service

router = APIRouter(prefix="/api/v1/vital-signs", tags=["vital-signs"])


@router.get("/latest", response_model=list[SignoVitalDto])
async def get_latest(
    patient_id: int | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    conn=Depends(get_connection),
):
    id_paciente = await access_control.resolve_patient_id(conn, current_user, patient_id)
    return await vital_signs_service.get_latest(conn, id_paciente)


@router.get("/history", response_model=list[SignoVitalDto])
async def get_history(
    tipo: str | None = Query(default=None),
    from_: datetime = Query(alias="from"),
    to: datetime = Query(),
    patient_id: int | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    conn=Depends(get_connection),
):
    id_paciente = await access_control.resolve_patient_id(conn, current_user, patient_id)
    return await vital_signs_service.get_history(conn, id_paciente, tipo=tipo, desde=from_, hasta=to)


@router.post("", response_model=list[SignoVitalDto], status_code=status.HTTP_201_CREATED)
async def create_reading(
    body: CreateVitalSignRequest,
    current_user: CurrentUser = Depends(require_role("paciente")),
    conn=Depends(get_connection),
):
    return await vital_signs_service.record_reading(conn, id_paciente=current_user.id_usuario, body=body)


@router.websocket("/live")
async def vital_signs_live(websocket: WebSocket, token: str):
    try:
        payload = decode_access_token(token)
    except Exception:
        await websocket.close(code=4401)
        return
    id_usuario = int(payload["sub"])
    await vital_signs_ws_manager.connect(id_usuario, websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        vital_signs_ws_manager.disconnect(id_usuario, websocket)
