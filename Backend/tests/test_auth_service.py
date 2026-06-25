from datetime import datetime, timedelta

import pytest
from fastapi import HTTPException

from app.core.security import hash_password
from app.repositories import user_repository
from app.services import auth_service


def test_password_policy_rejects_weak_password():
    with pytest.raises(HTTPException) as exc:
        auth_service.validate_password_policy("weak")
    assert exc.value.status_code == 422


def test_password_policy_accepts_strong_password():
    auth_service.validate_password_policy("Test1234!")  # no debe lanzar


async def test_register_rejects_duplicate_email(monkeypatch, fake_conn):
    async def fake_find_by_email(conn, email):
        return {"id_usuario": 1, "email": email}

    monkeypatch.setattr(user_repository, "find_by_email", fake_find_by_email)

    with pytest.raises(HTTPException) as exc:
        await auth_service.register(
            fake_conn,
            nombre="Ana",
            apellido="Pérez",
            email="ana@test.com",
            password="Test1234!",
            tipo_perfil_api="paciente",
        )
    assert exc.value.status_code == 409
    assert exc.value.detail == "EMAIL_ALREADY_EXISTS"


async def test_register_creates_user_and_returns_token(monkeypatch, fake_conn):
    async def fake_find_by_email(conn, email):
        return None

    created_row = {
        "id_usuario": 7,
        "email": "ana@test.com",
        "nombre": "Ana",
        "apellido": "Pérez",
        "tipo_perfil": "PACIENTE",
    }

    async def fake_create_user(conn, **kwargs):
        return 7

    async def fake_find_by_id(conn, id_usuario):
        return created_row

    monkeypatch.setattr(user_repository, "find_by_email", fake_find_by_email)
    monkeypatch.setattr(user_repository, "create_user", fake_create_user)
    monkeypatch.setattr(user_repository, "find_by_id", fake_find_by_id)

    user, token = await auth_service.register(
        fake_conn,
        nombre="Ana",
        apellido="Pérez",
        email="ana@test.com",
        password="Test1234!",
        tipo_perfil_api="paciente",
    )
    assert user.id == 7
    assert user.tipo_perfil == "paciente"
    assert token


async def test_login_rejects_invalid_credentials(monkeypatch, fake_conn):
    row = {
        "id_usuario": 1,
        "email": "ana@test.com",
        "nombre": "Ana",
        "apellido": "Pérez",
        "tipo_perfil": "PACIENTE",
        "password_hash": hash_password("Correcta123!"),
        "bloqueado_hasta": None,
        "intentos_fallidos": 0,
    }

    async def fake_find_by_email(conn, email):
        return row

    async def fake_register_failed_attempt(conn, id_usuario, *, lock_until_on_5th):
        return 1

    monkeypatch.setattr(user_repository, "find_by_email", fake_find_by_email)
    monkeypatch.setattr(user_repository, "register_failed_attempt", fake_register_failed_attempt)

    with pytest.raises(HTTPException) as exc:
        await auth_service.login(fake_conn, email="ana@test.com", password="Incorrecta")
    assert exc.value.status_code == 401
    assert exc.value.detail == "INVALID_CREDENTIALS"


async def test_login_locks_account_after_5_failed_attempts(monkeypatch, fake_conn):
    row = {
        "id_usuario": 1,
        "email": "ana@test.com",
        "password_hash": hash_password("Correcta123!"),
        "bloqueado_hasta": None,
        "intentos_fallidos": 4,
    }

    async def fake_find_by_email(conn, email):
        return row

    async def fake_register_failed_attempt(conn, id_usuario, *, lock_until_on_5th):
        return 5

    monkeypatch.setattr(user_repository, "find_by_email", fake_find_by_email)
    monkeypatch.setattr(user_repository, "register_failed_attempt", fake_register_failed_attempt)

    with pytest.raises(HTTPException) as exc:
        await auth_service.login(fake_conn, email="ana@test.com", password="Incorrecta")
    assert exc.value.status_code == 403
    assert exc.value.detail == "ACCOUNT_LOCKED"


async def test_login_rejects_while_locked_without_checking_password(monkeypatch, fake_conn):
    row = {
        "id_usuario": 1,
        "email": "ana@test.com",
        "password_hash": hash_password("Correcta123!"),
        "bloqueado_hasta": datetime.now() + timedelta(minutes=10),
        "intentos_fallidos": 5,
    }

    async def fake_find_by_email(conn, email):
        return row

    monkeypatch.setattr(user_repository, "find_by_email", fake_find_by_email)

    with pytest.raises(HTTPException) as exc:
        # password correcta a propósito: debe rechazar igual por estar bloqueado
        await auth_service.login(fake_conn, email="ana@test.com", password="Correcta123!")
    assert exc.value.status_code == 403
    assert exc.value.detail == "ACCOUNT_LOCKED"


async def test_login_success_resets_failed_attempts(monkeypatch, fake_conn):
    row = {
        "id_usuario": 1,
        "email": "ana@test.com",
        "nombre": "Ana",
        "apellido": "Pérez",
        "tipo_perfil": "PACIENTE",
        "password_hash": hash_password("Correcta123!"),
        "bloqueado_hasta": None,
        "intentos_fallidos": 3,
    }
    reset_calls = []

    async def fake_find_by_email(conn, email):
        return row

    async def fake_reset_failed_attempts(conn, id_usuario):
        reset_calls.append(id_usuario)

    monkeypatch.setattr(user_repository, "find_by_email", fake_find_by_email)
    monkeypatch.setattr(user_repository, "reset_failed_attempts", fake_reset_failed_attempts)

    user, token = await auth_service.login(fake_conn, email="ana@test.com", password="Correcta123!")
    assert user.id == 1
    assert reset_calls == [1]
    assert token
