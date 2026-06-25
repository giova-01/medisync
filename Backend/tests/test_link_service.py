import pytest
from fastapi import HTTPException

from app.repositories import link_repository, user_repository
from app.services import alerts_service, link_service


def _vinculo_row(**overrides):
    base = {
        "id_vinculo": 1,
        "id_paciente": 1,
        "id_usuario_vinculado": 2,
        "tipo_vinculo": "CUIDADOR",
        "estado": "PENDIENTE",
        "email_usuario_vinculado": "cuidador@test.com",
        "nombre_usuario_vinculado": "María",
        "apellido_usuario_vinculado": "García",
    }
    base.update(overrides)
    return base


async def test_request_link_rejects_unknown_patient_email(monkeypatch, fake_conn):
    async def fake_find_by_email(conn, email):
        return None

    monkeypatch.setattr(user_repository, "find_by_email", fake_find_by_email)

    with pytest.raises(HTTPException) as exc:
        await link_service.request_link(
            fake_conn, id_solicitante=2, target_email="no-existe@test.com", rol_api="cuidador"
        )
    assert exc.value.status_code == 404
    assert exc.value.detail == "EMAIL_NOT_FOUND"


async def test_request_link_creates_pending_link_and_notifies_patient(monkeypatch, fake_conn):
    paciente = {"id_usuario": 1, "tipo_perfil": "PACIENTE", "email": "pac@test.com", "nombre": "Juan", "apellido": "Pérez"}
    solicitante = {"id_usuario": 2, "email": "cuidador@test.com", "nombre": "María", "apellido": "García"}
    dispatched = []

    async def fake_find_by_email(conn, email):
        return paciente

    async def fake_create_link(conn, **kwargs):
        return 1

    async def fake_find_by_id(conn, id_vinculo):
        return _vinculo_row()

    async def fake_find_by_id_user(conn, id_usuario):
        return solicitante

    async def fake_dispatch_alert(conn, **kwargs):
        dispatched.append(kwargs)
        return 1

    monkeypatch.setattr(user_repository, "find_by_email", fake_find_by_email)
    monkeypatch.setattr(link_repository, "create_link", fake_create_link)
    monkeypatch.setattr(link_repository, "find_by_id", fake_find_by_id)
    monkeypatch.setattr(user_repository, "find_by_id", fake_find_by_id_user)
    monkeypatch.setattr(alerts_service, "dispatch_alert", fake_dispatch_alert)

    vinculo = await link_service.request_link(
        fake_conn, id_solicitante=2, target_email="pac@test.com", rol_api="cuidador"
    )
    assert vinculo.estado == "pendiente"
    assert len(dispatched) == 1
    assert dispatched[0]["tipo_db"] == "VINCULO_SOLICITADO"


async def test_respond_link_rejects_when_not_link_owner(monkeypatch, fake_conn):
    async def fake_find_by_id(conn, id_vinculo):
        return _vinculo_row(id_paciente=1)

    monkeypatch.setattr(link_repository, "find_by_id", fake_find_by_id)

    with pytest.raises(HTTPException) as exc:
        # el cuidador (id 2) intenta responder su propia solicitud en vez del paciente (id 1)
        await link_service.respond_link(fake_conn, id_vinculo=1, id_paciente=2, aceptar=True)
    assert exc.value.status_code == 403
    assert exc.value.detail == "NOT_LINK_OWNER"


async def test_revoke_link_sets_estado_revocado(monkeypatch, fake_conn):
    calls = []

    async def fake_find_by_id(conn, id_vinculo):
        return _vinculo_row(id_paciente=1, estado="ACEPTADO")

    async def fake_update_estado(conn, id_vinculo, estado_db):
        calls.append((id_vinculo, estado_db))

    monkeypatch.setattr(link_repository, "find_by_id", fake_find_by_id)
    monkeypatch.setattr(link_repository, "update_estado", fake_update_estado)

    await link_service.revoke_link(fake_conn, id_vinculo=1, id_paciente=1)
    assert calls == [(1, "REVOCADO")]
