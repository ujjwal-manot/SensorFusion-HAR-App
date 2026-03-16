interface ConfidenceBadgeProps {
  confidence: number;
  size?: "sm" | "md" | "lg";
}

function getConfidenceColor(confidence: number): string {
  if (confidence >= 0.8) return "bg-green-500/20 text-green-400 border-green-500/30";
  if (confidence >= 0.6) return "bg-yellow-500/20 text-yellow-400 border-yellow-500/30";
  return "bg-red-500/20 text-red-400 border-red-500/30";
}

function getSizeClasses(size: "sm" | "md" | "lg"): string {
  switch (size) {
    case "sm":
      return "px-2 py-0.5 text-xs";
    case "lg":
      return "px-4 py-2 text-lg";
    default:
      return "px-3 py-1 text-sm";
  }
}

export default function ConfidenceBadge({
  confidence,
  size = "md",
}: ConfidenceBadgeProps) {
  const colorClass = getConfidenceColor(confidence);
  const sizeClass = getSizeClasses(size);

  return (
    <span
      className={`inline-flex items-center rounded-full border font-semibold ${colorClass} ${sizeClass}`}
    >
      {(confidence * 100).toFixed(1)}%
    </span>
  );
}
