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
        <style>
          :root {
            --bg: #0d1117;
            --card-bg: #161b22;
            --border: #30363d;
            --text: #c9d1d9;
            --accent: #58a6ff;
            --subtext: #8b949e;
          }
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, monospace, sans-serif;
            background: var(--bg);
            color: var(--text);
            max-width: 720px;
            margin: 40px auto;
            padding: 0 20px;
            line-height: 1.6;
          }
          .notice {
            background: var(--card-bg);
            border: 1px solid var(--border);
            padding: 16px;
            border-radius: 6px;
            margin-bottom: 32px;
            font-size: 0.9em;
            color: var(--subtext);
          }
          .notice a { color: var(--accent); }
          h1 { margin-bottom: 4px; color: #fff; }
          .post {
            border-bottom: 1px solid var(--border);
            padding: 18px 0;
          }
          .post:last-child { border-bottom: none; }
          .post-title {
            font-size: 1.25em;
            font-weight: 600;
          }
          .post-title a {
            color: var(--accent);
            text-decoration: none;
          }
          .post-title a:hover { text-decoration: underline; }
          .post-date {
            font-size: 0.85em;
            color: var(--subtext);
            margin: 4px 0 8px;
          }
          .post-desc { margin: 0; }
        </style>
      </head>
      <body>
        <div class="notice">
          ℹ️ <strong>RSS Feed:</strong> This is a web feed. Copy this page's URL into your favorite feed reader (e.g., Feedly, NetNewsWire) to subscribe.
        </div>

        <h1><xsl:value-of select="/rss/channel/title"/></h1>
        <p style="color: var(--subtext); margin-top: 0;">
          <xsl:value-of select="/rss/channel/description"/>
        </p>

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
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>