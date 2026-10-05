const version = '1.0.3';
let reported = false;
export function showRunnerError(error, stage = 'carga') {
  if (reported) return;reported = true;
  clearTimeout(window.runnerBootTimer);
  const reason = String(error?.message || error || 'Error desconocido').slice(0, 600);
  document.getElementById('title').textContent = 'No pudimos abrir el bosque';
  document.getElementById('message').textContent = 'Toca «Ver detalle» y envíanos ese texto para revisar el fallo de tu teléfono.';
  const panel = document.getElementById('panel');panel.hidden = false;
  const details = document.createElement('details');
  const summary = document.createElement('summary');summary.textContent = 'Ver detalle';
  const text = document.createElement('pre');text.style.cssText = 'white-space:pre-wrap;text-align:left;font-size:11px;user-select:text;overflow-wrap:anywhere';
  text.textContent = `TwoHearts ${version}\nEtapa: ${stage}\n${reason}\n${navigator.userAgent}`;
  details.append(summary, text);document.getElementById('card').append(details);
  document.getElementById('start').hidden = true;
}
window.addEventListener('error', event => showRunnerError(event.error || event.message, 'motor 3D'));
window.addEventListener('unhandledrejection', event => showRunnerError(event.reason, 'motor 3D'));
window.runnerBootTimer = setTimeout(() => showRunnerError('La carga tardó más de 60 segundos', 'inicio'), 60000);
