import { useMemo } from "react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import type { LiveFeedMessage } from "../types";

interface ActivityChartProps {
  history: LiveFeedMessage[];
}

const MACRO_COLORS: Record<string, string> = {
  stationary: "#22c55e",
  locomotion: "#3b82f6",
  vehicle: "#f97316",
  gesture: "#a855f7",
};

function getColor(macro: string): string {
  return MACRO_COLORS[macro] ?? "#6b7280";
}

export default function ActivityChart({ history }: ActivityChartProps) {
  const chartData = useMemo(() => {
    const recent = history.slice(-60);
    return recent.map((item, index) => ({
      index,
      confidence: Number((item.confidence * 100).toFixed(1)),
      activity: item.activity.replace(/_/g, " "),
      macro: item.macro_category,
      color: getColor(item.macro_category),
      time: new Date(item.timestamp).toLocaleTimeString(),
    }));
  }, [history]);

  if (chartData.length === 0) {
    return (
      <div className="flex h-48 items-center justify-center rounded-xl border border-gray-700 bg-gray-800/50 text-sm text-gray-500">
        No activity data yet
      </div>
    );
  }

  return (
    <div className="rounded-xl border border-gray-700 bg-gray-800/50 p-4">
      <h3 className="mb-3 text-sm font-semibold uppercase tracking-wider text-gray-400">
        Confidence Over Time
      </h3>
      <ResponsiveContainer width="100%" height={200}>
        <AreaChart data={chartData}>
          <defs>
            <linearGradient id="confidenceGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
              <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
          <XAxis
            dataKey="time"
            tick={{ fontSize: 10, fill: "#6b7280" }}
            interval="preserveStartEnd"
            stroke="#374151"
          />
          <YAxis
            domain={[0, 100]}
            tick={{ fontSize: 10, fill: "#6b7280" }}
            stroke="#374151"
            tickFormatter={(v) => `${v}%`}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: "#1f2937",
              border: "1px solid #374151",
              borderRadius: "8px",
              fontSize: "12px",
              color: "#f9fafb",
            }}
            formatter={(value: number) => [`${value}%`, "Confidence"]}
            labelFormatter={(_, payload) => {
              if (payload.length > 0) {
                const item = payload[0].payload;
                return `${item.activity} (${item.macro})`;
              }
              return "";
            }}
          />
          <Area
            type="monotone"
            dataKey="confidence"
            stroke="#3b82f6"
            strokeWidth={2}
            fill="url(#confidenceGrad)"
            dot={false}
            animationDuration={300}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
