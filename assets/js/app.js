/**
 * ==========================================================================
 * BEETH73 // JOURNAL ENGINE
 * Core Application Logic (The Controller)
 * ==========================================================================
 */

import { parseMarkdownWasm } from './wasm_loader.js';

// --- Element References ---
const themeToggle = document.getElementById('theme-toggle');
const html = document.documentElement;
const toggleIcon = themeToggle.querySelector('.toggle-icon');
const metaThemeColor = document.getElementById('meta-theme-color');
const contentBridge = document.getElementById('content-bridge');

// --- 1. Theme Engine & A11y ---

function initTheme() {
    // The initial theme is set by the inline script in index.html to prevent FOUC.
    // We just need to sync the UI (button state, icons) on load.
    const currentTheme = html.getAttribute('data-theme');
    updateThemeUI(currentTheme);

    themeToggle.addEventListener('click', () => {
        const activeTheme = html.getAttribute('data-theme');
        const newTheme = activeTheme === 'light' ? 'dark' : 'light';
        
        // Update DOM
        html.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
        
        // Update Meta Tag for mobile browsers
        metaThemeColor.setAttribute('content', newTheme === 'dark' ? '#1a1a1a' : '#f7f3ea');
        
        updateThemeUI(newTheme);
    });
}

// --- Font Family Switcher Engine ---

function initFontSwitcher() {
    const fonts = ['hand', 'serif', 'mono', 'sans'];
    const fontToggleBtn = document.getElementById('font-family-toggle');
    const fontLabel = document.getElementById('font-family-label');

    // Load saved font preference or default to 'hand'
    const savedFont = localStorage.getItem('font-preference') || 'hand';
    applyFont(savedFont);

    if (fontToggleBtn) {
        fontToggleBtn.addEventListener('click', () => {
            const currentFont = document.documentElement.getAttribute('data-font') || 'hand';
            const nextIndex = (fonts.indexOf(currentFont) + 1) % fonts.length;
            const nextFont = fonts[nextIndex];

            applyFont(nextFont);
            localStorage.setItem('font-preference', nextFont);
        });
    }

    function applyFont(fontName) {
        document.documentElement.setAttribute('data-font', fontName);
        if (fontLabel) {
            fontLabel.textContent = `[font: ${fontName}]`;
        }
    }
}

function updateThemeUI(theme) {
    if (theme === 'dark') {
        toggleIcon.textContent = '[sun]';
        themeToggle.setAttribute('aria-label', 'Switch to Library mode (Light)');
        themeToggle.setAttribute('aria-pressed', 'true');
    } else {
        toggleIcon.textContent = '[moon]';
        themeToggle.setAttribute('aria-label', 'Switch to Workbench mode (Dark)');
        themeToggle.setAttribute('aria-pressed', 'false');
    }
}

// --- 2. Data Fetching ---

async function fetchSitemap() {
    try {
        const response = await fetch('sitemap.json');
        if (!response.ok) throw new Error('Sitemap unreachable.');
        return await response.json();
    } catch (err) {
        console.error("Engine Error: ", err);
        return { posts: [] };
    }
}

async function fetchRawMarkdown(path) {
    const response = await fetch(path);
    if (!response.ok) throw new Error(`404: File not found at ${path}`);
    return await response.text();
}


async function renderHome() {
    try {
        document.title = "beeth73 | ~/home";

        // 1. Re-use your existing fetch helper
        const markdown = await fetchRawMarkdown('home.md');

        // 2. Await the WASM parser so it returns the actual HTML string
        const htmlOutput = await parseMarkdownWasm(markdown);

        // 3. Wrap in markdown-body so all your custom CSS applies
        const finalDOM = `
            <div class="markdown-body">
                ${htmlOutput}
            </div>
        `;

        // 4. Use your existing render engine helper
        renderHTML(finalDOM);
    } catch (err) {
        renderHTML(`<h1>Kernel Panic</h1><p>Error: ${err.message}</p>`);
    }
}

// --- 3. Routing & Rendering ---

async function router() {
    const params = new URLSearchParams(window.location.search);
    const viewList = params.get('list');
    const postSlug = params.get('post');

    const sitemap = await fetchSitemap();

    try {
        if (viewList === 'all') {
            await renderPostList(sitemap.posts);
        } else if (postSlug) {
            await renderPost(postSlug, sitemap.posts);
        } else {
            // Default home view: Load home.md instead of the first post!
            await renderHome();
        }
    } catch (error) {
        renderHTML(`<h1>Kernel Panic</h1><p>Error: ${error.message}</p>`);
    }
}

