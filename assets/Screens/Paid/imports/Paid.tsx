import svgPaths from "./svg-72qxr6mege";
import imgVisaPng41 from "figma:asset/5d085a41c0740ec6118c5c25b886831b4e5db03e.png";

function Frame() {
  return (
    <div className="absolute inset-[20%]" data-name="Frame">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="Frame">
          <path d={svgPaths.p217bb200} fill="var(--fill-0, white)" id="Vector" />
        </g>
      </svg>
    </div>
  );
}

function Term() {
  return (
    <div className="bg-[#2dbe60] overflow-clip relative rounded-[8px] shrink-0 size-[40px]" data-name="Term 3">
      <Frame />
    </div>
  );
}

function Frame3() {
  return (
    <div className="content-stretch flex gap-[5px] items-center justify-center relative shrink-0">
      <div className="h-[14px] relative shrink-0 w-[34px]" data-name="visa_PNG4 1">
        <img alt="" className="absolute inset-0 max-w-none object-50%-50% object-cover pointer-events-none size-full" src={imgVisaPng41} />
      </div>
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        **** 9918
      </p>
    </div>
  );
}

function Frame12() {
  return (
    <div className="content-stretch flex flex-col gap-[6px] items-start relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Tuition Fee
      </p>
      <Frame3 />
    </div>
  );
}

function Frame9() {
  return (
    <div className="content-stretch flex gap-[10px] items-center relative shrink-0">
      <Term />
      <Frame12 />
    </div>
  );
}

function Frame11() {
  return (
    <div className="content-stretch flex flex-col gap-[3px] items-end justify-center relative shrink-0 text-nowrap">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] relative shrink-0 text-[#2dbe60] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Paid
      </p>
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px]">₹ 15,500</p>
    </div>
  );
}

function Frame16() {
  return (
    <div className="content-stretch flex items-start justify-between relative shrink-0 w-full">
      <Frame9 />
      <Frame11 />
    </div>
  );
}

function Frame5() {
  return (
    <div className="content-stretch flex gap-[6px] items-center justify-center relative shrink-0">
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#1f2933] text-[14px] text-nowrap">Paid Date:</p>
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#6b7280] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>{`10 July 2025 `}</p>
      <div className="flex items-center justify-center relative shrink-0">
        <div className="flex-none rotate-[180deg]">
          <div className="relative size-[4px]">
            <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 4">
              <circle cx="2" cy="2" fill="var(--fill-0, #6B7280)" id="Ellipse 7" r="2" />
            </svg>
          </div>
        </div>
      </div>
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#6b7280] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        6:00 pm
      </p>
    </div>
  );
}

function VuesaxLinearArrowLeft() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/arrow-left">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="arrow-left">
          <path d={svgPaths.p2a5cd480} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
          <g id="Vector_2" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function VuesaxLinearArrowLeft1() {
  return (
    <div className="relative size-[24px]" data-name="vuesax/linear/arrow-left">
      <VuesaxLinearArrowLeft />
    </div>
  );
}

function Frame17() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-[322px]">
      <Frame5 />
      <div className="flex items-center justify-center relative shrink-0">
        <div className="flex-none rotate-[180deg]">
          <VuesaxLinearArrowLeft1 />
        </div>
      </div>
    </div>
  );
}

function Frame6() {
  return (
    <div className="content-stretch flex flex-col gap-[12px] items-start relative shrink-0 w-full">
      <Frame16 />
      <Frame17 />
    </div>
  );
}

function Frame15() {
  return (
    <div className="absolute bg-white content-stretch flex flex-col items-end left-[24px] p-[16px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[106px] w-[354px]">
      <Frame6 />
    </div>
  );
}

function VuesaxBoldBus() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/bold/bus">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="bus">
          <g id="Vector" opacity="0"></g>
          <path d={svgPaths.p2657bb00} fill="var(--fill-0, white)" id="Vector_2" />
          <path d={svgPaths.p15b8700} fill="var(--fill-0, white)" id="Vector_3" />
          <path d={svgPaths.p28daad80} fill="var(--fill-0, white)" id="Vector_4" />
        </g>
      </svg>
    </div>
  );
}

function VuesaxBoldBus1() {
  return (
    <div className="absolute inset-[20%]" data-name="vuesax/bold/bus">
      <VuesaxBoldBus />
    </div>
  );
}

function Term1() {
  return (
    <div className="bg-[#2dbe60] overflow-clip relative rounded-[8px] shrink-0 size-[40px]" data-name="Term 4">
      <VuesaxBoldBus1 />
    </div>
  );
}

