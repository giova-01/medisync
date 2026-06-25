import logging
from contextlib import asynccontextmanager

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.db import close_pool, init_pool
from app.routers import alerts, auth, devices, links, medication, profile, vital_signs
from app.services.intake_scheduler import auto_omit_overdue_intakes

logger = logging.getLogger("medisync")

scheduler = AsyncIOScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_pool()
    scheduler.add_job(
        auto_omit_overdue_intakes,
        "interval",
        minutes=settings.scheduler_interval_minutes,
        id="auto_omit_overdue_intakes",
    )
    scheduler.start()
    yield
    scheduler.shutdown()
    await close_pool()


app = FastAPI(title="MediSync API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.cors_origins.split(",")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("Error no controlado en %s", request.url)
    return JSONResponse(status_code=500, content={"detail": "INTERNAL_SERVER_ERROR"})


@app.get("/health")
async def health():
    return {"status": "ok"}


app.include_router(auth.router)
app.include_router(profile.router)
app.include_router(links.router)
app.include_router(medication.router)
app.include_router(devices.router)
app.include_router(vital_signs.router)
app.include_router(alerts.router)
