import svgPaths from "./svg-uieumrag6z";
import imgTabletLogin11 from "figma:asset/297a7844c0d837bf579f3b145c718ebec2a78d86.png";

function Frame2() {
  return (
    <div className="absolute content-stretch flex flex-col gap-[8px] items-start justify-center left-[24px] text-nowrap top-[104px]">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[28px] relative shrink-0 text-[#1f2933] text-[22px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Select Student
      </p>
      <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px]">Welcome back !</p>
    </div>
  );
}

function VuesaxLinearArrow() {
  return (
    <div className="absolute contents inset-0" data-name="vuesax/linear/arrow-2">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="arrow-2">
          <g id="Group">
            <path d={svgPaths.p1d6dd700} id="Vector" stroke="var(--stroke-0, white)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.8" />
            <path d="M3 11.72H21" id="Vector_2" stroke="var(--stroke-0, white)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.8" />
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

function Frame() {
  return (
    <div className="absolute bg-[#007dfc] content-stretch flex gap-[10px] items-center justify-center left-1/2 px-[8px] py-[14px] rounded-[12px] shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_2px_4px_1px_#e5e7eb] top-[608px] translate-x-[-50%] w-[354px]">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[16px] text-nowrap text-white" style={{ fontVariationSettings: "'wdth' 100" }}>
        Continue
      </p>
      <VuesaxLinearArrow1 />
    </div>
  );
}

function ArrowLeft() {
  return (
    <div className="absolute inset-[27.27%]" data-name="arrow-left">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 20 20">
        <g id="arrow-left">
          <path d={svgPaths.p2628f300} id="Vector" stroke="var(--stroke-0, #1F2933)" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
          <path d={svgPaths.p17ba5f00} id="Vector_2" opacity="0" stroke="var(--stroke-0, #1F2933)" />
        </g>
      </svg>
    </div>
  );
}

function VuesaxLinearArrowLeft() {
  return (
    <div className="absolute contents inset-[27.27%]" data-name="vuesax/linear/arrow-left">
      <ArrowLeft />
    </div>
  );
}

function ArrowLeft1() {
  return (
    <button className="bg-white block cursor-pointer relative rounded-[50px] shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_2px_4px_1px_#e5e7eb] shrink-0 size-[44px]" data-name="arrow-left">
      <VuesaxLinearArrowLeft />
    </button>
  );
}

function Filter() {
  return <div className="overflow-clip rounded-[50px] shrink-0 size-[44px]" data-name="Filter" />;
}

function Frame1() {
  return (
    <div className="absolute content-stretch flex items-center justify-between left-1/2 rounded-[10px] top-[40px] translate-x-[-50%] w-[354px]">
      <ArrowLeft1 />
      <Filter />
    </div>
  );
}

function Icon() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="icon">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="icon">
          <path d={svgPaths.pf1830f2} fill="var(--fill-0, #007DFC)" id="icon_2" />
        </g>
      </svg>
    </div>
  );
}

function Frame7() {
  return (
    <div className="content-stretch flex flex-col font-['SF_Pro:Regular',sans-serif] font-normal gap-[4px] items-start justify-center relative shrink-0 text-nowrap">
      <p className="leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Admission No.
      </p>
      <p className="leading-[22px] relative shrink-0 text-[#1f2933] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        3562756
      </p>
    </div>
  );
}

function DescriptionRow() {
  return (
    <div className="content-stretch flex font-normal gap-[8px] items-center min-w-[120px] relative shrink-0 text-nowrap" data-name="Description Row">
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Name :
      </p>
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#1f2933] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Robert
      </p>
      <p className="font-['Inter:Regular',sans-serif] leading-[1.4] not-italic relative shrink-0 text-[#1f2933] text-[16px]">|</p>
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Class :
      </p>
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#1f2933] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        10-B
      </p>
    </div>
  );
}

function Frame3() {
  return (
    <div className="content-stretch flex flex-col gap-[4px] items-start justify-center relative shrink-0">
      <Frame7 />
      <DescriptionRow />
    </div>
  );
}

function Frame6() {
  return (
    <div className="content-stretch flex gap-[12px] items-center relative shrink-0">
      <Icon />
      <Frame3 />
    </div>
  );
}

function DescriptionRow1() {
  return (
    <div className="bg-[#f59e0b] content-stretch flex items-center overflow-clip px-[8px] py-[4px] relative rounded-[6px] shrink-0" data-name="Description Row">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] relative shrink-0 text-[12px] text-nowrap text-white" style={{ fontVariationSettings: "'wdth' 100" }}>
        Pending
      </p>
    </div>
  );
}

function RadioField() {
  return (
    <div className="absolute bg-white content-stretch flex items-start justify-between left-[24px] px-[16px] py-[12px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[256px] w-[354px]" data-name="Radio Field">
      <Frame6 />
      <DescriptionRow1 />
    </div>
  );
}

function RadioButtonUnchecked() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="radio_button_unchecked">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="radio_button_unchecked">
          <path d={svgPaths.p1ee5e230} fill="var(--fill-0, #1F2933)" id="icon" />
        </g>
      </svg>
    </div>
  );
}

