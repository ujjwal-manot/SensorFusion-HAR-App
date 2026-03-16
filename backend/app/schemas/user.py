from datetime import datetime
from pydantic import BaseModel


class UserOnlineStatus(BaseModel):
    id: int
    email: str
    display_name: str
    is_online: bool
    last_activity: str | None = None
    last_seen: datetime | None = None
