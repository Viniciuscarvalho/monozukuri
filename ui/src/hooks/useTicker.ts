import { useEffect, useState } from 'react';

/**
 * 1 Hz clock. Returns the current Date, updated every second.
 * Used for elapsed time calculations in FeatureCard.
 */
export function useTicker(): Date {
  const [now, setNow] = useState(() => new Date());

  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(id);
  }, []);

  return now;
}
