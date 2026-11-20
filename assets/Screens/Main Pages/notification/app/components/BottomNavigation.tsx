import svgPaths from "../../imports/svg-97awn6rvfg";

interface NavItemProps {
  icon: React.ReactNode;
  label: string;
  isActive?: boolean;
  onClick?: () => void;
}

function NavItem({ icon, label, isActive = false, onClick }: NavItemProps) {
  return (
    <div
      className="content-stretch flex flex-col items-center justify-center px-[12px] py-0 relative shrink-0 cursor-pointer"
      onClick={onClick}
    >
      <div className="content-stretch flex flex-col gap-[5px] items-center relative shrink-0">
        {icon}
        <p
          className={`font-['SF_Pro:${
            isActive ? "Semibold" : "Regular"
          }',sans-serif] font-${
            isActive ? "[590]" : "normal"
          } leading-[18px] relative shrink-0 text-${
            isActive ? "[#007dfc]" : "[#6b7280]"
          } text-[12px] text-nowrap`}
          style={{ fontVariationSettings: "'wdth' 100" }}
        >
          {label}
        </p>
      </div>
    </div>
  );
}

export function BottomNavigation() {
  return (
    <div className="bg-white fixed bottom-0 left-0 right-0 content-stretch flex flex-col items-start shadow-[0px_0px_1px_0px_rgba(61,117,252,0.24),0px_-4px_4px_1px_rgba(229,231,235,0.5)] max-w-[402px] mx-auto">
      <div className="bg-white relative shrink-0 w-full">
        <div className="flex flex-row items-center size-full">
          <div className="content-stretch flex items-center justify-between px-[24px] py-[16px] relative w-full">
            <NavItem
              icon={
                <div className="relative shrink-0 size-[24px]">
                  <svg
                    className="block size-full"
                    fill="none"
                    preserveAspectRatio="none"
                    viewBox="0 0 24 24"
                  >
                    <g id="home">
                      <path
                        d="M12 18V15"
                        id="Vector"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="1.5"
                      />
                      <path
                        d={svgPaths.p1f860900}
                        id="Vector_2"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="1.5"
                      />
                      <g id="Vector_3" opacity="0"></g>
                    </g>
                  </svg>
                </div>
              }
              label="Home"
            />

            <NavItem
              icon={
                <div className="relative shrink-0 size-[24px]">
                  <svg
                    className="block size-full"
                    fill="none"
                    preserveAspectRatio="none"
                    viewBox="0 0 24 24"
                  >
                    <g id="card">
                      <path
                        d="M2 8.50496H22"
                        id="Vector"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeMiterlimit="10"
                        strokeWidth="1.5"
                      />
                      <path
                        d="M6 16.505H8"
                        id="Vector_2"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeMiterlimit="10"
                        strokeWidth="1.5"
                      />
                      <path
                        d="M10.5 16.505H14.5"
                        id="Vector_3"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeMiterlimit="10"
                        strokeWidth="1.5"
                      />
                      <path
                        d={svgPaths.p34478e00}
                        id="Vector_4"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="1.5"
                      />
                      <g id="Vector_5" opacity="0"></g>
                    </g>
                  </svg>
                </div>
              }
              label="Fees"
            />

            <NavItem
              icon={
                <div className="relative shrink-0 size-[24px]">
                  <svg
                    className="block size-full"
                    fill="none"
                    preserveAspectRatio="none"
                    viewBox="0 0 24 24"
                  >
                    <g clipPath="url(#clip0_1_608)" id="history">
                      <g id="Vector"></g>
                      <path
                        d="M4 4V8H7"
                        id="Vector_2"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="2"
                      />
                      <path
                        d={svgPaths.p1d901900}
                        id="Vector_3"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="2"
                      />
                      <path
                        d="M12.0006 7L12 12.2752L16 16"
                        id="Vector_4"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="2"
                      />
                    </g>
                    <defs>
                      <clipPath id="clip0_1_608">
                        <rect fill="white" height="24" width="24" />
                      </clipPath>
                    </defs>
                  </svg>
                </div>
              }
              label="History"
            />

            <NavItem
              icon={
                <div className="relative shrink-0 size-[24px]">
                  <svg
                    className="block size-full"
                    fill="none"
                    preserveAspectRatio="none"
                    viewBox="0 0 24 24"
                  >
                    <g id="notification">
                      <path
                        d={svgPaths.pcd71700}
                        fill="var(--fill-0, #007DFC)"
                        id="Vector"
                      />
                      <path
                        d={svgPaths.p144aa1f0}
                        fill="var(--fill-0, #007DFC)"
                        id="Vector_2"
                      />
                      <g id="Vector_3" opacity="0"></g>
                    </g>
                  </svg>
                </div>
              }
              label="Alerts"
              isActive
            />

            <NavItem
              icon={
                <div className="relative shrink-0 size-[24px]">
                  <svg
                    className="block size-full"
                    fill="none"
                    preserveAspectRatio="none"
                    viewBox="0 0 24 24"
                  >
                    <g id="profile-circle">
                      <path
                        d={svgPaths.p3aeab480}
                        id="Vector"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="1.5"
                      />
                      <path
                        d={svgPaths.p364c500}
                        id="Vector_2"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="1.5"
                      />
                      <path
                        d={svgPaths.pace200}
                        id="Vector_3"
                        stroke="var(--stroke-0, #6B7280)"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="1.5"
                      />
                      <g id="Vector_4" opacity="0"></g>
                    </g>
                  </svg>
                </div>
              }
              label="Profile"
            />
          </div>
        </div>
      </div>
      <div
        className="bg-white h-[24px] relative shrink-0 w-full"
        data-name=".Building Blocks/navigation"
      >
        <div
          className="absolute bg-[#1f2933] h-[4px] left-1/2 rounded-[12px] top-1/2 translate-x-[-50%] translate-y-[-50%] w-[108px]"
          data-name="handle"
        />
      </div>
    </div>
  );
}
