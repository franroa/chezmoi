(function_call
   "(" @delimiter
   ")" @delimiter @sentinel) @container

(block_body
  "{" @delimiter
  "}" @delimiter @sentinel) @container

(object
  "{" @delimiter
  "}" @delimiter @sentinel) @container

(parenthesized_expression
  "(" @delimiter
  ")" @delimiter @sentinel) @container

(function_call
  "(" @delimiter
  ")" @delimiter @sentinel) @container

(array
  "[" @delimiter
  "]" @delimiter @sentinel) @container

(access
  "[" @delimiter
  "]" @delimiter @sentinel) @container
