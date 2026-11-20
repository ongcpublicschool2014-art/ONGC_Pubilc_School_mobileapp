import { useState } from "react";
import svgPaths from "./imports/svg-aew0fhjskw";
import imgTabletLogin11 from "figma:asset/db2648d010296363179bc3bc255f0296fecd7804.png";
import { ArrowLeft, Eye, EyeOff } from "lucide-react";

const countryCodes = [
  { flag: "🇮🇳", code: "+91", country: "India (IN)" },
  { flag: "🇺🇸", code: "+1", country: "United States (US)" },
  { flag: "🇬🇧", code: "+44", country: "United Kingdom (GB)" },
  { flag: "🇦🇺", code: "+61", country: "Australia (AU)" },
];

function IndianFlag() {
  return (
    <div className="h-[15px] overflow-clip relative rounded-[2px] shrink-0 w-[20px]">
      <div className="absolute contents inset-0">
        <div className="absolute inset-[0_0_66.67%_0]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 20 5">
            <path d="M0 0H20V5H0V0Z" fill="#F59E0B" />
          </svg>
        </div>
        <div className="absolute inset-[33.33%_0]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 20 5">
            <path d="M0 0H20V5H0V0Z" fill="white" />
          </svg>
        </div>
        <div className="absolute inset-[66.67%_0_0_0]">
          <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 20 5">
            <path d="M0 0H20V5H0V0Z" fill="#128807" />
          </svg>
        </div>
        <div className="absolute contents inset-[21.67%_29.11%_26.96%_32.48%]">
          <div className="absolute inset-[36.67%_40%]">
            <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 4 4">
              <path d={svgPaths.p31ad4500} fill="#000088" />
            </svg>
          </div>
          <div className="absolute inset-[38.33%_41.25%]">
            <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 3.5 3.5">
              <path d={svgPaths.p33077f0} fill="white" />
            </svg>
          </div>
          <div className="absolute inset-[47.67%_48.25%]">
            <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 0.7 0.7">
              <path d={svgPaths.p237690b0} fill="#000088" />
            </svg>
          </div>
        </div>
      </div>
    </div>
  );
}

function CaretDown() {
  return (
    <div className="relative shrink-0 size-[14px]">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 14 14">
        <path d={svgPaths.pa059c00} fill="#6B7280" />
      </svg>
    </div>
  );
}

function ShieldIcon() {
  return (
    <div className="relative shrink-0 size-[24px]">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <path d={svgPaths.p3485cb80} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" />
        <path d={svgPaths.p3e7eb200} stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
        <path d="M12 12.5V15.5" stroke="#6B7280" strokeLinecap="round" strokeLinejoin="round" strokeMiterlimit="10" strokeWidth="1.5" />
      </svg>
    </div>
  );
}

function LoginIcon() {
  return (
    <div className="relative shrink-0 size-[24px]">
      <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 24">
        <path d={svgPaths.p2c2f0680} fill="white" />
        <path d={svgPaths.p113d7180} fill="white" />
      </svg>
    </div>
  );
}

