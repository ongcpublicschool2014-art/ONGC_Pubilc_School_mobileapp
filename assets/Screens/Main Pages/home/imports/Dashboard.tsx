import svgPaths from "./svg-f8q60dm9lb";
import clsx from "clsx";
import imgFrame6 from "figma:asset/8e8997ca481f4def3991bd517dcbef8d057e52ee.png";
import imgBackSchool1 from "figma:asset/ad7c9055c0864b6266f670f3d2c34956f0ff7256.png";
import imgEllipse6 from "figma:asset/b74001473ed48cfbfd34abbfab205a2118710677.png";
type Wrapper2Props = {
  additionalClassNames?: string;
};

function Wrapper2({ children, additionalClassNames = "" }: React.PropsWithChildren<Wrapper2Props>) {
  return (
    <div className={additionalClassNames}>
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 28 28">
        {children}
      </svg>
    </div>
  );
}
type Wrapper1Props = {
  additionalClassNames?: string;
};

function Wrapper1({ children, additionalClassNames = "" }: React.PropsWithChildren<Wrapper1Props>) {
  return (
    <div className={additionalClassNames}>
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        {children}
      </svg>
    </div>
  );
}

function VuesaxLinearNotification4({ children }: React.PropsWithChildren<{}>) {
  return (
    <Wrapper1 additionalClassNames="absolute contents inset-0">
      <g id="notification">{children}</g>
    </Wrapper1>
  );
}

function Frame13({ children }: React.PropsWithChildren<{}>) {
  return (
    <Wrapper2 additionalClassNames="relative shrink-0 size-[28px]">
      <g id="Frame">{children}</g>
    </Wrapper2>
  );
}

function Wrapper({ children }: React.PropsWithChildren<{}>) {
  return (
    <div className="bg-white relative rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] shrink-0 w-full">
      <div className="flex flex-row items-center size-full">
        <div className="content-stretch flex items-center p-[16px] relative w-full">{children}</div>
      </div>
    </div>
  );
}
type TextProps = {
  text: string;
  additionalClassNames?: string;
};

function Text({ text, children, additionalClassNames = "" }: React.PropsWithChildren<TextProps>) {
  return (
    <div className={clsx("content-stretch flex gap-[4px] items-center pl-0 pr-[8px] py-0 relative shrink-0", additionalClassNames)}>
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        {text}
      </p>
      <div className="flex items-center justify-center relative shrink-0">
        <div className="flex-none rotate-[180deg]">{children}</div>
      </div>
    </div>
  );
}
type HelperProps = {
  text: string;
  text1: string;
};

function Helper({ text, text1 }: HelperProps) {
  return (
    <div className="content-stretch flex font-['SF_Pro:Regular',sans-serif] font-normal gap-[4px] items-center justify-center leading-[18px] relative shrink-0 text-[12px] text-nowrap">
      <p className="relative shrink-0 text-[#6b7280]" style={{ fontVariationSettings: "'wdth' 100" }}>
        {text}
      </p>
      <p className="relative shrink-0 text-[#1f2933]" style={{ fontVariationSettings: "'wdth' 100" }}>
        {text1}
      </p>
    </div>
  );
}

