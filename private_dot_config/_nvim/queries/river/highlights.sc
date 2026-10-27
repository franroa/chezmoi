(block      ; Then matches the block node immediately following those comments
  name: (qualified_identifier) @type) ; @first_block_context is optional for query debugging
(config_file
  (comment)* ; Matches zero or more comment nodes that might appear first
  (block      ; Then matches the block node immediately following those comments
    name: (qualified_identifier )  @punctuation.special)) ; @first_block_context is optional for query debugging

(config_file
  (comment)* 
  (block 
    body: (block_body 
      (block 
        name: (qualified_identifier) @keyword))))

;======================================================================
; Base Tokens
;======================================================================

(comment) @comment
(numeric_lit) @number
(bool_lit) @boolean
(null_lit) @constant.builtin

;======================================================================
; String Literals and Their Contents
;======================================================================

(string_lit) @string
; (_string_content) @string ; Captures the plain text inside a string
(escape_sequence) @string.escape

;======================================================================
; Keywords, Types, and Functions
;======================================================================

; Highlight function names
(function_call
  function: (qualified_identifier) @function)

;======================================================================
; Attributes, Variables, and Identifiers
;======================================================================

; Highlight the key of an attribute, e.g., the "job_name" in job_name = "..."
(attribute
  key: (identifier) @property)

; For a reference like `discovery.relabel.output`, this highlights
; the first part as a namespace/variable and subsequent parts as properties.
(attribute
  (qualified_identifier
    (identifier) @namespace
    "."
    (identifier) @namespace
    "."
    (identifier) @property))
(array
  (qualified_identifier
    (identifier) @namespace
    "."
    (identifier) @namespace
    "."
    (identifier) @property))

; Highlight identifiers when they are used as values
(attribute
  value: (qualified_identifier) @keyword)

(array
  (qualified_identifier) @keyword)

; Highlight the special label string for a block
(block
  label: (label) @string)

;======================================================================
; Punctuation and Operators
;======================================================================

[
  "[" "]"
  "{" "}"
  "(" ")"
] @punctuation.bracket

[
  "."
  ","
] @punctuation.delimiter

[
  "-" "!" "!="
  "*" "/" "%" "^"
  "+" "<" "<="
  "=" "==" ">" ">="
  "||" "&&"
] @operator


;======================================================================
; String Interpolation
;======================================================================

; Highlight the interpolation markers `${` and `}`
(interpolation
  "${" @punctuation.special
  "}" @punctuation.special) @embedded

; Highlight the expression inside an interpolation block as a variable
(interpolation
  (_expression) @variable)

; Highlight the qualified_identifier inside an interpolation as a type.
; This is the specific rule you requested.
(interpolation
  (qualified_identifier (identifier) @punctuation.special))

; Fallback for any other expression inside an interpolation, highlighting it as a variable.
(interpolation
  (_expression) @variable)
