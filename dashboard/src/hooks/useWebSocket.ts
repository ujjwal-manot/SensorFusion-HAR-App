import { useState, useEffect, useRef, useCallback } from "react";
import type { LiveFeedMessage } from "../types";

type ConnectionStatus = "connecting" | "connected" | "disconnected";

const MAX_HISTORY = 200;
const RECONNECT_DELAY_MS = 3000;

interface UseLiveFeedReturn {
  latestData: LiveFeedMessage | null;
  history: LiveFeedMessage[];
  connectionStatus: ConnectionStatus;
}

export function useUserLiveFeed(userId: number): UseLiveFeedReturn {
  const [latestData, setLatestData] = useState<LiveFeedMessage | null>(null);
  const [history, setHistory] = useState<LiveFeedMessage[]>([]);
  const [connectionStatus, setConnectionStatus] =
    useState<ConnectionStatus>("disconnected");

  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const mountedRef = useRef(true);

  const connect = useCallback(() => {
    const token = localStorage.getItem("access_token");
    if (!token || !mountedRef.current) return;

    const wsProtocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    const wsHost =
      (typeof import.meta !== "undefined" && import.meta.env?.VITE_WS_URL) ||
      `${wsProtocol}//localhost:8000`;
    const url = `${wsHost}/ws/admin/${userId}?token=${token}`;

    setConnectionStatus("connecting");

    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onopen = () => {
      if (mountedRef.current) {
        setConnectionStatus("connected");
      }
    };

    ws.onmessage = (event) => {
      if (!mountedRef.current) return;
      try {
        const message: LiveFeedMessage = JSON.parse(event.data);
        setLatestData(message);
        setHistory((prev) => {
          const updated = [...prev, message];
          return updated.length > MAX_HISTORY
            ? updated.slice(updated.length - MAX_HISTORY)
            : updated;
        });
      } catch {
        // Ignore malformed messages
      }
    };

    ws.onclose = () => {
      if (!mountedRef.current) return;
      setConnectionStatus("disconnected");
      reconnectTimerRef.current = setTimeout(() => {
        if (mountedRef.current) {
          connect();
        }
      }, RECONNECT_DELAY_MS);
    };

    ws.onerror = () => {
      ws.close();
    };
  }, [userId]);

  useEffect(() => {
    mountedRef.current = true;
    setLatestData(null);
    setHistory([]);
    connect();

    return () => {
      mountedRef.current = false;
      if (reconnectTimerRef.current) {
        clearTimeout(reconnectTimerRef.current);
        reconnectTimerRef.current = null;
      }
      if (wsRef.current) {
        wsRef.current.close();
        wsRef.current = null;
      }
    };
  }, [connect]);

  return { latestData, history, connectionStatus };
}
