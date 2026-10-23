"""Generate the small public support site, independently of Flutter UI."""
from pathlib import Path
import html, re, shutil
root=Path(__file__).resolve().parents[1]
out=root/'web'/'legal';out.mkdir(parents=True,exist_ok=True)
css='body{margin:0;background:#fff8f1;color:#342d29;font:17px/1.75 system-ui}main{max-width:850px;margin:auto;padding:32px 22px}nav{display:flex;gap:22px;flex-wrap:wrap}a{color:#a43459}h1,h2{font-family:Georgia,serif;line-height:1.2}h1{font-size:clamp(32px,6vw,52px)}h2{margin-top:36px}.card{background:white;border:1px solid #efddd3;border-radius:24px;padding:24px;margin:24px 0}.button{display:inline-block;background:#a43459;color:white;padding:12px 20px;border-radius:30px;text-decoration:none}img{max-width:100%;border-radius:24px}footer{margin-top:48px;font-size:14px}'
nav='<nav aria-label="Principal"><a href="index.html">NIDO</a><a href="privacidad.html">Privacidad</a><a href="eliminar-cuenta.html">Eliminar cuenta</a><a href="comunidad.html">Comunidad</a></nav>'
def page(name,title,body):
 (out/name).write_text('<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+' · NIDO</title><style>'+css+'</style></head><body><main>'+nav+body+'<footer>NIDO · Alessandro BC · <a href="mailto:alessandroproyectos@gmail.com">alessandroproyectos@gmail.com</a></footer></main></body></html>',encoding='utf-8')
source=(root/'docs/play-console/privacidad.md').read_text(encoding='utf-8')
parts=[]
for p in source.split('\n\n'):
 p=p.strip()
 if not p:continue
 if p.startswith('## '):parts.append('<h2>'+html.escape(p[3:])+'</h2>')
 elif p.startswith('# '):parts.append('<h1>'+html.escape(p[2:])+'</h1>')
 else:parts.append('<p>'+html.escape(p)+'</p>')
page('privacidad.html','Privacidad',''.join(parts))
page('eliminar-cuenta.html','Eliminar cuenta','<h1>Eliminar tu cuenta de NIDO</h1><p>Puedes solicitar el borrado sin tener instalada la app ni iniciar sesión en esta página.</p><section class="card"><h2>Por correo</h2><p>Escribe desde el correo asociado a tu cuenta a <strong>alessandroproyectos@gmail.com</strong>, con asunto «Eliminar cuenta NIDO». Indica que deseas eliminar tu cuenta y los datos asociados. Verificaremos la titularidad; no envíes tu contraseña ni documentos de identidad.</p><a class="button" href="mailto:alessandroproyectos@gmail.com?subject=Eliminar%20cuenta%20NIDO&amp;body=Solicito%20eliminar%20mi%20cuenta%20de%20NIDO%20y%20los%20datos%20asociados.">Solicitar por correo</a><p>Si no se abre tu correo, copia la dirección y envía el mensaje desde tu servicio habitual.</p></section><h2>Desde NIDO</h2><p>Abre Perfil → Tu cuenta y tus datos → Solicitar eliminación y confirma. La solicitud queda registrada para revisión; no implica un borrado instantáneo.</p><h2>Qué se elimina y cuándo</h2><p>Atenderemos la solicitud en un máximo de 30 días, tras verificar la titularidad. Eliminaremos cuenta, perfil, ubicación, archivos propios, publicaciones, mensajes y registros asociados. Revisaremos la información compartida para retirar tus datos sin borrar contenido independiente de otras personas. Cualquier retención excepcional por seguridad u obligación legal se te comunicará con su motivo y plazo. Más detalles en la <a href="privacidad.html">política de privacidad</a>.</p><p>También puedes solicitar por correo la eliminación de una ubicación u otros datos concretos sin cerrar la cuenta.</p>')
page('comunidad.html','Normas de comunidad','<h1>Un nido para compartir con respeto</h1><p>NIDO está dirigido a mayores de 18 años. No se permite acoso, amenazas, discriminación, desnudos, contenido sexual explícito, violencia gráfica real, explotación de menores, estafas ni publicación de datos ajenos sin permiso.</p><p>Usa las opciones de denunciar y bloquear en Social. Para comunicar un problema, escribe a alessandroproyectos@gmail.com con la referencia de la publicación; evita reenviar contenido ilegal o datos privados innecesarios. El responsable revisará los reportes y podrá retirar contenido o restringir cuentas. No se garantiza vigilancia ni moderación del chat en tiempo real.</p>')
page('index.html','Nuestro espacio juntos','<h1>Un pequeño nido para compartir.</h1><img src="grafico-destacado.png" alt="Las mascotas de NIDO en una habitación acogedora"><p>Recuerdos, mascotas, habitaciones y minijuegos para disfrutar con alguien especial.</p><a class="button" href="../">Abrir NIDO</a><p>Versión de pruebas para mayores de 18 años. Las compras con dinero real no están activadas.</p>')
shutil.copy2(root/'outputs/play-console/grafico-destacado-1024x500.png',out/'grafico-destacado.png')
for p in out.glob('*.html'):
 s=p.read_text(encoding='utf-8');assert 'BORRADOR' not in s and 'NO PUBLICADO' not in s
print('Generated 4 public support pages and feature graphic; no credentials included.')
