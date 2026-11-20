export interface Notification {
  id: string;
  type: "fee-due" | "payment-success" | "late-fee" | "ptm";
  title: string;
  description: string;
  timestamp: string;
  dateGroup: string;
  isRead: boolean;
  createdAt: Date;
}

export interface NotificationGroup {
  date: string;
  notifications: Notification[];
}
