; Variable definitions in vars sections
((key) @definition.var
 (#parent-type? @definition.var "dictionary"))

; References in values (simple heuristic - any {{...}} pattern would be captured by injections)
((value) @reference
 (#match? @reference "\\{\\{.*\\}\\}"))

; Script variables
((rawtext) @reference
 (#match? @reference "[a-zA-Z_][a-zA-Z0-9_]*"))