function VuesaxLinearInfoCircle() {
  return (
    <div className="absolute contents inset-0">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 20 20">
        <g id="info-circle">
          <path d={svgPaths.p2ab72580} id="Vector" stroke="var(--stroke-0, #DC2626)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
          <path d="M10 6.66667V10.8333" id="Vector_2" stroke="var(--stroke-0, #DC2626)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
          <path d="M9.99542 13.3333H10.0029" id="Vector_3" stroke="var(--stroke-0, #DC2626)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
          <g id="Vector_4" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function VuesaxLinearArrowLeft() {
  return (
    <Wrapper1 additionalClassNames="absolute contents inset-0">
      <g id="arrow-left">
        <path d={svgPaths.p2a5cd480} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
        <g id="Vector_2" opacity="0"></g>
      </g>
    </Wrapper1>
  );
}

function Frame47() {
  return (
    <div className="absolute content-stretch flex inset-[20%] items-center p-[3px]">
      <div className="relative shrink-0 size-[18px]" data-name="Vector">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 18 18">
          <path d={svgPaths.p1c62b000} fill="var(--fill-0, #F59E0B)" id="Vector" />
        </svg>
      </div>
    </div>
  );
}

function Term() {
  return (
    <div className="bg-[#ffe9ce] overflow-clip relative rounded-[8px] shrink-0 size-[40px]" data-name="Term 3">
      <Frame47 />
    </div>
  );
}

function Frame19() {
  return (
    <div className="content-stretch flex flex-col font-['SF_Pro:Regular',sans-serif] font-normal gap-[2px] items-start justify-center relative shrink-0 text-nowrap">
      <p className="leading-[22px] relative shrink-0 text-[#1f2933] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Term-1 Fee
      </p>
      <p className="leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Sep 01, 2026
      </p>
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

function Frame15() {
  return (
    <Text text="₹ 9,000" additionalClassNames="overflow-clip">
      <VuesaxLinearArrowLeft1 />
    </Text>
  );
}

function Frame23() {
  return (
    <div className="basis-0 content-stretch flex grow items-center justify-between min-h-px min-w-px relative shrink-0">
      <Frame19 />
      <Frame15 />
    </div>
  );
}

function Frame21() {
  return (
    <div className="basis-0 content-stretch flex gap-[8px] grow items-center min-h-px min-w-px relative shrink-0">
      <Term />
      <Frame23 />
    </div>
  );
}

function Frame14() {
  return (
    <div className="absolute bg-white content-stretch flex items-center left-[24px] p-[12px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[556px] w-[354px]">
      <Frame21 />
    </div>
  );
}

function VuesaxBoldBus() {
  return (
    <Wrapper1 additionalClassNames="absolute contents inset-0">
      <g id="bus">
        <g id="Vector" opacity="0"></g>
        <path d={svgPaths.p2657bb00} fill="var(--fill-0, #F59E0B)" id="Vector_2" />
        <path d={svgPaths.p15b8700} fill="var(--fill-0, #F59E0B)" id="Vector_3" />
        <path d={svgPaths.p28daad80} fill="var(--fill-0, #F59E0B)" id="Vector_4" />
      </g>
    </Wrapper1>
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
    <div className="bg-[#ffe9ce] overflow-clip relative rounded-[8px] shrink-0 size-[40px]" data-name="Term 3">
      <VuesaxBoldBus1 />
    </div>
  );
}

function Frame20() {
  return (
    <div className="content-stretch flex flex-col font-['SF_Pro:Regular',sans-serif] font-normal gap-[3px] items-start justify-center relative shrink-0 text-nowrap">
      <p className="leading-[22px] relative shrink-0 text-[#1f2933] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>{`Bus  Fee`}</p>
      <p className="leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Sep 01, 2026
      </p>
    </div>
  );
}

function VuesaxLinearArrowLeft2() {
  return (
    <div className="relative size-[24px]" data-name="vuesax/linear/arrow-left">
      <VuesaxLinearArrowLeft />
    </div>
  );
}

function Frame17() {
  return (
    <Text text="₹ 10,000">
      <VuesaxLinearArrowLeft2 />
    </Text>
  );
}

function Frame24() {
  return (
    <div className="basis-0 content-stretch flex grow items-center justify-between min-h-px min-w-px relative shrink-0">
      <Frame20 />
      <Frame17 />
    </div>
  );
}

function Frame22() {
  return (
    <div className="basis-0 content-stretch flex gap-[8px] grow items-center min-h-px min-w-px relative shrink-0">
      <Term1 />
      <Frame24 />
    </div>
  );
}

function Frame40() {
  return (
    <div className="absolute bg-white content-stretch flex items-center left-[24px] p-[12px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[634px] w-[354px]">
      <Frame22 />
    </div>
  );
}

function BxsCreditCard() {
  return (
    <Wrapper2 additionalClassNames="relative shrink-0 size-[28px]">
      <g id="bxs-credit-card">
        <path d={svgPaths.p98e6d00} fill="var(--fill-0, #007DFC)" id="Vector" />
      </g>
    </Wrapper2>
  );
}

function Frame27() {
  return (
    <Wrapper>
      <BxsCreditCard />
    </Wrapper>
  );
}

function Frame31() {
  return (
    <div className="content-stretch flex flex-col gap-[8px] items-center relative shrink-0 w-[60px]">
      <Frame27 />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#1f2933] text-[12px] text-center w-full" style={{ fontVariationSettings: "'wdth' 100" }}>
        Pay Fee
      </p>
    </div>
  );
}

function Frame() {
  return (
    <Frame13>
      <path d={svgPaths.p347ddc80} fill="var(--fill-0, #F59E0B)" id="Vector" />
    </Frame13>
  );
}

function Frame28() {
  return (
    <Wrapper>
      <Frame />
    </Wrapper>
  );
}

function Frame32() {
  return (
    <div className="content-stretch flex flex-col gap-[8px] items-center relative shrink-0 w-[60px]">
      <Frame28 />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#1f2933] text-[12px] text-center text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Upcoming
      </p>
    </div>
  );
}

function Frame3() {
  return (
    <Frame13>
      <path d={svgPaths.p1e107300} fill="var(--fill-0, #2DBE60)" id="Subtract" />
    </Frame13>
  );
}

function Frame29() {
  return (
    <Wrapper>
      <Frame3 />
    </Wrapper>
  );
}

function Frame33() {
  return (
    <div className="content-stretch flex flex-col gap-[8px] items-center relative shrink-0 w-[60px]">
      <Frame29 />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#1f2933] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Paid
      </p>
    </div>
  );
}

function Frame4() {
  return (
    <Frame13>
      <path d={svgPaths.p1421b800} fill="var(--fill-0, #005FCC)" id="Vector" />
    </Frame13>
  );
}

function Frame38() {
  return (
    <div className="content-stretch flex items-center relative shrink-0">
      <Frame4 />
    </div>
  );
}

function Frame30() {
  return (
    <Wrapper>
      <Frame38 />
    </Wrapper>
  );
}

function Frame34() {
  return (
    <div className="content-stretch flex flex-col gap-[8px] items-center relative shrink-0 w-[60px]">
      <Frame30 />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#1f2933] text-[12px] text-center w-full" style={{ fontVariationSettings: "'wdth' 100" }}>
        Support
      </p>
    </div>
  );
}

function Frame35() {
  return (
    <div className="absolute content-stretch flex items-center justify-between left-[24px] px-[9px] py-0 top-[310px] w-[354px]">
      <Frame31 />
      <Frame32 />
      <Frame33 />
      <Frame34 />
    </div>
  );
}

function Frame5() {
  return (
    <Wrapper1 additionalClassNames="relative shrink-0 size-[24px]">
      <g id="Frame">
        <path d={svgPaths.p29cf7472} fill="var(--fill-0, #059669)" id="Vector" />
      </g>
    </Wrapper1>
  );
}

function Frame41() {
  return (
    <div className="content-stretch flex gap-[6px] items-center relative shrink-0">
      <Frame5 />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Total Outstanding
      </p>
    </div>
  );
}

function Alert() {
  return (
    <div className="absolute left-[137px] size-[20px] top-0" data-name="Alert">
      <VuesaxLinearInfoCircle />
    </div>
  );
}

function Group() {
  return (
    <div className="absolute contents left-[137px] top-0">
      <Alert />
      <p className="absolute font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] left-[167px] text-[#dc2626] text-[12px] text-nowrap top-[3px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        If payment is not received by the due date, there will be a ₹100 late fee.
      </p>
    </div>
  );
}

function Alert1() {
  return (
    <div className="absolute left-[707px] size-[20px] top-0" data-name="Alert">
      <VuesaxLinearInfoCircle />
    </div>
  );
}

function Group1() {
  return (
    <div className="absolute contents left-[707px] top-0">
      <Alert1 />
      <p className="absolute font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] left-[737px] text-[#dc2626] text-[12px] text-nowrap top-[3px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        If payment is not received by the due date, there will be a ₹100 late fee.
      </p>
    </div>
  );
}

function DueAlertMessageAnimation() {
  return (
    <div className="h-[20px] overflow-clip relative shrink-0 w-[138px]" data-name="Due alert message  animation">
      <p className="absolute font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] left-[4px] text-[#1f2933] text-[12px] text-nowrap top-[3px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Due by: Feb 15,2026
      </p>
      <p className="absolute font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] left-[574px] text-[#1f2933] text-[12px] text-nowrap top-[3px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Due by: Feb 15,2026
      </p>
      <Group />
      <Group1 />
    </div>
  );
}

function Frame6() {
  return (
    <div className="absolute content-stretch flex flex-col gap-[10px] items-start left-[24px] pl-[16px] pr-[12px] py-[12px] rounded-[12px] top-[170px] w-[354px]">
      <div aria-hidden="true" className="absolute inset-0 pointer-events-none rounded-[12px]">
        <img alt="" className="absolute max-w-none object-50%-50% object-cover rounded-[12px] size-full" src={imgFrame6} />
        <div className="absolute bg-[rgba(0,125,252,0.08)] inset-0 rounded-[12px]" />
      </div>
      <Frame41 />
      <p className="font-['SF_Pro:Bold',sans-serif] font-bold leading-[36px] relative shrink-0 text-[#005fcc] text-[26px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        ₹ 15,000
      </p>
      <DueAlertMessageAnimation />
      <div className="absolute bottom-0 flex items-center justify-center right-[15px] size-[145px]">
        <div className="flex-none rotate-[180deg] scale-y-[-100%]">
          <div className="relative size-[145px]" data-name="back-school 1">
            <img alt="" className="absolute inset-0 max-w-none object-50%-50% object-cover pointer-events-none size-full" src={imgBackSchool1} />
          </div>
        </div>
      </div>
      <div className="absolute inset-0 pointer-events-none shadow-[inset_0px_0px_1px_0px_rgba(0,81,198,0.35),inset_0px_0px_2px_0px_rgba(0,81,198,0.2)]" />
    </div>
  );
}

function Frame36() {
  return (
    <div className="absolute content-stretch flex items-end justify-between left-[24px] overflow-clip text-nowrap top-[516px] w-[354px]">
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px]">Fees Due</p>
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#007dfc] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        View All
      </p>
    </div>
  );
}

function Frame46() {
  return (
    <div className="content-stretch flex items-center justify-center px-0 py-[7px] relative shrink-0">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Robert
      </p>
    </div>
  );
}

function Frame44() {
  return (
    <div className="content-stretch flex font-['SF_Pro:Regular',sans-serif] font-normal gap-[3px] items-center relative shrink-0 text-[12px] text-nowrap">
      <p className="leading-[18px] relative shrink-0 text-[#6b7280]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Admn No:
      </p>
      <p className="leading-[18px] relative shrink-0 text-[#1f2933]" style={{ fontVariationSettings: "'wdth' 100" }}>
        <span className="font-['SF_Pro:Regular',sans-serif] font-normal" style={{ fontVariationSettings: "'wdth' 100" }}>
          3562756
        </span>{" "}
      </p>
    </div>
  );
}

function Frame45() {
  return (
    <div className="content-stretch flex gap-[8px] items-start relative shrink-0">
      <Helper text="Class:" text1="10-B" />
      <div className="h-[18px] relative shrink-0 w-px" data-name="|">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 1 18">
          <path d="M1 0V18H0V0H1Z" fill="var(--fill-0, #AAD4FD)" id="|" />
        </svg>
      </div>
      <Helper text="Blood Group:" text1="B+" />
    </div>
  );
}

function Frame37() {
  return (
    <div className="content-stretch flex flex-col gap-[4px] items-start relative shrink-0">
      <Frame46 />
      <Frame44 />
      <Frame45 />
    </div>
  );
}

function Frame43() {
  return (
    <div className="content-stretch flex gap-[12px] items-start relative shrink-0">
      <div className="relative shrink-0 size-[60px]">
        <img alt="" className="block max-w-none size-full" height="60" src={imgEllipse6} width="60" />
      </div>
      <Frame37 />
    </div>
  );
}

function VuesaxBoldArrowSwapHorizontal() {
  return (
    <Wrapper2 additionalClassNames="absolute contents inset-0">
      <g id="arrow-swap-horizontal">
        <path d={svgPaths.p2ccde600} fill="var(--fill-0, #292D32)" id="Vector" />
        <g id="Vector_2" opacity="0"></g>
      </g>
    </Wrapper2>
  );
}

function VuesaxBoldArrowSwapHorizontal1() {
  return (
    <div className="relative shrink-0 size-[28px]" data-name="vuesax/bold/arrow-swap-horizontal">
      <VuesaxBoldArrowSwapHorizontal />
    </div>
  );
}

function Frame42() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <Frame43 />
      <VuesaxBoldArrowSwapHorizontal1 />
    </div>
  );
}

function Frame39() {
  return (
    <div className="absolute bg-white content-stretch flex flex-col items-start left-[24px] px-[16px] py-[12px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[412px] w-[354px]">
      <Frame42 />
    </div>
  );
}

function Group2() {
  return (
    <div className="relative shrink-0 size-[36px]">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 36 36">
        <g id="Group 1000000941">
          <path clipRule="evenodd" d={svgPaths.p1227d080} fill="var(--fill-0, #007DFC)" fillRule="evenodd" id="Vector" />
          <path clipRule="evenodd" d={svgPaths.p632b200} fill="var(--fill-0, #007DFC)" fillRule="evenodd" id="Vector_2" />
        </g>
      </svg>
    </div>
  );
}

function Frame25() {
  return (
    <div className="content-stretch flex items-center p-[5px] relative shrink-0">
      <Group2 />
    </div>
  );
}

function Frame11() {
  return (
    <div className="content-stretch flex flex-col gap-[6px] items-start relative shrink-0 text-nowrap">
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px]">Vidyaranya High School</p>
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>{`7/9, MG Road, Udumalpet. `}</p>
    </div>
  );
}

