import svgPaths from "./svg-37cvg2twkg";
import imgEllipse6 from "figma:asset/b54e0cffee83bfae2d59ff3ac1df0631549c8e0f.png";

function Group() {
  return (
    <div className="relative shrink-0 size-[30px]">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 30 30">
        <g id="Group 1000000941">
          <path clipRule="evenodd" d={svgPaths.p30820080} fill="var(--fill-0, #007DFC)" fillRule="evenodd" id="Vector" />
          <path clipRule="evenodd" d={svgPaths.p241c8400} fill="var(--fill-0, #007DFC)" fillRule="evenodd" id="Vector_2" />
        </g>
      </svg>
    </div>
  );
}

function Frame7() {
  return (
    <div className="content-stretch flex items-center p-[5px] relative shrink-0">
      <Group />
    </div>
  );
}

function Frame1() {
  return (
    <div className="content-stretch flex flex-col font-['SF_Pro:Regular',sans-serif] font-normal gap-[4px] items-start relative shrink-0 text-nowrap">
      <p className="leading-[22px] relative shrink-0 text-[#1f2933] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Vidyaranya High School
      </p>
      <p className="leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>{`7/9, MG Road, Udumalpet. `}</p>
    </div>
  );
}

function Frame21() {
  return (
    <div className="content-stretch flex gap-[4px] items-center relative shrink-0">
      <Frame7 />
      <Frame1 />
    </div>
  );
}

function CloseSmall() {
  return (
    <div className="absolute inset-[20%]" data-name="close-small">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="close-small">
          <path d="M6 6.5L18 18.5" id="Vector" stroke="var(--stroke-0, #1F2933)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
          <path d="M6 18.5L18 6.5" id="Vector_2" stroke="var(--stroke-0, #1F2933)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
        </g>
      </svg>
    </div>
  );
}

function Term() {
  return (
    <div className="bg-white overflow-clip relative rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] shrink-0 size-[40px]" data-name="Term 3">
      <CloseSmall />
    </div>
  );
}

function Frame8() {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <Frame21 />
      <Term />
    </div>
  );
}

function Frame17() {
  return (
    <div className="content-stretch flex items-center justify-center px-0 py-[7px] relative shrink-0">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[#1f2933] text-[16px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Robert
      </p>
    </div>
  );
}

function Frame18() {
  return (
    <div className="content-stretch flex font-['SF_Pro:Regular',sans-serif] font-normal gap-[4px] items-center justify-center leading-[18px] relative shrink-0 text-[12px] text-nowrap">
      <p className="relative shrink-0 text-[#6b7280]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Class:
      </p>
      <p className="relative shrink-0 text-[#1f2933]" style={{ fontVariationSettings: "'wdth' 100" }}>
        10-B
      </p>
    </div>
  );
}

function Frame16() {
  return (
    <div className="content-stretch flex items-start relative shrink-0">
      <Frame18 />
    </div>
  );
}

function Frame9() {
  return (
    <div className="content-stretch flex flex-col gap-[4px] items-start relative shrink-0">
      <Frame17 />
      <Frame16 />
    </div>
  );
}

function Frame11() {
  return (
    <div className="content-stretch flex gap-[12px] items-center relative shrink-0">
      <div className="relative shrink-0 size-[46px]">
        <div className="absolute inset-[-76.09%_-86.96%_-97.83%_-86.96%]">
          <img alt="" className="block max-w-none size-full" height="126" src={imgEllipse6} width="126" />
        </div>
      </div>
      <Frame9 />
    </div>
  );
}

function Frame10() {
  return (
    <div className="content-stretch flex gap-[12px] items-center relative shrink-0 w-full">
      <Frame11 />
    </div>
  );
}

function VuesaxBoldKey() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/bold/key">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="vuesax/bold/key">
          <path d={svgPaths.p3391b300} fill="var(--fill-0, #6B7280)" id="Vector" />
          <g id="Vector_2" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function Frame13() {
  return (
    <div className="content-stretch flex items-center relative rounded-[6px] shrink-0">
      <VuesaxBoldKey />
    </div>
  );
}

function Frame2() {
  return (
    <div className="relative shrink-0 w-full">
      <div className="flex flex-row items-center size-full">
        <div className="content-stretch flex gap-[8px] items-center p-[8px] relative w-full">
          <Frame13 />
          <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
            Change Password
          </p>
        </div>
      </div>
    </div>
  );
}

function Frame() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="Frame">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="Frame">
          <path d={svgPaths.p20477c00} fill="var(--fill-0, #6B7280)" id="Vector" />
        </g>
      </svg>
    </div>
  );
}

