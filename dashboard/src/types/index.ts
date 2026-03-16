export interface User {
  id: number;
  email: string;
  display_name: string;
  role: string;
  created_at?: string;
}

export interface OnlineUser {
  id: number;
  email: string;
  display_name: string;
  is_online: boolean;
  last_activity: string | null;
  last_seen: string | null;
}

export interface ActivityLog {
  id: number;
  activity: string;
  macro_category: string;
  confidence: number;
  timestamp: string;
  duration_seconds?: number;
}

export interface LiveFeedMessage {
  activity: string;
  macro_category: string;
  confidence: number;
  sensor_data: number[];
  timestamp: string;
}
