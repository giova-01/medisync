from datetime import date, datetime, time

import pytest
from fastapi import HTTPException

from app.repositories import intake_repository, medication_repository
from app.services import intake_service


def _toma_row(**overrides):
    base = {
        "id_toma": 1,
        "fecha_programada": datetime(2026, 6, 21, 8, 0),
        "fecha_confirmada": None,
        "estado": "PENDIENTE",
        "id_horario": 5,
        "nombre_medicamento": "Enalapril",
        "dosis": "10mg",
    }
    base.update(overrides)
    return base


async def test_confirm_intake_rejects_already_confirmed(monkeypatch, fake_conn):
    async def fake_find_by_id(conn, id_toma):
        return _toma_row(estado="CONFIRMADA")

    monkeypatch.setattr(intake_repository, "find_by_id", fake_find_by_id)

    with pytest.raises(HTTPException) as exc:
        await intake_service.confirm_intake(fake_conn, 1)
    assert exc.value.status_code == 409
    assert exc.value.detail == "INTAKE_ALREADY_CONFIRMED"


async def test_confirm_intake_succeeds_when_pending(monkeypatch, fake_conn):
    calls = []

    async def fake_find_by_id(conn, id_toma):
        if calls:
            return _toma_row(estado="CONFIRMADA", fecha_confirmada=datetime.now())
        return _toma_row(estado="PENDIENTE")

    async def fake_confirm(conn, id_toma):
        calls.append(id_toma)

    monkeypatch.setattr(intake_repository, "find_by_id", fake_find_by_id)
    monkeypatch.setattr(intake_repository, "confirm", fake_confirm)

    toma = await intake_service.confirm_intake(fake_conn, 1)
    assert toma.estado == "confirmada"
    assert calls == [1]


async def test_postpone_intake_rejects_second_postpone(monkeypatch, fake_conn):
    async def fake_find_by_id(conn, id_toma):
        return _toma_row(estado="POSPUESTA")

    monkeypatch.setattr(intake_repository, "find_by_id", fake_find_by_id)

    with pytest.raises(HTTPException) as exc:
        await intake_service.postpone_intake(fake_conn, 1)
    assert exc.value.status_code == 409
    assert exc.value.detail == "INTAKE_ALREADY_POSTPONED"


async def test_postpone_intake_rejects_confirmed(monkeypatch, fake_conn):
    async def fake_find_by_id(conn, id_toma):
        return _toma_row(estado="CONFIRMADA")

    monkeypatch.setattr(intake_repository, "find_by_id", fake_find_by_id)

    with pytest.raises(HTTPException) as exc:
        await intake_service.postpone_intake(fake_conn, 1)
    assert exc.value.status_code == 409


async def test_get_daily_intakes_is_idempotent(monkeypatch, fake_conn):
    schedule = {"id_horario": 5, "hora_del_dia": time(8, 0), "nombre_medicamento": "Enalapril", "dosis": "10mg"}
    create_calls = []

    async def fake_list_schedules(conn, id_paciente):
        return [schedule]

    async def fake_exists(conn, id_horario, dia):
        return True  # ya existe: no debe crear una toma duplicada

    async def fake_create_intake(conn, **kwargs):
        create_calls.append(kwargs)
        return 99

    async def fake_list_for_patient(conn, id_paciente, dia):
        return [_toma_row()]

    monkeypatch.setattr(medication_repository, "list_active_schedules_for_patient", fake_list_schedules)
    monkeypatch.setattr(intake_repository, "exists_for_schedule_on_date", fake_exists)
    monkeypatch.setattr(intake_repository, "create_intake", fake_create_intake)
    monkeypatch.setattr(intake_repository, "list_for_patient_on_date", fake_list_for_patient)

    tomas = await intake_service.get_daily_intakes(fake_conn, id_paciente=1, dia=date(2026, 6, 21))
    assert len(tomas) == 1
    assert create_calls == []  # no se duplicó la toma existente
