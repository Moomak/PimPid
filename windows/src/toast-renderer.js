const toastAPI = window.toastAPI;

toastAPI.onToastData((data) => {
  // Apply theme
  const html = document.documentElement;
  html.classList.remove('theme-light', 'theme-dark');
  if (data.theme === 'light') html.classList.add('theme-light');
  else if (data.theme === 'dark') html.classList.add('theme-dark');

  const dirEl = document.getElementById('toast-direction');
  const origEl = document.getElementById('toast-original');
  const convEl = document.getElementById('toast-converted');
  if (dirEl) dirEl.textContent = data.directionLabel || '';
  if (origEl) origEl.textContent = data.original || '';
  if (convEl) convEl.textContent = data.converted || '';

  // Start fade out after 3 seconds
  setTimeout(() => {
    const toast = document.getElementById('toast');
    if (toast) toast.classList.add('fade-out');
  }, 3000);
});
