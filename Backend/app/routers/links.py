from fastapi import APIRouter, Depends, status

from app.core.db import get_connection
from app.core.enums import TIPO_PERFIL_FROM_API
from app.core.security import CurrentUser, get_current_user, require_role
from app.schemas.links import RequestLinkRequest, RespondLinkRequest, VinculoDto
from app.services import link_service

router = APIRouter(prefix="/api/v1/links", tags=["links"])


@router.get("", response_model=list[VinculoDto])
async def list_links(current_user: CurrentUser = Depends(get_current_user), conn=Depends(get_connection)):
    tipo_perfil_db = TIPO_PERFIL_FROM_API[current_user.tipo_perfil]
    return await link_service.list_links(conn, current_user.id_usuario, tipo_perfil_db)


@router.post("/request", response_model=VinculoDto)
async def request_link(
    body: RequestLinkRequest,
    current_user: CurrentUser = Depends(require_role("cuidador", "profesional_salud")),
    conn=Depends(get_connection),
):
    return await link_service.request_link(
        conn,
        id_solicitante=current_user.id_usuario,
        target_email=body.target_email,
        rol_api=body.rol,
    )


@router.post("/{id_vinculo}/respond", response_model=VinculoDto)
async def respond_link(
    id_vinculo: int,
    body: RespondLinkRequest,
    current_user: CurrentUser = Depends(require_role("paciente")),
    conn=Depends(get_connection),
):
    return await link_service.respond_link(
        conn, id_vinculo=id_vinculo, id_paciente=current_user.id_usuario, aceptar=body.aceptar
    )


@router.delete("/{id_vinculo}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_link(
    id_vinculo: int,
    current_user: CurrentUser = Depends(require_role("paciente")),
    conn=Depends(get_connection),
):
    await link_service.revoke_link(conn, id_vinculo=id_vinculo, id_paciente=current_user.id_usuario)
