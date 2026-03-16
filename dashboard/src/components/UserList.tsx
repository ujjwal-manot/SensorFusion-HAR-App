import { useMemo, useState } from "react";
import { Search, User as UserIcon } from "lucide-react";
import type { OnlineUser } from "../types";

interface UserListProps {
  users: OnlineUser[];
  selectedId: number | null;
  onSelect: (id: number) => void;
}

function formatTimeSince(dateString: string | null): string {
  if (!dateString) return "Never";
  const diff = Date.now() - new Date(dateString).getTime();
  const seconds = Math.floor(diff / 1000);
  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

function formatActivityLabel(activity: string | null): string {
  if (!activity) return "No activity";
  return activity
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

export default function UserList({
  users,
  selectedId,
  onSelect,
}: UserListProps) {
  const [searchQuery, setSearchQuery] = useState("");

  const filteredAndSorted = useMemo(() => {
    const query = searchQuery.toLowerCase().trim();
    const filtered = query
      ? users.filter(
          (u) =>
            u.display_name.toLowerCase().includes(query) ||
            u.email.toLowerCase().includes(query)
        )
      : users;

    return [...filtered].sort((a, b) => {
      if (a.is_online && !b.is_online) return -1;
      if (!a.is_online && b.is_online) return 1;
      const aTime = a.last_seen ? new Date(a.last_seen).getTime() : 0;
      const bTime = b.last_seen ? new Date(b.last_seen).getTime() : 0;
      return bTime - aTime;
    });
  }, [users, searchQuery]);

  return (
    <div className="flex h-full flex-col">
      <div className="relative p-3">
        <Search className="absolute left-6 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
        <input
          type="text"
          placeholder="Search users..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full rounded-lg border border-gray-700 bg-gray-800 py-2 pl-10 pr-3 text-sm text-white placeholder-gray-500 outline-none transition-colors focus:border-blue-500"
        />
      </div>

      <div className="flex-1 overflow-y-auto px-3 pb-3">
        {filteredAndSorted.length === 0 && (
          <div className="py-8 text-center text-sm text-gray-500">
            No users found
          </div>
        )}

        <div className="space-y-1">
          {filteredAndSorted.map((user) => {
            const isSelected = selectedId === user.id;
            return (
              <button
                key={user.id}
                onClick={() => onSelect(user.id)}
                className={`w-full rounded-lg p-3 text-left transition-all ${
                  isSelected
                    ? "bg-blue-600/20 border border-blue-500/40"
                    : "border border-transparent hover:bg-gray-800"
                }`}
              >
                <div className="flex items-start gap-3">
                  <div className="relative mt-0.5">
                    <div className="flex h-9 w-9 items-center justify-center rounded-full bg-gray-700">
                      <UserIcon className="h-4 w-4 text-gray-300" />
                    </div>
                    <span
                      className={`absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-gray-900 ${
                        user.is_online ? "bg-green-500" : "bg-gray-500"
                      }`}
                    />
                  </div>

                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between">
                      <span className="truncate text-sm font-medium text-white">
                        {user.display_name}
                      </span>
                      <span className="ml-2 shrink-0 text-xs text-gray-500">
                        {formatTimeSince(user.last_seen)}
                      </span>
                    </div>
                    <p className="truncate text-xs text-gray-400">
                      {user.email}
                    </p>
                    <p className="mt-0.5 text-xs text-gray-500">
                      {formatActivityLabel(user.last_activity)}
                    </p>
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
