from datetime import datetime, timedelta

import pytest
from fastapi import HTTPException

from app.repositories import device_repository, link_repository, vital_signs_repository
from app.schemas.vital_signs import CreateVitalSignRequest
from app.services import alerts_service, vital_signs_service


def _signo_row(**overrides):
    base = {
        "id_signo": 10,
        "id_paciente": 1,
        "frecuencia_cardiaca": 75,
        "spo2": 97.0,
        "calidad_senal": 90,
        "registrado_en": datetime(2026, 6, 21, 10, 0),
    }
    base.update(overrides)
    return base


def _patch_common(monkeypatch, *, signo_row, recent_readings=None):
    async def fake_find_by_patient(conn, id_paciente):
        return {"id_dispositivo": 1}

    async def fake_create_reading(conn, **kwargs):
        return 10

    async def fake_find_by_id(conn, id_signo):
        return signo_row

    async def fake_find_since(conn, id_paciente, *, since):
        return recent_readings or []

    async def fake_list_accepted_recipients(conn, id_paciente):
        return []

    monkeypatch.setattr(device_repository, "find_by_patient", fake_find_by_patient)
    monkeypatch.setattr(vital_signs_repository, "create_reading", fake_create_reading)
    monkeypatch.setattr(vital_signs_repository, "find_by_id", fake_find_by_id)
    monkeypatch.setattr(vital_signs_repository, "find_since", fake_find_since)
    monkeypatch.setattr(link_repository, "list_accepted_recipients", fake_list_accepted_recipients)


async def test_record_reading_rejects_low_signal_quality(fake_conn):
    body = CreateVitalSignRequest(
        frecuencia_cardiaca=75, spo2=97, calidad_senal=10, registrado_en=datetime.now()
    )
    with pytest.raises(HTTPException) as exc:
        await vital_signs_service.record_reading(fake_conn, id_paciente=1, body=body)
    assert exc.value.status_code == 422
    assert exc.value.detail == "LOW_SIGNAL_QUALITY"


async def test_record_reading_rejects_without_linked_device(monkeypatch, fake_conn):
    async def fake_find_by_patient(conn, id_paciente):
        return None

    monkeypatch.setattr(device_repository, "find_by_patient", fake_find_by_patient)

    body = CreateVitalSignRequest(
        frecuencia_cardiaca=75, spo2=97, calidad_senal=90, registrado_en=datetime.now()
    )
    with pytest.raises(HTTPException) as exc:
        await vital_signs_service.record_reading(fake_conn, id_paciente=1, body=body)
    assert exc.value.status_code == 409
    assert exc.value.detail == "NO_DEVICE_LINKED"


async def test_critical_spo2_dispatches_critical_alert(monkeypatch, fake_conn):
    _patch_common(monkeypatch, signo_row=_signo_row(spo2=85.0))
    dispatched = []

    async def fake_dispatch_alert(conn, **kwargs):
        dispatched.append(kwargs)
        return 1

    monkeypatch.setattr(alerts_service, "dispatch_alert", fake_dispatch_alert)

    body = CreateVitalSignRequest(
        frecuencia_cardiaca=75, spo2=85, calidad_senal=90, registrado_en=datetime(2026, 6, 21, 10, 0)
    )
    await vital_signs_service.record_reading(fake_conn, id_paciente=1, body=body)

    assert any(call["severidad_db"] == "CRITICAL" for call in dispatched)


async def test_warning_spo2_dispatches_warning_alert(monkeypatch, fake_conn):
    _patch_common(monkeypatch, signo_row=_signo_row(spo2=92.0))
    dispatched = []

    async def fake_dispatch_alert(conn, **kwargs):
        dispatched.append(kwargs)
        return 1

    monkeypatch.setattr(alerts_service, "dispatch_alert", fake_dispatch_alert)

    body = CreateVitalSignRequest(
        frecuencia_cardiaca=75, spo2=92, calidad_senal=90, registrado_en=datetime(2026, 6, 21, 10, 0)
    )
    await vital_signs_service.record_reading(fake_conn, id_paciente=1, body=body)

    assert any(call["severidad_db"] == "WARNING" for call in dispatched)


async def test_normal_readings_do_not_dispatch_alerts(monkeypatch, fake_conn):
    _patch_common(monkeypatch, signo_row=_signo_row(spo2=97.0, frecuencia_cardiaca=75))
    dispatched = []

    async def fake_dispatch_alert(conn, **kwargs):
        dispatched.append(kwargs)
        return 1

    monkeypatch.setattr(alerts_service, "dispatch_alert", fake_dispatch_alert)

    body = CreateVitalSignRequest(
        frecuencia_cardiaca=75, spo2=97, calidad_senal=90, registrado_en=datetime(2026, 6, 21, 10, 0)
    )
    await vital_signs_service.record_reading(fake_conn, id_paciente=1, body=body)

    assert dispatched == []


async def test_sustained_out_of_range_heart_rate_dispatches_alert(monkeypatch, fake_conn):
    now = datetime(2026, 6, 21, 10, 0)
    recent_readings = [
        {"frecuencia_cardiaca": 120, "registrado_en": now - timedelta(minutes=8)},
        {"frecuencia_cardiaca": 125, "registrado_en": now - timedelta(minutes=4)},
    ]
    _patch_common(monkeypatch, signo_row=_signo_row(frecuencia_cardiaca=125, spo2=97.0), recent_readings=recent_readings)
    dispatched = []

    async def fake_dispatch_alert(conn, **kwargs):
        dispatched.append(kwargs)
        return 1

    monkeypatch.setattr(alerts_service, "dispatch_alert", fake_dispatch_alert)

    body = CreateVitalSignRequest(
        frecuencia_cardiaca=125, spo2=97, calidad_senal=90, registrado_en=now
    )
    await vital_signs_service.record_reading(fake_conn, id_paciente=1, body=body)

    assert any("fuera de rango" in call["titulo"].lower() or "frecuencia cardíaca" in call["titulo"].lower() for call in dispatched)
