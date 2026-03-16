from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from app.config import settings
from app.database import async_session, init_db
from app.models.user import User
from app.routers import activities, admin, auth, ws
from app.services.auth_service import hash_password


async def _seed_admin() -> None:
    """Create the default admin user if it does not exist."""
    async with async_session() as db:
        stmt = select(User).where(User.email == settings.ADMIN_EMAIL)
        result = await db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing is None:
            admin_user = User(
                email=settings.ADMIN_EMAIL,
                hashed_password=hash_password(settings.ADMIN_PASSWORD),
                display_name="Admin",
                role="admin",
                is_active=True,
            )
            db.add(admin_user)
            await db.commit()


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncGenerator[None, None]:
    await init_db()
    await _seed_admin()
    yield


app = FastAPI(
    title="SensorFusion HAR API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(activities.router, prefix="/activities", tags=["activities"])
app.include_router(admin.router, prefix="/admin", tags=["admin"])
app.include_router(ws.router, prefix="/ws", tags=["websocket"])


@app.get("/")
async def root() -> dict:
    return {"status": "ok", "service": "SensorFusion HAR API"}