function Frame4() {
  return (
    <div className="content-stretch flex gap-[5px] items-center justify-center relative shrink-0">
      <div className="h-[14px] relative shrink-0 w-[34px]" data-name="visa_PNG4 1">
        <img alt="" className="absolute inset-0 max-w-none object-50%-50% object-cover pointer-events-none size-full" src={imgVisaPng41} />
      </div>
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        **** 9918
      </p>
    </div>
  );
}

function Frame13() {
  return (
    <div className="content-stretch flex flex-col gap-[6px] items-start relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Bus Fee
      </p>
      <Frame4 />
    </div>
  );
}

function Frame10() {
  return (
    <div className="content-stretch flex gap-[10px] items-center relative shrink-0">
      <Term1 />
      <Frame13 />
    </div>
  );
}

function Frame14() {
  return (
    <div className="content-stretch flex flex-col gap-[3px] items-end justify-center relative shrink-0 text-nowrap">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] relative shrink-0 text-[#2dbe60] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Paid
      </p>
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px]">₹ 10,000</p>
    </div>
  );
}

function Frame18() {
  return (
    <div className="content-stretch flex items-start justify-between relative shrink-0 w-full">
      <Frame10 />
      <Frame14 />
    </div>
  );
}

function Frame7() {
  return (
    <div className="content-stretch flex gap-[6px] items-center justify-center relative shrink-0">
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#1f2933] text-[14px] text-nowrap">Paid Date:</p>
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px] text-nowrap">{`10 July 2025 `}</p>
      <div className="flex items-center justify-center relative shrink-0">
        <div className="flex-none rotate-[180deg]">
          <div className="relative size-[4px]">
            <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 4">
              <circle cx="2" cy="2" fill="var(--fill-0, #6B7280)" id="Ellipse 7" r="2" />
            </svg>
          </div>
        </div>
      </div>
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px] text-nowrap">6:00 pm</p>
    </div>
  );
}

function VuesaxLinearArrowLeft2() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/arrow-left">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="arrow-left">
          <path d={svgPaths.p2a5cd480} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
          <g id="Vector_2" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function VuesaxLinearArrowLeft3() {
  return (
    <div className="relative size-[24px]" data-name="vuesax/linear/arrow-left">
      <VuesaxLinearArrowLeft2 />
    </div>
  );
}

function Frame20() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-[322px]">
      <Frame7 />
      <div className="flex items-center justify-center relative shrink-0">
        <div className="flex-none rotate-[180deg]">
          <VuesaxLinearArrowLeft3 />
        </div>
      </div>
    </div>
  );
}

function Frame8() {
  return (
    <div className="content-stretch flex flex-col gap-[12px] items-start relative shrink-0 w-full">
      <Frame18 />
      <Frame20 />
    </div>
  );
}

function Frame19() {
  return (
    <div className="absolute bg-white content-stretch flex flex-col items-end left-[24px] p-[16px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[232px] w-[354px]">
      <Frame8 />
    </div>
  );
}

function Frame1() {
  return (
    <div className="absolute content-stretch flex flex-col items-start left-1/2 top-[51px] translate-x-[-50%]" data-name="Frame">
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">Paid</p>
    </div>
  );
}

function VuesaxLinearArrowLeft4() {
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

function VuesaxLinearArrowLeft5() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/linear/arrow-left">
      <VuesaxLinearArrowLeft4 />
    </div>
  );
}

function Frame21() {
  return (
    <button className="absolute bg-white content-stretch cursor-pointer flex items-center left-[24px] overflow-clip p-[11px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[40px]">
      <VuesaxLinearArrowLeft5 />
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
            <circle cx="5.25" cy="5.25" fill="var(--fill-0, #007DFC)" id="Ellipse 2" r="4.5" stroke="var(--stroke-0, #FAFAFA)" strokeWidth="1.5" />
          </svg>
        </div>
      </div>
    </div>
  );
}

function Group() {
  return (
    <div className="absolute contents left-1/2 top-[40px] translate-x-[-50%]">
      <Frame2 />
      <Frame1 />
      <Frame21 />
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

export default function Paid() {
  return (
    <div className="bg-[#f8f9fa] overflow-clip relative rounded-[24px] size-full" data-name="Paid">
      <Group />
      <BuildingBlocksNavigation />
      <Frame15 />
      <Frame19 />
    </div>
  );
}