; extends

; Keys (properties) - dark blue highlighting
(block_mapping_pair
  key: (flow_node (plain_scalar (string_scalar) @keyword)))

; Quoted strings - normal string color
(double_quote_scalar) @string
(single_quote_scalar) @string 
(block_scalar) @string

; Plain scalars that are VALUES (not keys) - make them gray
; This targets values in mapping pairs
(block_mapping_pair
  value: (flow_node (plain_scalar (string_scalar) @constant)))

; Plain scalars in sequences/arrays - make them gray  
(block_sequence_item
  (flow_node (plain_scalar (string_scalar) @constant)))

; Plain scalars in flow sequences [item1, item2, item3] - make them gray
(flow_sequence
  (flow_node (plain_scalar (string_scalar) @constant)))

; Comments
(comment) @comment

; Numbers and booleans
(integer_scalar) @number
(float_scalar) @number.float
(boolean_scalar) @boolean

; Null values
(null_scalar) @constant.builtin

; Punctuation
":" @punctuation.delimiter
"-" @punctuation.delimiter
"[" @punctuation.bracket
"]" @punctuation.bracket
