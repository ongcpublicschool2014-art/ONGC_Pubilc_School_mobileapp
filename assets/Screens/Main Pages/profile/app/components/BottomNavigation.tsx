import React from 'react';
import { Home, CreditCard, History as HistoryIcon, Bell, User } from 'lucide-react';

interface BottomNavigationProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

export function BottomNavigation({ activeTab, onTabChange }: BottomNavigationProps) {
  const tabs = [
    { id: 'home', label: 'Home', Icon: Home },
    { id: 'fees', label: 'Fees', Icon: CreditCard },
    { id: 'history', label: 'History', Icon: HistoryIcon },
    { id: 'alerts', label: 'Alerts', Icon: Bell },
    { id: 'profile', label: 'Profile', Icon: User },
  ];

  return (
    <div className="absolute bottom-0 content-stretch flex flex-col items-start left-1/2 shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_-4px_4px_1px_rgba(229,231,235,0.5)] translate-x-[-50%] w-[402px]">
      <div className="bg-white relative shrink-0 w-full">
        <div className="flex flex-row items-center size-full">
          <div className="content-stretch flex items-center justify-between px-[24px] py-[16px] relative w-full">
            {tabs.map(({ id, label, Icon }) => (
              <button
                key={id}
                onClick={() => onTabChange(id)}
                className="content-stretch flex flex-col items-center justify-center px-[8px] py-0 relative shrink-0 transition-colors"
              >
                <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
                  <Icon
                    className="shrink-0 size-[24px]"
                    strokeWidth={activeTab === id ? 2 : 1.5}
                    color={activeTab === id ? '#007DFC' : '#6B7280'}
                  />
                  <p
                    className={`font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[12px] text-nowrap ${
                      activeTab === id ? 'font-[590] text-[#007dfc]' : 'font-normal text-[#6b7280]'
                    }`}
                    style={{ fontVariationSettings: "'wdth' 100" }}
                  >
                    {label}
                  </p>
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>
      <div className="bg-white h-[24px] relative shrink-0 w-full">
        <div className="absolute bg-[#1f2933] h-[4px] left-1/2 rounded-[12px] top-1/2 translate-x-[-50%] translate-y-[-50%] w-[108px]" />
      </div>
    </div>
  );
}
