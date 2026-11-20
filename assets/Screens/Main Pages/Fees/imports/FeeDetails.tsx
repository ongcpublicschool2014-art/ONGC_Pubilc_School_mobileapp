import svgPaths from "./svg-kzmacfwhmw";

function Frame() {
  return (
    <div className="absolute content-stretch flex flex-col items-start left-[calc(50%+0.5px)] top-[52px] translate-x-[-50%]" data-name="Frame">
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">Fees Details</p>
    </div>
  );
}

function Menu() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="menu-04">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="menu-04">
          <path d="M13.5 18H4M20 12H4M20 6H4" id="Icon" stroke="var(--stroke-0, #1F2933)" strokeLinecap="round" strokeWidth="2" />
        </g>
      </svg>
    </div>
  );
}

function Frame1() {
  return (
    <div className="absolute bg-white content-stretch flex flex-col items-center justify-center left-[24px] p-[11px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[39px]">
      <Menu />
    </div>
  );
}

function VuesaxLinearNotification() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/notification">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="notification">
          <path d={svgPaths.p2e393100} id="Vector" stroke="var(--stroke-0, #292D32)" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="1.5" />
          <path d={svgPaths.p3718def0} id="Vector_2" stroke="var(--stroke-0, #292D32)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
          <path d={svgPaths.p21656e00} id="Vector_3" stroke="var(--stroke-0, #292D32)" strokeMiterlimit="10" strokeWidth="1.5" />
          <g id="Vector_4" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function VuesaxLinearNotification1() {
  return (
    <div className="absolute inset-[7.14%]" data-name="vuesax/linear/notification">
      <VuesaxLinearNotification />
    </div>
  );
}

function Notification() {
  return (
    <div className="relative shrink-0 size-[28px]" data-name="Notification">
      <VuesaxLinearNotification1 />
    </div>
  );
}

function Frame2() {
  return (
    <div className="absolute bg-white content-stretch flex flex-col gap-[10px] items-center justify-center left-[calc(75%+30.5px)] p-[9px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[39px]">
      <Notification />
      <div className="absolute left-[24px] size-[8px] top-[11px]">
        <div className="absolute inset-[-6.25%]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 9 9">
            <circle cx="4.5" cy="4.5" fill="var(--fill-0, #007DFC)" id="Ellipse 2" r="4" stroke="var(--stroke-0, white)" />
          </svg>
        </div>
      </div>
    </div>
  );
}

function Group() {
  return (
    <div className="absolute contents left-[24px] top-[39px]">
      <Frame1 />
      <Frame2 />
    </div>
  );
}

function Frame15() {
  return (
    <div className="content-stretch flex flex-col gap-[6px] items-start relative shrink-0 text-nowrap">
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px]">Fee Breakdown</p>
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Academic Year 2025-2026
      </p>
    </div>
  );
}

function Frame27() {
  return (
    <div className="bg-[#2dbe60] content-stretch flex items-center justify-center px-[10px] py-[6px] relative rounded-[5px] shrink-0">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] relative shrink-0 text-[12px] text-nowrap text-white" style={{ fontVariationSettings: "'wdth' 100" }}>
        Term 1
      </p>
    </div>
  );
}

function Frame28() {
  return (
    <div className="content-stretch flex items-start justify-between relative shrink-0 w-full">
      <Frame15 />
      <Frame27 />
    </div>
  );
}

function Frame16() {
  return (
    <div className="content-stretch flex flex-col gap-[3px] items-start justify-center relative shrink-0">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Particular
      </p>
    </div>
  );
}

function Frame17() {
  return (
    <div className="content-stretch flex gap-[8px] items-center relative shrink-0">
      <Frame16 />
    </div>
  );
}

function Frame9() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Amount
      </p>
    </div>
  );
}

function Frame24() {
  return (
    <div className="content-stretch flex gap-[10px] items-center relative shrink-0">
      <Frame9 />
    </div>
  );
}

function Frame29() {
  return (
    <div className="content-stretch flex gap-[130px] items-center px-0 py-[8px] relative shrink-0 w-full">
      <Frame17 />
      <Frame24 />
    </div>
  );
}

function Frame18() {
  return (
    <div className="content-stretch flex flex-col font-['SF_Pro:Regular',sans-serif] font-normal gap-[3px] items-start justify-center relative shrink-0 text-[#6b7280] text-nowrap">
      <p className="leading-[22px] relative shrink-0 text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>{`Uniform & Text Book`}</p>
      <p className="leading-[18px] relative shrink-0 text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Fees
      </p>
    </div>
  );
}

function Frame19() {
  return (
    <div className="content-stretch flex gap-[8px] items-center relative shrink-0">
      <Frame18 />
    </div>
  );
}

function Frame11() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        ₹ 4,500
      </p>
    </div>
  );
}

