import { useState } from 'react';
import svgPaths from "../../imports/svg-37cvg2twkg";
import imgEllipse6 from "figma:asset/b54e0cffee83bfae2d59ff3ac1df0631549c8e0f.png";

interface ProfilePanelProps {
  onClose: () => void;
}

function SchoolLogo() {
  return (
    <div className="relative shrink-0 size-[30px]">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 30 30">
        <g id="Group 1000000941">
          <path clipRule="evenodd" d={svgPaths.p30820080} fill="#007DFC" fillRule="evenodd" />
          <path clipRule="evenodd" d={svgPaths.p241c8400} fill="#007DFC" fillRule="evenodd" />
        </g>
      </svg>
    </div>
  );
}

function CloseButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="bg-white overflow-clip relative rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] shrink-0 size-[40px] hover:bg-gray-50 transition-colors"
      aria-label="Close"
    >
      <div className="absolute inset-[20%]">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
          <path d="M6 6.5L18 18.5" stroke="#1F2933" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
          <path d="M6 18.5L18 6.5" stroke="#1F2933" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
        </svg>
      </div>
    </button>
  );
}

function SchoolHeader({ onClose }: { onClose: () => void }) {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <div className="content-stretch flex gap-[4px] items-center relative shrink-0">
        <div className="content-stretch flex items-center p-[5px] relative shrink-0">
          <SchoolLogo />
        </div>
        <div className="content-stretch flex flex-col font-['SF_Pro:Regular',sans-serif] font-normal gap-[4px] items-start relative shrink-0 text-nowrap">
          <p className="leading-[22px] relative shrink-0 text-[#1f2933] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
            Vidyaranya High School
          </p>
          <p className="leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
            7/9, MG Road, Udumalpet.
          </p>
        </div>
      </div>
      <CloseButton onClick={onClose} />
    </div>
  );
}

function UserProfile() {
  return (
    <div className="content-stretch flex gap-[12px] items-center relative shrink-0 w-full">
      <div className="content-stretch flex gap-[12px] items-center relative shrink-0">
        <div className="relative shrink-0 size-[46px]">
          <div className="absolute inset-[-76.09%_-86.96%_-97.83%_-86.96%]">
            <img alt="User avatar" className="block max-w-none size-full" height="126" src={imgEllipse6} width="126" />
          </div>
        </div>
        <div className="content-stretch flex flex-col gap-[4px] items-start relative shrink-0">
          <div className="content-stretch flex items-center justify-center px-0 py-[7px] relative shrink-0">
            <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
              Robert
            </p>
          </div>
          <div className="content-stretch flex items-start relative shrink-0">
            <div className="content-stretch flex font-['SF_Pro:Regular',sans-serif] font-normal gap-[4px] items-center justify-center leading-[18px] relative shrink-0 text-[12px] text-nowrap">
              <p className="relative shrink-0 text-[#6b7280]" style={{ fontVariationSettings: "'wdth' 100" }}>
                Class:
              </p>
              <p className="relative shrink-0 text-[#1f2933]" style={{ fontVariationSettings: "'wdth' 100" }}>
                10-B
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function MenuItem({ 
  icon, 
  label, 
  onClick 
}: { 
  icon: React.ReactNode; 
  label: string; 
  onClick?: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className="relative shrink-0 w-full hover:bg-gray-50 rounded-[6px] transition-colors"
    >
      <div className="flex flex-row items-center size-full">
        <div className="content-stretch flex gap-[8px] items-center p-[8px] relative w-full">
          <div className="content-stretch flex items-center relative rounded-[6px] shrink-0">
            {icon}
          </div>
          <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
            {label}
          </p>
        </div>
      </div>
    </button>
  );
}

function KeyIcon() {
  return (
    <div className="relative shrink-0 size-[24px]">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <path d={svgPaths.p3391b300} fill="#6B7280" />
      </svg>
    </div>
  );
}

function HelpIcon() {
  return (
    <div className="relative shrink-0 size-[24px]">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <path d={svgPaths.p20477c00} fill="#6B7280" />
      </svg>
    </div>
  );
}

function SettingIcon() {
  return (
    <div className="relative shrink-0 size-[24px]">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <path d={svgPaths.p3f496a00} fill="#6B7280" />
      </svg>
    </div>
  );
}

function LogoutButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="bg-[#ffd1cf] relative rounded-[8px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] shrink-0 w-full hover:bg-[#ffbcb9] transition-colors"
    >
      <div className="flex flex-row items-center justify-center overflow-clip rounded-[inherit] size-full">
        <div className="content-stretch flex gap-[8px] items-center justify-center px-[8px] py-[10px] relative w-full">
          <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
            <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#dc2626] text-[15px] text-center text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
              Logout
            </p>
          </div>
          <div className="relative shrink-0 size-[24px]">
            <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
              <path d={svgPaths.p14e7100} fill="#DC2626" />
              <path d={svgPaths.p2f943780} fill="#DC2626" />
            </svg>
          </div>
        </div>
      </div>
    </button>
  );
}

function Divider() {
  return (
    <div className="h-0 relative shrink-0 w-full">
      <div className="absolute inset-[-1px_0_0_0]">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 270 1">
          <line stroke="#AAD4FD" x2="270" y1="0.5" y2="0.5" />
        </svg>
      </div>
    </div>
  );
}

export default function ProfilePanel({ onClose }: ProfilePanelProps) {
  const [notification, setNotification] = useState<string | null>(null);

  const handleChangePassword = () => {
    setNotification('Change Password clicked');
    setTimeout(() => setNotification(null), 2000);
  };

  const handleHelpSupport = () => {
    setNotification('Help & Support clicked');
    setTimeout(() => setNotification(null), 2000);
  };

  const handleSettings = () => {
    setNotification('Settings clicked');
    setTimeout(() => setNotification(null), 2000);
  };

  const handleLogout = () => {
    setNotification('Logging out...');
    setTimeout(() => {
      setNotification(null);
      onClose();
    }, 1500);
  };

  return (
    <div className="bg-[#fafafa] relative rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] size-full">
      {notification && (
        <div className="absolute top-4 left-1/2 transform -translate-x-1/2 bg-gray-800 text-white px-4 py-2 rounded-lg shadow-lg z-50 text-sm">
          {notification}
        </div>
      )}
      <div className="size-full">
        <div className="content-stretch flex flex-col items-start justify-between px-[16px] py-[52px] relative size-full">
          {/* Top Section */}
          <div className="content-stretch flex flex-col gap-[20px] items-start relative shrink-0 w-full">
            <SchoolHeader onClose={onClose} />
            <Divider />
            <UserProfile />
            <Divider />
            <MenuItem icon={<KeyIcon />} label="Change Password" onClick={handleChangePassword} />
            <MenuItem icon={<HelpIcon />} label="Help & Support" onClick={handleHelpSupport} />
            <MenuItem icon={<SettingIcon />} label="Setting" onClick={handleSettings} />
          </div>

          {/* Bottom Section */}
          <div className="content-stretch flex flex-col gap-[20px] items-start relative shrink-0 w-full">
            <Divider />
            <LogoutButton onClick={handleLogout} />
          </div>
        </div>
      </div>
    </div>
  );
}
