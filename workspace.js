const previews = {
  design: {
    name: '전체 화면 설계',
    path: 'farm-cargo-mockups.html',
    description: '16개 핵심 화면과 사용자 흐름',
    title: '팜카고 전체 화면 설계 미리보기',
  },
  demo: {
    name: '클릭 가능한 PWA 데모',
    path: 'app-demo.html',
    description: '가입부터 배차까지 직접 눌러보는 시연',
    title: '팜카고 클릭 데모 미리보기',
  },
};

const storageKey = 'farm-cargo-prompt-history';
const maxHistory = 8;
const form = document.querySelector('#prompt-form');
const input = document.querySelector('#prompt-input');
const note = document.querySelector('#composer-note');
const historyList = document.querySelector('#history-list');
const clearHistoryButton = document.querySelector('#clear-history');
const iframe = document.querySelector('#app-preview');
const openPreview = document.querySelector('#open-preview');
const previewName = document.querySelector('#preview-name');
const previewPath = document.querySelector('#preview-path');
const previewDescription = document.querySelector('#preview-description');

function readHistory() {
  try {
    return JSON.parse(localStorage.getItem(storageKey)) ?? [];
  } catch {
    return [];
  }
}

function writeHistory(history) {
  localStorage.setItem(storageKey, JSON.stringify(history.slice(0, maxHistory)));
}

function renderHistory() {
  const history = readHistory();

  if (!history.length) {
    historyList.innerHTML = '<p class="empty-history">아직 저장한 프롬프트가 없습니다.</p>';
    return;
  }

  historyList.replaceChildren();
  history.forEach((item, index) => {
    const row = document.createElement('div');
    row.className = 'history-item';
    row.tabIndex = 0;
    row.title = '클릭해서 입력창에 다시 불러오기';
    row.append(document.createTextNode(item.text));

    const removeButton = document.createElement('button');
    removeButton.type = 'button';
    removeButton.setAttribute('aria-label', '프롬프트 삭제');
    removeButton.textContent = '×';
    removeButton.addEventListener('click', (event) => {
      event.stopPropagation();
      const next = readHistory().filter((_, itemIndex) => itemIndex !== index);
      writeHistory(next);
      renderHistory();
    });

    const restore = () => {
      input.value = item.text;
      input.focus();
    };
    row.addEventListener('click', restore);
    row.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' || event.key === ' ') restore();
    });
    row.append(removeButton);
    historyList.append(row);
  });
}

async function copyPrompt(text) {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    input.select();
    return document.execCommand('copy');
  }
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  const text = input.value.trim();
  if (!text) return;

  const previous = readHistory().filter((item) => item.text !== text);
  writeHistory([{ text, createdAt: Date.now() }, ...previous]);
  renderHistory();

  const copied = await copyPrompt(text);
  note.textContent = copied
    ? '저장하고 복사했습니다. Codex 작업창에 붙여넣어 이어서 개발하세요.'
    : '브라우저에 저장했습니다. 최근 프롬프트에서 다시 불러올 수 있습니다.';
  note.classList.add('success');
  window.setTimeout(() => note.classList.remove('success'), 2600);
});

input.addEventListener('keydown', (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
    form.requestSubmit();
  }
});

clearHistoryButton.addEventListener('click', () => {
  localStorage.removeItem(storageKey);
  renderHistory();
});

document.querySelectorAll('[data-preview]').forEach((button) => {
  button.addEventListener('click', () => {
    const selected = previews[button.dataset.preview];
    document.querySelectorAll('[data-preview]').forEach((item) => item.classList.remove('active'));
    button.classList.add('active');
    iframe.src = selected.path;
    iframe.title = selected.title;
    openPreview.href = selected.path;
    previewName.textContent = selected.name;
    previewPath.textContent = selected.path;
    previewDescription.textContent = selected.description;
  });
});

document.querySelector('#refresh-preview').addEventListener('click', () => {
  iframe.src = iframe.src;
});

const workspace = document.querySelector('#workspace');
const resizer = document.querySelector('#resizer');
let dragging = false;

function resizePromptPanel(clientX) {
  const width = Math.min(Math.max(clientX, 320), Math.min(window.innerWidth * 0.58, 620));
  workspace.style.setProperty('--panel-width', `${width}px`);
}

resizer.addEventListener('pointerdown', (event) => {
  dragging = true;
  resizer.classList.add('dragging');
  resizer.setPointerCapture(event.pointerId);
});

resizer.addEventListener('pointermove', (event) => {
  if (dragging) resizePromptPanel(event.clientX);
});

resizer.addEventListener('pointerup', (event) => {
  dragging = false;
  resizer.classList.remove('dragging');
  resizer.releasePointerCapture(event.pointerId);
});

resizer.addEventListener('keydown', (event) => {
  const current = Number.parseInt(getComputedStyle(workspace).getPropertyValue('--panel-width'), 10) || 390;
  if (event.key === 'ArrowLeft') workspace.style.setProperty('--panel-width', `${Math.max(320, current - 20)}px`);
  if (event.key === 'ArrowRight') workspace.style.setProperty('--panel-width', `${Math.min(620, current + 20)}px`);
});

renderHistory();
