import { FeeDashboard } from "./components/FeeDashboard";

export default function App() {
  return (
    <div className="size-full flex items-center justify-center bg-[#fafafa]">
      <div className="w-full max-w-[402px] h-full max-h-[874px]">
        <FeeDashboard />
      </div>
    </div>
  );
}