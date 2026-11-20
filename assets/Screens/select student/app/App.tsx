import { useState } from "react";
import svgPaths from "../imports/svg-uieumrag6z";
import imgTabletLogin11 from "figma:asset/297a7844c0d837bf579f3b145c718ebec2a78d86.png";

interface Student {
  id: number;
  admissionNo: string;
  name: string;
  class: string;
  status: "Pending" | "Paid";
}

// Mock student data
const students: Student[] = [
  {
    id: 1,
    admissionNo: "3562756",
    name: "Robert",
    class: "10-B",
    status: "Pending",
  },
  {
    id: 2,
    admissionNo: "9003237",
    name: "Cody Fisher",
    class: "8-C",
    status: "Paid",
  },
  {
    id: 3,
    admissionNo: "8656436",
    name: "Juile",
    class: "6-A",
    status: "Paid",
  },
];

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

function VuesaxLinearArrowIcon() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="vuesax/linear/arrow-2">
      <VuesaxLinearArrow />
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

function RadioButtonChecked() {
  return (
    <div className="relative shrink-0 size-[24px]" data-name="radio_button_checked">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <g id="radio_button_checked">
          <path d={svgPaths.pf1830f2} fill="var(--fill-0, #007DFC)" id="icon" />
        </g>
      </svg>
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

interface StudentCardProps {
  student: Student;
  isSelected: boolean;
  onClick: () => void;
}

function StudentCard({ student, isSelected, onClick }: StudentCardProps) {
  const isFirstStudent = student.id === 1;
  const bgColor = isFirstStudent && isSelected ? "bg-white" : "bg-[#fafafa]";
  const shadow = isFirstStudent && isSelected 
    ? "shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)]"
    : "";
  
  return (
    <button
      onClick={onClick}
      className={`${bgColor} ${shadow} content-stretch flex items-start justify-between px-[16px] py-[12px] rounded-[12px] w-full`}
      data-name="Radio Field"
    >
      <div className="content-stretch flex gap-[12px] items-center relative shrink-0">
        {isSelected ? <RadioButtonChecked /> : <RadioButtonUnchecked />}
        <div className="content-stretch flex flex-col gap-[4px] items-start justify-center relative shrink-0">
          <div className="content-stretch flex flex-col font-['SF_Pro:Regular',sans-serif] font-normal gap-[4px] items-start justify-center relative shrink-0 text-nowrap">
            <p className="leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
              Admission No.
            </p>
            <p className="leading-[22px] relative shrink-0 text-[#1f2933] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
              {student.admissionNo}
            </p>
          </div>
          <div className="content-stretch flex font-normal gap-[8px] items-center min-w-[120px] relative shrink-0 text-nowrap">
            <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
              Name :
            </p>
            <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#1f2933] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
              {student.name}
            </p>
            <p className="font-['Inter:Regular',sans-serif] leading-[1.4] not-italic relative shrink-0 text-[#1f2933] text-[16px]">|</p>
            <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
              Class :
            </p>
            <p className="font-['SF_Pro:Regular',sans-serif] leading-[18px] relative shrink-0 text-[#1f2933] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
              {student.class}
            </p>
          </div>
        </div>
      </div>
      <div className={`${student.status === "Pending" ? "bg-[#f59e0b]" : "bg-[#2dbe60]"} content-stretch flex items-center overflow-clip px-[8px] py-[4px] relative rounded-[6px] shrink-0`}>
        <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] relative shrink-0 text-[12px] text-nowrap text-white" style={{ fontVariationSettings: "'wdth' 100" }}>
          {student.status}
        </p>
      </div>
      {!isFirstStudent && !isSelected && (
        <div className="absolute inset-0 pointer-events-none shadow-[inset_0px_0px_1px_0px_rgba(0,81,198,0.35),inset_0px_0px_2px_0px_rgba(0,81,198,0.2)]" />
      )}
    </button>
  );
}

export default function App() {
  const [selectedStudentId, setSelectedStudentId] = useState<number>(1);

  const handleBack = () => {
    console.log("Back button clicked");
  };

  const handleContinue = () => {
    const selectedStudent = students.find(s => s.id === selectedStudentId);
    console.log("Continue with student:", selectedStudent);
  };

  return (
    <div className="bg-[#fafafa] overflow-clip relative rounded-[16px] size-full min-h-[700px]" data-name="Select Student">
      {/* Illustration */}
      <div className="absolute left-[calc(87.5%-40.25px)] size-[133px] top-[104px] translate-x-[-50%]" data-name="Tablet login (1) 1">
        <img alt="" className="absolute inset-0 max-w-none object-50%-50% object-cover pointer-events-none size-full" src={imgTabletLogin11} />
      </div>

      {/* Header */}
      <div className="absolute content-stretch flex flex-col gap-[8px] items-start justify-center left-[24px] text-nowrap top-[104px]">
        <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[28px] relative shrink-0 text-[#1f2933] text-[22px]" style={{ fontVariationSettings: "'wdth' 100" }}>
          Select Student
        </p>
        <p className="font-['Inter:Regular',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px]">Welcome back !</p>
      </div>

      {/* Continue Button */}
      <button
        onClick={handleContinue}
        className="absolute bg-[#007dfc] content-stretch flex gap-[10px] items-center justify-center left-1/2 px-[8px] py-[14px] rounded-[12px] shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_2px_4px_1px_#e5e7eb] top-[608px] translate-x-[-50%] w-[354px] hover:bg-[#0066d6] transition-colors"
      >
        <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[16px] text-nowrap text-white" style={{ fontVariationSettings: "'wdth' 100" }}>
          Continue
        </p>
        <VuesaxLinearArrowIcon />
      </button>

      {/* Top Navigation */}
      <div className="absolute content-stretch flex items-center justify-between left-1/2 rounded-[10px] top-[40px] translate-x-[-50%] w-[354px]">
        <button 
          onClick={handleBack}
          className="bg-white block cursor-pointer relative rounded-[50px] shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_2px_4px_1px_#e5e7eb] shrink-0 size-[44px] hover:bg-[#f9f9f9] transition-colors" 
          data-name="arrow-left"
        >
          <VuesaxLinearArrowLeft />
        </button>
        <div className="overflow-clip rounded-[50px] shrink-0 size-[44px]" data-name="Filter" />
      </div>

      {/* Student List */}
      <div className="absolute left-[24px] top-[256px] w-[354px] flex flex-col gap-[12px]">
        {students.map((student) => (
          <StudentCard
            key={student.id}
            student={student}
            isSelected={selectedStudentId === student.id}
            onClick={() => setSelectedStudentId(student.id)}
          />
        ))}
      </div>

      {/* Navigation Handle */}
      <div className="absolute bottom-0 h-[24px] left-1/2 translate-x-[-50%] w-[402px]" data-name=".Building Blocks/navigation">
        <div className="absolute bg-[#1f2933] h-[4px] left-1/2 rounded-[12px] top-1/2 translate-x-[-50%] translate-y-[-50%] w-[108px]" data-name="handle" />
      </div>
    </div>
  );
}
