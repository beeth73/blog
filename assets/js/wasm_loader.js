/**
 * ==========================================================================
 * BEETH73 // WASM BRIDGE
 * Linear Memory Management & Text Parsing
 * ==========================================================================
 * 
 * MEMORY PROTOCOL FOR YOUR FUTURE .wat FILE:
 * 1. JS allocates 1 page (64KB) of memory.
 * 2. JS writes the UTF-8 encoded Markdown string starting at Offset 0.
 * 3. JS calls `wasmInstance.exports.parse(input_ptr, input_length)`.
 * 4. Your .wat code must read from `input_ptr`, process the tokens, and 
 *    write the resulting HTML bytes starting directly after the input (Offset = input_length).
 * 5. Your .wat code must return an i32 representing the length of the generated HTML.
 * 6. JS reads the bytes from (input_length) to (input_length + output_length) and decodes to HTML.
 */

const WASM_PATH = 'assets/wasm/parser.wasm';

// Allocate 1 page of memory (64KB) - Expandable up to 10 pages (640KB)
const wasmMemory = new WebAssembly.Memory({ initial: 1, maximum: 10 });
let wasmInstance = null;
let isWasmReady = false;

/**
 * Initializes the WASM engine. 
 * If the binary is missing or fails to compile, it degrades gracefully.
 */
async function initWasm() {
    if (isWasmReady) return;

    try {
        const response = await fetch(WASM_PATH);
        if (!response.ok) throw new Error(`Binary not found at ${WASM_PATH}`);
        
        const bytes = await response.arrayBuffer();

        // The Import Object: Giving your WASM code access to memory and a debug logger
        const importObject = {
            env: {
                memory: wasmMemory,
                // A lifeline for when you write your .wat file: call sys_log(i32) to debug
                sys_log: (num) => console.log(`[WASM log]: ${num}`) 
            }
        };

        const { instance } = await WebAssembly.instantiate(bytes, importObject);
        wasmInstance = instance;
        isWasmReady = true;
        
        console.log("%c[WASM] Engine loaded and memory allocated.", "color: #a1673f; font-weight: bold;");
    } catch (error) {
        console.warn(`%c[WASM Fallback] ${error.message}. Using JS parsing layer.`, "color: #6b6a63;");
        isWasmReady = false;
    }
}

/**
 * Main export: Takes raw markdown, bridges it to WASM if available, 
 * or uses the fallback parser.
 */
export async function parseMarkdownWasm(markdown) {
    await initWasm();

    if (isWasmReady && wasmInstance.exports.parse) {
        // 1. Run the structural WASM engine
        const wasmHtml = executeWasmParser(markdown);
        
        // 2. Pass the output through the progressive inline polisher
        return postProcessInlineMarkdown(wasmHtml);
    } else {
        return executeJsFallbackParser(markdown);
    }
}

/**
 * The strict memory hand-off to your WebAssembly module.
 */
function executeWasmParser(markdown) {
    const encoder = new TextEncoder();
    const decoder = new TextDecoder();
    
    // 1. Encode markdown to bytes
    const inputBytes = encoder.encode(markdown);
    const inputLength = inputBytes.length;
    
    // 2. Write to WASM Memory at offset 0
    const memoryView = new Uint8Array(wasmMemory.buffer);
    memoryView.set(inputBytes, 0);
    
    // 3. Call your exported .wat function: (ptr: 0, length: inputLength)
    // It should return the length of the generated HTML.
    const outputLength = wasmInstance.exports.parse(0, inputLength);
    
    // 4. We assume your .wat code wrote the output right after the input bytes.
    const outputOffset = inputLength;
    
    // 5. Read the output memory and decode back to a JS String
    const outputBytes = new Uint8Array(wasmMemory.buffer, outputOffset, outputLength);
    return decoder.decode(outputBytes);
}

/**
 * ==========================================================================
 * GRACEFUL DEGRADATION: NATIVE JS PARSER
 * Provides immediate utility while you build the .wat engine.
 * Supports: Headers, Code Blocks, Inline Code, Blockquotes, Links, and Paragraphs.
 * ==========================================================================
 */
function executeJsFallbackParser(markdown) {
    let html = markdown;

    // 1. Code Blocks (```lang\ncode```)
    // Captures the optional language identifier and the code content
    html = html.replace(/```(\w*)\n([\s\S]*?)```/g, (match, lang, code) => {
        const escapedCode = code.replace(/</g, '&lt;').replace(/>/g, '&gt;').trim();
        const langClass = lang ? ` class="language-${lang.toLowerCase()}"` : '';
        return `<pre><code${langClass}>${escapedCode}</code></pre>`;
    });

    // 2. Inline Code (`code`)
    html = html.replace(/`([^`]+)`/g, '<code>$1</code>');

    // 3. Headers (## Header)
    html = html.replace(/^### (.*$)/gim, '<h3>$1</h3>');
    html = html.replace(/^## (.*$)/gim, '<h2>$1</h2>');
    html = html.replace(/^# (.*$)/gim, '<h1>$1</h1>');

    // 4. Blockquotes (> Quote)
    html = html.replace(/^\> (.*$)/gim, '<blockquote>$1</blockquote>');

    // Add this RIGHT BEFORE step 5 (Links):
    // 4.5. Images (![Alt](URL))
    html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1" style="max-width: 100%; height: auto; margin: 1.5rem 0; border-radius: 4px;">');

    // 5. Links ([Title](URL))
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');

    // 6. Paragraphs (Wrap text not already inside HTML tags)
    // Split by double newline to identify text blocks
    html = html.split(/\n\n+/).map(block => {
        block = block.trim();
        if (block.startsWith('<') && block.endsWith('>')) {
            return block; // Already a block-level HTML element
        } else {
            return `<p>${block}</p>`;
        }
    }).join('\n');

    return html;
}

/**
 * Progressive Enhancement: Leverages the browser's native C++ regex compiler
 * to quickly parse inline style markers on the returned WASM string.
 */
function postProcessInlineMarkdown(html) {
    let processed = html;

    // 1. Triple bold-italic: ***text*** -> <strong><em>text</em></strong>
    processed = processed.replace(/\*\*\*([^*]+)\*\*\*/g, '<strong><em>$1</em></strong>');

    // 2. Bold: **text** -> <strong>text</strong>
    processed = processed.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');

    // 3. Inline Code: `text` -> <code>text</code>
    processed = processed.replace(/`([^`]+)`/g, '<code>$1</code>');

    // Add right before step 4 (Links):
    processed = processed.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1" style="max-width: 100%; height: auto; margin: 1.5rem 0; border-radius: 4px;">');
    
    // 4. Links: [text](url) -> <a href="url">text</a>
    processed = processed.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');

    return processed;
}