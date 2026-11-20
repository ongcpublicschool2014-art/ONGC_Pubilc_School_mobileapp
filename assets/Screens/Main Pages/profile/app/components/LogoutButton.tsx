import React from 'react';
import { LogOut } from 'lucide-react';

interface LogoutButtonProps {
  onLogout: () => void;
}

export function LogoutButton({ onLogout }: LogoutButtonProps) {
  return (
    <button
      onClick={onLogout}
      className="absolute bg-[#ffd1cf] content-stretch flex gap-[8px] items-center justify-center left-[24px] px-[8px] py-[14px] rounded-[8px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[682px] w-[354px] hover:bg-[#ffbbb8] transition-colors"
    >
      <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
        <p
          className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#dc2626] text-[16px] text-center text-nowrap"
          style={{ fontVariationSettings: "'wdth' 100" }}
        >
          Logout
        </p>
      </div>
      <LogOut className="shrink-0 size-[24px] text-[#dc2626]" />
    </button>
  );
}
