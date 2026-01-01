'use client';

import { useState } from 'react';

interface CurrencyConverterProps {
  usdAmount: number;
  cadAmount: number;
}

export default function CurrencyConverter({ usdAmount, cadAmount }: CurrencyConverterProps) {
  const [showUSD, setShowUSD] = useState(false);

  return (
    <div className="mt-2">
      <button
        onClick={() => setShowUSD(!showUSD)}
        className="text-xs text-[var(--muted)] hover:text-[var(--accent-primary)] transition-colors flex items-center gap-1"
        type="button"
      >
        <span>{showUSD ? `$${usdAmount.toFixed(2)} USD` : `$${cadAmount.toFixed(2)} CAD`}</span>
        <svg className={`w-3 h-3 transition-transform ${showUSD ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>
      <div className="text-[10px] text-[var(--muted)] mt-1">
        {showUSD ? `$${cadAmount.toFixed(2)} CAD` : `$${usdAmount.toFixed(2)} USD`}
      </div>
    </div>
  );
}