function Frame26() {
  return (
    <div className="absolute content-stretch flex gap-[8px] items-start left-[24px] px-[5px] py-0 top-[106px] w-[354px]">
      <Frame25 />
      <Frame11 />
    </div>
  );
}

function VuesaxBoldHome() {
  return (
    <Wrapper1 additionalClassNames="absolute contents inset-0">
      <g id="home">
        <path d={svgPaths.p2a26d200} fill="var(--fill-0, #007DFC)" id="Vector" />
        <g id="Vector_2" opacity="0"></g>
      </g>
    </Wrapper1>
  );
}

function NavBarIcon() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="Nav Bar Icon">
      <VuesaxBoldHome />
    </div>
  );
}

function Frame7() {
  return (
    <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
      <NavBarIcon />
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] relative shrink-0 text-[#007dfc] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Home
      </p>
    </div>
  );
}

function NavBar() {
  return (
    <div className="content-stretch flex flex-col items-center justify-center px-[9px] py-0 relative shrink-0" data-name="Nav Bar">
      <Frame7 />
    </div>
  );
}

function VuesaxLinearCard() {
  return (
    <Wrapper1 additionalClassNames="absolute contents inset-0">
      <g id="card">
        <path d="M2 8.50496H22" id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
        <path d="M6 16.505H8" id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
        <path d="M10.5 16.505H14.5" id="Vector_3" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
        <path d={svgPaths.p34478e00} id="Vector_4" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        <g id="Vector_5" opacity="0"></g>
      </g>
    </Wrapper1>
  );
}

