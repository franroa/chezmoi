; This file defines "endwise" behaviors for the configuration file syntax.
; It helps automatically insert closing delimiters for certain language constructs.

[
    ;; When a 'block' is started (e.g., after typing '{' or the block name/label),
    ;; automatically insert the closing '}'.
    ;; We capture the 'block' node as both @endable and @indent to signify
    ;; that it's a structure that needs an 'end' and its content should be indented.
    ;; The @cursor is placed within the block_body to indicate where the cursor
    ;; should be after the automatic insertion, typically inside the block.
    (block body: (block_body) @cursor) @endable @indent (#endwise! "}")

    ;; You might also consider rules for 'object' and 'array' if you want
    ;; auto-closing for their respective delimiters ({}) and ([]).
    ;; Example for object (untested, depending on exact grammar behavior):
    ; (object) @endable @indent (#endwise! "}")
    ;; Example for array (untested, depending on exact grammar behavior):
    ; (array) @endable @indent (#endwise! "]")
]

