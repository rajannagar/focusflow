'use client';

import { useState } from 'react';

type Currency = 'USD' | 'CAD';

interface CurrencySelectorProps {
  onCurrencyChange: (currency: Currency) => void;
  defaultCurrency?: Currency;
}

export default function CurrencySelector({ onCurrencyChange, defaultCurrency = 'CAD' }: CurrencySelectorProps) {
  const [selectedCurrency, setSelectedCurrency] = useState<Currency>(defaultCurrency);

  const handleCurrencyChange = (currency: Currency) => {
    setSelectedCurrency(currency);
    onCurrencyChange(currency);
  };

  return (
    <div className="flex items-center gap-2 bg-[var(--soft)] rounded-lg p-1 border border-[var(--border)]">
      <button
        onClick={() => handleCurrencyChange('USD')}
        className={`px-4 py-2 rounded-md text-sm font-medium transition-all ${
          selectedCurrency === 'USD'
            ? 'bg-[var(--foreground)] text-[var(--background)] shadow-sm'
            : 'text-[var(--muted)] hover:text-[var(--foreground)]'
        }`}
        type="button"
      >
        USD
      </button>
      <button
        onClick={() => handleCurrencyChange('CAD')}
        className={`px-4 py-2 rounded-md text-sm font-medium transition-all ${
          selectedCurrency === 'CAD'
            ? 'bg-[var(--foreground)] text-[var(--background)] shadow-sm'
            : 'text-[var(--muted)] hover:text-[var(--foreground)]'
        }`}
        type="button"
      >
        CAD
      </button>
    </div>
  );
}

