; This file defines "smart" text subjects for the configuration file syntax.
; These subjects are intended for more granular and context-aware selections.

((comment) @_start @_end
     (#make-range! "range" @_start @_end))


    ; (block (_) @_start @_end
    ; (#make-range! "range" @_start @_end))
    ;; ;; String literals (the content within quotes).
    ;; ;; Based on your parse tree, 'string_lit' usually includes the quotes.
    ;; (string_lit) @_start @_end
    ;; (#make-range! "range" @_start @_end)
    ;;
    ;; ;; Basic identifiers (e.g., attribute keys, single parts of block names).
    ;; (identifier) @_start @_end
    ;; (#make-range! "range" @_start @_end)
    ;;
    ;; ;; Qualified identifiers (e.g., 'source.file', 'log.level.debug').
    ;; ;; This selects the full multi-part identifier.
    ;; (qualified_identifier) @_start @_end
    ;; (#make-range! "range" @_start @_end)
    ;;
    ;; ;; An entire attribute (a 'key: value' pair).
    ;; (attribute) @_start @_end
    ;; (#make-range! "range" @_start @_end)
    ;;
    ;; ;; An object assignment within an object literal ('"key": "value"').
    ;; (object_assignment) @_start @_end
    ;; (#make-range! "range" @_start @_end)
    ;;
    ;; ;; Interpolated parts within strings (e.g., '${variable}').
    ;; ;; This selects the entire interpolation syntax, including `${` and `}`.
    ;; (interpolation) @_start @_end
    ;; (#make-range! "range" @_start @_end)
    ;;
    ;; ;; Comments (e.g., '; this is a comment').
    ;; ;; This selects the entire comment line.
    ;; (comment) @_start @_end
    ;; (#make-range! "range" @_start @_end)
