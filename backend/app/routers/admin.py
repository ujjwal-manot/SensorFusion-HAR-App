from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.auth_middleware import require_admin
from app.models.user import User
from app.schemas.activity import ActivityResponse
from app.schemas.user import UserOnlineStatus
from app.services.activity_service import get_history
from app.services.ws_manager import manager

router = APIRouter()


@router.get("/users", response_model=list[UserOnlineStatus])
async def list_users(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> list[UserOnlineStatus]:
    stmt = select(User).order_by(User.id)
    result = await db.execute(stmt)
    all_users = list(result.scalars().all())

    online_map = {u["id"]: u for u in manager.get_online_users()}

    response: list[UserOnlineStatus] = []
    for user in all_users:
        online_info = online_map.get(user.id)
        if online_info is not None:
            response.append(
                UserOnlineStatus(
                    id=user.id,
                    email=user.email,
                    display_name=user.display_name,
                    is_online=True,
                    last_activity=online_info.get("last_activity"),
                    last_seen=online_info.get("last_seen"),
                )
            )
        else:
            response.append(
                UserOnlineStatus(
                    id=user.id,
                    email=user.email,
                    display_name=user.display_name,
                    is_online=False,
                    last_activity=None,
                    last_seen=None,
                )
            )
    return response


@router.get("/users/{user_id}/history", response_model=list[ActivityResponse])
async def user_history(
    user_id: int,
    limit: int = Query(default=100, ge=1, le=1000),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> list[ActivityResponse]:
    logs = await get_history(db, user_id, limit=limit, offset=0)
    return [ActivityResponse.model_validate(log) for log in logs]
