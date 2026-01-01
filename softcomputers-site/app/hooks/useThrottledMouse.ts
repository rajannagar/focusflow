import { useEffect, useState } from 'react';

/**
 * Throttled mouse position hook for performance
 * Updates mouse position at most once every 50ms (20fps)
 */
export function useThrottledMouse() {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    let lastUpdate = 0;
    const throttleDelay = 50; // 20fps max update rate
    
    const handleMouseMove = (e: MouseEvent) => {
      const now = Date.now();
      if (now - lastUpdate >= throttleDelay) {
        setMousePosition({ x: e.clientX, y: e.clientY });
        lastUpdate = now;
      }
    };
    
    window.addEventListener('mousemove', handleMouseMove, { passive: true });
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
    };
  }, []);

  return mousePosition;
}

