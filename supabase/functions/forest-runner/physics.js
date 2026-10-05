export const LANES = [-1.6, 0, 1.6];
export function jumpStep(height, velocity, dt) {
  const nextVelocity = velocity - 20 * dt;
  const nextHeight = height + nextVelocity * dt;
  return nextHeight <= 0 ? [0, 0] : [nextHeight, nextVelocity];
}
export function crossesPlayer(previousZ, z) { return previousZ < 0 && z >= 0; }
export function hitsObstacle(playerX, obstacleX, height) {
  return Math.abs(playerX - obstacleX) < 0.72 && height < 0.95;
}
export function collectsCoin(playerX, coinX, height, coinY) {
  return Math.abs(playerX - coinX) < 0.75 && Math.abs(height + 0.7 - coinY) < 0.65;
}
