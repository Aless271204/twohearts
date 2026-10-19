export function newMatch(){return {round:0,score:[0,0],attempts:[[],[]],winner:null,last:null};}
export function shooter(s){return s.round%2;}
export function resolveShot(shot,keeper){
 if(!shot||!keeper||![shot.x,shot.y,shot.power,keeper.x,keeper.y].every(Number.isFinite))throw Error('Jugada inválida');
 if([shot.x,shot.y,shot.power,keeper.x,keeper.y].some(n=>n<0||n>1))throw Error('Fuera del campo');
 const outside=shot.power>.96&&(shot.x<.08||shot.x>.92||shot.y>.92);
 const post=!outside&&shot.power>.86&&(shot.x<.035||shot.x>.965);
 const saved=!outside&&!post&&Math.hypot((shot.x-keeper.x)*1.3,shot.y-keeper.y)<.23+(1-shot.power)*.12;
 return {kind:outside?'miss':post?'post':saved?'save':'goal',shot,keeper};
}
export function advanceMatch(s,result){
 if(s.winner!==null)throw Error('Partida terminada');
 const next=structuredClone(s),side=shooter(s),goal=result.kind==='goal';
 next.attempts[side].push(goal);if(goal)next.score[side]++;next.round++;next.last={...result,side};
 // Each player always receives their five attempts. Sudden death resolves after equal attempts.
 if(next.round>=10&&next.round%2===0&&next.score[0]!==next.score[1])next.winner=next.score[0]>next.score[1]?0:1;
 return next;
}