function VuesaxLinearCard1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/linear/card">
      <VuesaxLinearCard />
    </div>
  );
}

function Frame12() {
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
      <Frame12 />
    </div>
  );
}

function History() {
  return (
    <Wrapper1 additionalClassNames="relative shrink-0 size-[24px]">
      <g clipPath="url(#clip0_1_690)" id="history">
        <g id="Vector"></g>
        <path d="M4 4V8H7" id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
        <path d={svgPaths.p1d901900} id="Vector_3" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
        <path d="M12.0006 7L12 12.2752L16 16" id="Vector_4" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
      </g>
      <defs>
        <clipPath id="clip0_1_690">
          <rect fill="white" height="24" width="24" />
        </clipPath>
      </defs>
    </Wrapper1>
  );
}

function Frame8() {
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
      <Frame8 />
    </div>
  );
}

function VuesaxLinearNotification() {
  return (
    <VuesaxLinearNotification4>
      <path d={svgPaths.p2e393100} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="1.5" />
      <path d={svgPaths.p3718def0} id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
      <path d={svgPaths.p21656e00} id="Vector_3" stroke="var(--stroke-0, #6B7280)" strokeMiterlimit="10" strokeWidth="1.5" />
      <g id="Vector_4" opacity="0"></g>
    </VuesaxLinearNotification4>
  );
}

