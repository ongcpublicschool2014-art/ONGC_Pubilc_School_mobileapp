import { Notification } from "../types/notification";

export const mockNotifications: Notification[] = [
  {
    id: "1",
    type: "fee-due",
    title: "Upcoming Fee Due",
    description:
      "Term 2 tuition fee of ₹12,000 is due by 20 July 2025. Avoid late charges by paying on time.",
    timestamp: "2 hours ago",
    dateGroup: "Today",
    isRead: true,
    createdAt: new Date("2024-12-29T10:00:00"),
  },
  {
    id: "2",
    type: "payment-success",
    title: "Payment Successful",
    description:
      "Your payment of ₹4,500 for Term 1 was received on 10 July 2025. Receipt is now available to download.",
    timestamp: "10 hours ago",
    dateGroup: "Today",
    isRead: true,
    createdAt: new Date("2024-12-29T02:00:00"),
  },
  {
    id: "3",
    type: "late-fee",
    title: "Late Fee Applied",
    description:
      "A late fee of ₹200 has been added to your Transport Fee for Term 1. Please clear dues to avoid further penalties.",
    timestamp: "Yesterday • 6:00 pm",
    dateGroup: "Yesterday",
    isRead: false,
    createdAt: new Date("2024-12-28T18:00:00"),
  },
  {
    id: "4",
    type: "ptm",
    title: "Parent-Teacher Meeting",
    description:
      "PTM for Class 6 will be held on 25 July 2025 at 10:00 AM in the school auditorium. Attendance is encouraged.",
    timestamp: "7 July 2025 • 6:00 pm",
    dateGroup: "7 July 2025",
    isRead: false,
    createdAt: new Date("2025-07-07T18:00:00"),
  },
];
