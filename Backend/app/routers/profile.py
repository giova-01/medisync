from fastapi import APIRouter, Depends

from app.core.db import get_connection
from app.core.security import CurrentUser, get_current_user
from app.schemas.profile import ProfileResponse, UpdateProfileRequest
from app.services import profile_service

router = APIRouter(prefix="/api/v1/profile", tags=["profile"])


@router.get("", response_model=ProfileResponse)
async def get_profile(current_user: CurrentUser = Depends(get_current_user), conn=Depends(get_connection)):
    return await profile_service.get_profile(conn, current_user.id_usuario)


@router.put("", response_model=ProfileResponse)
async def update_profile(
    body: UpdateProfileRequest,
    current_user: CurrentUser = Depends(get_current_user),
    conn=Depends(get_connection),
):
    return await profile_service.update_profile(conn, current_user.id_usuario, body)
