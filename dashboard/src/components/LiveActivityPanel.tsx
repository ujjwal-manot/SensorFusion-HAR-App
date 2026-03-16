import {
  Activity,
  Car,
  Footprints,
  Hand,
  Pause,
  Wifi,
  WifiOff,
  Loader,
} from "lucide-react";
import { useUserLiveFeed } from "../hooks/useWebSocket";
import ConfidenceBadge from "./ConfidenceBadge";

interface LiveActivityPanelProps {
  userId: number;
}

const MACRO_CONFIG: Record<
  string,
  { color: string; bgColor: string; borderColor: string; icon: typeof Activity }
> = {
  stationary: {
    color: "text-green-400",
    bgColor: "bg-green-500/10",
    borderColor: "border-green-500/30",
    icon: Pause,
  },
  locomotion: {
    color: "text-blue-400",
    bgColor: "bg-blue-500/10",
    borderColor: "border-blue-500/30",
    icon: Footprints,
  },
  vehicle: {
    color: "text-orange-400",
    bgColor: "bg-orange-500/10",
    borderColor: "border-orange-500/30",
    icon: Car,
  },
  gesture: {
    color: "text-purple-400",
    bgColor: "bg-purple-500/10",
    borderColor: "border-purple-500/30",
    icon: Hand,
  },
};

function getConfig(macro: string) {
  return (
    MACRO_CONFIG[macro] ?? {
      color: "text-gray-400",
      bgColor: "bg-gray-500/10",
      borderColor: "border-gray-500/30",
      icon: Activity,
    }
  );
}

function formatActivity(activity: string): string {
  return activity
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

function getConfidenceBarColor(confidence: number): string {
  if (confidence >= 0.8) return "bg-green-500";
  if (confidence >= 0.6) return "bg-yellow-500";
  return "bg-red-500";
}

function formatTimeSince(timestamp: string): string {
  const diff = Date.now() - new Date(timestamp).getTime();
  const seconds = Math.floor(diff / 1000);
  if (seconds < 5) return "Just now";
  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  return `${minutes}m ago`;
}

export default function LiveActivityPanel({ userId }: LiveActivityPanelProps) {
  const { latestData, history, connectionStatus } = useUserLiveFeed(userId);

  const config = latestData
    ? getConfig(latestData.macro_category)
    : getConfig("");

  const IconComponent = config.icon;

  return (
    <div
      className={`rounded-xl border ${config.borderColor} ${config.bgColor} p-6`}
    >
      {/* Connection status */}
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-sm font-semibold uppercase tracking-wider text-gray-400">
          Live Activity
        </h3>
        <div className="flex items-center gap-2">
          {connectionStatus === "connected" && (
            <>
              <Wifi className="h-4 w-4 text-green-400" />
              <span className="text-xs text-green-400">Connected</span>
            </>
          )}
          {connectionStatus === "connecting" && (
            <>
              <Loader className="h-4 w-4 animate-spin text-yellow-400" />
              <span className="text-xs text-yellow-400">Connecting...</span>
            </>
          )}
          {connectionStatus === "disconnected" && (
            <>
              <WifiOff className="h-4 w-4 text-red-400" />
              <span className="text-xs text-red-400">Disconnected</span>
            </>
          )}
        </div>
      </div>

      {!latestData ? (
        <div className="flex flex-col items-center justify-center py-8 text-gray-500">
          <Activity className="mb-2 h-8 w-8" />
          <p className="text-sm">Waiting for activity data...</p>
        </div>
      ) : (
        <>
          {/* Main activity display */}
          <div className="mb-4 flex items-center gap-4">
            <div
              className={`flex h-16 w-16 items-center justify-center rounded-2xl ${config.bgColor} border ${config.borderColor}`}
            >
              <IconComponent className={`h-8 w-8 ${config.color}`} />
            </div>
            <div>
              <h2 className="text-2xl font-bold text-white">
                {formatActivity(latestData.activity)}
              </h2>
              <span
                className={`inline-block mt-1 rounded-full px-2.5 py-0.5 text-xs font-medium ${config.bgColor} ${config.color} border ${config.borderColor}`}
              >
                {latestData.macro_category}
              </span>
            </div>
          </div>

          {/* Confidence bar */}
          <div className="mb-3">
            <div className="mb-1 flex items-center justify-between">
              <span className="text-xs text-gray-400">Confidence</span>
              <ConfidenceBadge confidence={latestData.confidence} size="sm" />
            </div>
            <div className="h-2.5 w-full overflow-hidden rounded-full bg-gray-700">
              <div
                className={`h-full rounded-full transition-all duration-500 ${getConfidenceBarColor(latestData.confidence)}`}
                style={{ width: `${latestData.confidence * 100}%` }}
              />
            </div>
          </div>

          {/* Footer info */}
          <div className="flex items-center justify-between text-xs text-gray-500">
            <span>
              {history.length} event{history.length !== 1 ? "s" : ""} recorded
            </span>
            <span>{formatTimeSince(latestData.timestamp)}</span>
          </div>
        </>
      )}
    </div>
  );
}

export { useUserLiveFeed };
