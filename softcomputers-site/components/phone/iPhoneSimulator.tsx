'use client';

import { useState } from 'react';
import Image from 'next/image';

interface iPhoneSimulatorProps {
  screenshots?: string[];
  screenData?: Array<{ icon: string; title: string; desc: string; gradient: string }>;
}

export default function iPhoneSimulator({ 
  screenshots = [], 
  screenData = [
    { icon: '⏱️', title: 'Focus Timer', desc: 'Timed sessions', gradient: 'from-blue-500 to-cyan-500' },
    { icon: '✅', title: 'Tasks', desc: 'Smart management', gradient: 'from-green-500 to-emerald-500' },
    { icon: '📈', title: 'Progress', desc: 'Track growth', gradient: 'from-purple-500 to-pink-500' },
    { icon: '👤', title: 'Profile', desc: 'Customize & sync', gradient: 'from-orange-500 to-red-500' },
  ]
}: iPhoneSimulatorProps) {
  const [currentScreen, setCurrentScreen] = useState(0);
  const [imageError, setImageError] = useState<Record<number, boolean>>({});

  const defaultScreens = [
    '/images/screen-focus.png',
    '/images/screen-tasks.png',
    '/images/screen-progress.png',
    '/images/screen-profile.png',
  ];

  const screens = screenshots.length > 0 ? screenshots : defaultScreens;
  const displayData = screenData.length > 0 ? screenData : [
    { icon: '⏱️', title: 'FocusFlow', desc: 'Be Present', gradient: 'from-blue-500 to-purple-600' },
  ];

  const handleImageError = (index: number) => {
    setImageError(prev => ({ ...prev, [index]: true }));
  };

  const showFallback = imageError[currentScreen] || !screens.length || !screens[currentScreen];

  return (
    <div className="relative">
      {/* iPhone Frame */}
      <div className="relative mx-auto" style={{ width: '375px', maxWidth: '100%' }}>
        {/* iPhone Outer Frame */}
        <div className="relative bg-gradient-to-b from-gray-900 to-black rounded-[3.5rem] p-[10px] shadow-2xl border border-gray-800/50" style={{ 
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.05) inset'
        }}>
          {/* Screen Bezel */}
          <div className="bg-black rounded-[3rem] p-[6px] overflow-hidden">
            {/* Dynamic Island */}
            <div className="absolute top-[10px] left-1/2 transform -translate-x-1/2 w-32 h-6 bg-black rounded-full z-20 border border-gray-900/50" />
            
            {/* Screen */}
            <div className="relative bg-black rounded-[2.5rem] overflow-hidden" style={{ aspectRatio: '9/19.5' }}>
              {!showFallback ? (
                <div className="relative w-full h-full bg-black">
                  <Image
                    src={screens[currentScreen]}
                    alt={`FocusFlow screen ${currentScreen + 1}`}
                    fill
                    className="object-cover"
                    priority={currentScreen === 0}
                    quality={95}
                    onError={() => handleImageError(currentScreen)}
                    sizes="375px"
                  />
                </div>
              ) : (
                <div className={`w-full h-full bg-gradient-to-br ${displayData[currentScreen]?.gradient || 'from-blue-500 to-purple-600'} flex items-center justify-center`}>
                  <div className="text-center text-white p-8">
                    <div className="text-6xl mb-4">{displayData[currentScreen]?.icon || '⏱️'}</div>
                    <div className="text-2xl font-semibold mb-2">{displayData[currentScreen]?.title || 'FocusFlow'}</div>
                    <div className="text-sm opacity-90">{displayData[currentScreen]?.desc || 'Focus Timer'}</div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Screen Navigation Dots */}
        {screens.length > 1 && (
          <div className="flex justify-center gap-2 mt-6">
            {screens.map((_, index) => (
              <button
                key={index}
                onClick={() => setCurrentScreen(index)}
                className={`h-2 rounded-full transition-all ${
                  index === currentScreen ? 'w-8 bg-[var(--foreground)]' : 'w-2 bg-[var(--muted)]/50'
                }`}
                aria-label={`View screen ${index + 1}`}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
