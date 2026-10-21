// Gameplay events, shared verbatim with the authoritative replay validator.
const EVENTS=[
 ['warmup','Primeros pasos','El sendero empieza tranquilo.'],
 ['rocks','Lluvia de rocas','Más rocas: cambia de carril o salta.'],
 ['fences','Vallas del verano','Vallas más seguidas; prepara el salto.'],
 ['slalom','Zigzag entre obstáculos','Dos carriles con obstáculos; busca el libre.'],
 ['leaves','Rocas entre las hojas','El otoño trae obstáculos más frecuentes.'],
 ['slalom','Sendero estrecho','Menos espacio: anticipa el cambio de carril.'],
 ['ice','Cumbres heladas','Rocas de invierno y menos tiempo para reaccionar.'],
 ['fences','Saltos entre la nieve','Vallas más seguidas en el sendero nevado.'],
 ['collapse','El suelo cede','Aparecen más tramos que se derrumban.'],
 ['collapse','Bajo la lluvia','El suelo cede con más frecuencia.'],
 ['trees','Tormenta total','Árboles caídos, derrumbes y mayor velocidad.'],
];
export function kilometreEvent(distance){
 const km=Math.max(0,Math.floor((Number.isFinite(distance)?distance:0)/1000));
 const [id,title,hint]=EVENTS[Math.min(km,10)];
 return {km,id,title:km>10?`Tormenta · reto ${km-9}`:title,hint,pressure:1-.08*(1-Math.exp(-km/5))};
}
