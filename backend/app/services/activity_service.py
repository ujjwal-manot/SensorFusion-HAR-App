from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.activity_log import ActivityLog
from app.schemas.activity import ActivityCreate


async def create_activity(db: AsyncSession, user_id: int, data: ActivityCreate) -> ActivityLog:
    log = ActivityLog(
        user_id=user_id,
        activity=data.activity,
        macro_category=data.macro_category,
        confidence=data.confidence,
        sensor_snapshot=data.sensor_snapshot,
        timestamp=data.timestamp,
    )
    db.add(log)
    await db.flush()
    return log


async def batch_sync(db: AsyncSession, user_id: int, items: list[ActivityCreate]) -> int:
    logs = [
        ActivityLog(
            user_id=user_id,
            activity=item.activity,
            macro_category=item.macro_category,
            confidence=item.confidence,
            sensor_snapshot=item.sensor_snapshot,
            timestamp=item.timestamp,
        )
        for item in items
    ]
    db.add_all(logs)
    await db.flush()
    return len(logs)


async def get_history(
    db: AsyncSession, user_id: int, limit: int = 50, offset: int = 0
) -> list[ActivityLog]:
    stmt = (
        select(ActivityLog)
        .where(ActivityLog.user_id == user_id)
        .order_by(ActivityLog.timestamp.desc())
        .limit(limit)
        .offset(offset)
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_latest(db: AsyncSession, user_id: int) -> ActivityLog | None:
    stmt = (
        select(ActivityLog)
        .where(ActivityLog.user_id == user_id)
        .order_by(ActivityLog.timestamp.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()
