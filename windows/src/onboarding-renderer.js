const api = window.onboardingAPI;

// ─── i18n ───────────────────────────────────────────────────────────────────
const STRINGS = {
  th: {
    welcomeTitle: 'PimPid',
    welcomeDesc: 'PimPid \u0E0A\u0E48\u0E27\u0E22\u0E41\u0E1B\u0E25\u0E07\u0E02\u0E49\u0E2D\u0E04\u0E27\u0E32\u0E21\u0E40\u0E21\u0E37\u0E48\u0E2D\u0E1E\u0E34\u0E21\u0E1E\u0E4C\u0E1C\u0E34\u0E14\u0E20\u0E32\u0E29\u0E32\n\u0E44\u0E17\u0E22 \u21C4 English \u0E2D\u0E31\u0E15\u0E42\u0E19\u0E21\u0E31\u0E15\u0E34',
    shortcutTitle: '\u0E04\u0E35\u0E22\u0E4C\u0E25\u0E31\u0E14\u0E41\u0E1B\u0E25\u0E07\u0E02\u0E49\u0E2D\u0E04\u0E27\u0E32\u0E21',
    shortcutDesc: '\u0E40\u0E25\u0E37\u0E2D\u0E01\u0E02\u0E49\u0E2D\u0E04\u0E27\u0E32\u0E21\u0E41\u0E25\u0E49\u0E27\u0E01\u0E14 Ctrl+Shift+L\n\u0E40\u0E1E\u0E37\u0E48\u0E2D\u0E41\u0E1B\u0E25\u0E07\u0E20\u0E32\u0E29\u0E32\u0E17\u0E31\u0E19\u0E17\u0E35',
    autocorrectTitle: '\u0E41\u0E01\u0E49\u0E44\u0E02\u0E2D\u0E31\u0E15\u0E42\u0E19\u0E21\u0E31\u0E15\u0E34',
    autocorrectDesc: '\u0E40\u0E1B\u0E34\u0E14 Auto-Correct \u0E40\u0E1E\u0E37\u0E48\u0E2D\u0E43\u0E2B\u0E49 PimPid\n\u0E41\u0E01\u0E49\u0E44\u0E02\u0E02\u0E49\u0E2D\u0E04\u0E27\u0E32\u0E21\u0E17\u0E35\u0E48\u0E1E\u0E34\u0E21\u0E1E\u0E4C\u0E1C\u0E34\u0E14\u0E20\u0E32\u0E29\u0E32\u0E17\u0E31\u0E19\u0E17\u0E35\u0E17\u0E35\u0E48\u0E1E\u0E34\u0E21\u0E1E\u0E4C',
    getstartedTitle: '\u0E1E\u0E23\u0E49\u0E2D\u0E21\u0E43\u0E0A\u0E49\u0E07\u0E32\u0E19!',
    getstartedDesc: 'PimPid \u0E08\u0E30\u0E17\u0E33\u0E07\u0E32\u0E19\u0E43\u0E19\u0E16\u0E32\u0E14\u0E23\u0E30\u0E1A\u0E1A (System Tray)\n\u0E40\u0E23\u0E34\u0E48\u0E21\u0E15\u0E49\u0E19\u0E43\u0E0A\u0E49\u0E07\u0E32\u0E19\u0E44\u0E14\u0E49\u0E40\u0E25\u0E22',
    next: '\u0E16\u0E31\u0E14\u0E44\u0E1B',
    prev: '\u0E01\u0E48\u0E2D\u0E19\u0E2B\u0E19\u0E49\u0E32',
    start: '\u0E40\u0E23\u0E34\u0E48\u0E21\u0E43\u0E0A\u0E49\u0E07\u0E32\u0E19',
    skip: '\u0E02\u0E49\u0E32\u0E21',
  },
  en: {
    welcomeTitle: 'PimPid',
    welcomeDesc: 'Automatically convert text when you type\nin the wrong keyboard layout. Thai \u21C4 English.',
    shortcutTitle: 'Quick Convert Shortcut',
    shortcutDesc: 'Select text and press Ctrl+Shift+L\nto instantly convert between Thai and English.',
    autocorrectTitle: 'Auto-Correct',
    autocorrectDesc: 'Enable Auto-Correct to let PimPid\nautomatically fix text typed in the wrong language.',
    getstartedTitle: 'Ready to Go!',
    getstartedDesc: 'PimPid runs in the System Tray.\nStart using it right away!',
    next: 'Next',
    prev: 'Back',
    start: 'Get Started',
    skip: 'Skip',
  },
};

