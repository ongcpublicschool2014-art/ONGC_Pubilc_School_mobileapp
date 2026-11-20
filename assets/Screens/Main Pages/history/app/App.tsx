import { useState } from "react";
import svgPaths from "../imports/svg-y33o0oj5ip";
import imgVisaPng41 from "figma:asset/5d085a41c0740ec6118c5c25b886831b4e5db03e.png";

// Types
type PaymentStatus = "paid" | "failed";
type PaymentType = "tuition" | "bus" | "library";

interface Payment {
  id: string;
  type: PaymentType;
  title: string;
  amount: number;
  status: PaymentStatus;
  date: string;
  time: string;
  cardNumber: string;
  term?: number;
}

// Data
const paymentsData: Payment[] = [
  {
    id: "1",
    type: "tuition",
    title: "Tuition Fee",
    amount: 15500,
    status: "paid",
    date: "10 July 2025",
    time: "6:00 pm",
    cardNumber: "**** 9918",
    term: 3,
  },
  {
    id: "2",
    type: "bus",
    title: "Bus Fee",
    amount: 10000,
    status: "paid",
    date: "10 July 2025",
    time: "6:00 pm",
    cardNumber: "**** 9918",
    term: 2,
  },
  {
    id: "3",
    type: "library",
    title: "Library Fee",
    amount: 1000,
    status: "failed",
    date: "10 July 2025",
    time: "6:00 pm",
    cardNumber: "**** 9918",
    term: 1,
  },
];

// Icons Components
function CheckIcon() {
  return (
    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
      <path d={svgPaths.p217bb200} fill="white" />
    </svg>
  );
}

function BusIcon() {
  return (
    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
      <path d={svgPaths.p2657bb00} fill="white" />
      <path d={svgPaths.p15b8700} fill="white" />
      <path d={svgPaths.p28daad80} fill="white" />
    </svg>
  );
}

function CloseIcon() {
  return (
    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
      <path d="M6 6.5L18 18.5" stroke="white" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
      <path d="M6 18.5L18 6.5" stroke="white" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
    </svg>
  );
}

function ArrowRightIcon() {
  return (
    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
      <path d={svgPaths.p2a5cd480} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
    </svg>
  );
}

function MenuIcon() {
  return (
    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
      <path d="M13.5 18H4M20 12H4M20 6H4" stroke="#1F2933" strokeLinecap="round" strokeWidth="2" />
    </svg>
  );
}

function NotificationIcon() {
  return (
    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
      <path d={svgPaths.p2e393100} stroke="#292D32" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="1.5" />
      <path d={svgPaths.p3718def0} stroke="#292D32" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
      <path d={svgPaths.p21656e00} stroke="#292D32" strokeMiterlimit="10" strokeWidth="1.5" />
    </svg>
  );
}

function HomeIcon() {
  return (
    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
      <path d="M12 18V15" stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
      <path d={svgPaths.p1f860900} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
    </svg>
  );
}

function CardIcon() {
  return (
    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
      <path d="M2 8.50496H22" stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
      <path d="M6 16.505H8" stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
      <path d="M10.5 16.505H14.5" stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
      <path d={svgPaths.p34478e00} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
    </svg>
  );
}

function HistoryIcon() {
  return (
    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
      <path d="M4 4V8H7" stroke="#007DFC" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
      <path d={svgPaths.p1d901900} stroke="#007DFC" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
      <path d="M12.0006 7L12 12.2752L16 16" stroke="#007DFC" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
    </svg>
  );
}

function ProfileIcon() {
  return (
    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
      <path d={svgPaths.p3aeab480} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
      <path d={svgPaths.p364c500} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
      <path d={svgPaths.pace200} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
    </svg>
  );
}