function VuesaxLinearTickSquare() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/tick-square">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="tick-square">
          <path d={svgPaths.p21a7200} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
          <g id="Vector_2" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function CheckBox() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="check box">
      <VuesaxLinearTickSquare />
    </div>
  );
}

function Frame25() {
  return (
    <div className="content-stretch flex gap-[30px] items-center relative shrink-0">
      <Frame11 />
      <CheckBox />
    </div>
  );
}

function Frame31() {
  return (
    <div className="content-stretch flex items-center justify-between overflow-clip relative shrink-0 w-full">
      <Frame19 />
      <Frame25 />
    </div>
  );
}

function Frame20() {
  return (
    <div className="content-stretch flex flex-col font-['SF_Pro:Regular',sans-serif] font-normal gap-[3px] items-start justify-center relative shrink-0 text-[#6b7280] text-nowrap">
      <p className="leading-[22px] relative shrink-0 text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Extracurricular
      </p>
      <p className="leading-[18px] relative shrink-0 text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Fees
      </p>
    </div>
  );
}

function Frame21() {
  return (
    <div className="content-stretch flex gap-[8px] items-center relative shrink-0">
      <Frame20 />
    </div>
  );
}

function Frame12() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        ₹ 4,500
      </p>
    </div>
  );
}

function VuesaxLinearTickSquare1() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/tick-square">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="tick-square">
          <path d={svgPaths.p21a7200} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
          <g id="Vector_2" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function CheckBox1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="check box">
      <VuesaxLinearTickSquare1 />
    </div>
  );
}

function Frame26() {
  return (
    <div className="content-stretch flex gap-[30px] items-center relative shrink-0">
      <Frame12 />
      <CheckBox1 />
    </div>
  );
}

function Frame30() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <Frame21 />
      <Frame26 />
    </div>
  );
}

function Frame22() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">Total Amount</p>
    </div>
  );
}

function Frame13() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center pl-0 pr-[8px] py-0 relative shrink-0">
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">₹ 0</p>
    </div>
  );
}

function Frame23() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <Frame22 />
      <Frame13 />
    </div>
  );
}

function VuesaxLinearArrow() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/arrow-2">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="arrow-2">
          <g id="Group">
            <path d={svgPaths.p1d6dd700} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.8" />
            <path d="M3 11.72H21" id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.8" />
          </g>
          <g id="Vector_3" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function VuesaxLinearArrow1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/linear/arrow-2">
      <VuesaxLinearArrow />
    </div>
  );
}

function Frame8() {
  return (
    <div className="bg-[#f1f6fd] relative rounded-[8px] shrink-0 w-full">
      <div className="flex flex-row items-center justify-center size-full">
        <div className="content-stretch flex gap-[10px] items-center justify-center px-[8px] py-[12px] relative w-full">
          <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#6b7280] text-[16px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
            Pay Now
          </p>
          <VuesaxLinearArrow1 />
        </div>
      </div>
    </div>
  );
}

function FeesSelectionContainer() {
  return (
    <div className="absolute bg-white content-stretch flex flex-col gap-[16px] items-start left-1/2 p-[16px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[105px] translate-x-[-50%] w-[354px]" data-name="Fees Selection Container">
      <Frame28 />
      <div className="h-0 relative shrink-0 w-full">
        <div className="absolute inset-[-1px_0_0_0]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 322 1">
            <line id="Line 50" stroke="var(--stroke-0, #AAD4FD)" x2="322" y1="0.5" y2="0.5" />
          </svg>
        </div>
      </div>
      <Frame29 />
      <Frame31 />
      <Frame30 />
      <div className="h-0 relative shrink-0 w-full">
        <div className="absolute inset-[-1px_0_0_0]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 322 1">
            <line id="Line 50" stroke="var(--stroke-0, #AAD4FD)" x2="322" y1="0.5" y2="0.5" />
          </svg>
        </div>
      </div>
      <Frame23 />
      <div className="h-0 relative shrink-0 w-full">
        <div className="absolute inset-[-1px_0_0_0]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 322 1">
            <line id="Line 50" stroke="var(--stroke-0, #AAD4FD)" x2="322" y1="0.5" y2="0.5" />
          </svg>
        </div>
      </div>
      <Frame8 />
    </div>
  );
}

function VuesaxLinearHome() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/home">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="home">
          <path d="M12 18V15" id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
          <path d={svgPaths.p1f860900} id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
          <g id="Vector_3" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function NavBarIcon() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="Nav Bar Icon">
      <VuesaxLinearHome />
    </div>
  );
}

function Frame4() {
  return (
    <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
      <NavBarIcon />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Home
      </p>
    </div>
  );
}

function NavBar() {
  return (
    <div className="content-stretch flex flex-col items-center justify-center px-[9px] py-0 relative shrink-0" data-name="Nav Bar">
      <Frame4 />
    </div>
  );
}

