; Keywords
(keyword) @keyword

; Meta and other top-level tags
((keyword) @keyword.function
 (#match? @keyword.function "^(meta|query|headers|assert|tests|docs|settings)$"))

; HTTP Methods
((keyword) @keyword.function
 (#match? @keyword.function "^(get|post|put|delete|patch|options|head|connect|trace)$"))

; Auth types
((keyword) @keyword.function
 (#match? @keyword.function "^auth(:.*)?$"))

; Script types
((keyword) @keyword.function
 (#match? @keyword.function "^script:"))

; Body types
((keyword) @keyword.function
 (#match? @keyword.function "^body(:.*)?$"))

; Variables
((keyword) @keyword.function
 (#match? @keyword.function "^vars(:|$)"))

; Punctuation
[
	"{"
	"}"
	"["
	"]"
] @punctuation.bracket
":" @punctuation.delimiter
"," @punctuation.delimiter

; Keys and values
(key) @property
[
  (value)
  (array_value)
] @string

; Errors
(ERROR) @error