export default function App() {
  const [mobileNumber, setMobileNumber] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [selectedCountry, setSelectedCountry] = useState(0);
  const [showCountryDropdown, setShowCountryDropdown] = useState(false);

  const handleSignIn = () => {
    if (!mobileNumber || !password) {
      alert("Please fill in all fields");
      return;
    }
    console.log("Sign in attempted with:", {
      country: countryCodes[selectedCountry].code,
      mobile: mobileNumber,
      password: password,
    });
    alert(`Sign in with ${countryCodes[selectedCountry].code} ${mobileNumber}`);
  };

  const handleBack = () => {
    console.log("Back button clicked");
  };

  const handleForgotPassword = () => {
    console.log("Forgot password clicked");
    alert("Password reset link would be sent to your mobile number");
  };

  const handleSignUp = () => {
    console.log("Sign up clicked");
    alert("Redirecting to sign up...");
  };

  return (
    <div className="bg-[#fafafa] overflow-clip relative rounded-[16px] size-full min-h-screen flex items-center justify-center">
      <div className="relative w-full max-w-[402px] h-[852px]">
        {/* Illustration */}
        <div className="absolute left-[calc(87.5%-40.25px)] size-[133px] top-[104px] translate-x-[-50%]">
          <img alt="" className="absolute inset-0 max-w-none object-50%-50% object-cover pointer-events-none size-full" src={imgTabletLogin11} />
        </div>

        {/* Back Button */}
        <div className="absolute content-stretch flex items-center justify-between left-1/2 rounded-[10px] top-[40px] translate-x-[-50%] w-[354px]">
          <button 
            onClick={handleBack}
            className="bg-white block cursor-pointer relative rounded-[50px] shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_2px_4px_1px_#e5e7eb] shrink-0 size-[44px] hover:bg-gray-50 transition-colors flex items-center justify-center"
          >
            <ArrowLeft className="size-5 text-[#1f2933]" />
          </button>
          <div className="overflow-clip rounded-[50px] shrink-0 size-[44px]" />
        </div>

        {/* Title */}
        <div className="absolute content-stretch flex flex-col gap-[8px] items-start justify-center left-[24px] text-nowrap top-[104px]">
          <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[28px] relative shrink-0 text-[#1f2933] text-[22px]" style={{ fontVariationSettings: "'wdth' 100" }}>
            Sign In
          </p>
          <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#6b7280] text-[15px]" style={{ fontVariationSettings: "'wdth' 100" }}>
            Welcome back !
          </p>
        </div>

        {/* Mobile Number Field */}
        <div className="absolute content-stretch flex flex-col gap-[4px] items-start justify-center right-[24px] top-[256px]">
          <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
            Mobile No.
          </p>
          <div className="bg-white content-stretch flex gap-[10px] items-center p-[14px] relative rounded-[12px] shrink-0 w-[354px]">
            <div aria-hidden="true" className="absolute border-[#007dfc] border-[1.5px] border-solid inset-[-0.75px] pointer-events-none rounded-[12.75px]" />
            
            {/* Country Code Selector */}
            <div className="relative">
              <button
                onClick={() => setShowCountryDropdown(!showCountryDropdown)}
                className="content-stretch flex gap-[6px] items-center relative shrink-0 cursor-pointer hover:opacity-80 transition-opacity"
              >
                <div className="content-stretch flex flex-col items-center justify-center overflow-clip relative shrink-0 size-[24px]">
                  <IndianFlag />
                </div>
                <CaretDown />
              </button>

              {/* Dropdown */}
              {showCountryDropdown && (
                <div className="absolute top-full mt-2 left-0 bg-white rounded-lg shadow-lg border border-gray-200 py-2 z-10 min-w-[200px]">
                  {countryCodes.map((country, index) => (
                    <button
                      key={index}
                      onClick={() => {
                        setSelectedCountry(index);
                        setShowCountryDropdown(false);
                      }}
                      className="w-full px-4 py-2 text-left hover:bg-gray-100 flex items-center gap-2 transition-colors"
                    >
                      <span className="text-xl">{country.flag}</span>
                      <span className="text-sm text-gray-700">{country.code}</span>
                      <span className="text-sm text-gray-500">{country.country}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Separator */}
            <div className="flex h-[24px] items-center justify-center relative shrink-0 w-px">
              <div className="flex-none rotate-[90deg]">
                <div className="h-px relative w-[24px]">
                  <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 0.999999">
                    <path d="M24 0V0.999999H0V0H24Z" fill="#AAD4FD" />
                  </svg>
                </div>
              </div>
            </div>

            {/* Phone Input */}
            <div className="content-stretch flex font-['SF_Pro:Regular',sans-serif] font-normal gap-[10px] items-center leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap flex-1">
              <p className="relative shrink-0" style={{ fontVariationSettings: "'wdth' 100" }}>
                {countryCodes[selectedCountry].code}
              </p>
              <input
                type="tel"
                value={mobileNumber}
                onChange={(e) => setMobileNumber(e.target.value)}
                placeholder="(415) 728-3046"
                className="relative shrink-0 bg-transparent outline-none w-full placeholder:text-[#1f2933]"
                style={{ fontVariationSettings: "'wdth' 100" }}
              />
            </div>
          </div>
        </div>

        {/* Password Field */}
        <div className="absolute content-stretch flex flex-col gap-[4px] items-start justify-center right-[24px] top-[346px]">
          <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#1f2933] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
            Password
          </p>
          <div className="bg-[#f1f6fd] content-stretch flex items-center justify-between overflow-clip px-[16px] py-[14px] relative rounded-[12px] shadow-[0px_0px_1px_1px_rgba(0,95,204,0.24)] shrink-0 w-[354px]">
            <div className="content-stretch flex gap-[10px] items-center relative shrink-0 flex-1">
              <ShieldIcon />
              <div className="flex h-[24px] items-center justify-center relative shrink-0 w-px">
                <div className="flex-none rotate-[90deg]">
                  <div className="h-px relative w-[24px]">
                    <svg className="block size-full" fill="none" preserveAspectRatio="none" viewBox="0 0 24 0.999999">
                      <path d="M24 0V0.999999H0V0H24Z" fill="#AAD4FD" />
                    </svg>
                  </div>
                </div>
              </div>
              <input
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
                className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#6b7280] text-[15px] text-nowrap bg-transparent outline-none flex-1"
                style={{ fontVariationSettings: "'wdth' 100" }}
              />
            </div>
            <button
              onClick={() => setShowPassword(!showPassword)}
              className="relative shrink-0 size-[24px] cursor-pointer hover:opacity-70 transition-opacity"
            >
              {showPassword ? (
                <Eye className="size-full text-[#6B7280]" />
              ) : (
                <EyeOff className="size-full text-[#6B7280]" />
              )}
            </button>
          </div>
        </div>

        {/* Forgot Password */}
        <button
          onClick={handleForgotPassword}
          className="absolute font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] left-[calc(50%+177px)] text-[#007dfc] text-[15px] text-right top-[440px] translate-x-[-100%] w-[354px] hover:underline cursor-pointer"
          style={{ fontVariationSettings: "'wdth' 100" }}
        >
          Forgot Password ?
        </button>

        {/* Sign In Button */}
        <button
          onClick={handleSignIn}
          className="absolute bg-[#007dfc] content-stretch flex gap-[10px] items-center justify-center left-[24px] px-[8px] py-[14px] rounded-[12px] shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_2px_4px_1px_#e5e7eb] top-[502px] w-[354px] hover:bg-[#0066d4] active:bg-[#0056b3] transition-colors cursor-pointer"
        >
          <p className="font-['SF_Pro:Semibold',sans-serif] font-[590] leading-[0.3px] relative shrink-0 text-[16px] text-nowrap text-white" style={{ fontVariationSettings: "'wdth' 100" }}>
            Sign In
          </p>
          <LoginIcon />
        </button>

        {/* Sign Up Link */}
        <div className="absolute content-stretch flex gap-[4px] items-center left-1/2 top-[802px] translate-x-[-50%]">
          <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#6b7280] text-[15px] text-nowrap" style={{ fontVariationSettings: "'wdth' 100" }}>
            Don't have an Account ?
          </p>
          <button
            onClick={handleSignUp}
            className="content-stretch flex h-[24px] items-center justify-center relative rounded-[8px] shrink-0 cursor-pointer"
          >
            <p className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 text-[#007dfc] text-[15px] text-nowrap hover:underline" style={{ fontVariationSettings: "'wdth' 100" }}>
              Sign up
            </p>
          </button>
        </div>

        {/* Navigation Handle */}
        <div className="absolute bottom-0 h-[24px] left-1/2 translate-x-[-50%] w-[402px]">
          <div className="absolute bg-[#1f2933] h-[4px] left-1/2 rounded-[12px] top-1/2 translate-x-[-50%] translate-y-[-50%] w-[108px]" />
        </div>
      </div>
    </div>
  );
}
