// Shared with the reward validator: a free lane always remains available.
export function runnerRow(row, distance, version=3) {
  if(version<3)return {obstacleLane:row%3,kind:['crate','fence','rock'][row%3],coinLane:row%3,alternateLane:(row+1)%3};
  const sequence=[0,2,1,2,0,1,0,2,2,1,0,1];
  const obstacleLane=sequence[row%sequence.length];
  const coinLane=distance<180?(obstacleLane+1)%3:row%4===0?obstacleLane:(obstacleLane+2)%3;
  return {obstacleLane,kind:['crate','rock','fence','rock'][row%4],coinLane,alternateLane:(coinLane+1)%3};
}
