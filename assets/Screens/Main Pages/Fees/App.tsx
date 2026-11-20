import { useState } from 'react';
import svgPaths from './imports/svg-kzmacfwhmw';

interface FeeItem {
  id: string;
  title: string;
  subtitle: string;
  amount: number;
  selected: boolean;
}

export default function App() {
  const [feeItems, setFeeItems] = useState<FeeItem[]>([
    {
      id: '1',
      title: 'Uniform & Text Book',
      subtitle: 'Fees',
      amount: 4500,
      selected: false,
    },
    {
      id: '2',
      title: 'Extracurricular',
      subtitle: 'Fees',
      amount: 4500,
      selected: false,
    },
  ]);

  const toggleFeeItem = (id: string) => {
    setFeeItems((items) =>
      items.map((item) =>
        item.id === id ? { ...item, selected: !item.selected } : item
      )
    );
  };

  const totalAmount = feeItems.reduce(
    (sum, item) => (item.selected ? sum + item.amount : sum),
    0
  );

  return (
    <div className="bg-[#fafafa] overflow-clip relative min-h-screen w-full flex items-center justify-center">
      <div className="relative w-full max-w-[402px] h-[844px] bg-[#fafafa] rounded-[24px] overflow-hidden">
        {/* Header */}
        <div className="absolute content-stretch flex flex-col items-start left-[calc(50%+0.5px)] top-[52px] translate-x-[-50%]">
          <p className="font-['Plus_Jakarta_Sans',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">
            Fees Details
          </p>
        </div>

        {/* Menu Button */}
        <div className="absolute bg-white content-stretch flex flex-col items-center justify-center left-[24px] p-[11px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[39px]">
          <div className="relative shrink-0 size-[24px]">
            <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
              <path d="M13.5 18H4M20 12H4M20 6H4" stroke="#1F2933" strokeLinecap="round" strokeWidth="2" />
            </svg>
          </div>
        </div>

        {/* Notification Button */}
        <div className="absolute bg-white content-stretch flex flex-col gap-[10px] items-center justify-center left-[calc(75%+30.5px)] p-[9px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[39px]">
          <div className="relative shrink-0 size-[28px]">
            <div className="absolute inset-[7.14%]">
              <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
                <path d={svgPaths.p2e393100} stroke="#292D32" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="1.5" />
                <path d={svgPaths.p3718def0} stroke="#292D32" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
                <path d={svgPaths.p21656e00} stroke="#292D32" strokeMiterlimit="10" strokeWidth="1.5" />
              </svg>
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

        {/* Fee Details Card */}
        <div className="absolute bg-white content-stretch flex flex-col gap-[16px] items-start left-1/2 p-[16px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[105px] translate-x-[-50%] w-[354px]">
          {/* Header Section */}
          <div className="content-stretch flex items-start justify-between relative shrink-0 w-full">
            <div className="content-stretch flex flex-col gap-[6px] items-start relative shrink-0 text-nowrap">
              <p className="font-['Plus_Jakarta_Sans',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px]">
                Fee Breakdown
              </p>
              <p className="font-['SF_Pro',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]">
                Academic Year 2025-2026
              </p>
            </div>
            <div className="bg-[#2dbe60] content-stretch flex items-center justify-center px-[10px] py-[6px] relative rounded-[5px] shrink-0">
              <p className="font-['SF_Pro',sans-serif] font-semibold leading-[18px] relative shrink-0 text-[12px] text-nowrap text-white">
                Term 1
              </p>
            </div>
          </div>

          {/* Divider */}
          <div className="h-0 relative shrink-0 w-full">
            <div className="absolute inset-[-1px_0_0_0]">
              <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 322 1">
                <line stroke="#AAD4FD" x2="322" y1="0.5" y2="0.5" />
              </svg>
            </div>
          </div>

          {/* Table Header */}
          <div className="content-stretch flex gap-[130px] items-center px-0 py-[8px] relative shrink-0 w-full">
            <div className="content-stretch flex flex-col gap-[3px] items-start justify-center relative shrink-0">
              <p className="font-['SF_Pro',sans-serif] font-semibold leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap">
                Particular
              </p>
            </div>
            <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
              <p className="font-['SF_Pro',sans-serif] font-semibold leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap">
                Amount
              </p>
            </div>
          </div>

          {/* Fee Items */}
          {feeItems.map((item) => (
            <div key={item.id} className="content-stretch flex items-center justify-between overflow-clip relative shrink-0 w-full">
              <div className="content-stretch flex gap-[8px] items-center relative shrink-0">
                <div className="content-stretch flex flex-col font-['SF_Pro',sans-serif] font-normal gap-[3px] items-start justify-center relative shrink-0 text-[#6b7280] text-nowrap">
                  <p className="leading-[22px] relative shrink-0 text-[15px]">{item.title}</p>
                  <p className="leading-[18px] relative shrink-0 text-[12px]">{item.subtitle}</p>
                </div>
              </div>
              <div className="content-stretch flex gap-[30px] items-center relative shrink-0">
                <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
                  <p className="font-['SF_Pro',sans-serif] font-semibold leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap">
                    ₹ {item.amount.toLocaleString('en-IN')}
                  </p>
                </div>
                <button
                  onClick={() => toggleFeeItem(item.id)}
                  className="relative shrink-0 size-[24px] cursor-pointer"
                  aria-label={`Select ${item.title}`}
                >
                  <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
                    <path
                      d={svgPaths.p21a7200}
                      stroke={item.selected ? "#007DFC" : "#6B7280"}
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="1.5"
                    />
                    {item.selected && (
                      <path
                        d="M7.75 12L10.58 14.83L16.25 9.17"
                        stroke="#007DFC"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="1.5"
                      />
                    )}
                  </svg>
                </button>
              </div>
            </div>
          ))}

          {/* Divider */}
          <div className="h-0 relative shrink-0 w-full">
            <div className="absolute inset-[-1px_0_0_0]">
              <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 322 1">
                <line stroke="#AAD4FD" x2="322" y1="0.5" y2="0.5" />
              </svg>
            </div>
          </div>

          {/* Total Amount */}
          <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
            <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
              <p className="font-['Plus_Jakarta_Sans',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">
                Total Amount
              </p>
            </div>
            <div className="content-stretch flex flex-col items-start justify-center pl-0 pr-[8px] py-0 relative shrink-0">
              <p className="font-['Plus_Jakarta_Sans',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">
                ₹ {totalAmount.toLocaleString('en-IN')}
              </p>
            </div>
          </div>

          {/* Divider */}
          <div className="h-0 relative shrink-0 w-full">
            <div className="absolute inset-[-1px_0_0_0]">
              <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 322 1">
                <line stroke="#AAD4FD" x2="322" y1="0.5" y2="0.5" />
              </svg>
            </div>
          </div>

          {/* Pay Now Button */}
          <div className="bg-[#f1f6fd] relative rounded-[8px] shrink-0 w-full">
            <div className="flex flex-row items-center justify-center size-full">
              <button
                className="content-stretch flex gap-[10px] items-center justify-center px-[8px] py-[12px] relative w-full cursor-pointer hover:bg-[#e5eef9] transition-colors"
                disabled={totalAmount === 0}
              >
                <p className="font-['SF_Pro',sans-serif] font-semibold leading-[0.3px] relative shrink-0 text-[#6b7280] text-[16px] text-nowrap">
                  Pay Now
                </p>
                <div className="relative shrink-0 size-[24px]">
                  <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
                    <path d={svgPaths.p1d6dd700} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.8" />
                    <path d="M3 11.72H21" stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.8" />
                  </svg>
                </div>
              </button>
            </div>
          </div>
        </div>

        {/* Bottom Navigation */}
        <div className="absolute bg-white bottom-0 content-stretch flex flex-col items-start left-1/2 shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_-4px_4px_1px_rgba(229,231,235,0.5)] translate-x-[-50%] w-[402px]">
          <div className="bg-white relative shrink-0 w-full">
            <div className="flex flex-row items-center size-full">
              <div className="content-stretch flex items-center justify-between px-[24px] py-[16px] relative w-full">
                {/* Home */}
                <div className="content-stretch flex flex-col items-center justify-center px-[9px] py-0 relative shrink-0">
                  <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
                    <div className="relative shrink-0 size-[24px]">
                      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
                        <path d="M12 18V15" stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
                        <path d={svgPaths.p1f860900} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
                      </svg>
                    </div>
                    <p className="font-['SF_Pro',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] text-nowrap">
                      Home
                    </p>
                  </div>
                </div>

                {/* Fees (Active) */}
                <div className="content-stretch flex flex-col items-center justify-center px-[12px] py-0 relative shrink-0">
                  <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
                    <div className="relative shrink-0 size-[24px]">
                      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
                        <path d={svgPaths.p347d0e00} fill="#007DFC" />
                        <path d={svgPaths.p2d7b2a40} fill="#007DFC" />
                      </svg>
                    </div>
                    <p className="font-['SF_Pro',sans-serif] font-semibold leading-[18px] relative shrink-0 text-[#007dfc] text-[12px] text-nowrap">
                      Fees
                    </p>
                  </div>
                </div>

                {/* History */}
                <div className="content-stretch flex items-center justify-center px-[6px] py-0 relative shrink-0 w-[48px]">
                  <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
                    <div className="relative shrink-0 size-[24px]">
                      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
                        <path d="M4 4V8H7" stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
                        <path d={svgPaths.p1d901900} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
                        <path d="M12.0006 7L12 12.2752L16 16" stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
                      </svg>
                    </div>
                    <p className="font-['SF_Pro',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] text-nowrap">
                      History
                    </p>
                  </div>
                </div>

                {/* Alerts */}
                <div className="content-stretch flex flex-col items-center justify-center px-[12px] py-0 relative shrink-0">
                  <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
                    <div className="relative shrink-0 size-[24px]">
                      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
                        <path d={svgPaths.p2e393100} stroke="#6B7280" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="1.5" />
                        <path d={svgPaths.p3718def0} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
                        <path d={svgPaths.p21656e00} stroke="#6B7280" strokeMiterlimit="10" strokeWidth="1.5" />
                      </svg>
                    </div>
                    <p className="font-['SF_Pro',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] text-nowrap">
                      Alerts
                    </p>
                  </div>
                </div>

                {/* Profile */}
                <div className="content-stretch flex items-center justify-center px-[8px] py-0 relative shrink-0 w-[53px]">
                  <div className="basis-0 content-stretch flex flex-col gap-[5px] grow items-center min-h-px min-w-px relative shrink-0">
                    <div className="relative shrink-0 size-[24px]">
                      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
                        <path d={svgPaths.p3aeab480} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
                        <path d={svgPaths.p364c500} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
                        <path d={svgPaths.pace200} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
                      </svg>
                    </div>
                    <p className="font-['SF_Pro',sans-serif] font-normal leading-[18px] min-w-full relative shrink-0 text-[#6b7280] text-[12px] w-[min-content]">
                      Profile
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Bottom Handle */}
          <div className="bg-white h-[24px] relative shrink-0 w-full">
            <div className="absolute bg-[#1f2933] h-[4px] left-1/2 rounded-[12px] top-1/2 translate-x-[-50%] translate-y-[-50%] w-[108px]" />
          </div>
        </div>
      </div>
    </div>
  );
}
