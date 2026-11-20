import { useState } from 'react';
import svgPaths from '../imports/svg-cp6ee9iqmj';

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
    <button className="bg-white content-stretch cursor-pointer flex items-center overflow-clip p-[10px] relative rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] shrink-0">
      <VuesaxLinearArrowLeft1 />
    </button>
  );
}

function Frame19() {
  return (
    <div className="content-stretch flex items-center relative shrink-0">
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">{`Help & Support`}</p>
    </div>
  );
}

function Filter() {
  return <div className="overflow-clip rounded-[50px] shrink-0 size-[44px]" data-name="Filter" />;
}

function Frame23() {
  return (
    <div className="absolute content-stretch flex items-center justify-between left-1/2 rounded-[10px] top-[40px] translate-x-[-50%] w-[354px]">
      <Frame27 />
      <Frame19 />
      <Filter />
    </div>
  );
}

interface FaqItemProps {
  question: string;
  answer?: string;
  isOpen: boolean;
  onToggle: () => void;
}

function FaqItem({ question, answer, isOpen, onToggle }: FaqItemProps) {
  return (
    <div 
      className={`bg-white relative rounded-[12px] shrink-0 w-full ${
        isOpen 
          ? 'shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)]' 
          : 'shadow-[0px_0px_3px_3px_rgba(0,95,204,0.24)]'
      }`}
    >
      <div className="flex flex-col size-full">
        <div className={`content-stretch flex flex-col items-center justify-center px-[10px] py-[11px] relative w-full ${isOpen ? 'gap-[8px]' : 'gap-[16px]'}`}>
          <button 
            onClick={onToggle}
            className="relative shrink-0 w-full"
          >
            <div className="flex flex-row items-center size-full">
              <div className="content-stretch flex items-center justify-between px-[2px] py-0 relative w-full">
                <div className="content-stretch flex flex-col items-start justify-center pl-0 pr-[16px] py-0 relative shrink-0">
                  <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[normal] relative shrink-0 text-[#1f2933] text-[12px] text-nowrap">
                    {question}
                  </p>
                </div>
                <div className={`flex items-center justify-center relative shrink-0 ${isOpen ? 'flex-none rotate-[180deg]' : ''}`}>
                  <div className="relative size-[24px]" data-name="Frame">
                    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
                      <g id="Frame">
                        <path d="M6 9L12 15L18 9" id="Vector" stroke="var(--stroke-0, #1F2933)" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
                      </g>
                    </svg>
                  </div>
                </div>
              </div>
            </div>
          </button>
          
          {isOpen && answer && (
            <div className="bg-[#fafafa] content-stretch flex flex-col items-start overflow-clip relative rounded-[8px] shrink-0 w-full">
              <div className="relative shrink-0 w-full">
                <div className="size-full">
                  <div className="content-stretch flex items-start justify-between px-[8px] py-[10px] relative w-full">
                    <div className="basis-0 content-stretch flex flex-col grow items-start justify-center min-h-px min-w-px relative shrink-0">
                      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] w-full" style={{ fontVariationSettings: "'wdth' 100" }}>
                        {answer}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="absolute inset-0 pointer-events-none shadow-[inset_0px_0px_1px_0px_rgba(0,81,198,0.35),inset_0px_0px_2px_0px_rgba(0,81,198,0.2)]" />
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function Frame24() {
  const [openFaqIndex, setOpenFaqIndex] = useState<number>(0);

  const faqs = [
    {
      question: "How do I pay my child's fees online?",
      answer: "Go to the \"Fee Details\" page, review the pending dues, and click on the 'Pay Now' button. Choose your preferred payment method and complete the transaction."
    },
    {
      question: "What payment methods are accepted?",
      answer: "We accept various payment methods including credit/debit cards, net banking, UPI, and digital wallets."
    },
    {
      question: "Will I receive a receipt after payment?",
      answer: "Yes, you will receive a digital receipt via email immediately after successful payment completion."
    },
    {
      question: "What happens if I miss a payment due date?",
      answer: "Late fees may apply if payment is not received by the due date. Please contact the school administration for assistance."
    }
  ];

  return (
    <div className="absolute content-stretch flex flex-col gap-[12px] items-start left-[24px] top-[320px] w-[354px]">
      {faqs.map((faq, index) => (
        <FaqItem
          key={index}
          question={faq.question}
          answer={faq.answer}
          isOpen={openFaqIndex === index}
          onToggle={() => setOpenFaqIndex(openFaqIndex === index ? -1 : index)}
        />
      ))}
    </div>
  );
}

function Group() {
  return (
    <div className="absolute contents left-[24px] top-[284px]">
      <Frame24 />
      <p className="absolute font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] left-[24px] text-[#1f2933] text-[18px] text-nowrap top-[284px]">FAQ's</p>
    </div>
  );
}

function Frame11() {
  return (
    <div className="content-stretch flex flex-col items-start relative shrink-0">
      <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">Contact School</p>
    </div>
  );
}

function Frame26() {
  return (
    <div className="content-stretch flex items-center relative shrink-0 w-full">
      <Frame11 />
    </div>
  );
}

function Frame14() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center px-[12px] py-0 relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#6b7280] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Email
      </p>
    </div>
  );
}

function Frame9() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center pl-0 pr-[8px] py-0 relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        johnson@gmail.com
      </p>
    </div>
  );
}

function Frame21() {
  return (
    <div className="content-stretch flex gap-[20px] items-center relative shrink-0 w-full">
      <Frame14 />
      <Frame9 />
    </div>
  );
}

function Frame18() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center px-[9px] py-0 relative shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#6b7280] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        Phone
      </p>
    </div>
  );
}

function Frame20() {
  return (
    <div className="content-stretch flex items-center relative rounded-[12px] shrink-0">
      <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
        +84 414 323 567
      </p>
    </div>
  );
}

function Frame10() {
  return (
    <div className="content-stretch flex flex-col items-start justify-center pl-0 pr-[8px] py-0 relative shrink-0">
      <Frame20 />
    </div>
  );
}

function Frame22() {
  return (
    <div className="content-stretch flex gap-[20px] items-center relative shrink-0 w-full">
      <Frame18 />
      <Frame10 />
    </div>
  );
}

function Frame25() {
  return (
    <div className="absolute bg-white content-stretch flex flex-col gap-[20px] items-start left-1/2 p-[16px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[104px] translate-x-[-50%] w-[354px]">
      <Frame26 />
      <div className="h-0 relative shrink-0 w-full">
        <div className="absolute inset-[-1px_0_0_0]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 322 1">
            <line id="Line 50" stroke="var(--stroke-0, #AAD4FD)" x2="322" y1="0.5" y2="0.5" />
          </svg>
        </div>
      </div>
      <Frame21 />
      <Frame22 />
    </div>
  );
}

function BuildingBlocksNavigation() {
  return (
    <div className="absolute bg-[#fafafa] bottom-0 h-[24px] left-1/2 translate-x-[-50%] w-[402px]" data-name=".Building Blocks/navigation">
      <div className="absolute bg-[#1f2933] h-[4px] left-1/2 rounded-[12px] top-1/2 translate-x-[-50%] translate-y-[-50%] w-[108px]" data-name="handle" />
    </div>
  );
}

export default function App() {
  return (
    <div className="bg-[#fafafa] overflow-clip relative rounded-[16px] size-full min-h-screen" data-name="Support">
      <Frame23 />
      <Group />
      <Frame25 />
      <BuildingBlocksNavigation />
    </div>
  );
}
