'use client';

import { useState, useCallback } from 'react';
import Image from 'next/image';

interface iPhoneSimulatorProps {
  screenshots?: string[];
  screenData?: Array<{ icon: string; title: string; desc: string; gradient: string }>;
}

export default function iPhoneSimulator({ 
  screenshots = [], 
  screenData = [
    { icon: '⏱️', title: 'Focus Timer', desc: 'Timed sessions', gradient: 'from-violet-500 to-purple-600' },
    { icon: '✅', title: 'Tasks', desc: 'Smart management', gradient: 'from-emerald-500 to-teal-600' },
    { icon: '📈', title: 'Progress', desc: 'Track growth', gradient: 'from-amber-500 to-orange-600' },
    { icon: '👤', title: 'Profile', desc: 'Customize & sync', gradient: 'from-rose-500 to-pink-600' },
  ]
}: iPhoneSimulatorProps) {
  const [currentScreen, setCurrentScreen] = useState(0);
  const [imageError, setImageError] = useState<Record<number, boolean>>({});
  
  // Touch/Swipe state
  const [touchStart, setTouchStart] = useState<number | null>(null);
  const [touchEnd, setTouchEnd] = useState<number | null>(null);
  
  // Mouse drag state
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState<number | null>(null);
  const [dragEnd, setDragEnd] = useState<number | null>(null);

  const minSwipeDistance = 50;

  const defaultScreens = [
    '/images/screen-focus.png',
    '/images/screen-tasks.png',
    '/images/screen-progress.png',
    '/images/screen-profile.png',
  ];

  const screens = screenshots.length > 0 ? screenshots : defaultScreens;
  const displayData = screenData.length > 0 ? screenData : [
    { icon: '⏱️', title: 'FocusFlow', desc: 'Be Present', gradient: 'from-violet-500 to-purple-600' },
  ];

  const handleImageError = (index: number) => {
    setImageError(prev => ({ ...prev, [index]: true }));
  };

  const showFallback = imageError[currentScreen] || !screens.length || !screens[currentScreen];

  // Navigate to next/previous screen
  const goToScreen = useCallback((direction: 'next' | 'prev') => {
    if (direction === 'next') {
      setCurrentScreen((prev) => (prev + 1) % screens.length);
    } else {
      setCurrentScreen((prev) => (prev - 1 + screens.length) % screens.length);
    }
  }, [screens.length]);

  // Touch handlers for mobile swipe
  const onTouchStart = (e: React.TouchEvent) => {
    setTouchEnd(null);
    setTouchStart(e.targetTouches[0].clientX);
  };

  const onTouchMove = (e: React.TouchEvent) => {
    setTouchEnd(e.targetTouches[0].clientX);
  };

  const onTouchEnd = () => {
    if (!touchStart || !touchEnd) return;
    const distance = touchStart - touchEnd;
    const isLeftSwipe = distance > minSwipeDistance;
    const isRightSwipe = distance < -minSwipeDistance;
    
    if (isLeftSwipe) {
      goToScreen('next');
    } else if (isRightSwipe) {
      goToScreen('prev');
    }
    
    setTouchStart(null);
    setTouchEnd(null);
  };

  // Mouse handlers for desktop click-and-drag
  const onMouseDown = (e: React.MouseEvent) => {
    setIsDragging(true);
    setDragStart(e.clientX);
    setDragEnd(null);
  };

  const onMouseMove = (e: React.MouseEvent) => {
    if (!isDragging) return;
    setDragEnd(e.clientX);
  };

  const onMouseUp = () => {
    if (!isDragging || !dragStart) {
      setIsDragging(false);
      return;
    }
    
    if (dragEnd !== null) {
      const distance = dragStart - dragEnd;
      const isLeftSwipe = distance > minSwipeDistance;
      const isRightSwipe = distance < -minSwipeDistance;
      
      if (isLeftSwipe) {
        goToScreen('next');
      } else if (isRightSwipe) {
        goToScreen('prev');
      }
    }
    
    setIsDragging(false);
    setDragStart(null);
    setDragEnd(null);
  };

  const onMouseLeave = () => {
    if (isDragging) {
      onMouseUp();
    }
  };


  return (
    <div className="relative md:animate-float">
      {/* iPhone Frame */}
      <div className="relative mx-auto w-[280px] md:w-[340px]">
        {/* Glow effect behind phone - reduced on mobile */}
        <div className="absolute inset-0 blur-2xl md:blur-3xl opacity-20 md:opacity-30" style={{
          background: `linear-gradient(135deg, var(--accent-primary) 0%, var(--accent-secondary) 100%)`,
          transform: 'scale(0.9)',
        }} />
        
        {/* iPhone Outer Frame - Premium titanium look */}
        <div className="relative bg-gradient-to-b from-[#2A2A2E] via-[#1C1C1E] to-[#0A0A0B] rounded-[2.5rem] md:rounded-[3.5rem] p-[8px] md:p-[10px] shadow-2xl" style={{ 
          boxShadow: '0 30px 60px -15px rgba(0, 0, 0, 0.6), 0 0 0 1px rgba(255, 255, 255, 0.08) inset, 0 0 60px rgba(139, 92, 246, 0.1)'
        }}>
          {/* Side buttons - Volume (hidden on mobile) */}
          <div className="hidden md:block absolute -left-[3px] top-32 w-[3px] h-8 bg-gradient-to-b from-[#3A3A3E] to-[#2A2A2E] rounded-l-sm" />
          <div className="hidden md:block absolute -left-[3px] top-44 w-[3px] h-8 bg-gradient-to-b from-[#3A3A3E] to-[#2A2A2E] rounded-l-sm" />
          {/* Side button - Power (hidden on mobile) */}
          <div className="hidden md:block absolute -right-[3px] top-36 w-[3px] h-12 bg-gradient-to-b from-[#3A3A3E] to-[#2A2A2E] rounded-r-sm" />
          
          {/* Screen Bezel */}
          <div className="bg-[#0A0A0B] rounded-[2rem] md:rounded-[3rem] p-[4px] md:p-[5px] overflow-hidden">
            {/* Dynamic Island */}
            <div className="absolute top-[12px] md:top-[14px] left-1/2 transform -translate-x-1/2 w-20 md:w-28 h-[20px] md:h-[26px] bg-black rounded-full z-20" style={{
              boxShadow: '0 0 0 2px rgba(30, 30, 32, 0.8) inset'
            }} />
            
            {/* Screen - with swipe/drag support */}
            <div 
              className="relative bg-black rounded-[1.75rem] md:rounded-[2.5rem] overflow-hidden select-none"
              style={{ aspectRatio: '9/19.5', cursor: isDragging ? 'grabbing' : 'grab' }}
              onTouchStart={onTouchStart}
              onTouchMove={onTouchMove}
              onTouchEnd={onTouchEnd}
              onMouseDown={onMouseDown}
              onMouseMove={onMouseMove}
              onMouseUp={onMouseUp}
              onMouseLeave={onMouseLeave}
            >
              {!showFallback ? (
                <div className="relative w-full h-full bg-black pointer-events-none">
                  <Image
                    src={screens[currentScreen]}
                    alt={`FocusFlow screen ${currentScreen + 1}`}
                    fill
                    className="object-cover"
                    priority={currentScreen === 0}
                    quality={95}
                    onError={() => handleImageError(currentScreen)}
                    sizes="340px"
                    draggable={false}
                  />
                </div>
              ) : (
                <div className={`w-full h-full bg-gradient-to-br ${displayData[currentScreen]?.gradient || 'from-violet-500 to-purple-600'} flex items-center justify-center pointer-events-none`}>
                  <div className="text-center text-white p-8">
                    <div className="text-5xl mb-4">{displayData[currentScreen]?.icon || '⏱️'}</div>
                    <div className="text-xl font-semibold mb-1">{displayData[currentScreen]?.title || 'FocusFlow'}</div>
                    <div className="text-sm opacity-80">{displayData[currentScreen]?.desc || 'Focus Timer'}</div>
                  </div>
                </div>
              )}
              
              {/* Home indicator */}
              <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-32 h-1 bg-white/30 rounded-full" />
            </div>
          </div>
        </div>

        {/* Screen Navigation Dots */}
        {screens.length > 1 && (
          <div className="flex justify-center gap-2 md:gap-2 mt-6 md:mt-8">
            {screens.map((_, index) => (
              <button
                key={index}
                onClick={() => setCurrentScreen(index)}
                className={`h-3 md:h-2 rounded-full transition-all duration-300 ${
                  index === currentScreen 
                    ? 'w-8 bg-[var(--accent-primary)]' 
                    : 'w-3 md:w-2 bg-[var(--foreground-subtle)] hover:bg-[var(--foreground-muted)]'
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
