"""Mapeos explícitos entre los valores ENUM de MySQL (mayúsculas/español,
fieles al diccionario de datos del TFG) y los valores que espera el
frontend Flutter (minúsculas, ver cada `*X.apiValue`/`fromApiValue` en
lib/features/**/domain/entities/*.dart). Nunca expongas un ENUM crudo de
la base de datos en una respuesta JSON sin pasarlo por `to_api()`.
"""

# tipo_perfil: usuarios.tipo_perfil <-> TipoPerfil.apiValue
TIPO_PERFIL_TO_API = {
    "PACIENTE": "paciente",
    "CUIDADOR": "cuidador",
    "PROFESIONAL_SALUD": "profesional_salud",
}
TIPO_PERFIL_FROM_API = {v: k for k, v in TIPO_PERFIL_TO_API.items()}

# vinculos.tipo_vinculo <-> TipoVinculo.apiValue
TIPO_VINCULO_TO_API = {
    "CUIDADOR": "cuidador",
    "PROFESIONAL_SALUD": "profesional_salud",
}
TIPO_VINCULO_FROM_API = {v: k for k, v in TIPO_VINCULO_TO_API.items()}

# vinculos.estado <-> EstadoVinculo.apiValue
ESTADO_VINCULO_TO_API = {
    "PENDIENTE": "pendiente",
    "ACEPTADO": "aceptado",
    "RECHAZADO": "rechazado",
    "REVOCADO": "revocado",
}
ESTADO_VINCULO_FROM_API = {v: k for k, v in ESTADO_VINCULO_TO_API.items()}

# tomas_medicacion.estado <-> EstadoToma.apiValue
ESTADO_TOMA_TO_API = {
    "PENDIENTE": "pendiente",
    "CONFIRMADA": "confirmada",
    "OMITIDA": "omitida",
    "POSPUESTA": "pospuesta",
}
ESTADO_TOMA_FROM_API = {v: k for k, v in ESTADO_TOMA_TO_API.items()}

# alertas.tipo <-> TipoAlerta.apiValue
TIPO_ALERTA_TO_API = {
    "TOMA_OMITIDA": "toma_omitida",
    "SIGNO_VITAL_CRITICO": "signo_vital_critico",
    "VINCULO_SOLICITADO": "vinculo_solicitado",
    "RECORDATORIO_TOMA": "recordatorio_toma",
}
TIPO_ALERTA_FROM_API = {v: k for k, v in TIPO_ALERTA_TO_API.items()}

# alertas.severidad <-> SeveridadAlerta.apiValue
SEVERIDAD_ALERTA_TO_API = {
    "INFO": "info",
    "WARNING": "warning",
    "CRITICAL": "critical",
}
SEVERIDAD_ALERTA_FROM_API = {v: k for k, v in SEVERIDAD_ALERTA_TO_API.items()}

# tipo de signo vital expuesto al frontend (no existe columna `tipo` en
# signos_vitales: cada fila se descompone en dos objetos de respuesta)
TIPO_SIGNO_VITAL_FRECUENCIA_CARDIACA = "frecuencia_cardiaca"
TIPO_SIGNO_VITAL_SATURACION_OXIGENO = "saturacion_oxigeno"


def to_api(mapping: dict[str, str], valor_db: str) -> str:
    return mapping[valor_db]


def from_api(mapping: dict[str, str], valor_api: str) -> str:
    return mapping[valor_api]
