; This file defines "big" text subjects for the configuration file syntax.
; These subjects are intended for selecting larger structural elements.

[
    ;; The entire configuration file.
    (config_file) @_start @_end
    (#make-range! "range" @_start @_end)

    ;; Any 'block' node (e.g., 'block { ... }', 'source.foo "label" { ... }').
    ;; This selects the entire block, including its name, label, and curly braces.
    (block) @_start @_end
    (#make-range! "range" @_start @_end)

    ;; The 'body' of a block, which contains its attributes and nested blocks.
    ;; This selects the content within the curly braces of a block.
    (block_body) @_start @_end
    (#make-range! "range" @_start @_end)

    ;; Object literals, like { "key": "value", ... }.
    ;; This selects the entire object, including its curly braces.
    (object) @_start @_end
    (#make-range! "range" @_start @_end)

    ;; Array literals, like ["item1", "item2", ... ].
    ;; This selects the entire array, including its square brackets.
    (array) @_start @_end
    (#make-range! "range" @_start @_end)
]

