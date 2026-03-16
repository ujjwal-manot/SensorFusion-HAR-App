from datetime import datetime, timezone

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        # user_id -> WebSocket (phone connection)
        self.phone_connections: dict[int, WebSocket] = {}
        # user_id -> list[WebSocket] (admin watchers)
        self.admin_watchers: dict[int, list[WebSocket]] = {}
        # user_id -> {last_activity, last_seen, display_name, email}
        self.online_users: dict[int, dict] = {}

    async def connect_phone(self, user_id: int, ws: WebSocket, user_info: dict) -> None:
        await ws.accept()
        self.phone_connections[user_id] = ws
        self.online_users[user_id] = {
            "last_activity": None,
            "last_seen": datetime.now(timezone.utc),
            **user_info,
        }

    def disconnect_phone(self, user_id: int) -> None:
        self.phone_connections.pop(user_id, None)
        self.online_users.pop(user_id, None)

    async def connect_admin(self, user_id: int, ws: WebSocket) -> None:
        await ws.accept()
        if user_id not in self.admin_watchers:
            self.admin_watchers[user_id] = []
        self.admin_watchers[user_id].append(ws)

    def disconnect_admin(self, user_id: int, ws: WebSocket) -> None:
        if user_id in self.admin_watchers:
            self.admin_watchers[user_id] = [
                w for w in self.admin_watchers[user_id] if w is not ws
            ]
            if not self.admin_watchers[user_id]:
                del self.admin_watchers[user_id]

    async def relay_to_admins(self, user_id: int, data: dict) -> None:
        # Update online status
        if user_id in self.online_users:
            self.online_users[user_id] = {
                **self.online_users[user_id],
                "last_activity": data.get("activity"),
                "last_seen": datetime.now(timezone.utc),
            }

        # Relay to all admin watchers
        watchers = self.admin_watchers.get(user_id, [])
        dead: list[WebSocket] = []
        for ws in watchers:
            try:
                await ws.send_json(data)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect_admin(user_id, ws)

    def get_online_users(self) -> list[dict]:
        result = []
        for uid, info in self.online_users.items():
            last_seen = info.get("last_seen")
            result.append(
                {
                    "id": uid,
                    "is_online": True,
                    "email": info.get("email", ""),
                    "display_name": info.get("display_name", ""),
                    "last_activity": info.get("last_activity"),
                    "last_seen": last_seen.isoformat() if last_seen else None,
                }
            )
        return result


manager = ConnectionManager()
