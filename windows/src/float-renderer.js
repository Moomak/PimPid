const floatAPI = window.floatAPI;

// ─── Click to convert ───────────────────────────────────────────────────────
let isDragging = false;
let dragStartX = 0;
let dragStartY = 0;
let hasMoved = false;

const btn = document.getElementById('float-btn');
const closeBtn = document.getElementById('close-btn');
if (!btn || !closeBtn) {
  console.error('[PimPid] Float button elements not found in DOM');
}

btn?.addEventListener('mousedown', (e) => {
  if (e.button !== 0) return;
  isDragging = true;
  hasMoved = false;
  dragStartX = e.screenX;
  dragStartY = e.screenY;
  if (btn) btn.style.cursor = 'grabbing';
});

document.addEventListener('mousemove', (e) => {
  if (!isDragging) return;
  const dx = e.screenX - dragStartX;
  const dy = e.screenY - dragStartY;

  // Only start drag if moved more than 4px (avoid accidental drag on click)
  if (Math.abs(dx) > 4 || Math.abs(dy) > 4) {
    hasMoved = true;
    floatAPI.dragMove(dx, dy);
    dragStartX = e.screenX;
    dragStartY = e.screenY;
  }
});

document.addEventListener('mouseup', () => {
  if (!isDragging) return;
  isDragging = false;
  if (btn) btn.style.cursor = 'grab';

  if (!hasMoved) {
    // It was a click, not a drag
    floatAPI.convert();
  }
});

// ─── Close button ───────────────────────────────────────────────────────────
closeBtn?.addEventListener('click', (e) => {
  e.stopPropagation();
  floatAPI.close();
});
