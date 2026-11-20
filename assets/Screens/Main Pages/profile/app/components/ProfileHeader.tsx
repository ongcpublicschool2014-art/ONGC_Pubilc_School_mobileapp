import React from 'react';
import { Camera } from 'lucide-react';

interface ProfileHeaderProps {
  student: {
    name: string;
    class: string;
    rollNo: string;
    profilePhoto: string;
  };
  onPhotoEdit: () => void;
}

export function ProfileHeader({ student, onPhotoEdit }: ProfileHeaderProps) {
  return (
    <div className="absolute content-stretch flex flex-col gap-[8px] items-center left-1/2 overflow-clip top-[105px] translate-x-[-50%] w-[354px]">
      <div className="content-stretch flex flex-col gap-[10px] items-center relative shrink-0">
        {/* Profile Photo */}
        <div className="relative shrink-0 size-[80px]">
          <div className="absolute inset-[-43.75%_-50%_-56.25%_-50%]">
            <img
              alt={student.name}
              className="block max-w-none size-full object-cover rounded-full"
              height="160"
              src={student.profilePhoto}
              width="160"
            />
          </div>
        </div>

        {/* Student Name and Info */}
        <div className="content-stretch flex flex-col gap-[5px] items-center leading-[0] relative shrink-0">
          <div className="grid-cols-[max-content] grid-rows-[max-content] inline-grid place-items-start relative shrink-0">
            <p
              className="[grid-area:1_/_1] font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[28px] ml-0 mt-0 relative text-[#1f2933] text-[22px] text-nowrap"
              style={{ fontVariationSettings: "'wdth' 100" }}
            >
              {student.name}
            </p>
          </div>
          <div className="grid-cols-[max-content] grid-rows-[max-content] inline-grid place-items-start relative shrink-0">
            <p
              className="[grid-area:1_/_1] font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] ml-0 mt-0 relative text-[#6b7280] text-[15px] text-nowrap"
              style={{ fontVariationSettings: "'wdth' 100" }}
            >
              {student.class} | Roll No:{student.rollNo}
            </p>
          </div>
        </div>
      </div>

      {/* Camera Button */}
      <button
        onClick={onPhotoEdit}
        className="absolute bg-[#007dfc] content-stretch flex items-center left-[191px] p-[6px] rounded-[50px] top-[54px] hover:bg-[#0066cc] transition-colors"
      >
        <div
          aria-hidden="true"
          className="absolute border-2 border-[#fafafa] border-solid inset-0 pointer-events-none rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)]"
        />
        <Camera className="shrink-0 size-[14px] text-white" />
      </button>
    </div>
  );
}
