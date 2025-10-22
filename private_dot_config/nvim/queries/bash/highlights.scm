;extends

; Highlight flag names in command line options (handles both -var= and -var-file=)
[
  (word) 
  (concatenation)
] @variable.parameter
(#lua-match? @variable.parameter "^%-[a-zA-Z][a-zA-Z0-9_%-]*=")

[
  (variable_name) 
] @variable.parameter
(#lua-match? @variable.parameter "^%-[a-zA-Z][a-zA-Z0-9_%-]*=")

