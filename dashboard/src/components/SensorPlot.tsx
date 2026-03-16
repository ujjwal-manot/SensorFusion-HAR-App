import { useMemo } from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import type { LiveFeedMessage } from "../types";

interface SensorPlotProps {
  history: LiveFeedMessage[];
}

export default function SensorPlot({ history }: SensorPlotProps) {
  const chartData = useMemo(() => {
    const recent = history.slice(-60);
    return recent.map((item, index) => ({
      index,
      ax: Number((item.sensor_data[0] ?? 0).toFixed(3)),
      ay: Number((item.sensor_data[1] ?? 0).toFixed(3)),
      az: Number((item.sensor_data[2] ?? 0).toFixed(3)),
      time: new Date(item.timestamp).toLocaleTimeString(),
    }));
  }, [history]);

  if (chartData.length === 0) {
    return (
      <div className="flex h-48 items-center justify-center rounded-xl border border-gray-700 bg-gray-800/50 text-sm text-gray-500">
        No sensor data yet
      </div>
    );
  }

  return (
    <div className="rounded-xl border border-gray-700 bg-gray-800/50 p-4">
      <h3 className="mb-3 text-sm font-semibold uppercase tracking-wider text-gray-400">
        Accelerometer (X, Y, Z)
      </h3>
      <ResponsiveContainer width="100%" height={220}>
        <LineChart data={chartData}>
          <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
          <XAxis
            dataKey="time"
            tick={{ fontSize: 10, fill: "#6b7280" }}
            interval="preserveStartEnd"
            stroke="#374151"
          />
          <YAxis
            tick={{ fontSize: 10, fill: "#6b7280" }}
            stroke="#374151"
          />
          <Tooltip
            contentStyle={{
              backgroundColor: "#1f2937",
              border: "1px solid #374151",
              borderRadius: "8px",
              fontSize: "12px",
              color: "#f9fafb",
            }}
          />
          <Legend
            wrapperStyle={{ fontSize: "12px", color: "#9ca3af" }}
          />
          <Line
            type="monotone"
            dataKey="ax"
            name="Accel X"
            stroke="#ef4444"
            strokeWidth={1.5}
            dot={false}
            animationDuration={300}
          />
          <Line
            type="monotone"
            dataKey="ay"
            name="Accel Y"
            stroke="#22c55e"
            strokeWidth={1.5}
            dot={false}
            animationDuration={300}
          />
          <Line
            type="monotone"
            dataKey="az"
            name="Accel Z"
            stroke="#3b82f6"
            strokeWidth={1.5}
            dot={false}
            animationDuration={300}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
