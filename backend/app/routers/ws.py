import json
from datetime import datetime, timezone

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from sqlalchemy import select

from app.database import async_session
from app.models.activity_log import ActivityLog
from app.models.user import User
from app.services.auth_service import decode_token
from app.services.ws_manager import manager

router = APIRouter()

VALID_MACRO_CLASSES = {"stationary", "locomotion", "vehicle", "gesture"}

VALID_FINE_CLASSES = {
    "stationary": {"standing", "sitting", "lying_down", "leaning"},
    "locomotion": {"walking", "running", "stairs_up", "stairs_down", "jogging", "cycling"},
    "vehicle": {"car", "bus", "train", "stationary_vehicle"},
    "gesture": {"phone_pickup", "phone_putdown", "shaking", "flipping", "typing", "calling"},
}


async def _authenticate_ws(token: str) -> User | None:
    """Authenticate a WebSocket connection via JWT token. Returns User or None."""
    try:
        payload = decode_token(token)
    except ValueError:
        return None

    user_id = payload.get("sub")
    if user_id is None:
        return None

    async with async_session() as db:
        stmt = select(User).where(User.id == int(user_id))
        result = await db.execute(stmt)
        user = result.scalar_one_or_none()

    if user is None or not user.is_active:
        return None

    return user


@router.websocket("/stream")
async def ws_phone_stream(ws: WebSocket, token: str = Query(...)) -> None:
    user = await _authenticate_ws(token)
    if user is None:
        await ws.accept()
        await ws.send_json({"error": "authentication_failed"})
        await ws.close(code=4001)
        return

    user_info = {"display_name": user.display_name, "email": user.email}
    await manager.connect_phone(user.id, ws, user_info)

    message_count = 0
    try:
        while True:
            raw = await ws.receive_text()
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                await ws.send_json({"error": "invalid_json"})
                continue

            # Validate required fields
            activity = data.get("activity", "")
            macro_category = data.get("macro_category", "")
            confidence = data.get("confidence", 0.0)
            sensor_data = data.get("sensor_data")
            timestamp_str = data.get("timestamp")

            if not activity or not macro_category:
                await ws.send_json({"error": "missing_fields"})
                continue

            # Relay ALL messages to admin watchers
            relay_payload = {
                "user_id": user.id,
                "activity": activity,
                "macro_category": macro_category,
                "confidence": confidence,
                "sensor_data": sensor_data,
                "timestamp": timestamp_str or datetime.now(timezone.utc).isoformat(),
            }
            await manager.relay_to_admins(user.id, relay_payload)

            # Store every 10th message to DB
            message_count += 1
            if message_count % 10 == 0:
                try:
                    ts = (
                        datetime.fromisoformat(timestamp_str)
                        if timestamp_str
                        else datetime.now(timezone.utc)
                    )
                except (ValueError, TypeError):
                    ts = datetime.now(timezone.utc)

                async with async_session() as db:
                    log = ActivityLog(
                        user_id=user.id,
                        activity=activity,
                        macro_category=macro_category,
                        confidence=float(confidence),
                        sensor_snapshot=sensor_data,
                        timestamp=ts,
                    )
                    db.add(log)
                    await db.commit()

            # Acknowledge receipt
            await ws.send_json({"status": "ok", "seq": message_count})

    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect_phone(user.id)


@router.websocket("/admin/{user_id}")
async def ws_admin_watch(ws: WebSocket, user_id: int, token: str = Query(...)) -> None:
    admin = await _authenticate_ws(token)
    if admin is None or admin.role != "admin":
        await ws.accept()
        await ws.send_json({"error": "authentication_failed"})
        await ws.close(code=4001)
        return

    # Check if user is online
    if user_id not in manager.online_users:
        await ws.accept()
        await ws.send_json({"error": "user_offline"})
        await ws.close(code=4002)
        return

    await manager.connect_admin(user_id, ws)

    try:
        # Send initial status
        user_info = manager.online_users.get(user_id, {})
        await ws.send_json(
            {
                "type": "connected",
                "user_id": user_id,
                "last_activity": user_info.get("last_activity"),
            }
        )

        # Keep connection alive; admin receives data via relay_to_admins
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect_admin(user_id, ws)
