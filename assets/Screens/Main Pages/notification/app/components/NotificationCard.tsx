import svgPaths from "../../imports/svg-97awn6rvfg";

interface NotificationCardProps {
  type: "fee-due" | "payment-success" | "late-fee" | "ptm";
  title: string;
  description: string;
  timestamp: string;
  isRead?: boolean;
  onClick?: () => void;
}

export function NotificationCard({
  type,
  title,
  description,
  timestamp,
  isRead = false,
  onClick,
}: NotificationCardProps) {
  const getIcon = () => {
    switch (type) {
      case "fee-due":
        return (
          <svg
            className="block size-full"
            fill="none"
            preserveAspectRatio="none"
            viewBox="0 0 24 24"
          >
            <g id="notification">
              <path
                d={svgPaths.pcd71700}
                fill="var(--fill-0, #1F2933)"
                id="Vector"
              />
              <path
                d={svgPaths.p144aa1f0}
                fill="var(--fill-0, #1F2933)"
                id="Vector_2"
              />
              <g id="Vector_3" opacity="0"></g>
            </g>
          </svg>
        );
      case "payment-success":
        return (
          <svg
            className="block size-full"
            fill="none"
            preserveAspectRatio="none"
            viewBox="0 0 24 24"
          >
            <g id="money-tick">
              <path
                d={svgPaths.p2352480}
                fill="var(--fill-0, #1F2933)"
                id="Vector"
              />
              <g id="Vector_2" opacity="0"></g>
              <path
                d={svgPaths.p2c85ddb0}
                fill="var(--fill-0, #1F2933)"
                id="Vector_3"
              />
            </g>
          </svg>
        );
      case "late-fee":
        return (
          <svg
            className="block size-full"
            fill="none"
            preserveAspectRatio="none"
            viewBox="0 0 24 24"
          >
            <g id="money-time">
              <g id="Vector" opacity="0"></g>
              <path
                d={svgPaths.p250f3800}
                fill="var(--fill-0, #6B7280)"
                id="Vector_2"
              />
              <path
                d={svgPaths.p2352480}
                fill="var(--fill-0, #6B7280)"
                id="Vector_3"
              />
            </g>
          </svg>
        );
      case "ptm":
        return (
          <svg
            className="block size-full"
            fill="none"
            preserveAspectRatio="none"
            viewBox="0 0 24 24"
          >
            <g id="profile-2user">
              <path
                d={svgPaths.p85bb080}
                fill="var(--fill-0, #6B7280)"
                id="Vector"
              />
              <path
                d={svgPaths.p128ca00}
                fill="var(--fill-0, #6B7280)"
                id="Vector_2"
              />
              <path
                d={svgPaths.p266c4000}
                fill="var(--fill-0, #6B7280)"
                id="Vector_3"
              />
              <path
                d={svgPaths.p86b9f80}
                fill="var(--fill-0, #6B7280)"
                id="Vector_4"
              />
              <g id="Vector_5" opacity="0"></g>
            </g>
          </svg>
        );
    }
  };

  return (
    <div
      className={`${
        isRead ? "bg-white" : "bg-[#fafafa]"
      } content-stretch flex gap-[8px] items-start p-[12px] relative rounded-[12px] ${
        isRead
          ? "shadow-[0px_5px_40px_0px_rgba(128,128,135,0.1),0px_0px_1px_0px_rgba(0,81,198,0.75)]"
          : "shadow-[0px_0px_3px_3px_rgba(0,95,204,0.24)]"
      } shrink-0 w-full cursor-pointer transition-all hover:scale-[1.01]`}
      onClick={onClick}
    >
      <div className="content-stretch flex items-center px-0 py-[3px] relative shrink-0">
        <div className="content-stretch flex items-start px-px py-[2px] relative rounded-[6px] shrink-0">
          <div className="relative shrink-0 size-[24px]">{getIcon()}</div>
        </div>
      </div>

      <div className="basis-0 content-stretch flex flex-col gap-[6px] grow items-start min-h-px min-w-px relative shrink-0">
        <div className="content-stretch flex flex-col items-start justify-center relative shrink-0">
          <p
            className={`font-['SF_Pro:Regular',sans-serif] font-normal leading-[22px] relative shrink-0 ${
              isRead ? "text-[#1f2933]" : "text-[#6b7280]"
            } text-[15px] text-nowrap`}
            style={{ fontVariationSettings: "'wdth' 100" }}
          >
            {title}
          </p>
        </div>

        <p
          className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#6b7280] text-[12px]"
          style={{ fontVariationSettings: "'wdth' 100" }}
        >
          {description}
        </p>

        <div className="relative shrink-0 w-full">
          <div className="flex flex-row items-center size-full">
            <div className="content-stretch flex items-center justify-between pl-0 pr-[8px] py-0 relative w-full">
              <div className="content-stretch flex items-center justify-center relative shrink-0">
                <p
                  className="font-['SF_Pro:Regular',sans-serif] font-normal leading-[18px] relative shrink-0 text-[#007dfc] text-[12px] text-nowrap"
                  style={{ fontVariationSettings: "'wdth' 100" }}
                >
                  {timestamp}
                </p>
              </div>
              <div className="flex items-center justify-center relative shrink-0">
                <div className="flex-none rotate-[180deg]">
                  <div className="relative size-[20px]">
                    <svg
                      className="block size-full"
                      fill="none"
                      preserveAspectRatio="none"
                      viewBox="0 0 20 20"
                    >
                      <g id="arrow-left">
                        <path
                          d={svgPaths.p3a43fe80}
                          id="Vector"
                          stroke="var(--stroke-0, #6B7280)"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeMiterlimit="10"
                          strokeWidth="1.5"
                        />
                        <g id="Vector_2" opacity="0"></g>
                      </g>
                    </svg>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}