import { useState } from 'react';
import ProfilePanel from './components/ProfilePanel';

export default function App() {
  const [isPanelOpen, setIsPanelOpen] = useState(true);

  return (
    <div className="size-full flex items-center justify-center bg-gray-100">
      {isPanelOpen && (
        <div className="w-[320px] h-[740px]">
          <ProfilePanel onClose={() => setIsPanelOpen(false)} />
        </div>
      )}
    </div>
  );
}
