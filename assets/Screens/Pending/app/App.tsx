import { useState, useEffect } from 'react';
import svgPaths from '../imports/svg-2s59s8d9i5';

// Payment card icon component
function PaymentIcon({ type }: { type: 'tuition' | 'bus' }) {
  if (type === 'tuition') {
    return (
      <div className="bg-[#f59e0b] overflow-clip relative rounded-[8px] shrink-0 size-[40px]">
        <div className="absolute content-stretch flex inset-[20%] items-center p-[3px]">
          <div className="relative shrink-0 size-[18px]">
            <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 18 18">
              <path d={svgPaths.p1c62b000} fill="white" />
            </svg>
          </div>
        </div>
      </div>
    );
  }
  
  return (
    <div className="bg-[#f59e0b] overflow-clip relative rounded-[8px] shrink-0 size-[40px]">
      <div className="absolute inset-[20%]">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
          <g>
            <g opacity="0"></g>
            <path d={svgPaths.p2657bb00} fill="white" />
            <path d={svgPaths.p15b8700} fill="white" />
            <path d={svgPaths.p28daad80} fill="white" />
          </g>
        </svg>
      </div>
    </div>
  );
}

// Arrow icon component
function ArrowIcon() {
  return (
    <div className="relative size-[24px]">
      <div className="absolute contents inset-0">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
          <g>
            <path d={svgPaths.p2a5cd480} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
            <g opacity="0"></g>
          </g>
        </svg>
      </div>
    </div>
  );
}

// Back button icon
function BackIcon() {
  return (
    <div className="relative shrink-0 size-[24px]">
      <div className="absolute contents inset-0">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
          <g>
            <path d={svgPaths.p2a5cd480} stroke="#1F2933" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="2" />
            <g opacity="0"></g>
          </g>
        </svg>
      </div>
    </div>
  );
}

// Notification bell icon
function NotificationIcon() {
  return (
    <div className="relative shrink-0 size-[28px]">
      <div className="absolute contents inset-0">
        <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 28 28">
          <g>
            <path d="M14 7.51333V11.3983" stroke="#1F2933" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="2" />
            <path d={svgPaths.p1ce61900} stroke="#1F2933" strokeLinecap="round" strokeMiterlimit="10" strokeWidth="2" />
            <path d={svgPaths.p116fbe00} stroke="#1F2933" strokeMiterlimit="10" strokeWidth="2" />
            <g opacity="0"></g>
          </g>
        </svg>
      </div>
    </div>
  );
}

// Payment card component
function PaymentCard({ 
  type, 
  title, 
  subtitle, 
  amount, 
  dueDate, 
  status,
  onClick 
}: { 
  type: 'tuition' | 'bus';
  title: string;
  subtitle: string;
  amount: number;
  dueDate: string;
  status: string;
  onClick: () => void;
}) {
  return (
    <div className="bg-white content-stretch flex flex-col p-[16px] rounded-[12px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] w-full">
      <div className="content-stretch flex flex-col gap-[12px] items-start relative shrink-0 w-full">
        <div className="content-stretch flex items-start justify-between relative shrink-0 w-full">
          <div className="content-stretch flex gap-[10px] items-center relative shrink-0">
            <PaymentIcon type={type} />
            <div className="content-stretch flex flex-col gap-[6px] items-start relative shrink-0">
              <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
                {title}
              </p>
              <div className="content-stretch flex items-center justify-center relative shrink-0">
                <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
                  {subtitle}
                </p>
              </div>
            </div>
          </div>
          <div className="content-stretch flex flex-col gap-[3px] items-end justify-center relative shrink-0 text-nowrap">
            <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[18px] relative shrink-0 text-[#f59e0b] text-[12px]" style={{ fontVariationSettings: "'wdth' 100" }}>
              {status}
            </p>
            <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px]">₹ {amount.toLocaleString()}</p>
          </div>
        </div>
        <div className="content-stretch flex items-center justify-between relative shrink-0 w-full">
          <div className="content-stretch flex font-normal gap-[6px] items-center justify-center relative shrink-0 text-nowrap">
            <p className="font-['SF_Pro:Regular',sans-serif] leading-[22px] relative shrink-0 text-[#6b7280] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
              Due Date:
            </p>
            <p className="font-['SF_Pro:Regular',sans-serif] leading-[22px] relative shrink-0 text-[#1f2933] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
              {dueDate}
            </p>
          </div>
          <button 
            onClick={onClick}
            className="flex items-center justify-center relative shrink-0 cursor-pointer"
          >
            <div className="flex-none rotate-[180deg]">
              <ArrowIcon />
            </div>
          </button>
        </div>
      </div>
    </div>
  );
}

