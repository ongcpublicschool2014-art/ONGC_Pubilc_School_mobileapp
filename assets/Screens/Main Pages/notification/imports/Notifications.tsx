import svgPaths from "./svg-97awn6rvfg";

function Wrapper3({ children }: React.PropsWithChildren<{}>) {
  return (
    <div className="content-stretch flex items-center px-0 py-[12px] relative shrink-0 w-full">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        {children}
      </p>
    </div>
  );
}
type Wrapper2Props = {
  additionalClassNames?: string;
};

function Wrapper2({ children, additionalClassNames = "" }: React.PropsWithChildren<Wrapper2Props>) {
  return (
    <div className={additionalClassNames}>
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        {children}
      </svg>
    </div>
  );
}

function Wrapper1({ children }: React.PropsWithChildren<{}>) {
  return (
    <div className="relative shrink-0 w-full">
      <div className="flex flex-row items-center size-full">
        <div className="content-stretch flex items-center justify-between pl-0 pr-[8px] py-0 relative w-full">{children}</div>
      </div>
    </div>
  );
}

function Wrapper({ children }: React.PropsWithChildren<{}>) {
  return (
    <Wrapper2 additionalClassNames="absolute contents inset-0">
      <g id="notification">{children}</g>
    </Wrapper2>
  );
}

function Helper() {
  return (
    <div className="flex items-center justify-center relative shrink-0">
      <div className="flex-none rotate-[180deg]">
        <div className="relative size-[4px]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 4">
            <circle cx="2" cy="2" fill="var(--fill-0, #007DFC)" id="Ellipse 7" r="2" />
          </svg>
        </div>
      </div>
    </div>
  );
}

function VuesaxLinearArrowLeft() {
  return (
    <div className="absolute contents inset-0">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 20 20">
        <g id="arrow-left">
          <path d={svgPaths.p3a43fe80} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
          <g id="Vector_2" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}
type Text1Props = {
  text: string;
};

function Text1({ text }: Text1Props) {
  return (
    <div className="content-stretch flex items-center justify-center relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#007dfc] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        {text}
      </p>
    </div>
  );
}
type TextProps = {
  text: string;
};

function Text({ text }: TextProps) {
  return (
    <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        {text}
      </p>
    </div>
  );
}

function Frame10() {
  return <Wrapper3>Today</Wrapper3>;
}

function VuesaxBoldNotification() {
  return (
    <Wrapper>
      <path d={svgPaths.pcd71700} fill="var(--fill-0, #1F2933)" id="Vector" />
      <path d={svgPaths.p144aa1f0} fill="var(--fill-0, #1F2933)" id="Vector_2" />
      <g id="Vector_3" opacity="0"></g>
    </Wrapper>
  );
}

function VuesaxBoldNotification1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/bold/notification">
      <VuesaxBoldNotification />
    </div>
  );
}

function Frame26() {
  return (
    <div className="content-stretch flex items-start px-px py-[2px] relative rounded-[6px] shrink-0">
      <VuesaxBoldNotification1 />
    </div>
  );
}

function Frame27() {
  return (
    <div className="content-stretch flex items-center px-0 py-[3px] relative shrink-0">
      <Frame26 />
    </div>
  );
}

function VuesaxLinearArrowLeft1() {
  return (
    <div className="relative size-[20px]" data-name="vuesax/linear/arrow-left">
      <VuesaxLinearArrowLeft />
    </div>
  );
}

function Frame28() {
  return (
    <Wrapper1>
      <Text1 text="2 hours ago" />
      <div className="flex items-center justify-center relative shrink-0">
        <div className="flex-none rotate-[180deg]">
          <VuesaxLinearArrowLeft1 />
        </div>
      </div>
    </Wrapper1>
  );
}

function Frame25() {
  return (
    <div className="basis-0 content-stretch flex flex-col gap-[6px] grow items-start min-h-px min-w-px relative shrink-0">
      <Text text="Upcoming Fee Due" />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal h-[36px] leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] w-full" style={{ fontVariationSettings: "'wdth' 100" }}>
        Term 2 tuition fee of ₹12,000 is due by 20 July 2025. Avoid late charges by paying on time.
      </p>
      <Frame28 />
    </div>
  );
}

function Frame16() {
  return (
    <div className="bg-white content-stretch flex gap-[8px] items-start p-[12px] relative rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] shrink-0 w-[354px]">
      <Frame27 />
      <Frame25 />
    </div>
  );
}

function VuesaxBoldMoneyTick() {
  return (
    <Wrapper2 additionalClassNames="absolute contents inset-0">
      <g id="money-tick">
        <path d={svgPaths.p2352480} fill="var(--fill-0, #1F2933)" id="Vector" />
        <g id="Vector_2" opacity="0"></g>
        <path d={svgPaths.p2c85ddb0} fill="var(--fill-0, #1F2933)" id="Vector_3" />
      </g>
    </Wrapper2>
  );
}

