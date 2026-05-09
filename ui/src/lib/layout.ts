// Terminal width utilities for adaptive Ink layouts.
import { useStdoutDimensions } from 'ink';

export function useTerminalWidth(maxWidth = 120): number {
  const [columns] = useStdoutDimensions();
  return Math.min(columns || 80, maxWidth);
}

export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}