function VuesaxLinearNotification1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/linear/notification">
      <VuesaxLinearNotification />
    </div>
  );
}

function Frame9() {
  return (
    <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
      <VuesaxLinearNotification1 />
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Alerts
      </p>
    </div>
  );
}

function NavBar3() {
  return (
    <div className="content-stretch flex flex-col items-center justify-center px-[12px] py-0 relative shrink-0" data-name="Nav Bar">
      <Frame9 />
    </div>
  );
}

function VuesaxLinearProfileCircle() {
  return (
    <Wrapper1 additionalClassNames="absolute contents inset-0">
      <g id="profile-circle">
        <path d={svgPaths.p3aeab480} id="Vector" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        <path d={svgPaths.p364c500} id="Vector_2" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        <path d={svgPaths.pace200} id="Vector_3" stroke="var(--stroke-0, #6B7280)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        <g id="Vector_4" opacity="0"></g>
      </g>
    </Wrapper1>
  );
}

function VuesaxLinearProfileCircle1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/linear/profile-circle">
      <VuesaxLinearProfileCircle />
    </div>
  );
}

function Frame10() {
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
      <Frame10 />
    </div>
  );
}

function Frame16() {
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

function Frame18() {
  return (
    <div className="absolute bottom-0 content-stretch flex flex-col items-start left-0 shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_-4px_4px_1px_rgba(229,231,235,0.5)] w-[402px]">
      <Frame16 />
      <BuildingBlocksNavigation />
    </div>
  );
}

function Menu() {
  return (
    <Wrapper1 additionalClassNames="relative shrink-0 size-[24px]">
      <g id="menu-04">
        <path d="M13.5 18H4M20 12H4M20 6H4" id="Icon" stroke="var(--stroke-0, #1F2933)" strokeLinecap="round" strokeWidth="2" />
      </g>
    </Wrapper1>
  );
}

function Frame1() {
  return (
    <div className="absolute bg-white content-stretch flex flex-col items-center justify-center left-[24px] p-[11px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[39px]">
      <Menu />
    </div>
  );
}

function VuesaxLinearNotification2() {
  return (
    <VuesaxLinearNotification4>
      <path d={svgPaths.p2e393100} id="Vector" stroke="var(--stroke-0, #292D32)" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="1.5" />
      <path d={svgPaths.p3718def0} id="Vector_2" stroke="var(--stroke-0, #292D32)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
      <path d={svgPaths.p21656e00} id="Vector_3" stroke="var(--stroke-0, #292D32)" strokeMiterlimit="10" strokeWidth="1.5" />
      <g id="Vector_4" opacity="0"></g>
    </VuesaxLinearNotification4>
  );
}

function VuesaxLinearNotification3() {
  return (
    <div className="absolute inset-[7.14%]" data-name="vuesax/linear/notification">
      <VuesaxLinearNotification2 />
    </div>
  );
}

function Notification() {
  return (
    <div className="relative shrink-0 size-[28px]" data-name="Notification">
      <VuesaxLinearNotification3 />
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

function Group3() {
  return (
    <div className="absolute contents left-[24px] top-[39px]">
      <Frame1 />
      <Frame2 />
    </div>
  );
}

export default function Dashboard() {
  return (
    <div className="bg-[#fafafa] overflow-clip relative rounded-[24px] size-full" data-name="Dashboard">
      <Frame26 />
      <Frame18 />
      <Group3 />
      <Frame14 />
      <Frame40 />
      <Frame35 />
      <Frame6 />
      <Frame36 />
      <Frame39 />
    </div>
  );
}