from pathlib import Path
import base64, html, json, zipfile

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
P='#F05280'; BG='#FFF9FA'; S='#B8DCCB'; INK='#292633'; MUT='#716B78'
names=['Nuestro Nido','Actividades','Juegos','Nuestro Álbum','Tienda','Mi mascota','Social','Viajes']
def esc(s): return html.escape(str(s))
def bitmap(path):
    p=ROOT/path
    return 'data:image/'+('jpeg' if p.suffix=='.jpg' else 'png')+';base64,'+base64.b64encode(p.read_bytes()).decode()
pet=bitmap(Path('assets/images/pets/penguin.png'))
forest=bitmap(Path('assets/runner/forest-kingdom.jpg'))

class Screen:
    def __init__(self,i,title,sub,active):
        self.i=i; self.parts=[]; self.active=active
        self.rect(0,0,390,844,BG,0)
        self.text(24,28,'9:41',13,600); self.text(300,28,'▰  ▰  ▰',12,600)
        self.text(24,78,title,25,700); self.text(24,102,sub,12,400,MUT)
    def rect(self,x,y,w,h,fill='white',r=22,stroke=None,shadow=False):
        self.parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" '+(f'stroke="{stroke}" ' if stroke else '')+('filter="url(#shadow)" ' if shadow else '')+'/>' )
    def text(self,x,y,t,size=14,weight=400,color=INK,anchor='start'):
        self.parts.append(f'<text x="{x}" y="{y}" fill="{color}" font-size="{size}" font-weight="{weight}" text-anchor="{anchor}">{esc(t)}</text>')
    def lines(self,x,y,lines,size=14,color=INK,gap=21):
        for n,line in enumerate(lines): self.text(x,y+n*gap,line,size,400,color)
    def button(self,x,y,w,t,to=None,soft=False):
        self.parts.append(f'<g class="button" role="button" tabindex="0" aria-label="{esc(t)}" '+(f'data-to="{to}"' if to is not None else f'data-action="{esc(t)}"')+'>')
        self.rect(x,y,w,44,'#FBE6ED' if soft else P,22)
        self.text(x+w/2,y+27,t,13,600,P if soft else 'white','middle'); self.parts.append('</g>')
    def image(self,x,y,w,h,data,r=20):
        k=f'clip{len(self.parts)}'; self.parts.append(f'<defs><clipPath id="{k}"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}"/></clipPath></defs><image x="{x}" y="{y}" width="{w}" height="{h}" href="{data}" preserveAspectRatio="xMidYMid slice" clip-path="url(#{k})"/>')
    def pet(self,x,y,w=180,h=220): self.image(x,y,w,h,pet,26)
    def heading(self,y,t,link=None,to=None):
        self.text(24,y,t,17,600)
        if link: self.parts.append(f'<g class="button" role="button" tabindex="0" data-to="{to}">'); self.text(366,y,link,12,600,P,'end'); self.parts.append('</g>')
    def tabs(self,y,labels):
        w=342/len(labels); self.rect(24,y,342,42,'#F5EBEF',21)
        for n,label in enumerate(labels):
            self.parts.append(f'<g class="tab button" role="button" tabindex="0" data-tab="{esc(label)}">')
            self.rect(26+n*w,y+2,w-4,38,P if n==0 else '#F5EBEF',19)
            self.text(24+n*w+w/2,y+26,label,12,600,'white' if n==0 else MUT,'middle'); self.parts.append('</g>')
    def row(self,y,icon,title,sub,action,to=None):
        self.rect(24,y,342,88,shadow=True); self.rect(36,y+14,58,58,'#E8F3EC',16); self.text(65,y+51,icon,25,500,INK,'middle')
        self.text(106,y+30,title,14,600); self.text(106,y+50,sub,11,400,MUT)
        self.button(268,y+23,86,action,to,True)
    def nav(self):
        self.rect(0,750,390,94,'white',0); self.parts.append('<path d="M0 750H390" stroke="#F2E7EC"/>')
        for n,(label,icon,to) in enumerate([('Nido','⌂',0),('Tienda','▤',4),('Mascota','♡',5),('Actividades','◇',1),('Social','♧',6)]):
            x=39+n*78
            self.parts.append(f'<g class="button" role="button" tabindex="0" data-to="{to}" aria-label="{label}">')
            if n==self.active: self.rect(x-25,758,50,38,'#FBE6ED',19)
            self.text(x,783,icon,24,500,P if n==self.active else MUT,'middle'); self.text(x,810,label,10,600 if n==self.active else 400,P if n==self.active else MUT,'middle'); self.parts.append('</g>')
        self.rect(132,831,126,5,INK,3)
    def svg(self):
        self.nav()
        return '<svg xmlns="http://www.w3.org/2000/svg" width="390" height="844" viewBox="0 0 390 844" style="font-family:Inter,Arial,sans-serif"><defs><filter id="shadow" x="-15%" y="-15%" width="130%" height="145%"><feDropShadow dx="0" dy="3" stdDeviation="5" flood-color="#63384B" flood-opacity=".045"/></filter></defs>'+''.join(self.parts)+'</svg>'

screens=[]
s=Screen(0,'Nuestro Nido','Un lugar para seguir eligiéndose',0)
s.rect(24,125,342,140,shadow=True); s.text(44,151,'HOY, PARA USTEDES',10,600,P); s.lines(44,182,['«Qué bonito coincidir contigo,','y seguir construyendo juntos.»'],17); s.button(44,214,174,'Compartir frase'); s.text(336,191,'♡',33,400,P,'middle')
for x,val,label in [(24,'128','Días juntos'),(142,'12','Recuerdos'),(260,'3','Viajes')]:
    s.rect(x,283,106,84,'#E8F3EC' if x==142 else '#FBECEF',18); s.text(x+53,317,val,24,700,INK,'middle'); s.text(x+53,344,label,11,400,MUT,'middle')
s.heading(397,'Su próxima aventura','Explorar →',7)
s.rect(24,414,342,118,'#E6F3EE'); s.text(44,443,'CERCA, AUN A LA DISTANCIA',10,600,'#426555'); s.lines(44,471,['Su historia tiene muchos destinos.','Planeen el siguiente.'],14); s.button(230,476,116,'Ver mapa',7,True)
s.heading(565,'Recuerdos compartidos','Ver álbum →',3)
s.image(24,583,164,112,forest); s.pet(202,583,164,112)
s.text(34,719,'Nuestra escapada',12,600); s.text(212,719,'Un nuevo integrante',12,600); screens.append(s)
s=Screen(1,'Actividades','Tiempo de calidad, a su manera',3)
s.tabs(126,['Para hoy','Categorías','Guardadas'])
s.rect(24,188,342,248,'#E8F3EC'); s.text(44,222,'DEJEN QUE LA SUERTE ELIJA',10,600,'#426555')
s.parts.append('<circle cx="195" cy="298" r="57" fill="white"/><path d="M195 241V298L245 326M195 298L145 326" fill="none" stroke="#B8DCCB" stroke-width="3"/>'); s.text(195,312,'♡',36,500,P,'middle'); s.parts.append('<path d="M185 236L195 251L205 236Z" fill="#F05280"/>')
s.button(105,369,180,'Girar la ruleta'); s.heading(472,'Pequeños planes, grandes momentos')
s.row(492,'☕','Una pausa juntos','20 min · Conexión','Elegir'); s.row(592,'✦','Cita creativa','45 min · Creatividad','Elegir'); screens.append(s)
s=Screen(2,'Juegos','Una aventura que se comparte',3)
s.tabs(126,['Todos','En pareja','Relajados'])
s.image(24,186,342,232,forest); s.rect(38,200,100,26,'white',13); s.text(88,218,'DESTACADO',10,600,P,'middle')
s.rect(38,290,314,115,'#FFF9FA',18); s.text(52,316,'Corre con tu mascota',20,700); s.text(52,338,'Bosque infinito · Superen su récord',12,400,MUT); s.button(52,350,112,'Jugar'); s.text(325,377,'+ monedas',11,600,'#84611A','end')
s.heading(451,'Más formas de jugar'); s.row(470,'◉','Ping pong en pareja','Competitivo · Dos jugadores','Jugar'); s.row(570,'?','¿Quién nos conoce?','Preguntas · Descúbranse','Jugar'); s.text(24,707,'Cada aventura suma momentos juntos.',12,400,MUT); screens.append(s)
s=Screen(3,'Nuestro Álbum','Lo cotidiano también merece guardarse',0)
s.tabs(126,['Todos','Lugares','Fechas','Favoritos'])
for x,y,data,title,sub in [(24,188,forest,'Nuestro bosque','12 fotos · Naturaleza'),(202,188,pet,'En familia','4 fotos · Mascota'),(24,428,forest,'Próxima aventura','8 fotos · Viajes'),(202,428,pet,'Pequeños momentos','6 fotos · Juntos')]:
    s.rect(x,y,164,222,shadow=True); s.image(x,y,164,159,data); s.text(x+12,y+182,title,13,600); s.text(x+12,y+203,sub,10,400,MUT)
s.button(100,678,190,'+ Crear recuerdo'); screens.append(s)
s=Screen(4,'Tienda','Detalles que hacen suyo este lugar',1)
s.tabs(126,['Catálogo','Mis objetos']); s.tabs(180,['Mascota','Habitación','Colecciones']); s.rect(24,236,342,42,'white',21,'#EADBE1'); s.text(42,263,'⌕  Buscar un accesorio',13,400,MUT)
for y,icon,title,sub in [(296,'⋈','Moño coral','Un toque de ternura'),(400,'♡','Gafas corazón','Para sus mejores fotos'),(504,'✿','Planta de interior','Un rincón lleno de vida')]:
    s.row(y,icon,title,sub,'Ver'); s.text(106,y+71,'Precio por definir',10,600,'#84611A')
s.rect(24,618,342,104,'#E8F3EC'); s.text(44,647,'Su habitación, su estilo',17,600); s.text(44,670,'Muebles, fondos y pequeños detalles.',12,400,MUT); s.button(231,672,115,'Explorar',5,True); screens.append(s)
s=Screen(5,'Mi mascota','Una mascota, el cariño de ambos',2)
s.rect(24,126,342,357,'#ECECEE'); s.pet(49,135,292,334); s.text(195,458,'Su mascota',18,600,INK,'middle')
s.rect(24,498,342,62,shadow=True); s.text(40,522,'Cría · Nivel 3',13,600); s.text(350,522,'Cuidado compartido',10,400,MUT,'end'); s.rect(40,537,310,6,'#F3E6EC',3); s.rect(40,537,122,6,S,3)
s.tabs(577,['Accesorios','Habitación']);
for x,icon,label in [(24,'×','Ninguno'),(142,'⋈','Moño'),(260,'♡','Gafas')]:
    s.rect(x,635,106,72,'white',18,P if x==24 else '#F0E6EA'); s.text(x+53,666,icon,25,500,P,'middle'); s.text(x+53,691,label,11,500,MUT,'middle')
s.text(195,735,'El nombre lo eligen ustedes.',11,400,MUT,'middle'); screens.append(s)
s=Screen(6,'Social','Conexiones que inspiran',4)
s.tabs(126,['Amigos','Descubrir'])
for y,title,subtitle in [(188,'Una historia compartida','Hace 2 horas'),(462,'Pareja aventurera','Ayer')]:
    s.rect(24,y,342,255,shadow=True); s.rect(40,y+16,34,34,'#E8F3EC',17); s.text(57,y+40,'♡',19,500,P,'middle'); s.text(86,y+30,title,13,600); s.text(86,y+47,subtitle,10,400,MUT); s.image(40,y+65,310,123,forest,14); s.text(40,y+211,'Un nuevo recuerdo para nuestra historia.',12); s.text(40,y+239,'♡  12      ◯  3',14,500,P); s.text(340,y+239,'⋯',20,500,MUT,'end')
screens.append(s)
s=Screen(7,'Viajes','El siguiente capítulo empieza aquí',0)
s.tabs(126,['Próximos','Visitados']); s.rect(24,188,342,188,'#E8F3EC'); s.text(44,220,'SU MAPA DE MOMENTOS',10,600,'#426555')
s.parts.append('<path d="M75 287Q195 196 305 287" fill="none" stroke="#6C9C86" stroke-width="2" stroke-dasharray="5 5"/><circle cx="75" cy="287" r="16" fill="#F05280"/><circle cx="305" cy="287" r="16" fill="#F05280"/>'); s.text(75,293,'♡',18,500,'white','middle'); s.text(305,293,'♡',18,500,'white','middle'); s.text(195,336,'Muchas formas de encontrarse.',12,500,'#426555','middle')
s.heading(411,'Planes compartidos'); s.row(431,'⌂','Una escapada al bosque','Fecha por elegir','Abrir'); s.row(531,'☀','Un fin de semana juntos','En planificación','Abrir'); s.button(97,653,196,'+ Planificar un viaje'); screens.append(s)

OUT.mkdir(parents=True,exist_ok=True)
svgs=[]
for i,s in enumerate(screens):
    svg=s.svg(); svgs.append(svg)
    (OUT/f'screen-{i+1:02d}.svg').write_text(svg,encoding='utf-8')
css='''*{box-sizing:border-box}body{margin:0;background:#F3E8EC;color:#292633;font-family:Inter,Arial,sans-serif}header{padding:28px 32px;display:flex;justify-content:space-between;align-items:center;gap:20px}h1{font-size:24px;margin:0}header p{font-size:13px;color:#716B78;margin:8px 0}button,select{font:inherit;border:0;border-radius:14px;padding:12px 16px;background:white;color:#292633;cursor:pointer}button:focus-visible,select:focus-visible,svg g:focus-visible{outline:3px solid #587E6B;outline-offset:3px}.grid{display:grid;grid-template-columns:repeat(4,minmax(0,390px));gap:28px;padding:0 32px 32px;justify-content:center}.frame{margin:0;min-width:0}figcaption{font-size:12px;font-weight:600;margin-bottom:12px}.phone{border-radius:30px;overflow:hidden;box-shadow:0 12px 28px #5435430d;background:#FFF9FA}svg{display:block;width:100%;height:auto}svg .button{cursor:pointer;transition:opacity .15s}svg .button:hover{opacity:.85}svg .button:active{opacity:.65}body.single .grid{display:block;max-width:454px;margin:auto}body.single .frame{display:none}body.single .frame.selected{display:block}#toast{position:fixed;bottom:24px;left:50%;transform:translateX(-50%);padding:14px 22px;background:#292633;color:white;border-radius:18px;display:none;max-width:90vw;text-align:center;font-size:13px}@media(max-width:1200px){.grid{grid-template-columns:repeat(2,minmax(0,390px))}}@media(max-width:620px){header{padding:20px;flex-wrap:wrap}.grid{grid-template-columns:minmax(0,390px);padding:0 16px 24px}}@media(prefers-reduced-motion:reduce){*{transition:none!important}}'''
js='''const frames=[...document.querySelectorAll('.frame')], picker=document.querySelector('select');let active=0;function go(n){active=n;frames.forEach((f,i)=>f.classList.toggle('selected',i===n));picker.value=n;document.body.classList.add('single');window.scrollTo(0,0)}document.querySelector('#overview').onclick=()=>document.body.classList.remove('single');picker.onchange=()=>go(+picker.value);document.querySelectorAll('[data-to]').forEach(g=>g.onclick=()=>go(+g.dataset.to));let timer;document.querySelectorAll('[data-action]').forEach(g=>g.onclick=()=>{let t=document.querySelector('#toast');t.textContent=g.dataset.action==='Girar la ruleta'?'Su plan: una pausa juntos, sin pantallas.':'Vista de diseño · '+g.dataset.action;t.style.display='block';clearTimeout(timer);timer=setTimeout(()=>t.style.display='none',2600)});document.querySelectorAll('[data-tab]').forEach(g=>g.onclick=()=>{[...g.parentNode.querySelectorAll('[data-tab]')].filter(s=>s.querySelector('rect').getAttribute('y')===g.querySelector('rect').getAttribute('y')).forEach(s=>{s.querySelector('rect').setAttribute('fill',s===g?'#F05280':'#F5EBEF');s.querySelector('text').setAttribute('fill',s===g?'white':'#716B78')})});document.querySelectorAll('svg [role=button]').forEach(g=>g.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();g.click()}});'''
page='<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>TwoHearts · Diseño de producto</title><style>'+css+'</style><header><div><h1>TwoHearts</h1><p>Ocho pantallas · Prototipo visual · Datos de ejemplo</p></div><div><button id="overview">Todas las pantallas</button> <select aria-label="Elegir pantalla">'+''.join(f'<option value="{i}">{esc(n)}</option>' for i,n in enumerate(names))+'</select></div></header><main class="grid">'+''.join(f'<figure class="frame {"selected" if i==0 else ""}"><figcaption>{i+1:02d} / {esc(names[i])}</figcaption><div class="phone">{svg}</div></figure>' for i,svg in enumerate(svgs))+'</main><div id="toast" role="status"></div><script>'+js+'</script></html>'
(OUT/'index.html').write_text(page,encoding='utf-8')
(OUT/'tokens.json').write_text(json.dumps({'brand':'TwoHearts','colors':{'background':BG,'primary':P,'secondary':S,'text':INK,'muted':MUT,'surface':'#FFFFFF'},'spacing':[4,8,12,16,24,32],'radius':{'card':22,'control':22,'thumbnail':16},'typography':{'family':'Inter / platform sans-serif','title':25,'section':17,'body':14,'secondary':12},'safeAreas':{'top':44,'bottom':34},'touchTarget':44},ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'README.md').write_text('''# TwoHearts · Especificación de diseño

Ocho pantallas independientes de 390 × 844. index.html es un prototipo visual navegable local; screen-01.svg a screen-08.svg conservan textos, tarjetas, botones y formas vectoriales editables. Las imágenes son los únicos elementos rasterizados. No es un archivo Figma nativo y no incluye Auto Layout o componentes nativos de Figma. Los SVG se pueden importar en Figma; allí hay que crear los componentes y restricciones. El prototipo usa la mascota aprobada del proyecto, sin nombre asignado.

## Sistema reutilizable
Header, PrimaryButton, SoftButton, SegmentedControl, ContentCard, FeatureCard, ListRow, PetStage, BottomNavigation. Tokens en tokens.json. Navegación constante: Nido, Tienda, Mascota, Actividades, Social. Álbum y Viajes dependen de Nido; Juegos depende de Actividades. La navegación debe ocultarse en la partida y en los editores inmersivos, como ya se implementó en la app. No hay botones flotantes de música.

## Interacciones y estados
La navegación y el selector cambian de pantalla. Los segmentos cambian estado activo. La ruleta entrega una propuesta de ejemplo. Los demás botones indican su acción de diseño, no ejecutan compras, publicaciones o viajes. Hover, pressed y focus están presentes; en producción añadir loading con spinner y etiqueta, disabled con explicación y error cerca del campo. No mostrar éxito antes de confirmar la operación. Los datos de pareja, fechas, conteos, contenido social y planes son ejemplos; los precios siguen por definir.

## Adaptación a desarrollo
Usar Column/Row/Flex y listas desplazables en Flutter, no coordenadas absolutas del SVG. SafeArea superior e inferior; objetivos táctiles de 44 pt iOS / 48 dp Android. En 320 px reducir la cantidad de columnas, nunca comprimir textos. Las tarjetas pueden crecer con accesibilidad y escalado de texto. Inter como opción; SF Pro / Roboto como alternativa nativa. El coral de marca se conserva para superficies y decoración; validar contraste WCAG AA para cada texto y usar un coral oscuro en etiquetas pequeñas sobre blanco cuando sea necesario. Fotografías del álbum deben sustituirse por las del usuario, no por escenarios de muestra. El mapa mostrado es una composición de diseño, no un mapa conectado a ubicación real.

## Alcance
Este paquete diseña la interfaz. No modifica todavía el APK, no añade modos de juego nuevos y no afirma que las acciones de ejemplo estén conectadas a Supabase. Requiere traslado y revisión visual en las pantallas reales de Flutter antes de publicar otra versión.
''',encoding='utf-8')
with zipfile.ZipFile(OUT/'TwoHearts-design.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in [OUT/'index.html',OUT/'tokens.json',OUT/'README.md',*[OUT/f'screen-{i+1:02d}.svg' for i in range(8)]]: z.write(p,p.name)
print('Created 8 editable screens, interactive prototype and design package.')
