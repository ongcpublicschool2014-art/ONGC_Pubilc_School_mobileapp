import { useState } from 'react';
import svgPaths from '../../imports/svg-d473a4nvqu';
import { toast } from 'sonner';

interface TransactionData {
  id: string;
  amount: number;
  date: string;
  time: string;
  paymentMethod: string;
  feeType: string;
  studentName: string;
  studentClass: string;
  status: 'failed' | 'success' | 'pending';
}

export default function TransactionDetailsEnhanced() {
  const [transaction] = useState<TransactionData>({
    id: '#TRA-9826',
    amount: 1000,
    date: '10 July 2025',
    time: '6:00 pm',
    paymentMethod: 'VISA**** 9918',
    feeType: 'Library Fee - Term 1',
    studentName: 'Robert',
    studentClass: '10-B',
    status: 'failed'
  });

  const handleRetry = () => {
    toast.info('Retrying payment...', {
      description: 'Redirecting to payment gateway...'
    });
    // In a real app, this would trigger a payment retry
  };

  const handleShare = async () => {
    const shareText = `Transaction ${transaction.id}\nAmount: ₹${transaction.amount}\nStatus: Payment Failed\nDate: ${transaction.date} ${transaction.time}`;
    
    if (navigator.share) {
      try {
        await navigator.share({
          title: 'Transaction Details',
          text: shareText
        });
      } catch (err) {
        if ((err as Error).name !== 'AbortError') {
          toast.error('Failed to share');
        }
      }
    } else {
      // Fallback: copy to clipboard
      navigator.clipboard.writeText(shareText);
      toast.success('Transaction details copied to clipboard!');
    }
  };

  const handleBack = () => {
    toast.info('Going back...');
    // In a real app, this would navigate back
  };

  const handleNotification = () => {
    toast.info('Opening notifications...');
    // In a real app, this would show notifications
  };

  return (
    <div className="bg-[#fafafa] overflow-clip relative rounded-[24px] size-full" data-name="Transaction Details">
      {/* Header */}
      <div className="absolute content-stretch flex flex-col items-start left-1/2 top-[51px] translate-x-[-50%]">
        <p className="font-['Plus_Jakarta_Sans',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">
          Transaction Details
        </p>
      </div>

      {/* Back Button */}
      <button 
        onClick={handleBack}
        className="absolute bg-white content-stretch cursor-pointer flex items-center left-[24px] overflow-clip p-[11px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[40px] hover:shadow-lg transition-shadow"
      >
        <div className="relative shrink-0 size-[24px]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
            <path d={svgPaths.p2a5cd480} stroke="#1F2933" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="2" />
          </svg>
        </div>
      </button>

      {/* Notification Button */}
      <button 
        onClick={handleNotification}
        className="absolute bg-white content-stretch flex flex-col gap-[10px] items-center justify-center left-[calc(75%+30.5px)] p-[9px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[40px] hover:shadow-lg transition-shadow"
      >
        <div className="relative shrink-0 size-[28px]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 28 28">
            <path d="M14 7.51333V11.3983" stroke="#1F2933" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="2" />
            <path d={svgPaths.p1ce61900} stroke="#1F2933" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="2" />
            <path d={svgPaths.p116fbe00} stroke="#1F2933" strokeMiterlimit="10" strokeWidth="2" />
          </svg>
        </div>
        <div className="absolute left-[25px] size-[9px] top-[8px]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 10.5 10.5">
            <circle cx="5.25" cy="5.25" fill="#007DFC" r="4.5" stroke="white" strokeWidth="1.5" />
          </svg>
        </div>
      </button>

      {/* Transaction Card */}
      <div className="absolute content-stretch flex flex-col items-start left-[24px] overflow-clip rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[106px] w-[354px]">
        {/* Status Header - Red for Failed */}
        <div className="bg-[#dc2626] relative shrink-0 w-full">
          <div className="flex flex-col items-center overflow-clip rounded-[inherit] size-full">
            <div className="content-stretch flex flex-col items-center p-[16px] relative w-full">
              <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
                {/* X Icon */}
                <div className="bg-[#dc2626] relative rounded-[50px] shrink-0">
                  <div className="content-stretch flex items-center overflow-clip p-[10px] relative rounded-[inherit]">
                    <div className="relative shrink-0 size-[36px]">
                      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 36 36">
                        <path d={svgPaths.p3de28e00} fill="white" />
                      </svg>
                    </div>
                  </div>
                  <div aria-hidden="true" className="absolute border border-[#f1f6fd] border-solid inset-[-1px] pointer-events-none rounded-[51px] shadow-[0px_3px_40px_0px_rgba(31,41,51,0.1),0px_0px_1px_0px_rgba(31,41,51,0.75)]" />
                </div>
                {/* Status Text */}
                <div className="grid-cols-[max-content] grid-rows-[max-content] inline-grid leading-[0] place-items-start relative shrink-0">
                  <p className="[grid-area:1_/_1] font-['SF_Pro',sans-serif] font-semibold leading-[28px] ml-0 mt-0 relative text-[22px] text-nowrap text-white">
                    Payment Failed
                  </p>
                </div>
                <div className="grid-cols-[max-content] grid-rows-[max-content] inline-grid leading-[0] place-items-start relative shrink-0">
                  <p className="[grid-area:1_/_1] font-['SF_Pro',sans-serif] font-normal leading-[18px] ml-0 mt-0 relative text-[12px] text-nowrap text-white">
                    Transaction In-completed
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Details Section */}
        <div className="bg-white relative shrink-0 w-full">
          <div className="flex flex-col items-center justify-center size-full">
            <div className="content-stretch flex flex-col gap-[16px] items-center justify-center p-[16px] relative w-full">
              {/* Amount */}
              <div className="content-stretch flex flex-col gap-[10px] items-center relative shrink-0 w-[105px]">
                <p className="font-['SF_Pro',sans-serif] font-normal leading-[22px] min-w-full relative shrink-0 text-[#6b7280] text-[15px] text-center w-[min-content]">
                  Amount Paid
                </p>
                <p className="font-['SF_Pro',sans-serif] font-bold leading-[36px] relative shrink-0 text-[#dc2626] text-[26px] text-nowrap">
                  ₹ {transaction.amount.toLocaleString()}
                </p>
              </div>

              {/* Divider */}
              <div className="h-0 relative shrink-0 w-full">
                <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 322 1">
                  <line stroke="#C6DDFF" x2="322" y1="0.5" y2="0.5" />
                </svg>
              </div>

              {/* Transaction Details */}
              <DetailRow label="Transaction ID" value={transaction.id} />
              <DetailRow 
                label="Date & Time" 
                value={
                  <div className="content-stretch flex gap-[5px] items-center justify-center relative shrink-0">
                    <p className="font-['SF_Pro',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap">
                      {transaction.date}
                    </p>
                    <div className="flex items-center justify-center relative shrink-0">
                      <div className="flex-none rotate-[180deg]">
                        <div className="relative size-[4px]">
                          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 4">
                            <circle cx="2" cy="2" fill="#1F2933" r="2" />
                          </svg>
                        </div>
                      </div>
                    </div>
                    <p className="font-['SF_Pro',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap">
                      {transaction.time}
                    </p>
                  </div>
                } 
              />
              <DetailRow label="Payment Method" value={transaction.paymentMethod} />
              <DetailRow label="Fee Type" value={transaction.feeType} />
              <DetailRow label="Student" value={transaction.studentName} />
              <DetailRow label="Class" value={transaction.studentClass} />
            </div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="absolute content-stretch flex gap-[16px] items-center left-[24px] top-[634px]">
        {/* Retry Button */}
        <button 
          onClick={handleRetry}
          className="bg-[#007dfc] content-stretch flex gap-[10px] items-center justify-center overflow-clip px-[8px] py-[14px] relative rounded-[12px] shrink-0 w-[169px] hover:bg-[#0066d9] transition-colors"
        >
          <div className="relative shrink-0 size-[24px]">
            <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
              <path d={svgPaths.pbc28a60} stroke="#FAFAFA" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
              <path d={svgPaths.p3d33fc0} stroke="#FAFAFA" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
              <path d={svgPaths.p39bde380} stroke="#FAFAFA" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
              <path d={svgPaths.p33e10200} stroke="#FAFAFA" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
            </svg>
          </div>
          <p className="font-['SF_Pro',sans-serif] font-semibold leading-[0.3px] relative shrink-0 text-[#fafafa] text-[16px] text-center text-nowrap">
            Retry
          </p>
        </button>

        {/* Share Button */}
        <button 
          onClick={handleShare}
          className="relative rounded-[12px] shrink-0 w-[169px] hover:bg-gray-50 transition-colors"
        >
          <div className="content-stretch flex gap-[10px] items-center justify-center overflow-clip px-[8px] py-[14px] relative rounded-[inherit] w-full">
            <div className="relative shrink-0 size-[24px]">
              <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
                <path d={svgPaths.p18a74f00} fill="#6B7280" />
              </svg>
            </div>
            <p className="font-['SF_Pro',sans-serif] font-semibold leading-[0.3px] relative shrink-0 text-[#6b7280] text-[16px] text-center text-nowrap">
              Share
            </p>
          </div>
          <div aria-hidden="true" className="absolute border-[#6b7280] border-[1.5px] border-solid inset-0 pointer-events-none rounded-[12px]" />
        </button>
      </div>

      {/* Bottom Navigation Handle */}
      <div className="absolute bottom-0 h-[24px] left-1/2 translate-x-[-50%] w-[402px]">
        <div className="absolute bg-[#1f2933] h-[4px] left-1/2 rounded-[12px] top-1/2 translate-x-[-50%] translate-y-[-50%] w-[108px]" />
      </div>
    </div>
  );
}

interface DetailRowProps {
  label: string;
  value: string | React.ReactNode;
}

function DetailRow({ label, value }: DetailRowProps) {
  return (
    <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
      <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
        <p className="font-['Inter',sans-serif] font-normal leading-[20px] not-italic relative shrink-0 text-[#6b7280] text-[14px] text-nowrap">
          {label}
        </p>
      </div>
      {typeof value === 'string' ? (
        <div className="content-stretch flex flex-col items-start justify-center overflow-clip relative shrink-0">
          <p className="font-['SF_Pro',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap">
            {value}
          </p>
        </div>
      ) : (
        value
      )}
    </div>
  );
}
