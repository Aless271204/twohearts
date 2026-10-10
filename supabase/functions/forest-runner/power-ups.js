// Deterministic gameplay rules shared verbatim with the server.
export const POWER_UPS = Object.freeze({
  magnet: {label: 'Imán', icon: '🧲', seconds: 12, color: '#f05280'},
  shield: {label: 'Escudo', icon: '🛡', seconds: 20, color: '#6ddcca'},
  doubleCoins: {label: 'Monedas ×2', icon: '×2', seconds: 12, color: '#ffd36a'},
  boost: {label: 'Velocidad ×2', icon: '⚡', seconds: 5, color: '#82c7ff'},
  tripleJump: {label: 'Triple salto', icon: '↑³', seconds: 15, color: '#c6a0f4'},
});
export function freshPowers() { return {magnet: 0, shield: 0, doubleCoins: 0, boost: 0, tripleJump: 0, jumps: 0}; }
export function tickPowers(powers, dt) { for (const key of Object.keys(POWER_UPS)) powers[key] = Math.max(0, powers[key] - dt); }
export function activatePower(powers, key) { if (!POWER_UPS[key]) throw Error('Unknown power-up'); powers[key] = POWER_UPS[key].seconds; }
// First pickup after the introductory stretch, then every twelve rows.
// Rotate types; put pickups in a safe lane ahead of the obstacle.
export function powerForRow(row, distance, obstacleLane) {
  if (distance < 180 || row % 12 !== 8) return null;
  const key = Object.keys(POWER_UPS)[Math.floor(row / 12) % 5];
  return {kind: 'power', power: key, lane: (obstacleLane + 1) % 3, z: -56, y: .7};
}
export function canJump(powers, height) { return height === 0 || powers.tripleJump > 0 && powers.jumps < 3; }
export function registerJump(powers, height) { powers.jumps = height === 0 ? 1 : powers.jumps + 1; }
export function coinMultiplier(powers) { return powers.doubleCoins > 0 ? 2 : 1; }
export function speedMultiplier(powers) { return powers.boost > 0 ? 2 : 1; }
export function protectsCollision(powers) {
  if (powers.boost > 0) return true;
  if (powers.shield > 0) { powers.shield = 0; return true; }
  return false;
}
export function magnetCollects(powers, previousZ, z) { return powers.magnet > 0 && previousZ < -3 && z >= -3; }
