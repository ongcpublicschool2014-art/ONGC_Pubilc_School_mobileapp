import { useState } from "react";
import svgPaths from "./imports/svg-vbv82be6kh";
import imgTabletLogin11 from "figma:asset/76fcbdd59904491d187bad7fa8122f5de1e8fe13.png";
import { toast } from "sonner@2.0.3";
import { Toaster } from "./components/ui/sonner";

export default function App() {
  const [phoneNumber, setPhoneNumber] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleGetOTP = () => {
    if (!phoneNumber) {
      toast.error("Please enter your phone number");
      return;
    }
    
    setIsLoading(true);
    // Simulate OTP sending
    setTimeout(() => {
      setIsLoading(false);
      toast.success("OTP sent successfully!");
    }, 1500);
  };

  const handleSignIn = () => {
    toast.info("Redirecting to Sign In page...");
  };

  return (
    <>
      <div className="min-h-screen bg-white flex items-center justify-center p-4">
        <div className="w-full max-w-[402px] relative">
          {/* Back Button */}
          <div className="flex items-center justify-between mb-8">
            <button 
              className="bg-white rounded-full shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_2px_4px_1px_#e5e7eb] size-[44px] flex items-center justify-center hover:shadow-md transition-shadow"
              onClick={() => toast.info("Going back...")}
            >
              <svg className="size-[20px]" fill="none" preserveAspectRatio="none" viewBox="0 0 20 20">
                <path 
                  d={svgPaths.p2628f300} 
                  stroke="#1F2933" 
                  strokeLinecap="round" 
                  strokeLinejoin="round" 
                  strokeMiterlimit="10" 
                  strokeWidth="1.5" 
                />
              </svg>
            </button>
            <div className="size-[44px]" />
          </div>

          {/* Title Section */}
          <div className="mb-8 flex items-start justify-between">
            <div>
              <h1 className="mb-2">Sign Up</h1>
              <p className="text-[#6b7280]">Create your Account !</p>
            </div>
            
            {/* Illustration */}
            <div className="size-[133px] relative shrink-0">
              <img 
                src={imgTabletLogin11} 
                alt="Sign up illustration" 
                className="absolute inset-0 max-w-none object-cover object-center size-full"
              />
            </div>
          </div>

          {/* Mobile Number Input */}
          <div className="mb-6">
            <label className="block mb-2 text-[#6b7280]">Mobile Number</label>
            <div className="bg-[#fafafa] rounded-[12px] border-[1.5px] border-[#007dfc] p-[14px] flex items-center gap-[10px]">
              {/* Country Selector */}
              <button className="flex items-center gap-[6px] shrink-0">
                <div className="size-[24px] flex items-center justify-center">
                  <IndiaFlag />
                </div>
                <svg className="size-[14px]" fill="none" viewBox="0 0 14 14">
                  <path d={svgPaths.pa059c00} fill="#6B7280" />
                </svg>
              </button>

              {/* Divider */}
              <div className="h-[24px] w-px">
                <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 0.999999 24">
                  <path d="M0.999999 24H0V0H0.999999V24Z" fill="#AAD4FD" />
                </svg>
              </div>

              {/* Phone Input */}
              <div className="flex items-center gap-[10px] flex-1">
                <span className="text-[#6b7280]">+91</span>
                <input
                  type="tel"
                  value={phoneNumber}
                  onChange={(e) => setPhoneNumber(e.target.value)}
                  placeholder="(415) 728-3046"
                  className="bg-transparent outline-none text-[#1f2933] flex-1 placeholder:text-[#6b7280]"
                />
              </div>
            </div>
          </div>

          {/* Get OTP Button */}
          <button
            onClick={handleGetOTP}
            disabled={isLoading}
            className="w-full bg-[#007dfc] text-white rounded-[12px] px-[8px] py-[14px] shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_2px_4px_1px_#e5e7eb] hover:bg-[#0066d9] transition-colors flex items-center justify-center gap-[10px] disabled:opacity-70 disabled:cursor-not-allowed"
          >
            <span>{isLoading ? "Sending..." : "Get OTP"}</span>
            <ShieldTickIcon />
          </button>

          {/* Sign In Link */}
          <div className="mt-12 text-center flex items-center justify-center gap-2">
            <p className="text-[#6b7280]">Already have an Account ?</p>
            <button 
              onClick={handleSignIn}
              className="text-[#007dfc] hover:underline"
            >
              Sign In
            </button>
          </div>

          {/* Bottom Handle */}
          <div className="mt-8 flex justify-center">
            <div className="w-[134px] h-[5px] bg-[#1f2933] rounded-full" />
          </div>
        </div>
      </div>
      <Toaster />
    </>
  );
}

function IndiaFlag() {
  return (
    <div className="h-[15px] w-[20px] rounded-[2px] overflow-hidden">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 20 15">
        <rect width="20" height="5" fill="#F59E0B" />
        <rect y="5" width="20" height="5" fill="#FAFAFA" />
        <rect y="10" width="20" height="5" fill="#128807" />
        <circle cx="10" cy="7.5" r="2" fill="#000088" />
        <circle cx="10" cy="7.5" r="1.75" fill="#FAFAFA" />
        <circle cx="10" cy="7.5" r="0.35" fill="#000088" />
      </svg>
    </div>
  );
}

function ShieldTickIcon() {
  return (
    <svg className="size-[24px]" fill="none" viewBox="0 0 24 24">
      <path 
        d={svgPaths.p3d3b8a00} 
        fill="white" 
      />
    </svg>
  );
}