function PaymentSuccess() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="Payment success">
      <VuesaxBoldMoneyTick />
    </div>
  );
}

function Frame29() {
  return (
    <div className="content-stretch flex items-start px-px py-[2px] relative rounded-[6px] shrink-0">
      <PaymentSuccess />
    </div>
  );
}

function Frame30() {
  return (
    <div className="content-stretch flex items-center px-0 py-[3px] relative shrink-0">
      <Frame29 />
    </div>
  );
}

function VuesaxLinearArrowLeft2() {
  return (
    <div className="relative size-[20px]" data-name="vuesax/linear/arrow-left">
      <VuesaxLinearArrowLeft />
    </div>
  );
}

function Frame31() {
  return (
    <Wrapper1>
      <Text1 text="10 hours ago" />
      <div className="flex items-center justify-center relative shrink-0">
        <div className="flex-none rotate-[180deg]">
          <VuesaxLinearArrowLeft2 />
        </div>
      </div>
    </Wrapper1>
  );
}

function Frame32() {
  return (
    <div className="basis-0 content-stretch flex flex-col gap-[6px] grow items-start min-h-px min-w-px relative shrink-0">
      <Text text="Payment Successful" />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] min-w-full relative shrink-0 text-[#6b7280] text-[12px] w-[min-content]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Your payment of ₹4,500 for Term 1 was received on 10 July 2025. Receipt is now available to download.
      </p>
      <Frame31 />
    </div>
  );
}

function Frame17() {
  return (
    <div className="bg-white content-stretch flex gap-[8px] items-start p-[12px] relative rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] shrink-0 w-[354px]">
      <Frame30 />
      <Frame32 />
    </div>
  );
}

function Frame15() {
  return (
    <div className="content-stretch flex flex-col gap-[12px] items-start relative shrink-0 w-full">
      <Frame10 />
      <Frame16 />
      <Frame17 />
    </div>
  );
}

function Frame11() {
  return (
    <div className="content-stretch flex items-center px-0 py-[12px] relative shrink-0 w-full">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] w-[79px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Yesterday
      </p>
    </div>
  );
}

function VuesaxBoldMoneyTime() {
  return (
    <Wrapper2 additionalClassNames="absolute contents inset-0">
      <g id="money-time">
        <g id="Vector" opacity="0"></g>
        <path d={svgPaths.p250f3800} fill="var(--fill-0, #6B7280)" id="Vector_2" />
        <path d={svgPaths.p2352480} fill="var(--fill-0, #6B7280)" id="Vector_3" />
      </g>
    </Wrapper2>
  );
}

function LateFeeApplyed() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="Late Fee Applyed">
      <VuesaxBoldMoneyTime />
    </div>
  );
}

function Frame33() {
  return (
    <div className="content-stretch flex items-start px-px py-[2px] relative rounded-[6px] shrink-0">
      <LateFeeApplyed />
    </div>
  );
}

function Frame34() {
  return (
    <div className="content-stretch flex items-center px-0 py-[3px] relative shrink-0">
      <Frame33 />
    </div>
  );
}

function Frame13() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#6b7280] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Late Fee Applied
      </p>
    </div>
  );
}

function Frame23() {
  return (
    <div className="content-stretch flex gap-[5px] items-center justify-center relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#007dfc] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Yesterday
      </p>
      <Helper />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#007dfc] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        6:00 pm
      </p>
    </div>
  );
}

function VuesaxLinearArrowLeft3() {
  return (
    <div className="relative size-[20px]" data-name="vuesax/linear/arrow-left">
      <VuesaxLinearArrowLeft />
    </div>
  );
}

function Frame35() {
  return (
    <Wrapper1>
      <Frame23 />
      <div className="flex items-center justify-center relative shrink-0">
        <div className="flex-none rotate-[180deg]">
          <VuesaxLinearArrowLeft3 />
        </div>
      </div>
    </Wrapper1>
  );
}

function Frame36() {
  return (
    <div className="basis-0 content-stretch flex flex-col gap-[6px] grow items-start min-h-px min-w-px relative shrink-0">
      <Frame13 />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] min-w-full relative shrink-0 text-[#6b7280] text-[12px] w-[min-content]" style={{ fontVariationSettings: "'wdth' 100" }}>
        A late fee of ₹200 has been added to your Transport Fee for Term 1. Please clear dues to avoid further penalties.
      </p>
      <Frame35 />
    </div>
  );
}

function Frame18() {
  return (
    <div className="bg-[#fafafa] content-stretch flex gap-[8px] items-start p-[12px] relative rounded-[12px] shadow-[0px_0px_3px_3px_rgba(0,95,204,0.24)] shrink-0 w-[354px]">
      <Frame34 />
      <Frame36 />
    </div>
  );
}

