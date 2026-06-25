from fastapi import APIRouter, Depends, Response, status

from app.core.db import get_connection
from app.core.security import CurrentUser, require_role
from app.schemas.devices import DeviceDto, LinkDeviceRequest
from app.services import device_service

router = APIRouter(prefix="/api/v1/devices", tags=["devices"])


@router.get("/me", response_model=DeviceDto | None)
async def get_my_device(
    current_user: CurrentUser = Depends(require_role("paciente")),
    conn=Depends(get_connection),
):
    device = await device_service.get_my_device(conn, current_user.id_usuario)
    if device is None:
        return Response(status_code=status.HTTP_204_NO_CONTENT)
    return device


@router.post("/link", response_model=DeviceDto)
async def link_device(
    body: LinkDeviceRequest,
    current_user: CurrentUser = Depends(require_role("paciente")),
    conn=Depends(get_connection),
):
    return await device_service.link_device(conn, id_paciente=current_user.id_usuario, body=body)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def unlink_device(
    current_user: CurrentUser = Depends(require_role("paciente")),
    conn=Depends(get_connection),
):
    await device_service.unlink_device(conn, current_user.id_usuario)
