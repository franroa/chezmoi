; This file defines "inner" container text subjects for the configuration file syntax.
; These subjects select the content *within* the delimiters of a container,
; excluding the delimiters themselves where possible, using the #make-range! directive.

[
    ;; The 'body' of a block, representing the content inside its curly braces.
    (block_body) @_start @_end
    (#make-range! "range" @_start @_end)

    ;; The content inside an 'object' literal.
    ;; This captures the span of 'object_assignment' children without the surrounding curly braces.
    ;; It will match if there is at least one object_assignment.
    (
        (object
            (object_assignment) @first_child
            . (_)*
            (object_assignment)? @last_child
        )
        (#make-range! "range" @first_child @last_child)
    )

    ;; The content inside an 'array' literal.
    ;; This captures the span of 'string_lit' (or other value) children without the surrounding square brackets.
    ;; It will match if there is at least one string_lit.
    (
        (array
            (string_lit) @first_child
            . (_)*
            (string_lit)? @last_child
        )
        (#make-range! "range" @first_child @last_child)
    )

    ;; The content of a string literal.
    ;; Note: Based on the parse tree, 'string_lit' and 'double_quoted_string'
    ;; often encompass the quotes themselves. This query will select the entire
    ;; 'string_lit' node. If you require selecting *only* the content without
    ;; the quotes, your grammar would need to expose a specific 'string_content'
    ;; node, or you would need to use advanced character-level offsets, which
    ;; are typically implemented via custom predicates or external logic.
    (string_lit) @_start @_end
    (#make-range! "range" @_start @_end)
]