async function renderPostList(posts) {
    document.title = "beeth73 | ~/posts";
    
    let htmlBuilder = `<h1>~/posts</h1><ul style="list-style: none; padding: 0;">`;
    
    posts.forEach(post => {
        // Formats date nicely
        const date = new Date(post.date).toLocaleDateString('en-US', {
            year: 'numeric', month: 'short', day: 'numeric'
        });
        
        htmlBuilder += `
            <li style="margin-bottom: 1.5rem;">
                <a href="?post=${post.id}" style="font-family: var(--font-heading); font-size: 1.5rem; text-decoration: none; border: none;">
                    ${post.title}
                </a>
                <div style="font-family: var(--font-ui); font-size: 0.85rem; color: var(--text-muted); margin-top: 0.25rem;">
                    <time datetime="${post.date}">${date}</time>
                </div>
                <p style="font-size: 1rem; margin-top: 0.5rem;">${post.description}</p>
            </li>
        `;
    });
    
    htmlBuilder += `</ul>`;
    renderHTML(htmlBuilder);
}

async function renderPost(slug, posts) {
    const post = posts.find(p => p.id === slug);
    if (!post) throw new Error("Post not indexed in sitemap.");

    document.title = `${post.title} | beeth73`;

    // 1. Fetch the raw markdown string

    // Senior-engineer touch: Strip the first title line (e.g., # Title) from the markdown body
    // to prevent duplicate rendering, since we already render it in the header.
    // 1. Fetch and clean the raw markdown string in one chain
    const rawMarkdown = (await fetchRawMarkdown(post.path))
        .replace(/^#\s+.*$/m, '')
        .trim();
    // 2. Hand it off to the WASM Engine to process
    // (This calls the function we will write in wasm_loader.js)
    const htmlOutput = await parseMarkdownWasm(rawMarkdown);
    
    // 3. Construct the final article DOM
    const date = new Date(post.date).toLocaleDateString('en-US', {
        year: 'numeric', month: 'long', day: 'numeric'
    });

    const finalDOM = `
        <article>
            <header style="margin-bottom: 3rem; border-bottom: 1px solid var(--border-color); padding-bottom: 1.5rem;">
                <h1>${post.title}</h1>
                <div style="font-family: var(--font-ui); color: var(--text-muted); font-size: 0.9rem;">
                    [ <time datetime="${post.date}">${date}</time> ] // authored by human
                </div>
            </header>
            <div class="markdown-body">
                ${htmlOutput}
            </div>
        </article>
    `;

    renderHTML(finalDOM);
}

// --- 4. DOM Injection & A11y Focus Management ---

function renderHTML(htmlContent) {
    const renderer = document.getElementById('article-renderer');
    
    // Inject only inside the sandbox, preserving the sliders!
    renderer.innerHTML = htmlContent;
    
    // 1. Tag the first paragraph for the Drop-Cap
    const firstP = renderer.querySelector('.markdown-body p');
    if (firstP) {
        firstP.classList.add('opening');
    }
    
    // 2. Style code blocks dynamically
    polishCodeBlocks();
    
    contentBridge.focus();
    window.scrollTo({ top: 0, behavior: 'smooth' });
}


// --- Progressive Enhancement: Code Block UI Polishing ---

function polishCodeBlocks() {
    const preBlocks = contentBridge.querySelectorAll('pre');
    
    preBlocks.forEach(pre => {
        const code = pre.querySelector('code');
        if (!code) return;

        // 1. Extract language from class (e.g., "language-bash" -> "Bash")
        let langName = 'Code';
        const classList = code.className.split(' ');
        const langClass = classList.find(c => c.startsWith('language-'));
        if (langClass) {
            const rawLang = langClass.replace('language-', '');
            langName = rawLang.charAt(0).toUpperCase() + rawLang.slice(1);
        }

        // 2. Create the Card Wrapper
        const wrapper = document.createElement('div');
        wrapper.className = 'code-block-card';

        // 3. Create the Header Bar
        const header = document.createElement('div');
        header.className = 'code-block-header';
        header.innerHTML = `
            <span class="code-lang">
                <span class="code-icon" aria-hidden="true">&lt;&gt;</span>
                <span class="lang-text">${langName}</span>
            </span>
            <div class="code-actions">
                <button class="copy-btn" aria-label="Copy code block">
                    <!-- Modern SVG Copy Icon -->
                    <svg class="icon-copy" viewBox="0 0 24 24" width="14" height="14" stroke="currentColor" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                        <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                    </svg>
                    <!-- Modern SVG Checkmark (Hidden initially) -->
                    <svg class="icon-check" viewBox="0 0 24 24" width="14" height="14" stroke="var(--accent)" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round" style="display: none;">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                </button>
            </div>
        `;

        // 4. Setup Copy Event Listener
        const copyBtn = header.querySelector('.copy-btn');
        const copyIcon = copyBtn.querySelector('.icon-copy');
        const checkIcon = copyBtn.querySelector('.icon-check');

        copyBtn.addEventListener('click', async () => {
            try {
                await navigator.clipboard.writeText(code.textContent);
                
                // Show Checkmark visual feedback
                copyIcon.style.display = 'none';
                checkIcon.style.display = 'block';
                copyBtn.classList.add('copied');

                setTimeout(() => {
                    copyIcon.style.display = 'block';
                    checkIcon.style.display = 'none';
                    copyBtn.classList.remove('copied');
                }, 2000);
            } catch (err) {
                console.error('Failed to copy: ', err);
            }
        });

        // 5. Inject Wrapper into the DOM
        pre.parentNode.insertBefore(wrapper, pre);
        wrapper.appendChild(header);
        wrapper.appendChild(pre); // Moves the original <pre> inside the wrapper
    });
}


// ==========================================================================
// INTERACTIVE WORKSPACE ENGINE
// Handling Drag-to-Resize Margins & Proportional Font Scaling
// ==========================================================================

// --- 1. Font Size Scaling Controller ---

let fontScale = parseFloat(localStorage.getItem('font-scale')) || 1.0;
document.documentElement.style.setProperty('--font-scale', fontScale);

const btnIncrease = document.getElementById('font-increase');
const btnDecrease = document.getElementById('font-decrease');

btnIncrease.addEventListener('click', () => {
    if (fontScale < 1.4) { // Absolute safety cap for maximum readability
        fontScale += 0.05;
        updateFontScale(fontScale);
    }
});

btnDecrease.addEventListener('click', () => {
    if (fontScale > 0.8) { // Absolute safety floor for minimum legibility
        fontScale -= 0.05;
        updateFontScale(fontScale);
    }
});

function updateFontScale(scale) {
    document.documentElement.style.setProperty('--font-scale', scale);
    localStorage.setItem('font-scale', scale);
}

// --- 2. Symmetric Drag-to-Resize Margin Controller ---

const sliderLeft = document.getElementById('slider-left');
const sliderRight = document.getElementById('slider-right');

// Load saved custom width on startup
const savedWidth = localStorage.getItem('content-max-width');
if (savedWidth) {
    document.documentElement.style.setProperty('--content-max-width', savedWidth);
}

// We use PointerEvents so dragging works flawlessly on both Mouse and Touch screens
sliderLeft.addEventListener('pointerdown', startDrag);
sliderRight.addEventListener('pointerdown', startDrag);

function startDrag(event) {
    event.preventDefault();
    
    // Set pointer capture to handle mouse exiting the boundary handle during fast drags
    event.target.setPointerCapture(event.pointerId);
    
    const onPointerMove = (moveEvent) => {
        const viewportCenterX = window.innerWidth / 2;
        
        // Symmetric math: calculate distance from center of screen to active cursor
        const halfWidth = Math.abs(moveEvent.clientX - viewportCenterX);
        let totalWidth = halfWidth * 2;
        
        // Guardrails: Bound custom width between 400px and 92% of the viewport
        const minLimit = 400;
        const maxLimit = window.innerWidth * 0.92;
        
        if (totalWidth < minLimit) totalWidth = minLimit;
        if (totalWidth > maxLimit) totalWidth = maxLimit;
        
        document.documentElement.style.setProperty('--content-max-width', `${totalWidth}px`);
        localStorage.setItem('content-max-width', `${totalWidth}px`);
    };
    
    const onPointerUp = (upEvent) => {
        event.target.releasePointerCapture(upEvent.pointerId);
        window.removeEventListener('pointermove', onPointerMove);
        window.removeEventListener('pointerup', onPointerUp);
    };
    
    window.addEventListener('pointermove', onPointerMove);
    window.addEventListener('pointerup', onPointerUp);
}


// --- Boot Sequence ---
console.log("%c[Engine Init] Booting beeth73 terminal...", "color: #d79921; font-family: monospace;");
initTheme();
initFontSwitcher(); // <--- ADD THIS LINE
router();