let lang = 'th';
function s(key) { return STRINGS[lang][key] ?? STRINGS['en'][key] ?? key; }

/** Safely set textContent on an element by ID */
function setText(id, text) {
  const el = document.getElementById(id);
  if (el) el.textContent = text;
}

function applyLang() {
  document.documentElement.lang = lang;
  setText('s-welcome-title', s('welcomeTitle'));
  setText('s-welcome-desc', s('welcomeDesc'));
  setText('s-shortcut-title', s('shortcutTitle'));
  setText('s-shortcut-desc', s('shortcutDesc'));
  setText('s-autocorrect-title', s('autocorrectTitle'));
  setText('s-autocorrect-desc', s('autocorrectDesc'));
  setText('s-getstarted-title', s('getstartedTitle'));
  setText('s-getstarted-desc', s('getstartedDesc'));
  setText('btn-skip', s('skip'));
  updateButtons();

  // WCAG: update progress
  const progress = document.getElementById('progress-indicator');
  if (progress) progress.setAttribute('aria-valuenow', String(currentStep + 1));
}

// ─── Slide navigation ─────────────────────────────────────────────────────────
let currentStep = 0;
const totalSteps = 4;
const slides = document.querySelectorAll('.slide');
const dots = document.querySelectorAll('.step-dot');
const btnPrev = document.getElementById('btn-prev');
const btnNext = document.getElementById('btn-next');

function goToStep(step) {
  if (step < 0 || step >= totalSteps) return;

  const direction = step > currentStep ? 1 : -1;

  // Animate out current
  slides[currentStep].classList.remove('active');
  slides[currentStep].classList.add(direction > 0 ? 'exit-left' : '');
  dots[currentStep].classList.remove('active');

  // Clean up after animation
  const oldStep = currentStep;
  setTimeout(() => {
    slides[oldStep].classList.remove('exit-left');
  }, 350);

  currentStep = step;

  // Animate in new
  slides[currentStep].classList.add('active');
  dots[currentStep].classList.add('active');

  updateButtons();
}

function updateButtons() {
  btnPrev.textContent = s('prev');
  btnPrev.classList.toggle('hidden', currentStep === 0);

  if (currentStep === totalSteps - 1) {
    btnNext.textContent = s('start');
  } else {
    btnNext.textContent = s('next');
  }
}

btnNext.addEventListener('click', () => {
  if (currentStep === totalSteps - 1) {
    api.completeOnboarding();
  } else {
    goToStep(currentStep + 1);
  }
});

btnPrev.addEventListener('click', () => {
  goToStep(currentStep - 1);
});

// Skip button
document.getElementById('btn-skip').addEventListener('click', () => {
  api.completeOnboarding();
});

// Keyboard navigation
document.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowRight' || e.key === 'Enter') {
    if (currentStep === totalSteps - 1) {
      api.completeOnboarding();
    } else {
      goToStep(currentStep + 1);
    }
  } else if (e.key === 'ArrowLeft') {
    goToStep(currentStep - 1);
  } else if (e.key === 'Escape') {
    api.completeOnboarding();
  }
});

// ─── Init ───────────────────────────────────────────────────────────────────
async function init() {
  try {
    const langFromMain = await api.getLang();
    lang = langFromMain || 'th';
  } catch { /* fallback th */ }
  applyLang();
}

init();
