import {LANES,jumpStep,crossesPlayer,hitsObstacle,collectsCoin} from './physics.js';

import {runnerDifficulty} from './difficulty.js';

// Independent reconstruction of a run. Only inputs and time steps are accepted;
// distance, coins and the terminal collision are calculated by the server.
export function replayRun(frames, version = 1) {
  if(![1,2].includes(version))throw Error('Invalid replay version');
  if(!Array.isArray(frames)||frames.length<1||frames.length>76000)throw Error('Invalid replay length');
  let lane=1,x=0,height=0,velocity=0,distance=0,coins=0,row=0,untilRow=0,elapsed=0,ended=false;
  const objects=[];
  for(const frame of frames){
    if(ended)throw Error('Inputs after game over');
    if(!Array.isArray(frame)||frame.length!==2||!Number.isInteger(frame[0])||frame[0]<1||frame[0]>40000||!Array.isArray(frame[1])||frame[1].length>8)throw Error('Invalid replay frame');
    for(const input of frame[1]){
      if(![-1,0,1].includes(input))throw Error('Invalid input');
      if(input===0){if(height===0)velocity=8;}else lane=Math.max(0,Math.min(2,lane+input));
    }
    const dt=frame[0]/1000000;elapsed+=dt;if(elapsed>1200)throw Error('Run is too long');
    const travel=runnerDifficulty(distance,version).speed*dt;distance+=travel;
    [height,velocity]=jumpStep(height,velocity,dt);x+=(LANES[lane]-x)*(1-Math.exp(-dt*10));
    untilRow-=travel;
    if(untilRow<=0){
      const obstacleLane=row%3;objects.push({kind:'obstacle',x:LANES[obstacleLane],z:-68});
      for(let i=0;i<5;i++)objects.push({kind:'coin',x:LANES[obstacleLane],z:-60-i*4,y:i===2?1.8:.7});
      objects.push({kind:'coin',x:LANES[(obstacleLane+1)%3],z:-68,y:.7});row++;untilRow+=runnerDifficulty(distance,version).spacing;
    }
    for(let i=objects.length-1;i>=0;i--){
      const item=objects[i],previous=item.z;item.z+=travel;
      if(crossesPlayer(previous,item.z)){
        if(item.kind==='obstacle'&&hitsObstacle(x,item.x,height)){ended=true;break;}
        if(item.kind==='coin'&&collectsCoin(x,item.x,height,item.y)){coins++;objects.splice(i,1);continue;}
      }
      if(item.z>6)objects.splice(i,1);
    }
    if(elapsed>=1199.96)ended=true;
  }
  if(!ended)throw Error('Run has no terminal collision');
  return {distance:Math.floor(distance),coins,elapsed};
}
