;; aerial.scm for the custom configuration file syntax

;; This query extracts symbols for the aerial view, now categorizing
;; top-level blocks as "Class", general nested blocks as "Method",
;; and attributes within 'rule' blocks as "Property".

;; --- Query 1: Specific handling for attributes within 'rule' blocks ---
;; This query now targets the 'attribute' nodes *inside* a 'rule' block.
;; The attribute's key will be the symbol name, and its kind will be "Property".
(block
  ;; Match the 'name' of the block, ensuring its identifier is "rule".
  name: (qualified_identifier (identifier) @rule_block_id)
  (#eq? @rule_block_id "rule") ; Tree-sitter predicate: ensures the identifier text is "rule"

  body: (block_body
    ;; Within the 'rule' block's body, find an 'attribute' node.
    (attribute
      key: (identifier) @name ; Capture the attribute's key identifier (e.g., "action", "target_label").
      ;; Set the 'kind' of the symbol to "Property" for these attributes.
      (#set! "kind" "Property")
    ) @symbol ;; The attribute itself becomes the symbol.
  )
)
  ; (block ; [15, 0] - [19, 1]
  ;   name: (qualified_identifier ; [15, 0] - [15, 10]
  ;     (identifier) ; [15, 0] - [15, 4]
  ;     (identifier)) ; [15, 5] - [15, 10]
  ;   label: (label ; [15, 11] - [15, 20]
  ;     (double_quoted_string)) ; [15, 11] - [15, 20]
  ;   body: (block_body ; [15, 21] - [19, 1]
  ;     (block ; [16, 4] - [18, 5]
  ;       name: (qualified_identifier ; [16, 4] - [16, 12]
  ;         (identifier)) ; [16, 4] - [16, 12]
  ;       body: (block_body ; [16, 13] - [18, 5]
  ;         (attribute ; [17, 8] - [17, 52]


(attribute
  key: (identifier) @name ; Capture the attribute's key identifier (e.g., "targets", "action", "address").
  (#set! "kind" "Property")
) @symbol
;; ;; --- Query 2: Handling for other nested 'block' types ---
;; ;; This query matches 'block' nodes that are direct children of a 'block_body'.
;; ;; This specifically targets blocks nested within other blocks (e.g., 'rule_namespace_selector').
;; ;; It will *not* match 'rule' blocks (whose attributes are handled by Query 1) due to query order.
(block_body
  (block
    name: (qualified_identifier) @name ; Capture the block's qualified identifier.

    ;; Set the 'kind' of the symbol to "Method" for nested blocks.
    (#set! "kind" "Struct")
  ) @symbol
)

;; --- Query 3: General handling for top-level 'block' types ---
;; This query acts as a fallback for any 'block' nodes that were not matched
;; by the more specific queries above. These are typically the top-level blocks
;; (e.g., 'discovery.relabel', 'loki.source.kubernetes', 'mimir.rules.kubernetes').
(block
  ;; Capture the 'qualified_identifier' as the primary name for the symbol.
  name: (qualified_identifier) @name

  ;; Set the 'kind' of the symbol to "Class" for top-level blocks.
  (#set! "kind" "Class")
) @symbol