// Payment Card Component
function PaymentCard({ payment }: { payment: Payment }) {
  const isPaid = payment.status === "paid";
  const iconBgColor = payment.type === "tuition" || payment.type === "bus" ? "#2dbe60" : "#dc2626";
  
  return (
    <div className="bg-white content-stretch flex flex-col items-end p-[16px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] w-full">
      <div className="content-stretch flex flex-col gap-[12px] items-start w-full">
        {/* Top Section */}
        <div className="content-stretch flex items-start justify-between w-full">
          {/* Left Side */}
          <div className="content-stretch flex gap-[10px] items-center">
            {/* Icon */}
            <div
              className="overflow-clip relative rounded-[8px] shrink-0 size-[40px]"
              style={{ backgroundColor: iconBgColor }}
            >
              <div className="absolute inset-[20%]">
                {payment.type === "tuition" && <CheckIcon />}
                {payment.type === "bus" && <BusIcon />}
                {payment.type === "library" && <CloseIcon />}
              </div>
            </div>
            
            {/* Title and Card Info */}
            <div className="content-stretch flex flex-col gap-[6px] items-start">
              <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
                {payment.title}
              </p>
              <div className="content-stretch flex gap-[5px] items-center justify-center">
                <div className="h-[14px] relative shrink-0 w-[34px]">
                  <img alt="" className="absolute inset-0 max-w-none object-50%-50% object-cover pointer-events-none size-full" src={imgVisaPng41} />
                </div>
                <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
                  {payment.cardNumber}
                </p>
              </div>
            </div>
          </div>
          
          {/* Right Side - Amount */}
          <div className="content-stretch flex flex-col gap-[3px] items-end justify-center text-nowrap">
            <p
              className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] text-[12px]"
              style={{ 
                fontVariationSettings: "'wdth' 100",
                color: isPaid ? "#2dbe60" : "#dc2626"
              }}
            >
              {isPaid ? "Paid" : "Failed"}
            </p>
            <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] text-[#1f2933] text-[18px]">
              ₹ {payment.amount.toLocaleString()}
            </p>
          </div>
        </div>
        
        {/* Bottom Section - Date and Arrow */}
        <div className="content-stretch flex items-center justify-between w-full">
          <div className="content-stretch flex gap-[6px] items-center justify-center">
            <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic text-[#1f2933] text-[14px] text-nowrap">
              {isPaid ? "Paid Date:" : "Failed Date:"}
            </p>
            <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic text-[#6b7280] text-[14px] text-nowrap">
              {payment.date}
            </p>
            <div className="flex items-center justify-center shrink-0">
              <div className="flex-none rotate-[180deg]">
                <div className="relative size-[4px]">
                  <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 4">
                    <circle cx="2" cy="2" fill="#6B7280" r="2" />
                  </svg>
                </div>
              </div>
            </div>
            <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic text-[#6b7280] text-[14px] text-nowrap">
              {payment.time}
            </p>
          </div>
          
          <div className="flex items-center justify-center shrink-0">
            <div className="flex-none rotate-[180deg]">
              <div className="relative size-[24px]">
                <ArrowRightIcon />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Filter Button Component
function FilterButton({ 
  label, 
  isActive, 
  onClick 
}: { 
  label: string; 
  isActive: boolean; 
  onClick: () => void;
}) {
  if (isActive) {
    return (
      <button
        onClick={onClick}
        className="bg-[#1f2933] content-stretch flex items-center px-[16px] py-[10px] rounded-[12px] shrink-0 cursor-pointer"
      >
        <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] text-[#fafafa] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
          {label}
        </p>
      </button>
    );
  }
  
  return (
    <button
      onClick={onClick}
      className="content-stretch flex items-center px-[16px] py-[10px] relative rounded-[12px] shrink-0 cursor-pointer"
    >
      <div aria-hidden="true" className="absolute border border-[#6b7280] border-solid inset-0 pointer-events-none rounded-[12px]" />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        {label}
      </p>
    </button>
  );
}

// Main App Component
export default function App() {
  const [activeFilter, setActiveFilter] = useState<"all" | 1 | 2 | 3>("all");

  const filteredPayments = activeFilter === "all" 
    ? paymentsData 
    : paymentsData.filter(payment => payment.term === activeFilter);

  return (
    <div className="bg-[#fafafa] overflow-clip relative size-full flex items-center justify-center">
      <div className="relative w-full max-w-[402px] h-full bg-[#fafafa] overflow-y-auto">
        {/* Header */}
        <div className="absolute left-[24px] top-[39px] z-10">
          <div className="bg-white content-stretch flex flex-col items-center justify-center p-[11px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)]">
            <div className="size-[24px]">
              <MenuIcon />
            </div>
          </div>
        </div>

        <div className="absolute right-[24px] top-[39px] z-10">
          <div className="bg-white content-stretch flex flex-col gap-[10px] items-center justify-center p-[9px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] relative">
            <div className="size-[28px]">
              <div className="absolute inset-[7.14%]">
                <NotificationIcon />
              </div>
            </div>
            <div className="absolute left-[24px] size-[8px] top-[11px]">
              <div className="absolute inset-[-6.25%]">
                <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 9 9">
                  <circle cx="4.5" cy="4.5" fill="#007DFC" r="4" stroke="white" />
                </svg>
              </div>
            </div>
          </div>
        </div>

        {/* Title */}
        <div className="absolute left-1/2 top-[52px] translate-x-[-50%] z-10">
          <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] text-[#1f2933] text-[18px] text-nowrap">
            History
          </p>
        </div>

        {/* Filter Buttons */}
        <div className="absolute left-[24px] top-[105px] content-stretch flex gap-[16px] items-center z-10">
          <FilterButton label="All" isActive={activeFilter === "all"} onClick={() => setActiveFilter("all")} />
          <FilterButton label="Term 1" isActive={activeFilter === 1} onClick={() => setActiveFilter(1)} />
          <FilterButton label="Term 2" isActive={activeFilter === 2} onClick={() => setActiveFilter(2)} />
          <FilterButton label="Term 3" isActive={activeFilter === 3} onClick={() => setActiveFilter(3)} />
        </div>

        {/* Payment Cards */}
        <div className="absolute left-[24px] right-[24px] top-[159px] flex flex-col gap-[16px]">
          {filteredPayments.map((payment) => (
            <PaymentCard key={payment.id} payment={payment} />
          ))}
        </div>

        {/* Bottom Navigation */}
        <div className="absolute bottom-0 left-1/2 translate-x-[-50%] shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_-4px_4px_1px_rgba(229,231,235,0.5)] w-full max-w-[402px]">
          <div className="bg-white w-full">
            <div className="flex flex-row items-center size-full">
              <div className="content-stretch flex items-center justify-between px-[24px] py-[16px] w-full">
                {/* Home */}
                <div className="content-stretch flex flex-col items-center justify-center px-[9px] py-0">
                  <div className="content-stretch flex flex-col gap-[5px] items-center">
                    <div className="size-[24px]">
                      <HomeIcon />
                    </div>
                    <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
                      Home
                    </p>
                  </div>
                </div>

                {/* Fees */}
                <div className="content-stretch flex flex-col items-center justify-center overflow-clip px-[12px] py-0">
                  <div className="content-stretch flex flex-col gap-[5px] items-center">
                    <div className="size-[24px]">
                      <CardIcon />
                    </div>
                    <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
                      Fees
                    </p>
                  </div>
                </div>

                {/* History (Active) */}
                <div className="content-stretch flex items-center justify-center px-[6px] py-0 w-[48px]">
                  <div className="content-stretch flex flex-col gap-[5px] items-center">
                    <div className="size-[24px]">
                      <HistoryIcon />
                    </div>
                    <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] text-[#007dfc] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
                      History
                    </p>
                  </div>
                </div>

                {/* Alerts */}
                <div className="content-stretch flex flex-col items-center justify-center px-[12px] py-0">
                  <div className="content-stretch flex flex-col gap-[5px] items-center">
                    <div className="size-[24px]">
                      <NotificationIcon />
                    </div>
                    <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
                      Alerts
                    </p>
                  </div>
                </div>

                {/* Profile */}
                <div className="content-stretch flex items-center justify-center px-[8px] py-0 w-[53px]">
                  <div className="basis-0 content-stretch flex flex-col gap-[5px] grow items-center min-h-px min-w-px">
                    <div className="size-[24px]">
                      <ProfileIcon />
                    </div>
                    <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] min-w-full text-[#6b7280] text-[12px] w-[min-content]" style={{ fontVariationSettings: "'wdth' 100" }}>
                      Profile
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          {/* Bottom Handle */}
          <div className="bg-white h-[24px] w-full">
            <div className="absolute bg-[#1f2933] h-[4px] left-1/2 rounded-[12px] top-1/2 translate-x-[-50%] translate-y-[-50%] w-[108px]" />
          </div>
        </div>
      </div>
    </div>
  );
}