function Frame19() {
  return (
    <div className="content-stretch flex flex-col gap-[12px] items-start relative shrink-0 w-full">
      <Frame11 />
      <Frame18 />
    </div>
  );
}

function Frame12() {
  return <Wrapper3>{`7 July 2025 `}</Wrapper3>;
}

function VuesaxBoldProfile2User() {
  return (
    <Wrapper2 additionalClassNames="absolute contents inset-0">
      <g id="profile-2user">
        <path d={svgPaths.p85bb080} fill="var(--fill-0, #6B7280)" id="Vector" />
        <path d={svgPaths.p128ca00} fill="var(--fill-0, #6B7280)" id="Vector_2" />
        <path d={svgPaths.p266c4000} fill="var(--fill-0, #6B7280)" id="Vector_3" />
        <path d={svgPaths.p86b9f80} fill="var(--fill-0, #6B7280)" id="Vector_4" />
        <g id="Vector_5" opacity="0"></g>
      </g>
    </Wrapper2>
  );
}

function Ptm() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="PTM">
      <VuesaxBoldProfile2User />
    </div>
  );
}

function Frame37() {
  return (
    <div className="content-stretch flex items-start px-px py-[2px] relative rounded-[6px] shrink-0">
      <Ptm />
    </div>
  );
}

function Frame38() {
  return (
    <div className="content-stretch flex items-center px-0 py-[3px] relative shrink-0">
      <Frame37 />
    </div>
  );
}

function Frame14() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] overflow-ellipsis overflow-hidden relative shrink-0 text-[#6b7280] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Parent-Teacher Meeting
      </p>
    </div>
  );
}

function Frame24() {
  return (
    <div className="content-stretch flex gap-[5px] items-center justify-center relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#007dfc] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>{`7 July 2025 `}</p>
      <Helper />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#007dfc] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        6:00 pm
      </p>
    </div>
  );
}

function VuesaxLinearArrowLeft4() {
  return (
    <div className="relative size-[20px]" data-name="vuesax/linear/arrow-left">
      <VuesaxLinearArrowLeft />
    </div>
  );
}

function Frame39() {
  return (
    <Wrapper1>
      <Frame24 />
      <div className="flex items-center justify-center relative shrink-0">
        <div className="flex-none rotate-[180deg]">
          <VuesaxLinearArrowLeft4 />
        </div>
      </div>
    </Wrapper1>
  );
}

function Frame40() {
  return (
    <div className="basis-0 content-stretch flex flex-col gap-[6px] grow items-start min-h-px min-w-px relative shrink-0">
      <Frame14 />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] min-w-full relative shrink-0 text-[#6b7280] text-[12px] w-[min-content]" style={{ fontVariationSettings: "'wdth' 100" }}>
        PTM for Class 6 will be held on 25 July 2025 at 10:00 AM in the school auditorium. Attendance is encouraged.
      </p>
      <Frame39 />
    </div>
  );
}

function Frame20() {
  return (
    <div className="bg-[#fafafa] content-stretch flex gap-[8px] items-start p-[12px] relative rounded-[12px] shadow-[0px_0px_3px_3px_rgba(0,95,204,0.24)] shrink-0 w-[354px]">
      <Frame38 />
      <Frame40 />
    </div>
  );
}

function Frame21() {
  return (
    <div className="content-stretch flex flex-col gap-[12px] items-start relative shrink-0 w-full">
      <Frame12 />
      <Frame20 />
    </div>
  );
}

function Frame22() {
  return (
    <div className="absolute content-stretch flex flex-col gap-[20px] h-[666px] items-start left-1/2 top-[105px] translate-x-[-50%] w-[354px]">
      <Frame15 />
      <Frame19 />
      <Frame21 />
    </div>
  );
}

function Frame2() {
  return (
    <div className="absolute content-stretch flex flex-col items-start left-[calc(50%+0.5px)] top-[52px] translate-x-[-50%]">
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">Notification</p>
    </div>
  );
}

function Menu() {
  return (
    <Wrapper2 additionalClassNames="relative shrink-0 size-[24px]">
      <g id="menu-04">
        <path d="M13.5 18H4M20 12H4M20 6H4" id="Icon" stroke="var(--stroke-0, #1F2933)" strokeLinecap="round" strokeWidth="2" />
      </g>
    </Wrapper2>
  );
}

function Frame() {
  return (
    <div className="absolute bg-white content-stretch flex flex-col items-center justify-center left-[24px] p-[11px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[39px]">
      <Menu />
    </div>
  );
}

