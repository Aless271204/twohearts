const version = '1.1.0';
let reported = false;
export function showRunnerError(error, stage = 'carga') {
  if (reported) return;reported = true;
  clearTimeout(window.runnerBootTimer);
  const reason = String(error?.message || error || 'Error desconocido').slice(0, 600);
  if (new URLSearchParams(location.search).get('pet') === '1') {
    const loader = document.getElementById('pet-loader');
    loader.style.cssText = 'display:flex;position:fixed;inset:0;align-items:center;justify-content:center;flex-direction:column;gap:12px;color:#746874;font:13px system-ui;text-align:center;padding:20px';
    loader.textContent = 'No pudimos cargar tu mascota.';
    const retry = document.createElement('button');retry.textContent = 'Reintentar';
    retry.style.cssText = 'background:#fff5f7;color:#e54378;border:1px solid #ffd0df;border-radius:99px;padding:10px 18px;font-size:13px';
    retry.addEventListener('click', () => location.reload());loader.append(retry);
    console.error('Pet renderer failed', stage, reason);return;
  }
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
