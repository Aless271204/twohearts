// One deterministic curve shared by rendering and reward validation.
export function runnerDifficulty(distance, version = 3) {
  if (version === 1) return {speed: Math.min(14, 8 + distance / 180), spacing: 28, level: 1};
  const progress = Math.max(0, Math.min(1, distance / (version>=3?600:900)));
  return {speed: 8 + 6 * progress, spacing: 28 - 10 * progress,
    level: Math.min(5, 1 + Math.floor(Math.max(0, distance) / (version>=3?150:225)))};
}
