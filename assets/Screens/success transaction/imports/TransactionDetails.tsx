import svgPaths from "./svg-e4xhzm93z0";

function Frame1() {
  return (
    <div className="absolute content-stretch flex flex-col items-start left-1/2 top-[51px] translate-x-[-50%]">
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">Transaction Details</p>
    </div>
  );
}

function VuesaxLinearArrowLeft() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/arrow-left">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="arrow-left">
          <path d={svgPaths.p2a5cd480} id="Vector" stroke="var(--stroke-0, #1F2933)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="2" />
          <g id="Vector_2" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function VuesaxLinearArrowLeft1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/linear/arrow-left">
      <VuesaxLinearArrowLeft />
    </div>
  );
}

function Frame27() {
  return (
    <button className="absolute bg-white content-stretch cursor-pointer flex items-center left-[24px] overflow-clip p-[11px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[40px]">
      <VuesaxLinearArrowLeft1 />
    </button>
  );
}

function VuesaxLinearNotificationBing() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/notification-bing">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 28 28">
        <g id="notification-bing">
          <path d="M14 7.51333V11.3983" id="Vector" stroke="var(--stroke-0, #1F2933)" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="2" />
          <path d={svgPaths.p1ce61900} id="Vector_2" stroke="var(--stroke-0, #1F2933)" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="2" />
          <path d={svgPaths.p116fbe00} id="Vector_3" stroke="var(--stroke-0, #1F2933)" strokeMiterlimit="10" strokeWidth="2" />
          <g id="Vector_4" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function Notification() {
  return (
    <div className="relative shrink-0 size-[28px]" data-name="Notification">
      <VuesaxLinearNotificationBing />
    </div>
  );
}

function Frame2() {
  return (
    <div className="absolute bg-white content-stretch flex flex-col gap-[10px] items-center justify-center left-[calc(75%+30.5px)] p-[9px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[40px]">
      <Notification />
      <div className="absolute left-[25px] size-[9px] top-[8px]">
        <div className="absolute inset-[-8.33%]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 10.5 10.5">
            <circle cx="5.25" cy="5.25" fill="var(--fill-0, #007DFC)" id="Ellipse 2" r="4.5" stroke="var(--stroke-0, white)" strokeWidth="1.5" />
          </svg>
        </div>
      </div>
    </div>
  );
}

function Group2() {
  return (
    <div className="absolute contents left-[24px] top-[40px]">
      <Frame2 />
      <Frame27 />
    </div>
  );
}

function Frame() {
  return (
    <div className="relative shrink-0 size-[36px]" data-name="Frame">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 36 36">
        <g id="Frame">
          <path d={svgPaths.pce34840} fill="var(--fill-0, white)" id="Union" />
        </g>
      </svg>
    </div>
  );
}

function Term() {
  return (
    <div className="bg-[#2dbe60] relative rounded-[50px] shrink-0" data-name="Term 3">
      <div className="content-stretch flex items-center overflow-clip p-[10px] relative rounded-[inherit]">
        <Frame />
      </div>
      <div aria-hidden="true" className="absolute border border-[#f1f6fd] border-solid inset-[-1px] pointer-events-none rounded-[51px]" />
    </div>
  );
}

function Group() {
  return (
    <div className="grid-cols-[max-content] grid-rows-[max-content] inline-grid leading-[0] place-items-start relative shrink-0">
      <p className="[grid-area:1_/_1] font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[28px] ml-0 mt-0 relative text-[22px] text-nowrap text-white" style={{ fontVariationSettings: "'wdth' 100" }}>{`Payment  Successful`}</p>
    </div>
  );
}

function Group1() {
  return (
    <div className="grid-cols-[max-content] grid-rows-[max-content] inline-grid leading-[0] place-items-start relative shrink-0">
      <p className="[grid-area:1_/_1] font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] ml-0 mt-0 relative text-[12px] text-nowrap text-white" style={{ fontVariationSettings: "'wdth' 100" }}>
        Transaction Completed
      </p>
    </div>
  );
}

function Frame4() {
  return (
    <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
      <Term />
      <Group />
      <Group1 />
    </div>
  );
}

function Frame13() {
  return (
    <div className="content-stretch flex flex-col items-center relative shrink-0">
      <Frame4 />
    </div>
  );
}

function Frame3() {
  return (
    <div className="bg-[#2dbe60] relative shrink-0 w-full">
      <div className="flex flex-col items-center overflow-clip rounded-[inherit] size-full">
        <div className="content-stretch flex flex-col items-center p-[16px] relative w-full">
          <Frame13 />
        </div>
      </div>
    </div>
  );
}

function Frame28() {
  return (
    <div className="content-stretch flex flex-col gap-[10px] items-center relative shrink-0">
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] min-w-full not-italic relative shrink-0 text-[#6b7280] text-[14px] text-center w-[min-content]">Amount Paid</p>
      <p className="font-['SF_Pro:Bold',sans-serif] font-bold leading-[36px] relative shrink-0 text-[#2dbe60] text-[26px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        ₹ 15,000
      </p>
    </div>
  );
}

function Frame14() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px] text-nowrap">Transaction ID</p>
    </div>
  );
}

