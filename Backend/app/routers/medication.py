from datetime import date

from fastapi import APIRouter, Depends, Query, status

from app.core.db import get_connection
from app.core.security import CurrentUser, get_current_user, require_role
from app.schemas.medication import (
    CreateMedicationRequest,
    MedicamentoCreateResponse,
    MedicamentoDto,
    TomaDto,
    UpdateMedicationRequest,
)
from app.services import access_control, intake_service, medication_service
from app.repositories import medication_repository

router = APIRouter(prefix="/api/v1", tags=["medication"])


@router.get("/medications", response_model=list[MedicamentoDto], response_model_exclude_none=True)
async def list_medications(
    patient_id: int | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    conn=Depends(get_connection),
):
    id_paciente = await access_control.resolve_patient_id(conn, current_user, patient_id)
    return await medication_service.list_medications(conn, id_paciente)


@router.post(
    "/medications",
    response_model=MedicamentoCreateResponse,
    response_model_exclude_none=True,
    status_code=status.HTTP_201_CREATED,
)
async def add_medication(
    body: CreateMedicationRequest,
    patient_id: int = Query(),
    current_user: CurrentUser = Depends(require_role("profesional_salud")),
    conn=Depends(get_connection),
):
    await access_control.require_linked_professional(conn, current_user, patient_id)
    return await medication_service.add_medication(
        conn, id_paciente=patient_id, id_profesional_creador=current_user.id_usuario, body=body
    )


@router.put("/medications/{id_medicamento}", response_model=MedicamentoCreateResponse, response_model_exclude_none=True)
async def update_medication(
    id_medicamento: int,
    body: UpdateMedicationRequest,
    current_user: CurrentUser = Depends(require_role("profesional_salud")),
    conn=Depends(get_connection),
):
    medicamento = await medication_repository.find_by_id(conn, id_medicamento)
    await access_control.require_linked_professional(conn, current_user, medicamento["id_paciente"])
    return await medication_service.update_medication(conn, id_medicamento=id_medicamento, body=body)


@router.delete("/medications/{id_medicamento}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_medication(
    id_medicamento: int,
    fecha_fin: date | None = None,
    current_user: CurrentUser = Depends(require_role("profesional_salud")),
    conn=Depends(get_connection),
):
    medicamento = await medication_repository.find_by_id(conn, id_medicamento)
    await access_control.require_linked_professional(conn, current_user, medicamento["id_paciente"])
    await medication_service.remove_medication(conn, id_medicamento=id_medicamento, fecha_fin=fecha_fin)


@router.get("/intakes", response_model=list[TomaDto])
async def get_intakes(
    date_: date = Query(alias="date"),
    patient_id: int | None = Query(default=None),
    current_user: CurrentUser = Depends(get_current_user),
    conn=Depends(get_connection),
):
    id_paciente = await access_control.resolve_patient_id(conn, current_user, patient_id)
    return await intake_service.get_daily_intakes(conn, id_paciente=id_paciente, dia=date_)


@router.post("/intakes/{id_toma}/confirm", response_model=TomaDto)
async def confirm_intake(
    id_toma: int,
    current_user: CurrentUser = Depends(require_role("paciente")),
    conn=Depends(get_connection),
):
    return await intake_service.confirm_intake(conn, id_toma)


@router.post("/intakes/{id_toma}/postpone", response_model=TomaDto)
async def postpone_intake(
    id_toma: int,
    current_user: CurrentUser = Depends(require_role("paciente")),
    conn=Depends(get_connection),
):
    return await intake_service.postpone_intake(conn, id_toma)
