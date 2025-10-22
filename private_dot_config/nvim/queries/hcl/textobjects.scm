
; extends

;-- OUTER CAPTURES --
; Capture the entire (block) node, but only if its first (identifier) child
; matches the given type (e.g., "resource").

(block
  (identifier) @type
  (#match? @type "^resource$")
) @resource.outer

(block
  (identifier) @type
  (#match? @type "^data$")
) @data.outer

(block
  (identifier) @type
  (#match? @type "^provider$")
) @provider.outer

(block
  (identifier) @type
  (#match? @type "^variable$")
) @variable.outer

(block
  (identifier) @type
  (#match? @type "^output$")
) @output.outer

(block
  (identifier) @type
  (#match? @type "^module$")
) @module.outer


;-- INNER CAPTURES --
; Match the block based on its type, but only capture the (body) node within it.

(block
  (identifier) @type
  (body) @resource.inner
  (#match? @type "^resource$")
)

(block
  (identifier) @type
  (body) @data.inner
  (#match? @type "^data$")
)

(block
  (identifier) @type
  (body) @provider.inner
  (#match? @type "^provider$")
)

(block
  (identifier) @type
  (body) @variable.inner
  (#match? @type "^variable$")
)

(block
  (identifier) @type
  (body) @output.inner
  (#match? @type "^output$")
)

(block
  (identifier) @type
  (body) @module.inner
  (#match? @type "^module$")
)


;-- GENERIC CAPTURES --

(attribute) @attribute.outer
(attribute (expression) @attribute.inner)
(block (body) @block.inner)
(object) @object.outer
(object (object_elem) @object.inner)
