# Contributing to beeth73/blog

First off, thank you for taking the time to contribute! This project is an architectural experiment in building a high-performance, accessible, and durable technical journal without modern framework bloat [1].

To preserve the integrity of the engine, all contributions must strictly adhere to our core engineering philosophies.

---

## 📜 Our Core Philosophies

Before submitting any Pull Request, ensure your code aligns with these three pillars:

1. **VanillaJS Maxxing:** We do not use frontend frameworks (React, Svelte, Vue), bundlers, or CSS preprocessors (Sass/SCSS) [1]. All interface features must rely strictly on standard Web APIs, semantic HTML, and native CSS.
2. **WASM/WAT Execution:** The markdown parsing logic lives in hand-authored WebAssembly Text (`.wat`) [1]. Do not bring in black-box compiled binaries or standard C/Rust compilation pipelines. If you are modifying the parser, write pure, clean, and highly documented `.wat` [1].
3. **Rigorous Accessibility (a11y):** Accessibility is not a checklist item; it is a core feature. All contributions must preserve responsive layouts, strict WCAG AA/AAA contrast ratios, logical focus-state management, and keyboard-navigation safety. Always test changes using a real screen reader (e.g., VoiceOver on macOS).

---

## 🛠 Local Development Setup

To test your changes locally:

1. **Install WABT (WebAssembly Binary Toolkit):**
   ```bash
   # On macOS
   brew install wabt
   ```
2. **Compile the WASM Binary:**
   If you make any changes to `assets/wasm/parser.wat`, compile it to binary before committing:
   ```bash
   wat2wasm assets/wasm/parser.wat -o assets/wasm/parser.wasm
   ```
3. **Run a Local Server:**
   Use a local development server (like VS Code Live Server or python's built-in server) to load the page and bypass browser CORS policies:
   ```bash
   python3 -m http.server 5500
   ```

---

## 📝 Git Commit Style Guide

We enforce the **Conventional Commits** specification. This keeps our git history clean, readable, and ready for automated changelogs.

Your commit messages should follow this format:
```text
<type>(<scope>): <short description>

[optional longer body detailing architectural decisions]
```

### Approved Types:
* `feat`: A new user-facing feature (e.g., `feat(a11y): add screen reader skip link`)
* `fix`: A bug fix (e.g., `fix(parser): resolve infinite loop on EOF`)
* `docs`: Documentation changes only (`CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, etc.)
* `style`: Styling changes that do not affect code logic (formatting, cleanups)
* `refactor`: A code change that neither fixes a bug nor adds a feature

---

## 🚀 How to Submit a Pull Request

1. **Fork** the repository and create your branch from `main`.
2. Ensure your code is thoroughly documented.
3. Test your changes locally (both visually and using a screen reader).
4. Commit your changes using Conventional Commit messages.
5. Submit a **Pull Request** detailing your architectural decisions.

We look forward to collaborating!
```