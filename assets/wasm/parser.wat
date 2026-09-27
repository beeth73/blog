;; ==========================================================================
;; BEETH73 // WASM ENGINE
;; Production-Grade State-Machine Markdown Compiler (v4)
;;
;; New in v4:
;;   - Multi-level headers: # through ###### (h1-h6). v3 only supported h1;
;;     the JS post-processing layer (postProcessInlineMarkdown) doesn't
;;     touch headers at all, so this was a genuine gap only WASM could fill.
;;   - Leading whitespace before line-start tokens (headers, quotes, hr,
;;     bullets, code fences) is now tolerated: indentation no longer
;;     blocks detection.
;;
;; NOTE: Images, links, and single-asterisk italics are intentionally NOT
;; handled here. Per wasm_loader.js, those are handled downstream by
;; postProcessInlineMarkdown() using native JS regex, after this parser's
;; output. Duplicating that logic here would create two independent
;; implementations of the same rules that could drift out of sync.
;; ==========================================================================

(module
  (import "env" "memory" (memory 1))
  (import "env" "sys_log" (func $sys_log (param i32)))

  (func $parse (export "parse") (param $in_ptr i32) (param $in_len i32) (result i32)

    ;; Register allocation
    (local $in_curr i32)          ;; Read cursor
    (local $out_curr i32)         ;; Write cursor
    (local $byte i32)             ;; Current active byte
    (local $is_at_line_start i32) ;; State: 1 = Start of line (leading whitespace allowed)
    (local $heading_level i32)    ;; State: 0 = not in heading, else 1-6
    (local $in_quote i32)         ;; State: 1 = Inside Blockquote
    (local $in_code i32)          ;; State: 1 = Inside Pre/Code Block
    (local $in_bold i32)          ;; State: 1 = Inside Bold (**)
    (local $in_italic i32)        ;; State: 1 = Inside Italic (*)
    (local $in_inline_code i32)   ;; State: 1 = Inside Inline Code (`)
    (local $in_bold_italic i32)   ;; State: 1 = Inside Bold-Italic (***)

    ;; Scratch locals for multi-char lookahead (headers, links)
    (local $hcount i32)
    (local $scan i32)
    (local $scan2 i32)
    (local $text_start i32)
    (local $text_end i32)
    (local $url_start i32)
    (local $url_end i32)
    (local $link_ok i32)

    ;; Initialize pointers
    local.get $in_ptr
    local.set $in_curr

    local.get $in_len
    local.set $out_curr

    ;; Set initial states
    i32.const 1   local.set $is_at_line_start
    i32.const 0   local.set $heading_level
    i32.const 0   local.set $in_quote
    i32.const 0   local.set $in_code
    i32.const 0   local.set $in_bold
    i32.const 0   local.set $in_italic
    i32.const 0   local.set $in_inline_code
    i32.const 0   local.set $in_bold_italic

    ;; =========================================================
    ;; THE STATE MACHINE LOOP
    ;; =========================================================
    (block $exit_loop
      (loop $process_chars

        ;; EOF check
        local.get $in_curr
        local.get $in_len
        i32.ge_u
        br_if $exit_loop

        ;; Load the current byte
        local.get $in_curr
        i32.load8_u
        local.set $byte

        ;; ---------------------------------------------------------
        ;; RULE 0: Leading whitespace at line start.
        ;; Pass spaces/tabs through untouched but KEEP is_at_line_start
        ;; set, so indented headers/quotes/hr/bullets/fences still fire.
        ;; ---------------------------------------------------------
        local.get $is_at_line_start
        (if
          (then
            local.get $byte
            i32.const 32 ;; ' '
            i32.eq
            local.get $byte
            i32.const 9  ;; '\t'
            i32.eq
            i32.or
            (if
              (then
                local.get $out_curr
                local.get $byte
                i32.store8

                local.get $in_curr  i32.const 1  i32.add  local.set $in_curr
                local.get $out_curr i32.const 1  i32.add  local.set $out_curr
                br $process_chars
              )
            )
          )
        )

        ;; ---------------------------------------------------------
        ;; RULE 1: Code Block Toggle (```) at line start
        ;; ---------------------------------------------------------
        local.get $is_at_line_start
        local.get $byte
        i32.const 96 ;; '`'
        i32.eq
        i32.and
        (if
          (then
            ;; Lookahead: Check if next two bytes are also '`'
            local.get $in_curr
            i32.const 2
            i32.add
            local.get $in_len
            i32.lt_u
            (if (result i32)
              (then
                local.get $in_curr
                i32.const 1
                i32.add
                i32.load8_u
                i32.const 96
                i32.eq
                (if (result i32)
                  (then
                    local.get $in_curr
                    i32.const 2
                    i32.add
                    i32.load8_u
                    i32.const 96
                    i32.eq
                  )
                  (else
                    i32.const 0
                  )
                )
              )
              (else
                i32.const 0
              )
            )
            (if
              (then
                ;; Skip the '```' (3 bytes)
                local.get $in_curr
                i32.const 3
                i32.add
                local.set $in_curr

                local.get $in_code
                (if
                  (then
                    ;; Close code block: "</code></pre>" (13 bytes)
                    local.get $out_curr  i32.const 60  i32.store8 ;; <
                    local.get $out_curr  i32.const 1  i32.add  i32.const 47  i32.store8 ;; /
                    local.get $out_curr  i32.const 2  i32.add  i32.const 99  i32.store8 ;; c
                    local.get $out_curr  i32.const 3  i32.add  i32.const 111 i32.store8 ;; o
                    local.get $out_curr  i32.const 4  i32.add  i32.const 100 i32.store8 ;; d
                    local.get $out_curr  i32.const 5  i32.add  i32.const 101 i32.store8 ;; e
                    local.get $out_curr  i32.const 6  i32.add  i32.const 62  i32.store8 ;; >
                    local.get $out_curr  i32.const 7  i32.add  i32.const 60  i32.store8 ;; <
                    local.get $out_curr  i32.const 8  i32.add  i32.const 47  i32.store8 ;; /
                    local.get $out_curr  i32.const 9  i32.add  i32.const 112 i32.store8 ;; p
                    local.get $out_curr  i32.const 10 i32.add  i32.const 114 i32.store8 ;; r
                    local.get $out_curr  i32.const 11 i32.add  i32.const 101 i32.store8 ;; e
                    local.get $out_curr  i32.const 12 i32.add  i32.const 62  i32.store8 ;; >

                    local.get $out_curr  i32.const 13  i32.add  local.set $out_curr
                    i32.const 0  local.set $in_code
                  )
                  (else
                    ;; Open code block: "<pre><code>" (11 bytes)
                    local.get $out_curr  i32.const 60  i32.store8 ;; <
                    local.get $out_curr  i32.const 1  i32.add  i32.const 112 i32.store8 ;; p
                    local.get $out_curr  i32.const 2  i32.add  i32.const 114 i32.store8 ;; r
                    local.get $out_curr  i32.const 3  i32.add  i32.const 101 i32.store8 ;; e
                    local.get $out_curr  i32.const 4  i32.add  i32.const 62  i32.store8 ;; >
                    local.get $out_curr  i32.const 5  i32.add  i32.const 60  i32.store8 ;; <
                    local.get $out_curr  i32.const 6  i32.add  i32.const 99  i32.store8 ;; c
                    local.get $out_curr  i32.const 7  i32.add  i32.const 111 i32.store8 ;; o
                    local.get $out_curr  i32.const 8  i32.add  i32.const 100 i32.store8 ;; d
                    local.get $out_curr  i32.const 9  i32.add  i32.const 101 i32.store8 ;; e
                    local.get $out_curr  i32.const 10 i32.add  i32.const 62  i32.store8 ;; >

                    local.get $out_curr  i32.const 11  i32.add  local.set $out_curr
                    i32.const 1  local.set $in_code

                    ;; Skip language flag (e.g., "javascript") until newline
                    (block $exit_skip
                      (loop $skip_loop
                        local.get $in_curr  local.get $in_len  i32.ge_u  br_if $exit_skip
                        local.get $in_curr  i32.load8_u  i32.const 10  i32.eq  br_if $exit_skip
                        local.get $in_curr  i32.const 1  i32.add  local.set $in_curr
                        br $skip_loop
                      )
                    )
                  )
                )
                i32.const 0  local.set $is_at_line_start
                br $process_chars
              )
            )
          )
        )

        ;; ---------------------------------------------------------
        ;; RULE 2: Detect Header Start ("#" x1-6, then " ") - Only
        ;; outside code. Supports h1 through h6.
        ;; ---------------------------------------------------------
        local.get $is_at_line_start
        local.get $byte
        i32.const 35 ;; '#'
        i32.eq
        i32.and
        local.get $in_code
        i32.eqz
        i32.and
        (if
          (then
            ;; Count consecutive '#' characters, up to 6, without
            ;; consuming input yet (use $scan as a lookahead cursor).
            local.get $in_curr
            local.set $scan
            i32.const 0
            local.set $hcount

            (block $exit_hcount
              (loop $hcount_loop
                local.get $scan
                local.get $in_len
                i32.ge_u
                br_if $exit_hcount

                local.get $hcount
                i32.const 6
                i32.ge_u
                br_if $exit_hcount

                local.get $scan
                i32.load8_u
                i32.const 35 ;; '#'
                i32.ne
                br_if $exit_hcount

                local.get $scan  i32.const 1  i32.add  local.set $scan
                local.get $hcount i32.const 1 i32.add  local.set $hcount
                br $hcount_loop
              )
            )

            ;; Valid header only if the run of '#' is immediately
            ;; followed by a space.
            local.get $scan
            local.get $in_len
            i32.lt_u
            (if (result i32)
              (then
                local.get $scan
                i32.load8_u
                i32.const 32
                i32.eq
              )
              (else
                i32.const 0
              )
            )
            (if
              (then
                ;; Consume the '#'s and the single following space
                local.get $scan
                i32.const 1
                i32.add
                local.set $in_curr

                ;; Write "<h" + digit
                local.get $out_curr  i32.const 60  i32.store8 ;; <
                local.get $out_curr  i32.const 1  i32.add  i32.const 104 i32.store8 ;; h
                local.get $out_curr  i32.const 2  i32.add
                i32.const 48
                local.get $hcount
                i32.add
                i32.store8 ;; '0'+hcount => '1'..'6'
                local.get $out_curr  i32.const 3  i32.add  i32.const 62  i32.store8 ;; >

                local.get $out_curr  i32.const 4  i32.add  local.set $out_curr
                local.get $hcount  local.set $heading_level
                i32.const 0  local.set $is_at_line_start
                br $process_chars
              )
            )
          )
        )

        ;; ---------------------------------------------------------
        ;; RULE 3: Detect Blockquote Start ("> ") - Only outside code
        ;; ---------------------------------------------------------
        local.get $is_at_line_start
        local.get $byte
        i32.const 62 ;; '>'
        i32.eq
        i32.and
        local.get $in_code
        i32.eqz
        i32.and
        (if
          (then
            ;; Lookahead: Space (32)
            local.get $in_curr  i32.const 1  i32.add  local.get $in_len  i32.lt_u
            (if (result i32)
              (then local.get $in_curr  i32.const 1  i32.add  i32.load8_u  i32.const 32  i32.eq)
              (else i32.const 0)
            )
            (if
              (then
                local.get $in_curr  i32.const 2  i32.add  local.set $in_curr
                local.get $out_curr  i32.const 60  i32.store8 ;; <
                local.get $out_curr  i32.const 1  i32.add  i32.const 98  i32.store8 ;; b
                local.get $out_curr  i32.const 2  i32.add  i32.const 108 i32.store8 ;; l
                local.get $out_curr  i32.const 3  i32.add  i32.const 111 i32.store8 ;; o
                local.get $out_curr  i32.const 4  i32.add  i32.const 99  i32.store8 ;; c
                local.get $out_curr  i32.const 5  i32.add  i32.const 107 i32.store8 ;; k
                local.get $out_curr  i32.const 6  i32.add  i32.const 113 i32.store8 ;; q
                local.get $out_curr  i32.const 7  i32.add  i32.const 117 i32.store8 ;; u
                local.get $out_curr  i32.const 8  i32.add  i32.const 111 i32.store8 ;; o
                local.get $out_curr  i32.const 9  i32.add  i32.const 116 i32.store8 ;; t
                local.get $out_curr  i32.const 10 i32.add  i32.const 101 i32.store8 ;; e
                local.get $out_curr  i32.const 11 i32.add  i32.const 62  i32.store8 ;; >
                local.get $out_curr  i32.const 12  i32.add  local.set $out_curr
                i32.const 1  local.set $in_quote
                i32.const 0  local.set $is_at_line_start
                br $process_chars
              )
            )
          )
        )

        ;; ---------------------------------------------------------
        ;; RULE 4: Detect Horizontal Rule ("---") at line start
        ;; ---------------------------------------------------------
        local.get $is_at_line_start
        local.get $byte
        i32.const 45 ;; '-'
        i32.eq
        i32.and
        (if
          (then
            local.get $in_curr  i32.const 2  i32.add  local.get $in_len  i32.lt_u
            (if (result i32)
              (then
                local.get $in_curr  i32.const 1  i32.add  i32.load8_u  i32.const 45  i32.eq
                (if (result i32)
                  (then
                    local.get $in_curr  i32.const 2  i32.add  i32.load8_u  i32.const 45  i32.eq
                  )
                  (else i32.const 0)
                )
              )
              (else i32.const 0)
            )
            (if
              (then
                local.get $in_curr  i32.const 3  i32.add  local.set $in_curr
                local.get $out_curr  i32.const 60  i32.store8 ;; <
                local.get $out_curr  i32.const 1  i32.add  i32.const 104 i32.store8 ;; h
                local.get $out_curr  i32.const 2  i32.add  i32.const 114 i32.store8 ;; r
                local.get $out_curr  i32.const 3  i32.add  i32.const 62  i32.store8 ;; >
                local.get $out_curr  i32.const 4  i32.add  local.set $out_curr
                br $process_chars
              )
            )
          )
        )

        ;; ---------------------------------------------------------
        ;; RULE 5: Detect Bullet Points ("* ") at line start
        ;; ---------------------------------------------------------
        local.get $is_at_line_start
        local.get $byte
        i32.const 42 ;; '*'
        i32.eq
        i32.and
        (if
          (then
            local.get $in_curr  i32.const 1  i32.add  local.get $in_len  i32.lt_u
            (if (result i32)
              (then local.get $in_curr  i32.const 1  i32.add  i32.load8_u  i32.const 32  i32.eq)
              (else i32.const 0)
            )
            (if
              (then
                local.get $in_curr  i32.const 2  i32.add  local.set $in_curr
                ;; Write "&bull; " (7 bytes)
                local.get $out_curr  i32.const 38  i32.store8 ;; &
                local.get $out_curr  i32.const 1  i32.add  i32.const 98  i32.store8 ;; b
                local.get $out_curr  i32.const 2  i32.add  i32.const 117 i32.store8 ;; u
                local.get $out_curr  i32.const 3  i32.add  i32.const 108 i32.store8 ;; l
                local.get $out_curr  i32.const 4  i32.add  i32.const 108 i32.store8 ;; l
                local.get $out_curr  i32.const 5  i32.add  i32.const 59  i32.store8 ;; ;
                local.get $out_curr  i32.const 6  i32.add  i32.const 32  i32.store8 ;; [space]

                local.get $out_curr  i32.const 7  i32.add  local.set $out_curr
                i32.const 0  local.set $is_at_line_start
                br $process_chars
              )
            )
          )
        )

        ;; ---------------------------------------------------------
        ;; RULE 6: Detect Bold-Italic (***) or Bold (**)
        ;; ---------------------------------------------------------
        local.get $byte
        i32.const 42 ;; '*'
        i32.eq
        local.get $in_code
        i32.eqz
        i32.and
        (if
          (then
            ;; Lookahead: Is next byte also '*' ?
            local.get $in_curr  i32.const 1  i32.add  local.get $in_len  i32.lt_u
            (if (result i32)
              (then local.get $in_curr  i32.const 1  i32.add  i32.load8_u  i32.const 42  i32.eq)
              (else i32.const 0)
            )
            (if
              (then
                ;; Double asterisk (**) detected. Now lookahead for third asterisk (***)
                local.get $in_curr  i32.const 2  i32.add  local.get $in_len  i32.lt_u
                (if (result i32)
                  (then local.get $in_curr  i32.const 2  i32.add  i32.load8_u  i32.const 42  i32.eq)
                  (else i32.const 0)
                )
                (if
                  (then
                    ;; TRIPLE ASTERISK (***)
                    local.get $in_curr  i32.const 3  i32.add  local.set $in_curr
                    local.get $in_bold_italic
                    (if
                      (then
                        ;; Close: "</em></strong>" (14 bytes)
                        local.get $out_curr  i32.const 60  i32.store8 ;; <
                        local.get $out_curr  i32.const 1  i32.add i32.const 47  i32.store8 ;; /
                        local.get $out_curr  i32.const 2  i32.add i32.const 101 i32.store8 ;; e
                        local.get $out_curr  i32.const 3  i32.add i32.const 109 i32.store8 ;; m
                        local.get $out_curr  i32.const 4  i32.add i32.const 62  i32.store8 ;; >
                        local.get $out_curr  i32.const 5  i32.add i32.const 60  i32.store8 ;; <
                        local.get $out_curr  i32.const 6  i32.add i32.const 47  i32.store8 ;; /
                        local.get $out_curr  i32.const 7  i32.add i32.const 115 i32.store8 ;; s
                        local.get $out_curr  i32.const 8  i32.add i32.const 116 i32.store8 ;; t
                        local.get $out_curr  i32.const 9  i32.add i32.const 114 i32.store8 ;; r
                        local.get $out_curr  i32.const 10 i32.add i32.const 111 i32.store8 ;; o
                        local.get $out_curr  i32.const 11 i32.add i32.const 110 i32.store8 ;; n
                        local.get $out_curr  i32.const 12 i32.add i32.const 103 i32.store8 ;; g
                        local.get $out_curr  i32.const 13 i32.add i32.const 62  i32.store8 ;; >

                        local.get $out_curr  i32.const 14  i32.add  local.set $out_curr
                        i32.const 0  local.set $in_bold_italic
                      )
                      (else
                        ;; Open: "<strong><em>" (12 bytes)
                        local.get $out_curr  i32.const 60  i32.store8 ;; <
                        local.get $out_curr  i32.const 1  i32.add i32.const 115 i32.store8 ;; s
                        local.get $out_curr  i32.const 2  i32.add i32.const 116 i32.store8 ;; t
                        local.get $out_curr  i32.const 3  i32.add i32.const 114 i32.store8 ;; r
                        local.get $out_curr  i32.const 4  i32.add i32.const 111 i32.store8 ;; o
                        local.get $out_curr  i32.const 5  i32.add i32.const 110 i32.store8 ;; n
                        local.get $out_curr  i32.const 6  i32.add i32.const 103 i32.store8 ;; g
                        local.get $out_curr  i32.const 7  i32.add i32.const 62  i32.store8 ;; >
                        local.get $out_curr  i32.const 8  i32.add i32.const 60  i32.store8 ;; <
                        local.get $out_curr  i32.const 9  i32.add i32.const 101 i32.store8 ;; e
                        local.get $out_curr  i32.const 10 i32.add i32.const 109 i32.store8 ;; m
                        local.get $out_curr  i32.const 11 i32.add i32.const 62  i32.store8 ;; >

                        local.get $out_curr  i32.const 12  i32.add  local.set $out_curr
                        i32.const 1  local.set $in_bold_italic
                      )
                    )
                  )
                  (else
                    ;; DOUBLE ASTERISK (**) ONLY
                    local.get $in_curr  i32.const 2  i32.add  local.set $in_curr
                    local.get $in_bold
                    (if
                      (then
                        ;; Close: "</strong>" (9 bytes)
                        local.get $out_curr  i32.const 60  i32.store8 ;; <
                        local.get $out_curr  i32.const 1 i32.add i32.const 47  i32.store8 ;; /
                        local.get $out_curr  i32.const 2 i32.add i32.const 115 i32.store8 ;; s
                        local.get $out_curr  i32.const 3 i32.add i32.const 116 i32.store8 ;; t
                        local.get $out_curr  i32.const 4 i32.add i32.const 114 i32.store8 ;; r
                        local.get $out_curr  i32.const 5 i32.add i32.const 111 i32.store8 ;; o
                        local.get $out_curr  i32.const 6 i32.add i32.const 110 i32.store8 ;; n
                        local.get $out_curr  i32.const 7 i32.add i32.const 103 i32.store8 ;; g
                        local.get $out_curr  i32.const 8 i32.add i32.const 62  i32.store8 ;; >

                        local.get $out_curr  i32.const 9  i32.add  local.set $out_curr
                        i32.const 0  local.set $in_bold
                      )
                      (else
                        ;; Open: "<strong>" (8 bytes)
                        local.get $out_curr  i32.const 60  i32.store8 ;; <
                        local.get $out_curr  i32.const 1 i32.add i32.const 115 i32.store8 ;; s
                        local.get $out_curr  i32.const 2 i32.add i32.const 116 i32.store8 ;; t
                        local.get $out_curr  i32.const 3 i32.add i32.const 114 i32.store8 ;; r
                        local.get $out_curr  i32.const 4 i32.add i32.const 111 i32.store8 ;; o
                        local.get $out_curr  i32.const 5 i32.add i32.const 110 i32.store8 ;; n
                        local.get $out_curr  i32.const 6 i32.add i32.const 103 i32.store8 ;; g
                        local.get $out_curr  i32.const 7 i32.add i32.const 62  i32.store8 ;; >

                        local.get $out_curr  i32.const 8  i32.add  local.set $out_curr
                        i32.const 1  local.set $in_bold
                      )
                    )
                  )
                )
                br $process_chars
              )
            )
          )
        )

        ;; ---------------------------------------------------------
        ;; RULE 7: Detect Single Backtick (`) for Inline Code
        ;; ---------------------------------------------------------
        local.get $byte
        i32.const 96 ;; '`'
        i32.eq
        local.get $in_code
        i32.eqz
        i32.and
        (if
          (then
            local.get $in_curr  i32.const 1  i32.add  local.set $in_curr
            local.get $in_inline_code
            (if
              (then
                ;; Close: "</code>" (7 bytes)
                local.get $out_curr  i32.const 60  i32.store8 ;; <
                local.get $out_curr  i32.const 1 i32.add i32.const 47  i32.store8 ;; /
                local.get $out_curr  i32.const 2 i32.add i32.const 99  i32.store8 ;; c
                local.get $out_curr  i32.const 3 i32.add i32.const 111 i32.store8 ;; o
                local.get $out_curr  i32.const 4 i32.add i32.const 100 i32.store8 ;; d
                local.get $out_curr  i32.const 5 i32.add i32.const 101 i32.store8 ;; e
                local.get $out_curr  i32.const 6 i32.add i32.const 62  i32.store8 ;; >

                local.get $out_curr  i32.const 7  i32.add  local.set $out_curr
                i32.const 0  local.set $in_inline_code
              )
              (else
                ;; Open: "<code>" (6 bytes)
                local.get $out_curr  i32.const 60  i32.store8 ;; <
                local.get $out_curr  i32.const 1 i32.add i32.const 99  i32.store8 ;; c
                local.get $out_curr  i32.const 2 i32.add i32.const 111 i32.store8 ;; o
                local.get $out_curr  i32.const 3 i32.add i32.const 100 i32.store8 ;; d
                local.get $out_curr  i32.const 4 i32.add i32.const 101 i32.store8 ;; e
                local.get $out_curr  i32.const 5 i32.add i32.const 62  i32.store8 ;; >

                local.get $out_curr  i32.const 6  i32.add  local.set $out_curr
                i32.const 1  local.set $in_inline_code
              )
            )
            br $process_chars
          )
        )

        ;; ---------------------------------------------------------
        ;; RULE 8: Detect Newline Actions
        ;; ---------------------------------------------------------
        local.get $byte
        i32.const 10 ;; '\n'
        i32.eq
        (if
          (then
            ;; Case A: Close heading if open (any level 1-6)
            local.get $heading_level
            i32.const 0
            i32.gt_u
            (if
              (then
                local.get $out_curr  i32.const 60  i32.store8 ;; <
                local.get $out_curr  i32.const 1 i32.add i32.const 47  i32.store8 ;; /
                local.get $out_curr  i32.const 2 i32.add i32.const 104 i32.store8 ;; h
                local.get $out_curr  i32.const 3 i32.add
                i32.const 48
                local.get $heading_level
                i32.add
                i32.store8 ;; '0'+level
                local.get $out_curr  i32.const 4 i32.add i32.const 62  i32.store8 ;; >
                local.get $out_curr  i32.const 5 i32.add  local.set $out_curr
                i32.const 0  local.set $heading_level
              )
            )

            ;; Case B: Close Blockquote if open
            local.get $in_quote
            (if
              (then
                local.get $out_curr  i32.const 60  i32.store8 ;; <
                local.get $out_curr  i32.const 1  i32.add i32.const 47  i32.store8 ;; /
                local.get $out_curr  i32.const 2  i32.add i32.const 98  i32.store8 ;; b
                local.get $out_curr  i32.const 3  i32.add i32.const 108 i32.store8 ;; l
                local.get $out_curr  i32.const 4  i32.add i32.const 111 i32.store8 ;; o
                local.get $out_curr  i32.const 5  i32.add i32.const 99  i32.store8 ;; c
                local.get $out_curr  i32.const 6  i32.add i32.const 107 i32.store8 ;; k
                local.get $out_curr  i32.const 7  i32.add i32.const 113 i32.store8 ;; q
                local.get $out_curr  i32.const 8  i32.add i32.const 117 i32.store8 ;; u
                local.get $out_curr  i32.const 9  i32.add i32.const 111 i32.store8 ;; o
                local.get $out_curr  i32.const 10 i32.add i32.const 116 i32.store8 ;; t
                local.get $out_curr  i32.const 11 i32.add i32.const 101 i32.store8 ;; e
                local.get $out_curr  i32.const 12 i32.add i32.const 62  i32.store8 ;; >
                local.get $out_curr  i32.const 13  i32.add  local.set $out_curr
                i32.const 0  local.set $in_quote
              )
              (else
                ;; Case C: If neither heading nor Blockquote, AND we are NOT inside a code block,
                ;; append "<br>" (4 bytes) so prose breaks nicely.
                local.get $in_code
                (if
                  (then)
                  (else
                    local.get $heading_level
                    i32.const 0
                    i32.eq
                    (if
                      (then
                        local.get $out_curr  i32.const 60  i32.store8 ;; <
                        local.get $out_curr  i32.const 1 i32.add i32.const 98  i32.store8 ;; b
                        local.get $out_curr  i32.const 2 i32.add i32.const 114 i32.store8 ;; r
                        local.get $out_curr  i32.const 3 i32.add i32.const 62  i32.store8 ;; >
                        local.get $out_curr  i32.const 4 i32.add  local.set $out_curr
                      )
                    )
                  )
                )
              )
            )

            ;; Write the actual newline byte (1 byte)
            local.get $out_curr
            local.get $byte
            i32.store8
            local.get $out_curr
            i32.const 1
            i32.add
            local.set $out_curr

            ;; Reset line start flag
            i32.const 1
            local.set $is_at_line_start

            ;; Increment input pointer and continue loop
            local.get $in_curr
            i32.const 1
            i32.add
            local.set $in_curr

            br $process_chars
          )
        )

        ;; ---------------------------------------------------------
        ;; DEFAULT: 1:1 Character Copy
        ;; ---------------------------------------------------------
        local.get $out_curr
        local.get $byte
        i32.store8

        i32.const 0
        local.set $is_at_line_start

        ;; Increment pointers
        local.get $in_curr
        i32.const 1
        i32.add
        local.set $in_curr

        local.get $out_curr
        i32.const 1
        i32.add
        local.set $out_curr

        br $process_chars
      )
    )

    ;; Return output length
    local.get $out_curr
    local.get $in_len
    i32.sub
  )
)