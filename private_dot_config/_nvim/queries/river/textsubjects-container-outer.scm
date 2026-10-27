; This file defines "outer" container text subjects for the configuration file syntax.
; These subjects select the entire container, including its surrounding delimiters.

[
    ;; The entire 'block' node, including its name, optional label, and curly braces.
    (block) @_start @_end
    (#make-range! "range" @_start @_end)

    ;; The entire 'object' literal, including its curly braces.
    (object) @_start @_end
    (#make-range! "range" @_start @_end)

    ;; The entire 'array' literal, including its square brackets.
    (array) @_start @_end
    (#make-range! "range" @_start @_end)

    ;; The entire 'double_quoted_string' including the quotes.
    (double_quoted_string) @_start @_end
    (#make-range! "range" @_start @_end)

    ;; The entire 'single_quoted_string' including the quotes.
    ;; (Assuming your grammar supports single-quoted strings, even if not shown in parse tree)
    (single_quoted_string) @_start @_end
    (#make-range! "range" @_start @_end)
]