function Frame14() {
  return (
    <div className="content-stretch flex items-center relative rounded-[6px] shrink-0">
      <Frame />
    </div>
  );
}

function Frame3() {
  return (
    <div className="relative shrink-0 w-full">
      <div className="flex flex-row items-center size-full">
        <div className="content-stretch flex gap-[8px] items-center p-[8px] relative w-full">
          <Frame14 />
          <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>{`Help & Support`}</p>
        </div>
      </div>
    </div>
  );
}

function VuesaxBoldSetting() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/bold/setting-2">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="setting-2">
          <path d={svgPaths.p3f496a00} fill="var(--fill-0, #6B7280)" id="Vector" />
          <g id="Vector_2" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function VuesaxBoldSetting1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/bold/setting-2">
      <VuesaxBoldSetting />
    </div>
  );
}

function Frame15() {
  return (
    <div className="content-stretch flex items-center relative rounded-[6px] shrink-0">
      <VuesaxBoldSetting1 />
    </div>
  );
}

function Frame4() {
  return (
    <div className="relative shrink-0 w-full">
      <div className="flex flex-row items-center size-full">
        <div className="content-stretch flex gap-[8px] items-center p-[8px] relative w-full">
          <Frame15 />
          <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
            Setting
          </p>
        </div>
      </div>
    </div>
  );
}

function Frame19() {
  return (
    <div className="content-stretch flex flex-col gap-[20px] items-start relative shrink-0 w-full">
      <Frame8 />
      <div className="h-0 relative shrink-0 w-full">
        <div className="absolute inset-[-1px_0_0_0]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 270 1">
            <line id="Line 51" stroke="var(--stroke-0, #AAD4FD)" x2="270" y1="0.5" y2="0.5" />
          </svg>
        </div>
      </div>
      <Frame10 />
      <div className="h-0 relative shrink-0 w-full">
        <div className="absolute inset-[-1px_0_0_0]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 270 1">
            <line id="Line 51" stroke="var(--stroke-0, #AAD4FD)" x2="270" y1="0.5" y2="0.5" />
          </svg>
        </div>
      </div>
      <Frame2 />
      <Frame3 />
      <Frame4 />
    </div>
  );
}

function Frame5() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#dc2626] text-[15px] text-center text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Logout
      </p>
    </div>
  );
}

function Logout() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="logout">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="logout">
          <path d={svgPaths.p14e7100} fill="var(--fill-0, #DC2626)" id="Vector" />
          <path d={svgPaths.p2f943780} fill="var(--fill-0, #DC2626)" id="Vector_2" />
          <g id="Vector_3" opacity="0"></g>
        </g>
      </svg>
    </div>
  );
}

function Frame6() {
  return (
    <div className="bg-[#ffd1cf] relative rounded-[8px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] shrink-0 w-full">
      <div className="flex flex-row items-center justify-center overflow-clip rounded-[inherit] size-full">
        <div className="content-stretch flex gap-[8px] items-center justify-center px-[8px] py-[10px] relative w-full">
          <Frame5 />
          <Logout />
        </div>
      </div>
    </div>
  );
}

function Frame20() {
  return (
    <div className="content-stretch flex flex-col gap-[20px] items-start relative shrink-0 w-full">
      <div className="h-0 relative shrink-0 w-full">
        <div className="absolute inset-[-1px_0_0_0]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 270 1">
            <line id="Line 51" stroke="var(--stroke-0, #AAD4FD)" x2="270" y1="0.5" y2="0.5" />
          </svg>
        </div>
      </div>
      <Frame6 />
    </div>
  );
}

export default function Frame12() {
  return (
    <div className="bg-[#fafafa] relative rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] size-full">
      <div className="size-full">
        <div className="content-stretch flex flex-col items-start justify-between px-[16px] py-[52px] relative size-full">
          <Frame19 />
          <Frame20 />
        </div>
      </div>
    </div>
  );
}