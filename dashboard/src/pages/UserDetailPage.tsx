import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, Clock, Activity } from "lucide-react";
import { getUserHistory } from "../api/users";
import { useUserLiveFeed } from "../hooks/useWebSocket";
import LiveActivityPanel from "../components/LiveActivityPanel";
import ActivityChart from "../components/ActivityChart";
import SensorPlot from "../components/SensorPlot";
import ConfidenceBadge from "../components/ConfidenceBadge";
import type { ActivityLog } from "../types";

const MACRO_BADGE_COLORS: Record<string, string> = {
  stationary: "bg-green-500/20 text-green-400 border-green-500/30",
  locomotion: "bg-blue-500/20 text-blue-400 border-blue-500/30",
  vehicle: "bg-orange-500/20 text-orange-400 border-orange-500/30",
  gesture: "bg-purple-500/20 text-purple-400 border-purple-500/30",
};

function getMacroBadgeColor(macro: string): string {
  return MACRO_BADGE_COLORS[macro] ?? "bg-gray-500/20 text-gray-400 border-gray-500/30";
}

function formatActivity(activity: string): string {
  return activity
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

function formatTimestamp(ts: string): string {
  const d = new Date(ts);
  return d.toLocaleString();
}

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const userId = Number(id);

  const { history: liveHistory } = useUserLiveFeed(userId);
  const [activityHistory, setActivityHistory] = useState<ActivityLog[]>([]);
  const [isLoadingHistory, setIsLoadingHistory] = useState(true);

  useEffect(() => {
    if (isNaN(userId)) return;

    setIsLoadingHistory(true);
    getUserHistory(userId, 100)
      .then((data) => {
        setActivityHistory(data);
      })
      .catch(() => {
        setActivityHistory([]);
      })
      .finally(() => {
        setIsLoadingHistory(false);
      });
  }, [userId]);

  if (isNaN(userId)) {
    return (
      <div className="flex h-screen items-center justify-center bg-gray-900 text-gray-400">
        Invalid user ID
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900">
      {/* Header */}
      <header className="sticky top-0 z-10 border-b border-gray-800 bg-gray-900/95 px-6 py-3 backdrop-blur-sm">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigate("/")}
            className="flex items-center gap-1.5 rounded-lg border border-gray-700 px-3 py-1.5 text-sm text-gray-300 transition-colors hover:border-blue-500/50 hover:text-blue-400"
          >
            <ArrowLeft className="h-4 w-4" />
            Back
          </button>
          <div>
            <h1 className="text-lg font-bold text-white">User #{userId}</h1>
            <p className="text-xs text-gray-400">Detailed activity view</p>
          </div>
        </div>
      </header>

      <div className="mx-auto max-w-6xl space-y-6 p-6">
        {/* Live Activity */}
        <LiveActivityPanel userId={userId} />

        {/* Charts side by side */}
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
          <ActivityChart history={liveHistory} />
          <SensorPlot history={liveHistory} />
        </div>

        {/* History Table */}
        <div className="rounded-xl border border-gray-700 bg-gray-800/50 p-4">
          <div className="mb-4 flex items-center gap-2">
            <Clock className="h-4 w-4 text-gray-400" />
            <h3 className="text-sm font-semibold uppercase tracking-wider text-gray-400">
              Activity History
            </h3>
          </div>

          {isLoadingHistory ? (
            <div className="flex items-center justify-center py-8">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-blue-500 border-t-transparent" />
            </div>
          ) : activityHistory.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-8 text-gray-500">
              <Activity className="mb-2 h-6 w-6" />
              <p className="text-sm">No activity history available</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-700 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                    <th className="px-3 py-2">Time</th>
                    <th className="px-3 py-2">Activity</th>
                    <th className="px-3 py-2">Category</th>
                    <th className="px-3 py-2">Confidence</th>
                    <th className="px-3 py-2">Duration</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-700/50">
                  {activityHistory.map((log) => (
                    <tr
                      key={log.id}
                      className="transition-colors hover:bg-gray-700/20"
                    >
                      <td className="whitespace-nowrap px-3 py-2.5 text-gray-400">
                        {formatTimestamp(log.timestamp)}
                      </td>
                      <td className="px-3 py-2.5 font-medium text-white">
                        {formatActivity(log.activity)}
                      </td>
                      <td className="px-3 py-2.5">
                        <span
                          className={`inline-block rounded-full border px-2 py-0.5 text-xs font-medium ${getMacroBadgeColor(log.macro_category)}`}
                        >
                          {log.macro_category}
                        </span>
                      </td>
                      <td className="px-3 py-2.5">
                        <ConfidenceBadge
                          confidence={log.confidence}
                          size="sm"
                        />
                      </td>
                      <td className="px-3 py-2.5 text-gray-400">
                        {log.duration_seconds != null
                          ? `${log.duration_seconds}s`
                          : "-"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
