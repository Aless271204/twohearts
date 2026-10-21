// Shared presentation presets. These never grant ownership or equip products.
// Production placement still goes through the authenticated room-layout RPC.
export function themedRoomLoadout(items,{theme,single=false,selected}={}){
 const collection=items.filter(i=>i.theme===theme);if(!collection.length)throw Error('Colección no disponible');
 const chosen=collection.find(i=>i.item_key===selected)??collection[0];
 const set=single?[chosen]:theme==='cities'?collection.slice(0,4):collection;
 const loadout={room_wall:{style:'sage_panel',color:collection[0].appearance.color},room_floor:{style:'honey',color:'#D9B17E'}},placements=[];
 for(const [index,item] of set.entries()){
  let [x,y,z]=item.equip_slot==='room_rug'?[0,0,.05]:item.equip_slot==='room_lamp'?[-1.50,0,-1.42]:item.equip_slot==='room_chair'?[.92,0,-.65]:item.equip_slot==='room_bed'?[-1.06,0,-.75]:item.equip_slot==='room_table'?[-1.1,0,-.55]:item.equip_slot==='room_decor'?[1.02,1.95,-2.32]:[1.00,0,-1.85];
  if(theme==='cities'){x=.33+(index%2)*.85;y=2.04-Math.floor(index/2)*.56;z=-2.32;}
  if(theme==='dolls'&&item.appearance.style==='dolls_shelf'){x=-1.18;y=0;z=-1.85;}
  placements.push({id:item.item_key,item_key:item.item_key,slot:item.equip_slot,x,y,z,rotation:0,appearance:{...item.appearance}});
 }
 loadout.room_options={editing:false,layout:{items:placements,editable:false,revision:0}};return loadout;
}
