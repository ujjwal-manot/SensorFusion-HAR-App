from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.auth_middleware import get_current_user
from app.models.user import User
from app.schemas.activity import ActivityBatchSync, ActivityResponse
from app.services.activity_service import batch_sync, get_history

router = APIRouter()


@router.post("/sync")
async def sync_activities(
    body: ActivityBatchSync,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    count = await batch_sync(db, user.id, body.items)
    return {"synced": count}


@router.get("/history", response_model=list[ActivityResponse])
async def activity_history(
    limit: int = Query(default=50, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[ActivityResponse]:
    logs = await get_history(db, user.id, limit=limit, offset=offset)
    return [ActivityResponse.model_validate(log) for log in logs]