function Frame8() {
  return (
    <div className="content-stretch flex flex-col font-['SF_Pro:Regular',sans-serif] font-normal gap-[4px] items-start justify-center relative shrink-0 text-nowrap">
      <p className="leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Admission No.
      </p>
      <p className="leading-[22px] relative shrink-0 text-[#1f2933] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        9003237
      </p>
    </div>
  );
}

function DescriptionRow2() {
  return (
    <div className="content-stretch flex font-normal gap-[8px] items-center min-w-[120px] relative shrink-0 text-nowrap" data-name="Description Row">
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Name :
      </p>
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#1f2933] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Cody Fisher
      </p>
      <p className="font-['Inter:Regular',sans-serif] leading-[1.4] not-italic relative shrink-0 text-[#1f2933] text-[16px]">|</p>
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Class :
      </p>
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#1f2933] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        8-C
      </p>
    </div>
  );
}

function Frame4() {
  return (
    <div className="content-stretch flex flex-col gap-[4px] items-start justify-center relative shrink-0">
      <Frame8 />
      <DescriptionRow2 />
    </div>
  );
}

function Frame9() {
  return (
    <div className="content-stretch flex gap-[12px] items-center relative shrink-0">
      <RadioButtonUnchecked />
      <Frame4 />
    </div>
  );
}

function DescriptionRow3() {
  return (
    <div className="bg-[#2dbe60] content-stretch flex items-center overflow-clip px-[8px] py-[4px] relative rounded-[6px] shrink-0" data-name="Description Row">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] relative shrink-0 text-[12px] text-nowrap text-white" style={{ fontVariationSettings: "'wdth' 100" }}>
        Paid
      </p>
    </div>
  );
}

function RadioField1() {
  return (
    <div className="absolute bg-[#fafafa] content-stretch flex items-start justify-between left-[24px] px-[16px] py-[12px] rounded-[12px] top-[362px] w-[354px]" data-name="Radio Field">
      <Frame9 />
      <DescriptionRow3 />
      <div className="absolute inset-0 pointer-events-none shadow-[inset_0px_0px_1px_0px_rgba(0,81,198,0.35),inset_0px_0px_2px_0px_rgba(0,81,198,0.2)]" />
    </div>
  );
}

function RadioButtonUnchecked1() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="radio_button_unchecked">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="radio_button_unchecked">
          <path d={svgPaths.p1ee5e230} fill="var(--fill-0, #1F2933)" id="icon" />
        </g>
      </svg>
    </div>
  );
}

function Frame10() {
  return (
    <div className="content-stretch flex flex-col font-['SF_Pro:Regular',sans-serif] font-normal gap-[4px] items-start justify-center relative shrink-0 text-nowrap">
      <p className="leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Admission No.
      </p>
      <p className="leading-[22px] relative shrink-0 text-[#1f2933] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        8656436
      </p>
    </div>
  );
}

function DescriptionRow4() {
  return (
    <div className="content-stretch flex font-normal gap-[8px] items-center min-w-[120px] relative shrink-0 text-nowrap" data-name="Description Row">
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Name :
      </p>
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#1f2933] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Juile
      </p>
      <p className="font-['Inter:Regular',sans-serif] leading-[1.4] not-italic relative shrink-0 text-[#1f2933] text-[16px]">|</p>
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        Class :
      </p>
      <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#1f2933] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
        6-A
      </p>
    </div>
  );
}

function Frame5() {
  return (
    <div className="content-stretch flex flex-col gap-[4px] items-start justify-center relative shrink-0">
      <Frame10 />
      <DescriptionRow4 />
    </div>
  );
}

function Frame11() {
  return (
    <div className="content-stretch flex gap-[12px] items-center relative shrink-0">
      <RadioButtonUnchecked1 />
      <Frame5 />
    </div>
  );
}

function DescriptionRow5() {
  return (
    <div className="bg-[#2dbe60] content-stretch flex items-center overflow-clip px-[8px] py-[4px] relative rounded-[6px] shrink-0" data-name="Description Row">
      <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] relative shrink-0 text-[12px] text-nowrap text-white" style={{ fontVariationSettings: "'wdth' 100" }}>
        Paid
      </p>
    </div>
  );
}

function RadioField2() {
  return (
    <div className="absolute bg-[#fafafa] content-stretch flex items-start justify-between left-[24px] px-[16px] py-[12px] rounded-[12px] top-[468px] w-[354px]" data-name="Radio Field">
      <Frame11 />
      <DescriptionRow5 />
      <div className="absolute inset-0 pointer-events-none shadow-[inset_0px_0px_1px_0px_rgba(0,81,198,0.35),inset_0px_0px_2px_0px_rgba(0,81,198,0.2)]" />
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

export default function SelectStudent() {
  return (
    <div className="bg-[#fafafa] overflow-clip relative rounded-[16px] size-full" data-name="Select Student">
      <div className="absolute left-[calc(87.5%-40.25px)] size-[133px] top-[104px] translate-x-[-50%]" data-name="Tablet login (1) 1">
        <img alt="" className="absolute inset-0 max-w-none object-50%-50% object-cover pointer-events-none size-full" src={imgTabletLogin11} />
      </div>
      <Frame2 />
      <Frame />
      <Frame1 />
      <RadioField />
      <RadioField1 />
      <RadioField2 />
      <BuildingBlocksNavigation />
    </div>
  );
}