function VuesaxLinearNotification() {
  return (
    <Wrapper>
      <path d={svgPaths.p2e393100} id="Vector" stroke="var(--stroke-0, #292D32)" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="1.5" />
      <path d={svgPaths.p3718def0} id="Vector_2" stroke="var(--stroke-0, #292D32)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
      <path d={svgPaths.p21656e00} id="Vector_3" stroke="var(--stroke-0, #292D32)" strokeMiterlimit="10" strokeWidth="1.5" />
      <g id="Vector_4" opacity="0"></g>
    </Wrapper>
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

function Frame1() {
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
      <Frame />
      <Frame1 />
    </div>
  );
}

function VuesaxLinearHome() {
  return (
    <Wrapper2 additionalClassNames="absolute contents inset-0">
      <g id="home">
        <path d="M12 18V15" id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        <path d={svgPaths.p1f860900} id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        <g id="Vector_3" opacity="0"></g>
      </g>
    </Wrapper2>
  );
}

function NavBarIcon() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="Nav Bar Icon">
      <VuesaxLinearHome />
    </div>
  );
}

function Frame3() {
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
      <Frame3 />
    </div>
  );
}

function VuesaxLinearCard() {
  return (
    <Wrapper2 additionalClassNames="absolute contents inset-0">
      <g id="card">
        <path d="M2 8.50496H22" id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
        <path d="M6 16.505H8" id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
        <path d="M10.5 16.505H14.5" id="Vector_3" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
        <path d={svgPaths.p34478e00} id="Vector_4" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        <g id="Vector_5" opacity="0"></g>
      </g>
    </Wrapper2>
  );
}

function VuesaxLinearCard1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/linear/card">
      <VuesaxLinearCard />
    </div>
  );
}

function Frame7() {
  return (
    <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
      <VuesaxLinearCard1 />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Fees
      </p>
    </div>
  );
}

function NavBar1() {
  return (
    <div className="content-stretch flex flex-col items-center justify-center overflow-clip px-[12px] py-0 relative shrink-0" data-name="Nav Bar">
      <Frame7 />
    </div>
  );
}

function History() {
  return (
    <Wrapper2 additionalClassNames="relative shrink-0 size-[24px]">
      <g clipPath="url(#clip0_1_608)" id="history">
        <g id="Vector"></g>
        <path d="M4 4V8H7" id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
        <path d={svgPaths.p1d901900} id="Vector_3" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
        <path d="M12.0006 7L12 12.2752L16 16" id="Vector_4" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
      </g>
      <defs>
        <clipPath id="clip0_1_608">
          <rect fill="white" height="24" width="24" />
        </clipPath>
      </defs>
    </Wrapper2>
  );
}

function Frame4() {
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
      <Frame4 />
    </div>
  );
}

function VuesaxBoldNotification2() {
  return (
    <Wrapper>
      <path d={svgPaths.pcd71700} fill="var(--fill-0, #007DFC)" id="Vector" />
      <path d={svgPaths.p144aa1f0} fill="var(--fill-0, #007DFC)" id="Vector_2" />
      <g id="Vector_3" opacity="0"></g>
    </Wrapper>
  );
}

function VuesaxBoldNotification3() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/bold/notification">
      <VuesaxBoldNotification2 />
    </div>
  );
}

function Frame5() {
  return (
    <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
      <VuesaxBoldNotification3 />
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] relative shrink-0 text-[#007dfc] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Alerts
      </p>
    </div>
  );
}

function NavBar3() {
  return (
    <div className="content-stretch flex flex-col items-center justify-center px-[12px] py-0 relative shrink-0" data-name="Nav Bar">
      <Frame5 />
    </div>
  );
}

function VuesaxLinearProfileCircle() {
  return (
    <Wrapper2 additionalClassNames="absolute contents inset-0">
      <g id="profile-circle">
        <path d={svgPaths.p3aeab480} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        <path d={svgPaths.p364c500} id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        <path d={svgPaths.pace200} id="Vector_3" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        <g id="Vector_4" opacity="0"></g>
      </g>
    </Wrapper2>
  );
}

function VuesaxLinearProfileCircle1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/linear/profile-circle">
      <VuesaxLinearProfileCircle />
    </div>
  );
}

function Frame6() {
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
      <Frame6 />
    </div>
  );
}

function Frame8() {
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

function Frame9() {
  return (
    <div className="absolute bottom-0 content-stretch flex flex-col items-start left-1/2 shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_-4px_4px_1px_rgba(229,231,235,0.5)] translate-x-[-50%] w-[402px]">
      <Frame8 />
      <BuildingBlocksNavigation />
    </div>
  );
}

export default function Notifications() {
  return (
    <div className="bg-[#fafafa] overflow-clip relative rounded-[24px] size-full" data-name="Notifications">
      <Frame9 />
      <Frame22 />
      <Frame2 />
      <Group />
    </div>
  );
}