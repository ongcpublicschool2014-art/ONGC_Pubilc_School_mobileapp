import { useState } from "react";
import Dashboard from "../../imports/Dashboard";

interface FeeItem {
  id: string;
  title: string;
  amount: number;
  dueDate: string;
  type: "term" | "bus";
}

interface Student {
  name: string;
  adminNo: string;
  class: string;
  bloodGroup: string;
  photo: string;
}

export function FeeDashboard() {
  const [activeTab, setActiveTab] = useState<"home" | "fees" | "history" | "alerts" | "profile">("home");
  
  const student: Student = {
    name: "Robert",
    adminNo: "3562756",
    class: "10-B",
    bloodGroup: "B+",
    photo: "https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=200&h=200&fit=crop"
  };

  const fees: FeeItem[] = [
    {
      id: "1",
      title: "Term-1 Fee",
      amount: 9000,
      dueDate: "Sep 01, 2026",
      type: "term"
    },
    {
      id: "2",
      title: "Bus Fee",
      amount: 10000,
      dueDate: "Sep 01, 2026",
      type: "bus"
    }
  ];

  const totalOutstanding = fees.reduce((sum, fee) => sum + fee.amount, 0);

  return (
    <div className="size-full">
      <Dashboard />
    </div>
  );
}
