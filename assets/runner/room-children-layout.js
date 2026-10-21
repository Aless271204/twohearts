export function childrenRoomLoadout(items,theme){
 const selected=items.filter(i=>i.theme===theme);const loadout={},layout=[];
 const positions={bed:[-1.12,0,-1.25],chair:[1.16,0,-.85],desk:[-.94,0,.45],shelf:[1.48,0,-2.06],dresser:[.64,0,-2.06],lamp:[1.65,0,.60],rug:[0,0,-.10],frame:[.65,1.86,-2.32],curtain:[-.92,1.83,-2.25],chest:[-1.53,0,-.16],plant:[.35,0,-1.45],toy:[.60,0,.60]};
 for(const item of selected){if(['wall','floor','pendant'].includes(item.part)){loadout[item.equip_slot]=item.appearance;continue;}const p=positions[item.part];if(!p)continue;layout.push({id:item.item_key,item_key:item.item_key,slot:item.equip_slot,x:p[0],y:p[1],z:p[2],rotation:0,appearance:item.appearance});}
 loadout.room_options={editing:false,layout:{items:layout,editable:false,revision:0}};return loadout;
}
