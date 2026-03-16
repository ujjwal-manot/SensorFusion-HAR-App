from datetime import datetime
from pydantic import BaseModel, Field


class ActivityCreate(BaseModel):
    activity: str = Field(..., min_length=1, max_length=50)
    macro_category: str = Field(..., min_length=1, max_length=20)
    confidence: float = Field(..., ge=0.0, le=1.0)
    sensor_snapshot: list[float] | None = None
    timestamp: datetime


class ActivityBatchSync(BaseModel):
    items: list[ActivityCreate] = Field(..., min_length=1)


class ActivityResponse(BaseModel):
    id: int
    activity: str
    macro_category: str
    confidence: float
    timestamp: datetime
    duration_seconds: float | None = None

    model_config = {"from_attributes": True}
