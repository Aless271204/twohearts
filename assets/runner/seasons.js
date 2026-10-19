export const SEASONS=[
 {id:'spring',label:'Primavera',sky:'#66bff1',horizon:'#dcebd6',fog:'#d0e7dc',leaves:['#f6b1d2','#fbd5e4','#85b964','#ec9fc7'],grass:'#7eac58',flowers:['#f5bad0','#fff0b0','#ef97bb'],snow:0},
 {id:'summer',label:'Verano',sky:'#4bb9ef',horizon:'#fff0bf',fog:'#d9e4bd',leaves:['#3c8b4e','#67a64d','#82b858','#32754d'],grass:'#8caf45',flowers:['#ffd45c','#fff2b6','#ffc847'],snow:0},
 {id:'autumn',label:'Otoño',sky:'#92b8dc',horizon:'#ffe1ab',fog:'#e7cead',leaves:['#cf7041','#eda74c','#bf5650','#d39d46'],grass:'#a68d4a',flowers:['#f1b967','#e9a377','#d78857'],snow:0},
 {id:'winter',label:'Invierno',sky:'#88bde5',horizon:'#f0eafa',fog:'#dce9ef',leaves:['#dcecf0','#b5d1d6','#eaf1ed','#9fbbc6'],grass:'#d8e6de',flowers:['#f4e9ef','#d2deef','#fff3da'],snow:1},
 {id:'storm',label:'Tormenta',sky:'#233b56',horizon:'#718998',fog:'#738b95',leaves:['#447163','#506e63','#6c8068','#3e6058'],grass:'#617957',flowers:['#d7b575','#b694b5','#e5c595'],snow:0}
];
export function seasonAt(distance){const d=Math.max(0,Number(distance)||0),i=Math.min(4,Math.floor(d/2000));return {...SEASONS[i],index:i,previous:SEASONS[Math.max(0,i-1)],blend:i?Math.min(1,(d-i*2000)/(i===4?2000:180)):1,storm:Math.max(0,Math.min(1,(d-8000)/2000)),lightning:d>=10000,fallingGround:d>=8000,fallingTrees:d>=10000};}
