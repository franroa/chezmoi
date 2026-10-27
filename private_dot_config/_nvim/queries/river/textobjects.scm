; ; extends
; ; This line tells Treesitter to extend the built-in textobjects.
; ; If your language has specific extensions or is a variant of another,
; ; you might need to adjust this.
;
; ;; --------------------------------------------------------------------------
; ;; @block - Text objects for 'block' nodes
; ;; 'ab' (around block): Selects the entire block, including its name, label, and body braces.
; ;; 'ib' (inner block): Selects only the content within the block's curly braces, excluding the braces themselves.
; ;; This applies to all blocks, whether top-level or nested.
; ;; --------------------------------------------------------------------------
;
; (block) @block.outer
; (block_body) @block.inner
;
; ;; --------------------------------------------------------------------------
; ;; @top_level_block - Text objects specifically for top-level 'block' nodes
; ;; 'aB' (around top-level block): Selects the entire top-level block.
; ;; 'iB' (inner top-level block): Selects only the content within a top-level block's body braces.
; ;; These objects specifically target blocks that are direct children of the config_file.
; ;; --------------------------------------------------------------------------
;
; (config_file
;   (block) @top_level_block.outer)
;
; (config_file
;   (block
;     body: (block_body) @top_level_block.inner))
;
; ;; --------------------------------------------------------------------------
; ;; @attribute - Text objects for 'attribute' nodes
; ;; 'aa' (around attribute): Selects the entire attribute line (key, equals sign, value, and any trailing whitespace/newlines before the next element).
; ;; 'ia' (inner attribute): Selects only the 'value' part of the attribute.
; ;; --------------------------------------------------------------------------
;
; (attribute) @attribute.outer
; (attribute
;   value: (_) @attribute.inner)
;
; ;; --------------------------------------------------------------------------
; ;; @string_lit - Text objects for 'string_lit' nodes
; ;; 'as' (around string): Selects the entire string literal, including its opening and closing quotes.
; ;; 'is' (inner string): Selects only the text content within the string literal, excluding the quotes.
; ;; --------------------------------------------------------------------------
;
; (string_lit) @string_lit.outer
; (string_lit
;   (string_text) @string_lit.inner)
;
; ;; --------------------------------------------------------------------------
; ;; @array - Text objects for 'array' nodes
; ;; 'a]' (around array): Selects the entire array literal, including its opening and closing square brackets.
; ;; 'i]' (inner array): Selects only the elements within the array, excluding the square brackets.
; ;; --------------------------------------------------------------------------
;
; (array) @array.outer
; (array
;   ; Selects any child nodes within the array, representing the elements.
;   ([
;     (literal_value)
;     (qualified_identifier)
;     (function_call)
;     (object)
;     (array)
;     (operation)
;     (access)
;     ; Add other potential node types if your array can contain them
;   ]) @array.inner)
;
; ;; --------------------------------------------------------------------------
; ;; @object - Text objects for 'object' nodes
; ;; 'ao' (around object): Selects the entire object, including its opening and closing curly braces.
; ;; 'io' (inner object): Selects only the key-value assignments within the object, excluding the braces.
; ;; --------------------------------------------------------------------------
;
; (object) @object.outer
; (object
;   (object_assignment)* @object.inner) ; Selects zero or more object assignments inside
;
; ;; --------------------------------------------------------------------------
; ;; @function_call - Text objects for 'function_call' nodes
; ;; 'af' (around function call): Selects the entire function call, including the function name and parentheses.
; ;; 'if' (inner function call): Selects only the parameters within the function call, excluding the parentheses.
; ;; --------------------------------------------------------------------------
;
; (function_call) @function_call.outer
; (function_call
;   params: (function_params) @function_call.inner) ; Selects the function_params node if present
;
; ;; --------------------------------------------------------------------------
; ;; @interpolation - Text objects for 'interpolation' nodes within strings
; ;; This allows for selecting and manipulating interpolated expressions directly.
; ;; 'ai' (around interpolation): Selects the entire interpolation, including `${` and `}`.
; ;; 'ii' (inner interpolation): Selects the expression inside the interpolation.
; ;; --------------------------------------------------------------------------
;
; (interpolation) @interpolation.outer
; (interpolation
;   expression: (interpolated_expression) @interpolation.inner)
;
