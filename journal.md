# Engineering Journal // beeth73

> A record of design choices, technical pivots, and the evolution of the `beeth73/blog` engine.

## 📜 The Core Philosophy
- **VanillaJS Maxxing:** No frameworks. The goal is to master the DOM and Web APIs.
- **WASM Implementation:** Only used when computationally necessary or for architectural interest. 
- **Human Content:** AI is a tool for code/infrastructure; personal expression remains 100% human-authored.

## 🎨 Design Vision (Current Phase: Research)
- **Concept:** "The Digital Kindle."
- **Goal:** Minimize eye strain. Avoid the "terminal" cliché. 
- **Details:** 
    - Soft, off-white/cream background (Paper-like).
    - High-quality Serif typography for long-form reading (e.g., *Merriweather* or *Playfair Display*).
    - Focus on white space and "breathing room" for the text.

## 🏗 Architectural Decisions
- **[2026-07-09] Content Addressing:** Chose a Markdown-to-HTML flow to separate "content" (MD) from "engine" (JS/WASM).
- **[2026-07-09] The WASM Void:** Left `/wasm` folder empty intentionally. Plans to write a `.wat` (WebAssembly Text) file manually later to understand the binary translation layer, rather than just using a black-box compiler.
- **[2026-07-09] Flat-File Database:** Using `sitemap.json` to avoid the need for a backend or heavy database queries.
- **[2026-07-22] The Midnight & Workbench Pivot:** Transitioned the design system from a stark lifestyle paper aesthetic to a dual-themed environment: "The Midnight Library" (warm sepia light mode) and "The Workbench" (glowing slate dark mode). Used blocking inline JS to prevent theme-flash (FOUC) and replaced default browser outlines with designed focus-state rings for clean web accessibility (a11y).
- **[2026-07-22] Hand-Authored WebAssembly Text (.wat) Engine:** Replaced the WASM void by hand-writing a custom state-machine parser in pure WAT compiled to WASM. Avoided heavy compilers (Rust/C) to deeply understand WebAssembly at the instruction level.
- **[2026-07-22] Shared Linear Memory Protocol:** Solved WASM's native inability to read strings by designing a strict memory protocol. JS writes UTF-8 encoded markdown to offset 0, WASM parses the bytes via register offsets, writes dynamic-length HTML tags (`<h1>`, `<blockquote>`, `<br>`) into the memory buffer directly after the input, and returns the output length.
- **[2026-07-22] Progressive Enhancement (Code Cards):** Decided to keep the WASM compiler lean by having it output standard semantic HTML `<pre><code>` blocks while passing on the code block's inner formatting (preserving raw newlines). Created a progressive-enhancement JS sweep on DOM paint to wrap these blocks in custom copyable terminal cards.

## 📝 Content Backlog (Topic Ideas)
- [ ] **WASM:** From `.wat` to `.wasm` - My journey into the binary.
- [ ] **IPFS:** The "Hydra" of the web and why the police can't stop a hash.
- [ ] **VanillaJS:** Why I deleted `node_modules` and found my soul.
- [ ] **OSINT:** The art of finding anything without a trace.
- [ ] **LLM Guardrails:** The battle between creative freedom and corporate safety.
- [ ] **Linux/Dual-boot:** A guide for those still trapped in the Windows ecosystem.
- [ ] **Tor:** Beyond the "Dark Web" - A tool for true digital sovereignty.

## ✅ To-Do List
- [ ] Finalize CSS variables for the "Kindle" theme.
- [ ] Write the `wasm_loader.js` to handle async instantiation.
- [ ] Research the most efficient `.wat` structure for string manipulation.
- [ ] Write the "Genesis" post (Post #000).

---
*Next entry: Finalizing the UI Shell.*