function VuesaxBoldCard() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/bold/card">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="card">
          <path d={svgPaths.p347d0e00} fill="var(--fill-0, #007DFC)" id="Vector" />
          <path d={svgPaths.p2d7b2a40} fill="var(--fill-0, #007DFC)" id="Vector_2" />
          <g id="Vector_3" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function VuesaxBoldCard1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/bold/card">
      <VuesaxBoldCard />
    </div>
  );
}

function Frame3() {
  return (
    <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
      <VuesaxBoldCard1 />
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] relative shrink-0 text-[#007dfc] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Fees
      </p>
    </div>
  );
}

function NavBar1() {
  return (
    <div className="content-stretch flex flex-col items-center justify-center px-[12px] py-0 relative shrink-0" data-name="Nav Bar">
      <Frame3 />
    </div>
  );
}

function History() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="history">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g clipPath="url(#clip0_1_937)" id="history">
          <g id="Vector"></g>
          <path d="M4 4V8H7" id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
          <path d={svgPaths.p1d901900} id="Vector_3" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
          <path d="M12.0006 7L12 12.2752L16 16" id="Vector_4" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
        </g>
        <defs>
          <clipPath id="clip0_1_937">
            <rect fill="white" height="24" width="24" />
          </clipPath>
        </defs>
      </svg>
    </div>
  );
}

function Frame5() {
  return (
    <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
      <History />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        History
      </p>
    </div>
  );
}

function NavBar2() {
  return (
    <div className="content-stretch flex items-center justify-center px-[6px] py-0 relative shrink-0 w-[48px]" data-name="Nav Bar">
      <Frame5 />
    </div>
  );
}

function VuesaxLinearNotification2() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/notification">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="notification">
          <path d={svgPaths.p2e393100} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="1.5" />
          <path d={svgPaths.p3718def0} id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
          <path d={svgPaths.p21656e00} id="Vector_3" stroke="var(--stroke-0, #6B7280)" strokeMiterlimit="10" strokeWidth="1.5" />
          <g id="Vector_4" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function VuesaxLinearNotification3() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/linear/notification">
      <VuesaxLinearNotification2 />
    </div>
  );
}

function Frame6() {
  return (
    <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
      <VuesaxLinearNotification3 />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Alerts
      </p>
    </div>
  );
}

function NavBar3() {
  return (
    <div className="content-stretch flex flex-col items-center justify-center px-[12px] py-0 relative shrink-0" data-name="Nav Bar">
      <Frame6 />
    </div>
  );
}

function VuesaxLinearProfileCircle() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/profile-circle">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="profile-circle">
          <path d={svgPaths.p3aeab480} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
          <path d={svgPaths.p364c500} id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
          <path d={svgPaths.pace200} id="Vector_3" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
          <g id="Vector_4" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function VuesaxLinearProfileCircle1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/linear/profile-circle">
      <VuesaxLinearProfileCircle />
    </div>
  );
}

function Frame7() {
  return (
    <div className="basis-0 content-stretch flex flex-col gap-[5px] grow items-center min-h-px min-w-px relative shrink-0">
      <VuesaxLinearProfileCircle1 />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] min-w-full relative shrink-0 text-[#6b7280] text-[12px] w-[min-content]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Profile
      </p>
    </div>
  );
}

function NavBar4() {
  return (
    <div className="content-stretch flex items-center justify-center px-[8px] py-0 relative shrink-0 w-[53px]" data-name="Nav Bar">
      <Frame7 />
    </div>
  );
}

function Frame10() {
  return (
    <div className="bg-white relative shrink-0 w-full">
      <div className="flex flex-row items-center size-full">
        <div className="content-stretch flex items-center justify-between px-[24px] py-[16px] relative w-full">
          <NavBar />
          <NavBar1 />
          <NavBar2 />
          <NavBar3 />
          <NavBar4 />
        </div>
      </div>
    </div>
  );
}

function BuildingBlocksNavigation() {
  return (
    <div className="bg-white h-[24px] relative shrink-0 w-full" data-name=".Building Blocks/navigation">
      <div className="absolute bg-[#1f2933] h-[4px] left-1/2 rounded-[12px] top-1/2 translate-x-[-50%] translate-y-[-50%] w-[108px]" data-name="handle" />
    </div>
  );
}

function Frame14() {
  return (
    <div className="absolute bg-white bottom-0 content-stretch flex flex-col items-start left-1/2 shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_-4px_4px_1px_rgba(229,231,235,0.5)] translate-x-[-50%] w-[402px]">
      <Frame10 />
      <BuildingBlocksNavigation />
    </div>
  );
}

export default function FeeDetails() {
  return (
    <div className="bg-[#fafafa] overflow-clip relative rounded-[24px] size-full" data-name="Fee Details">
      <Frame14 />
      <Frame />
      <Group />
      <FeesSelectionContainer />
    </div>
  );
}