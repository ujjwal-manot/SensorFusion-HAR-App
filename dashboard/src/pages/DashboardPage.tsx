import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { Activity, LogOut, ExternalLink, Users } from "lucide-react";
import { useAuth } from "../hooks/useAuth";
import { getOnlineUsers } from "../api/users";
import UserList from "../components/UserList";
import LiveActivityPanel from "../components/LiveActivityPanel";
import ActivityChart from "../components/ActivityChart";
import SensorPlot from "../components/SensorPlot";
import { useUserLiveFeed } from "../hooks/useWebSocket";
import type { OnlineUser } from "../types";

const POLL_INTERVAL_MS = 5000;

function SelectedUserPanel({ userId }: { userId: number }) {
  const { history } = useUserLiveFeed(userId);

  return (
    <div className="space-y-4">
      <LiveActivityPanel userId={userId} />
      <ActivityChart history={history} />
      <SensorPlot history={history} />
    </div>
  );
}

export default function DashboardPage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [users, setUsers] = useState<OnlineUser[]>([]);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [isLoadingUsers, setIsLoadingUsers] = useState(true);

  const fetchUsers = useCallback(async () => {
    try {
      const data = await getOnlineUsers();
      setUsers(data);
    } catch {
      // Silently retry on next interval
    } finally {
      setIsLoadingUsers(false);
    }
  }, []);

  useEffect(() => {
    fetchUsers();
    const interval = setInterval(fetchUsers, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [fetchUsers]);

  const selectedUser = users.find((u) => u.id === selectedId) ?? null;

  const onlineCount = users.filter((u) => u.is_online).length;

  return (
    <div className="flex h-screen flex-col bg-gray-900">
      {/* Header */}
      <header className="flex items-center justify-between border-b border-gray-800 bg-gray-900/95 px-6 py-3 backdrop-blur-sm">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-blue-600/20 border border-blue-500/30">
            <Activity className="h-5 w-5 text-blue-400" />
          </div>
          <div>
            <h1 className="text-lg font-bold text-white">
              SensorFusion HAR
            </h1>
            <p className="text-xs text-gray-400">Admin Dashboard</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 text-sm text-gray-400">
            <Users className="h-4 w-4" />
            <span>
              <span className="font-medium text-green-400">{onlineCount}</span>{" "}
              online / {users.length} total
            </span>
          </div>
          <div className="h-6 w-px bg-gray-700" />
          <span className="text-sm text-gray-400">
            {user?.display_name ?? user?.email}
          </span>
          <button
            onClick={logout}
            className="flex items-center gap-1.5 rounded-lg border border-gray-700 px-3 py-1.5 text-sm text-gray-300 transition-colors hover:border-red-500/50 hover:text-red-400"
          >
            <LogOut className="h-4 w-4" />
            Logout
          </button>
        </div>
      </header>

      {/* Body */}
      <div className="flex flex-1 overflow-hidden">
        {/* Sidebar */}
        <aside className="w-80 shrink-0 overflow-hidden border-r border-gray-800 bg-gray-900">
          <div className="flex h-full flex-col">
            <div className="border-b border-gray-800 px-4 py-3">
              <h2 className="text-sm font-semibold uppercase tracking-wider text-gray-400">
                Users
              </h2>
            </div>
            {isLoadingUsers ? (
              <div className="flex flex-1 items-center justify-center">
                <div className="h-6 w-6 animate-spin rounded-full border-2 border-blue-500 border-t-transparent" />
              </div>
            ) : (
              <UserList
                users={users}
                selectedId={selectedId}
                onSelect={setSelectedId}
              />
            )}
          </div>
        </aside>

        {/* Main */}
        <main className="flex-1 overflow-y-auto p-6">
          {selectedId === null ? (
            <div className="flex h-full flex-col items-center justify-center text-gray-500">
              <Users className="mb-3 h-12 w-12" />
              <p className="text-lg font-medium">Select a user</p>
              <p className="mt-1 text-sm">
                Choose a user from the sidebar to view their live activity
              </p>
            </div>
          ) : (
            <>
              {/* User header with link to detail page */}
              <div className="mb-4 flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-white">
                    {selectedUser?.display_name ?? `User #${selectedId}`}
                  </h2>
                  <p className="text-sm text-gray-400">
                    {selectedUser?.email}
                  </p>
                </div>
                <button
                  onClick={() => navigate(`/user/${selectedId}`)}
                  className="flex items-center gap-1.5 rounded-lg border border-gray-700 px-3 py-1.5 text-sm text-gray-300 transition-colors hover:border-blue-500/50 hover:text-blue-400"
                >
                  <ExternalLink className="h-4 w-4" />
                  Full View
                </button>
              </div>

              <SelectedUserPanel userId={selectedId} />
            </>
          )}
        </main>
      </div>
    </div>
  );
}
