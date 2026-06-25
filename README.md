# MediSync

Sistema de adherencia terapéutica para adultos mayores con soporte wearable — Trabajo Final de Grado de Ingeniería en Software (Universidad Siglo 21). Autor: **Giovanni Giraudo Vidal**.

MediSync integra tres componentes: una app móvil multiplataforma (Flutter), un backend centralizado (FastAPI + MySQL) y un wearable ESP32 + sensor MAX30102 que mide frecuencia cardíaca y SpO2 y se comunica por Bluetooth Low Energy directamente con el teléfono. El sistema da acceso diferenciado a tres perfiles: **Paciente**, **Cuidador** y **Profesional de Salud**.

---

## Estructura del repositorio

```
Tesis/
├── Backend/            API REST en FastAPI (Python)
└── Frontend/medisync/  App Flutter (Clean Architecture)
```

La base de datos MySQL (esquema y datos de prueba) se distribuye por separado.

---

## Arquitectura

```
┌─────────────────────┐        HTTP/HTTPS         ┌──────────────────────┐        SQL          ┌───────────────┐
│   App Flutter        │ ───────────────────────▶ │   Backend FastAPI    │ ──────────────────▶ │  MySQL 8.0    │
│  (Paciente/Cuidador/  │ ◀─────────────────────── │  (Uvicorn, sin ORM)  │ ◀────────────────── │  (medisync)   │
│   Profesional)        │      WebSocket (live)     └──────────────────────┘                     └───────────────┘
└──────────┬───────────┘
           │ BLE (local, sin pasar por el backend)
           ▼
┌─────────────────────┐
│  Wearable ESP32 +    │
│  sensor MAX30102     │
│  (FC + SpO2)         │
└─────────────────────┘
```

El backend nunca habla directamente con el ESP32 — el wearable solo se comunica por BLE con la app, que luego sincroniza las lecturas con el backend vía HTTP. Las notificaciones push (Firebase Cloud Messaging) están diseñadas pero diferidas.

---

## Cómo levantar el sistema completo (orden obligatorio)

### 1. Base de datos MySQL

Requiere MySQL 8.0+ corriendo en `localhost:3306`. Aplicar el esquema y los datos de prueba que se distribuyen por separado:

```bash
mysql -u root -p < schema.sql
mysql -u root -p medisync < seed.sql
```

### 2. Backend FastAPI

```bash
cd Backend
python -m venv .venv
.venv\Scripts\activate          # Windows; en bash: source .venv/Scripts/activate
pip install -r requirements.txt
copy .env.example .env          # completar DB_PASSWORD y JWT_SECRET
uvicorn app.main:app --reload
```

Documentación interactiva (Swagger) en `http://127.0.0.1:8000/docs`.

### 3. App Flutter

```bash
cd Frontend/medisync
flutter pub get
```

Crear/editar `.env` en la raíz de `Frontend/medisync` con la URL del backend:

```env
BASE_URL=http://10.0.2.2:8000/api/v1
```

- **Emulador Android**: `10.0.2.2` es el alias que apunta al `localhost` de la máquina host — el valor de arriba funciona tal cual.
- **Dispositivo físico en la misma red Wi-Fi**: reemplazar por la IP LAN de la máquina que corre el backend (`ipconfig` → IPv4).
- **Windows desktop / Chrome**: usar `http://localhost:8000/api/v1`.

```bash
flutter run
```

---

## Cuentas de prueba

| Email | Contraseña | Rol |
|---|---|---|
| `paciente@test.com` | `Test1234!` | Paciente |
| `cuidador@test.com` | `Test1234!` | Cuidador |
| `profesional@test.com` | `Test1234!` | Profesional de Salud |

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Frontend | Flutter / Dart 3.12+, Clean Architecture, `provider`, `go_router`, `get_it`, `dio` |
| Backend | Python 3.11+, FastAPI, Uvicorn, `aiomysql` (sin ORM), JWT (`PyJWT`), bcrypt, APScheduler |
| Base de datos | MySQL 8.0, SQL puro |
| Wearable | ESP32 + sensor MAX30102 (PPG), BLE, Arduino IDE 2.x |
| Notificaciones push | Firebase Cloud Messaging (diseñado, integración real diferida) |