function Frame5() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        #TRA-9826
      </p>
    </div>
  );
}

function Frame20() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <Frame14 />
      <Frame5 />
    </div>
  );
}

function Frame15() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px] text-nowrap">{`Date & Time`}</p>
    </div>
  );
}

function Frame26() {
  return (
    <div className="content-stretch flex gap-[5px] items-center justify-center relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>{`10 July 2025 `}</p>
      <div className="flex items-center justify-center relative shrink-0">
        <div className="flex-none rotate-[180deg]">
          <div className="relative size-[4px]">
            <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 4">
              <circle cx="2" cy="2" fill="var(--fill-0, #1F2933)" id="Ellipse 7" r="2" />
            </svg>
          </div>
        </div>
      </div>
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        6:00 pm
      </p>
    </div>
  );
}

function Frame21() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <Frame15 />
      <Frame26 />
    </div>
  );
}

function Frame16() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px] text-nowrap">Payment Method</p>
    </div>
  );
}

function Frame6() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        VISA**** 9918
      </p>
    </div>
  );
}

function Frame22() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <Frame16 />
      <Frame6 />
    </div>
  );
}

function Frame17() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px] text-nowrap">Fee Type</p>
    </div>
  );
}

function Frame7() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Tuition Fee - Term 1
      </p>
    </div>
  );
}

function Frame23() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <Frame17 />
      <Frame7 />
    </div>
  );
}

function Frame18() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px] text-nowrap">Student</p>
    </div>
  );
}

function Frame8() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Robert
      </p>
    </div>
  );
}

function Frame24() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <Frame18 />
      <Frame8 />
    </div>
  );
}

function Frame19() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px] text-nowrap">Class</p>
    </div>
  );
}

function Frame9() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        10-B
      </p>
    </div>
  );
}

function Frame29() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <Frame19 />
      <Frame9 />
    </div>
  );
}

function Frame25() {
  return (
    <div className="bg-white relative shrink-0 w-full">
      <div className="flex flex-col items-center justify-center size-full">
        <div className="content-stretch flex flex-col gap-[16px] items-center justify-center p-[16px] relative w-full">
          <Frame28 />
          <div className="h-0 relative shrink-0 w-full">
            <div className="absolute inset-[-1px_0_0_0]">
              <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 322 1">
                <line id="Line 50" stroke="var(--stroke-0, #C6DDFF)" x2="322" y1="0.5" y2="0.5" />
              </svg>
            </div>
          </div>
          <Frame20 />
          <Frame21 />
          <Frame22 />
          <Frame23 />
          <Frame24 />
          <Frame29 />
        </div>
      </div>
    </div>
  );
}

function Frame30() {
  return (
    <div className="absolute content-stretch flex flex-col items-start left-[24px] overflow-clip rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[106px] w-[354px]">
      <Frame3 />
      <Frame25 />
    </div>
  );
}

function Download() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="download-01">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="download-01">
          <path d={svgPaths.p2079d700} id="Icon" stroke="var(--stroke-0, #FAFAFA)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        </g>
      </svg>
    </div>
  );
}

function Frame10() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#fafafa] text-[16px] text-center text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Download
      </p>
    </div>
  );
}

function Frame12() {
  return (
    <div className="bg-[#007dfc] content-stretch flex gap-[10px] items-center justify-center overflow-clip px-[8px] py-[14px] relative rounded-[12px] shrink-0 w-[169px]">
      <Download />
      <Frame10 />
    </div>
  );
}

function ShareSocial() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="share-social">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="share-social">
          <path d={svgPaths.p18a74f00} fill="var(--fill-0, #6B7280)" id="Vector" />
        </g>
      </svg>
    </div>
  );
}

function Frame11() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#6b7280] text-[16px] text-center text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Share
      </p>
    </div>
  );
}

function Frame31() {
  return (
    <div className="relative rounded-[12px] shrink-0 w-[169px]">
      <div className="content-stretch flex gap-[10px] items-center justify-center overflow-clip px-[8px] py-[14px] relative rounded-[inherit] w-full">
        <ShareSocial />
        <Frame11 />
      </div>
      <div aria-hidden="true" className="absolute border border-[#6b7280] border-solid inset-0 pointer-events-none rounded-[12px]" />
    </div>
  );
}

function Frame32() {
  return (
    <div className="absolute content-stretch flex gap-[16px] items-center left-[24px] top-[633px]">
      <Frame12 />
      <Frame31 />
    </div>
  );
}

function BuildingBlocksNavigation() {
  return (
    <div className="absolute bottom-0 h-[24px] left-1/2 translate-x-[-50%] w-[402px]" data-name=".Building Blocks/navigation">
      <div className="absolute bg-[#1f2933] h-[4px] left-1/2 rounded-[12px] top-1/2 translate-x-[-50%] translate-y-[-50%] w-[108px]" data-name="handle" />
    </div>
  );
}

export default function TransactionDetails() {
  return (
    <div className="bg-[#f8f9fa] overflow-clip relative rounded-[24px] size-full" data-name="Transaction Details">
      <Frame1 />
      <Group2 />
      <Frame30 />
      <Frame32 />
      <BuildingBlocksNavigation />
    </div>
  );
}