# Security Policy // beeth73/blog

As an engine built on low-level WebAssembly Text (WAT) and shared linear memory, security is a core pillar of this project. We welcome and deeply appreciate security researchers conducting audits, security reviews, and responsible disclosures.

This policy outlines how to report vulnerabilities to us safely and securely.

---

## Supported Versions

We only support and patch the active branch of this repository.

| Version | Supported          |
| :---    | :---               |
| Main    | :white_check_mark: |
| < v1.0  | :x:                |

---

## Reporting a Vulnerability

**Do not open a public issue or discussion for security vulnerabilities.**

If you discover a security flaw (e.g., DOM XSS, WASM memory out-of-bounds access, or pipeline vulnerabilities), please report it privately through one of the following channels:

1. **GitHub Private Vulnerability Reporting:** Go to the **Security** tab of this repository, select **Vulnerability reporting** on the left sidebar, and click **Report a vulnerability**. This keeps the disclosure completely private between you and the maintainer.
2. **Direct Contact:** You can contact the maintainer, **beeth73**, directly through the contact channels listed on my [portfolio website](https://beeth73.github.io/10611/).

### Our SLA Commitment
We commit to the following response timeline:
* **Initial Triage:** Within 72 hours of receipt.
* **Status Updates:** Every 3 days until a patch is deployed.
* **Credit:** We will gladly credit you in our release notes and changelogs if you wish.

---

## Scope & Boundaries

### In Scope
* Memory-boundary exploits within `assets/wasm/parser.wasm` or `.wat`.
* DOM-based Cross-Site Scripting (XSS) vectors inside `assets/js/app.js` or the progressive code block card scripts.
* Directory traversal or path injection vulnerabilities within our dynamic router.

### Out of Scope
* GitHub Pages hosting infrastructure (report directly to GitHub).
* Third-party content delivery networks (CDNs) hosting Google Fonts.
* Social engineering or physical attacks against the maintainer.

---

## Safe Harbor / Policy Compliance

If you make a good faith effort to comply with this policy during your security research, we will:
* Consider your research authorized and will not pursue legal action against you.
* Work with you to understand and resolve the issue quickly.
* Publicly disclose the vulnerability alongside your credit once a patch is successfully merged.