import React from 'react';
import { ArrowLeftRight } from 'lucide-react';

interface StudentInfoCardProps {
  student: {
    adminNo: string;
    gender: string;
    dob: string;
    blood: string;
    parent: string;
    mobile: string;
    email: string;
    address: string;
  };
  onSwap: () => void;
}

export function StudentInfoCard({ student, onSwap }: StudentInfoCardProps) {
  const infoRows = [
    { label: 'Admn No.', value: student.adminNo },
    { label: 'Gender', value: student.gender },
    { label: 'DOB', value: student.dob },
    { label: 'Blood', value: student.blood },
    { label: 'Parent', value: student.parent },
    { label: 'Mobile', value: student.mobile },
    { label: 'Email', value: student.email },
    { label: 'Address', value: student.address },
  ];

  return (
    <div className="absolute bg-[#fafafa] content-stretch flex flex-col gap-[16px] items-start left-1/2 p-[16px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[264px] translate-x-[-50%] w-[354px]">
      {/* Header */}
      <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
        <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">
          Student Information
        </p>
        <button
          onClick={onSwap}
          className="content-stretch flex gap-[8px] items-center relative shrink-0 hover:opacity-80 transition-opacity"
        >
          <ArrowLeftRight className="size-[24px] text-[#007dfc]" />
          <p
            className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#007dfc] text-[15px] text-nowrap"
            style={{ fontVariationSettings: "'wdth' 100" }}
          >
            Swap
          </p>
        </button>
      </div>

      {/* Divider */}
      <div className="h-0 relative shrink-0 w-full">
        <div className="absolute inset-[-1px_0_0_0]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 322 1">
            <line stroke="#C6DDFF" x2="322" y1="0.5" y2="0.5" />
          </svg>
        </div>
      </div>

      {/* Info rows */}
      {infoRows.map(({ label, value }) => (
        <div key={label} className="content-stretch flex gap-[8px] items-start relative shrink-0 w-full">
          <div className="content-stretch flex flex-col items-start justify-center px-[8px] py-0 relative shrink-0 w-[82px]">
            <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px] text-nowrap">
              {label}
            </p>
          </div>
          <div className="basis-0 grow min-h-px min-w-px relative shrink-0">
            <div className="flex flex-col justify-center size-full">
              <div className="content-stretch flex flex-col items-start justify-center pl-0 pr-[8px] py-0 relative w-full">
                <p
                  className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px]"
                  style={{ fontVariationSettings: "'wdth' 100" }}
                >
                  {value}
                </p>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
