; Inject text language for word-level Git keyword highlighting
; Text parser should tokenize individual words
((message_line) @injection.content
 (#set! injection.language "markdown"))
; Inject diff syntax for the diff part in verbose commits
((diff) @injection.content
 (#set! injection.language "diff"))

