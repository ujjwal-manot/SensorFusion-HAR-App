import client from "./client";
import type { OnlineUser, ActivityLog } from "../types";

export async function getOnlineUsers(): Promise<OnlineUser[]> {
  const response = await client.get<OnlineUser[]>("/admin/users");
  return response.data;
}

export async function getUserHistory(
  userId: number,
  limit: number = 100
): Promise<ActivityLog[]> {
  const response = await client.get<ActivityLog[]>(
    `/admin/users/${userId}/history`,
    { params: { limit } }
  );
  return response.data;
}
