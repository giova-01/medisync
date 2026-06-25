import pytest


@pytest.fixture
def fake_conn():
    """Placeholder de conexión: los tests de servicio monkeypatchean las
    funciones de repositorio directamente, así que el objeto conexión
    nunca llega a ejecutar SQL real. Ver README.md para cómo correr la
    suite de integración completa contra una base `medisync_test`."""
    return object()
