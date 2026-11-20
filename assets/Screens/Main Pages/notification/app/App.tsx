import { useState } from "react";
import svgPaths from "../imports/svg-97awn6rvfg";
import { NotificationCard } from "./components/NotificationCard";
import { BottomNavigation } from "./components/BottomNavigation";
import { mockNotifications } from "./data/mockNotifications";
import { Notification, NotificationGroup } from "./types/notification";

export default function App() {
  const [notifications, setNotifications] =
    useState<Notification[]>(mockNotifications);
  const [hasUnread, setHasUnread] = useState(true);
  const [menuOpen, setMenuOpen] = useState(false);

  // Group notifications by date
  const groupedNotifications: NotificationGroup[] = notifications.reduce(
    (acc, notification) => {
      const existingGroup = acc.find(
        (group) => group.date === notification.dateGroup
      );
      if (existingGroup) {
        existingGroup.notifications.push(notification);
      } else {
        acc.push({
          date: notification.dateGroup,
          notifications: [notification],
        });
      }
      return acc;
    },
    [] as NotificationGroup[]
  );

  const handleNotificationClick = (notificationId: string) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === notificationId ? { ...n, isRead: true } : n))
    );
    // Check if there are any unread notifications
    const stillHasUnread = notifications.some(
      (n) => !n.isRead && n.id !== notificationId
    );
    setHasUnread(stillHasUnread);
  };

  return (
    <div className="bg-[#fafafa] overflow-clip relative size-full max-w-[402px] mx-auto">
      {/* Header with Menu and Notification Icons */}
      <div className="absolute contents left-[24px] top-[39px]">
        {/* Menu Button */}
        <div
          className="absolute bg-white content-stretch flex flex-col items-center justify-center left-[24px] p-[11px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[39px] cursor-pointer hover:scale-105 transition-transform z-10"
          onClick={() => setMenuOpen(!menuOpen)}
        >
          <div className="relative shrink-0 size-[24px]">
            <svg
              className="block size-full"
              fill="none"
              preserveAspectRatio="none"
              viewBox="0 0 24 24"
            >
              <g id="menu-04">
                <path
                  d="M13.5 18H4M20 12H4M20 6H4"
                  id="Icon"
                  stroke="var(--stroke-0, #1F2933)"
                  strokeLinecap="round"
                  strokeWidth="2"
                />
              </g>
            </svg>
          </div>
        </div>

        {/* Notification Bell Button */}
        <div className="absolute bg-white content-stretch flex flex-col gap-[10px] items-center justify-center left-[calc(75%+30.5px)] p-[9px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[39px] cursor-pointer hover:scale-105 transition-transform z-10">
          <div className="relative shrink-0 size-[28px]">
            <div className="absolute inset-[7.14%]">
              <svg
                className="block size-full"
                fill="none"
                preserveAspectRatio="none"
                viewBox="0 0 24 24"
              >
                <g id="notification">
                  <path
                    d={svgPaths.p2e393100}
                    id="Vector"
                    stroke="var(--stroke-0, #292D32)"
                    strokeLinecap="round"
                    strokeMiterlimit="10"
                    strokeWidth="1.5"
                  />
                  <path
                    d={svgPaths.p3718def0}
                    id="Vector_2"
                    stroke="var(--stroke-0, #292D32)"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeMiterlimit="10"
                    strokeWidth="1.5"
                  />
                  <path
                    d={svgPaths.p21656e00}
                    id="Vector_3"
                    stroke="var(--stroke-0, #292D32)"
                    strokeMiterlimit="10"
                    strokeWidth="1.5"
                  />
                  <g id="Vector_4" opacity="0"></g>
                </g>
              </svg>
            </div>
          </div>
          {hasUnread && (
            <div className="absolute left-[24px] size-[8px] top-[11px]">
              <div className="absolute inset-[-6.25%]">
                <svg
                  className="block size-full"
                  fill="none"
                  preserveAspectRatio="none"
                  viewBox="0 0 9 9"
                >
                  <circle
                    cx="4.5"
                    cy="4.5"
                    fill="var(--fill-0, #007DFC)"
                    id="Ellipse 2"
                    r="4"
                    stroke="var(--stroke-0, white)"
                  />
                </svg>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Title */}
      <div className="absolute content-stretch flex flex-col items-start left-1/2 top-[52px] translate-x-[-50%] z-10">
        <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">
          Notification
        </p>
      </div>

      {/* Notification List */}
      <div className="absolute content-stretch flex flex-col gap-[20px] h-auto max-h-[calc(100vh-200px)] items-start left-1/2 top-[105px] translate-x-[-50%] w-[354px] overflow-y-auto pb-32">
        {groupedNotifications.map((group) => (
          <div
            key={group.date}
            className="content-stretch flex flex-col gap-[12px] items-start relative shrink-0 w-full"
          >
            {/* Date Header */}
            <div className="content-stretch flex items-center px-0 py-[12px] relative shrink-0 w-full">
              <p
                className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap"
                style={{ fontVariationSettings: "'wdth' 100" }}
              >
                {group.date}
              </p>
            </div>

            {/* Notification Cards */}
            {group.notifications.map((notification) => (
              <NotificationCard
                key={notification.id}
                type={notification.type}
                title={notification.title}
                description={notification.description}
                timestamp={notification.timestamp}
                isRead={notification.isRead}
                onClick={() => handleNotificationClick(notification.id)}
              />
            ))}
          </div>
        ))}
      </div>

      {/* Bottom Navigation */}
      <BottomNavigation />
    </div>
  );
}