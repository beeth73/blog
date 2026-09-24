<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:atom="http://www.w3.org/2005/Atom">
  <xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title><xsl:value-of select="/rss/channel/title"/> (RSS Feed)</title>
        <link rel="preconnect" href="https://fonts.googleapis.com"/>
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"/>
        <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&amp;family=Google+Sans+Code&amp;display=swap" rel="stylesheet"/>
        <style>
          /* ==========================================================================
             THE MIDNIGHT LIBRARY &amp; THE WORKBENCH — RSS FEED VIEW
             Matched to the workstation design system
             ========================================================================== */

          :root {
            --bg-color: #f7f3ea;
            --text-main: #3a3a38;
            --text-muted: #6b6a63;
            --accent: #a1673f;
            --accent-hover: #7d4f30;
            --border-color: #e0d9c7;
            --code-bg: #ece7da;

            --font-heading: 'Playfair Display', Georgia, serif;
            --font-ui: 'Google Sans Code', monospace;
          }

          @media (prefers-color-scheme: dark) {
            :root {
              --bg-color: #1a1a1a;
              --text-main: #e0e0e0;
              --text-muted: #888888;
              --accent: #d79921;
              --accent-hover: #fabd2f;
              --border-color: #333333;
              --code-bg: #242424;
            }
          }

          * {
            box-sizing: border-box;
          }

          body {
            background-color: var(--bg-color);
            color: var(--text-main);
            font-family: var(--font-ui);
            font-size: 1rem;
            max-width: 720px;
            margin: 0 auto;
            padding: 3rem 1.5rem;
            line-height: 1.6;
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
            transition: background-color 0.3s ease, color 0.3s ease;
          }

          .notice {
            background: var(--code-bg);
            border: 1px solid var(--border-color);
            padding: 1rem 1.25rem;
            border-radius: 6px;
            margin-bottom: 2.5rem;
            font-size: 0.85em;
            color: var(--text-muted);
          }

          .notice a {
            color: var(--accent);
            text-decoration: none;
            border-bottom: 1px dotted var(--accent);
          }

          .notice a:hover {
            color: var(--accent-hover);
            border-bottom: 1px solid var(--accent-hover);
          }

          header.feed-header {
            text-align: center;
            border-top: 1px solid var(--border-color);
            border-bottom: 1px solid var(--border-color);
            padding: 2.5rem 0;
            margin-bottom: 3rem;
          }

          h1 {
            font-family: var(--font-heading);
            font-size: 2.5rem;
            letter-spacing: -0.02em;
            line-height: 1.2;
            margin: 0 0 0.75rem 0;
            color: var(--text-main);
          }

          .feed-description {
            font-family: var(--font-ui);
            color: var(--text-muted);
            font-size: 0.9rem;
            letter-spacing: 0.02em;
            margin: 0;
          }

          .post {
            border-bottom: 1px dashed var(--border-color);
            padding: 1.75rem 0;
          }

          .post:last-child {
            border-bottom: none;
          }

          .post-title {
            font-family: var(--font-heading);
            font-size: 1.4rem;
            font-weight: 700;
            line-height: 1.3;
          }

          .post-title a {
            color: var(--text-main);
            text-decoration: none;
            border-bottom: 1px dotted transparent;
            transition: color 0.2s ease, border-color 0.2s ease;
          }

          .post-title a:hover {
            color: var(--accent);
            border-bottom: 1px dotted var(--accent);
          }

          .post-date {
            font-family: var(--font-ui);
            font-size: 0.8rem;
            letter-spacing: 0.05em;
            text-transform: uppercase;
            color: var(--text-muted);
            margin: 0.4rem 0 0.75rem;
          }

          .post-desc {
            font-size: 0.95rem;
            color: var(--text-main);
            margin: 0;
          }

          footer.feed-footer {
            text-align: center;
            padding: 2rem 0;
            margin-top: 2rem;
            border-top: 1px solid var(--border-color);
            font-family: var(--font-ui);
            font-size: 0.8rem;
            color: var(--text-muted);
          }

          footer.feed-footer .accent {
            color: var(--accent);
            font-weight: 600;
          }

          @media (max-width: 600px) {
            body {
              padding: 2rem 1.25rem;
            }
            h1 {
              font-size: 2rem;
            }
          }
        </style>
      </head>
      <body>
        <div class="notice">
          ℹ️ <strong>RSS Feed:</strong> This is a web feed. Copy this page's URL into your favorite feed reader (e.g., Feedly, NetNewsWire) to subscribe.
        </div>

        <header class="feed-header">
          <h1><xsl:value-of select="/rss/channel/title"/></h1>
          <p class="feed-description">
            <xsl:value-of select="/rss/channel/description"/>
          </p>
        </header>

        <main>
          <xsl:for-each select="/rss/channel/item">
            <article class="post">
              <div class="post-title">
                <a target="_blank">
                  <xsl:attribute name="href">
                    <xsl:value-of select="link"/>
                  </xsl:attribute>
                  <xsl:value-of select="title"/>
                </a>
              </div>
              <div class="post-date">
                <xsl:value-of select="pubDate"/>
              </div>
              <p class="post-desc">
                <xsl:value-of select="description"/>
              </p>
            </article>
          </xsl:for-each>
        </main>

        <footer class="feed-footer">
          <span class="accent">✦</span> The Midnight Library &amp; The Workbench
        </footer>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
