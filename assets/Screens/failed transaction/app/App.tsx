import { Toaster } from './components/ui/sonner';
import TransactionDetailsEnhanced from './components/TransactionDetailsEnhanced';

export default function App() {
  return (
    <div className="size-full flex items-center justify-center bg-gray-100">
      <div className="w-full max-w-[402px] h-[896px]">
        <TransactionDetailsEnhanced />
      </div>
      <Toaster position="top-center" />
    </div>
  );
}