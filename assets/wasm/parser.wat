;; ==========================================================================
;; BEETH73 // WASM ENGINE
;; State-Machine Markdown Parser (v3: Headers, Blockquotes, & Code Blocks)
;; ==========================================================================

(module
  ;; Shared memory from JS (1 page = 64KB)
  (import "env" "memory" (memory 1))
  ;; Debug logger
  (import "env" "sys_log" (func $sys_log (param i32)))

  (func $parse (export "parse") (param $in_ptr i32) (param $in_len i32) (result i32)
    
    ;; Register allocation
    (local $in_curr i32)          ;; Read cursor
    (local $out_curr i32)         ;; Write cursor
    (local $byte i32)             ;; Current active byte
    (local $is_at_line_start i32) ;; State: 1 = Start of line, 0 = Middle
    (local $in_h1 i32)            ;; State: 1 = Inside H1
    (local $in_quote i32)         ;; State: 1 = Inside Blockquote
    (local $in_code i32)          ;; State: 1 = Inside Pre/Code Block

    ;; Initialize Read/Write pointers
    local.get $in_ptr
    local.set $in_curr

    ;; Output starts right after input in memory
    local.get $in_len
    local.set $out_curr

    ;; Set initial states
    i32.const 1
    local.set $is_at_line_start

    i32.const 0
    local.set $in_h1

    i32.const 0
    local.set $in_quote

    i32.const 0
    local.set $in_code

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
        ;; RULE 1: Detect Code Block Toggle (```)
        ;; ---------------------------------------------------------
        ;; If we are at the start of a line AND the byte is '`' (ASCII 96)
        local.get $is_at_line_start
        local.get $byte
        i32.const 96 
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
            ;; If indeed '```', execute the toggle
            (if
              (then
                ;; Skip the '```' (3 bytes) in the input stream
                local.get $in_curr
                i32.const 3
                i32.add
                local.set $in_curr

                local.get $in_code
                (if
                  (then
                    ;; CASE A: We were in a code block. Close it: "</code></pre>" (13 bytes)
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
                    ;; CASE B: Open a new code block: "<pre><code>" (11 bytes)
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

                    ;; Progressively skip the language identifier (e.g., "javascript") 
                    ;; until we hit the newline so it doesn't leak into the code output
                    (block $exit_skip
                      (loop $skip_loop
                        local.get $in_curr
                        local.get $in_len
                        i32.ge_u
                        br_if $exit_skip
                        
                        local.get $in_curr
                        i32.load8_u
                        i32.const 10 ;; '\n'
                        i32.eq
                        br_if $exit_skip
                        
                        local.get $in_curr
                        i32.const 1
                        i32.add
                        local.set $in_curr
                        br $skip_loop
                      )
                    )
                  )
                )

                i32.const 0
                local.set $is_at_line_start
                br $process_chars ;; Continue loop
              )
            )
          )
        )

        ;; ---------------------------------------------------------
        ;; RULE 2: Detect Header Start ("# ") - Only when NOT in code
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
            ;; Lookahead: Space (ASCII 32)
            local.get $in_curr
            i32.const 1
            i32.add
            local.get $in_len
            i32.lt_u
            (if (result i32)
              (then
                local.get $in_curr
                i32.const 1
                i32.add
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
                local.get $in_curr
                i32.const 2
                i32.add
                local.set $in_curr

                local.get $out_curr  i32.const 60  i32.store8 ;; <
                local.get $out_curr  i32.const 1  i32.add  i32.const 104 i32.store8 ;; h
                local.get $out_curr  i32.const 2  i32.add  i32.const 49  i32.store8 ;; 1
                local.get $out_curr  i32.const 3  i32.add  i32.const 62  i32.store8 ;; >

                local.get $out_curr  i32.const 4  i32.add  local.set $out_curr

                i32.const 1
                local.set $in_h1
                i32.const 0
                local.set $is_at_line_start

                br $process_chars
              )
            )
          )
        )

        ;; ---------------------------------------------------------
        ;; RULE 3: Detect Blockquote Start ("> ") - Only when NOT in code
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
            ;; Lookahead: Space (ASCII 32)
            local.get $in_curr
            i32.const 1
            i32.add
            local.get $in_len
            i32.lt_u
            (if (result i32)
              (then
                local.get $in_curr
                i32.const 1
                i32.add
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
                local.get $in_curr
                i32.const 2
                i32.add
                local.set $in_curr

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

                i32.const 1
                local.set $in_quote
                i32.const 0
                local.set $is_at_line_start

                br $process_chars
              )
            )
          )
        )

        ;; ---------------------------------------------------------
        ;; RULE 4: Detect Newline Actions
        ;; ---------------------------------------------------------
        local.get $byte
        i32.const 10 ;; '\n'
        i32.eq
        (if
          (then
            ;; Case A: Close H1 if open
            local.get $in_h1
            (if
              (then
                local.get $out_curr  i32.const 60  i32.store8 ;; <
                local.get $out_curr  i32.const 1 i32.add i32.const 47  i32.store8 ;; /
                local.get $out_curr  i32.const 2 i32.add i32.const 104 i32.store8 ;; h
                local.get $out_curr  i32.const 3 i32.add i32.const 49  i32.store8 ;; 1
                local.get $out_curr  i32.const 4 i32.add i32.const 62  i32.store8 ;; >
                local.get $out_curr  i32.const 5 i32.add  local.set $out_curr
                i32.const 0  local.set $in_h1
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
                ;; Case C: If neither H1 nor Blockquote, AND we are NOT inside a code block,
                ;; append "<br>" (4 bytes) so prose breaks nicely.
                local.get $in_code
                (if
                  (then
                    ;; Inside code: do nothing, preserve the raw newline
                  )
                  (else
                    local.get $out_curr  i32.const 60  i32.store8 ;; <
                    local.get $out_curr  i32.const 1 i32.add i32.const 98  i32.store8 ;; b
                    local.get $out_curr  i32.const 2 i32.add i32.const 114 i32.store8 ;; r
                    local.get $out_curr  i32.const 3 i32.add i32.const 62  i32.store8 ;; >
                    local.get $out_curr  i32.const 4 i32.add  local.set $out_curr
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