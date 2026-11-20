import React from 'react';
import { Menu, Bell } from 'lucide-react';

interface TopHeaderProps {
  hasNotifications?: boolean;
  onMenuClick: () => void;
  onNotificationClick: () => void;
}

export function TopHeader({ hasNotifications = true, onMenuClick, onNotificationClick }: TopHeaderProps) {
  return (
    <>
      {/* Menu Button */}
      <div className="absolute bg-white content-stretch flex flex-col items-center justify-center left-[24px] p-[11px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[39px]">
        <button onClick={onMenuClick} className="relative shrink-0 size-[24px] hover:opacity-70 transition-opacity">
          <Menu className="size-full text-[#1F2933]" strokeWidth={2} />
        </button>
      </div>

      {/* Notification Button */}
      <div className="absolute bg-white content-stretch flex flex-col gap-[10px] items-center justify-center left-[calc(75%+30.5px)] p-[9px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[39px]">
        <button
          onClick={onNotificationClick}
          className="relative shrink-0 size-[28px] hover:opacity-70 transition-opacity"
        >
          <Bell className="size-full text-[#292D32]" strokeWidth={1.5} />
        </button>
        {hasNotifications && (
          <div className="absolute left-[24px] size-[8px] top-[11px]">
            <div className="absolute inset-[-6.25%]">
              <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 9 9">
                <circle cx="4.5" cy="4.5" fill="#007DFC" r="4" stroke="white" />
              </svg>
            </div>
          </div>
        )}
      </div>

      {/* Title */}
      <div className="absolute content-stretch flex items-center left-[calc(50%+0.5px)] top-[51px] translate-x-[-50%]">
        <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">
          Profile
        </p>
      </div>
    </>
  );
}
