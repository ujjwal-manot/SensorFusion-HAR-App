from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, JSON, String
from sqlalchemy.orm import relationship

from app.database import Base


class ActivityLog(Base):
    __tablename__ = "activity_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    activity = Column(String(50), nullable=False)
    macro_category = Column(String(20), nullable=False)
    confidence = Column(Float, nullable=False)
    sensor_snapshot = Column(JSON, nullable=True)
    timestamp = Column(DateTime, nullable=False)
    duration_seconds = Column(Float, nullable=True)

    user = relationship("User", back_populates="activity_logs")