export default function App() {
  const [payments, setPayments] = useState<any[]>([]);
  const [hasNotifications, setHasNotifications] = useState(true);

  useEffect(() => {
    // Load initial payment data
    loadPayments();
  }, []);

  const loadPayments = () => {
    // Initial mock data - will be replaced with Supabase data
    const mockPayments = [
      {
        id: 1,
        type: 'tuition',
        title: 'Tuition Fee',
        subtitle: 'Uniform & Text Book',
        amount: 15500,
        dueDate: '10 July 2025',
        status: 'Pending'
      },
      {
        id: 2,
        type: 'bus',
        title: 'Bus Fee',
        subtitle: 'Monthly Transport',
        amount: 10000,
        dueDate: '10 July 2025',
        status: 'Pending'
      }
    ];
    setPayments(mockPayments);
  };

  const handlePaymentClick = (paymentId: number) => {
    console.log('Payment clicked:', paymentId);
    // Navigate to payment details
  };

  const handleBackClick = () => {
    console.log('Back clicked');
    // Navigate back
  };

  const handleNotificationClick = () => {
    console.log('Notification clicked');
    // Navigate to notifications
  };

  return (
    <div className="bg-[#f8f9fa] overflow-clip relative rounded-[24px] size-full">
      {/* Header */}
      <div className="absolute contents left-1/2 top-[40px] translate-x-[-50%]">
        {/* Notification Button */}
        <div className="absolute bg-white content-stretch flex flex-col gap-[10px] items-center justify-center left-[calc(75%+30.5px)] p-[9px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[40px]">
          <button onClick={handleNotificationClick} className="cursor-pointer">
            <NotificationIcon />
          </button>
          {hasNotifications && (
            <div className="absolute left-[25px] size-[9px] top-[8px]">
              <div className="absolute inset-[-8.33%]">
                <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 10.5 10.5">
                  <circle cx="5.25" cy="5.25" fill="#007DFC" r="4.5" stroke="#FAFAFA" strokeWidth="1.5" />
                </svg>
              </div>
            </div>
          )}
        </div>
        
        {/* Title */}
        <div className="absolute content-stretch flex flex-col items-start left-1/2 top-[51px] translate-x-[-50%]">
          <p className="font-['Plus_Jakarta_Sans:SemiBold',sans-serif] font-semibold leading-[24px] relative shrink-0 text-[#1f2933] text-[18px] text-nowrap">Pending</p>
        </div>
        
        {/* Back Button */}
        <button 
          onClick={handleBackClick}
          className="absolute bg-white content-stretch cursor-pointer flex items-center left-[24px] overflow-clip p-[11px] rounded-[50px] shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)] top-[40px]"
        >
          <BackIcon />
        </button>
      </div>

      {/* Payment Cards */}
      <div className="absolute left-[24px] top-[106px] flex flex-col gap-[16px] w-[354px]">
        {payments.map((payment, index) => (
          <PaymentCard
            key={payment.id}
            type={payment.type as 'tuition' | 'bus'}
            title={payment.title}
            subtitle={payment.subtitle}
            amount={payment.amount}
            dueDate={payment.dueDate}
            status={payment.status}
            onClick={() => handlePaymentClick(payment.id)}
          />
        ))}
      </div>

      {/* Bottom Navigation */}
      <div className="absolute bottom-0 h-[24px] left-1/2 translate-x-[-50%] w-[402px]">
        <div className="absolute bg-[#1f2933] h-[4px] left-1/2 rounded-[12px] top-1/2 translate-x-[-50%] translate-y-[-50%] w-[108px]" />
      </div>
    </div>
  );
}
