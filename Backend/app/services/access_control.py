from aiomysql import Connection
from fastapi import HTTPException, status

from app.core.security import CurrentUser
from app.repositories import link_repository


async def resolve_patient_id(
    conn: Connection, current_user: CurrentUser, patient_id: int | None
) -> int:
    """Resuelve sobre qué paciente opera la request. Un Paciente siempre
    opera sobre sí mismo (ignora `patient_id` si lo manda); un Cuidador o
    Profesional debe indicar `patient_id` y tener vínculo ACEPTADO con él."""
    if current_user.tipo_perfil == "paciente":
        return current_user.id_usuario

    if patient_id is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="PATIENT_ID_REQUIRED",
        )

    link = await link_repository.find_accepted_link(conn, patient_id, current_user.id_usuario)
    if link is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="NOT_LINKED_TO_PATIENT")

    return patient_id


async def require_linked_professional(
    conn: Connection, current_user: CurrentUser, patient_id: int
) -> None:
    if current_user.tipo_perfil != "profesional_salud":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="REQUIRES_PROFESSIONAL_ROLE")
    link = await link_repository.find_accepted_link(conn, patient_id, current_user.id_usuario)
    if link is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="NOT_LINKED_TO_PATIENT")
