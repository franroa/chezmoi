;; For plain flow scalars (e.g., key: some hcl code here)
; (block_mapping_pair
;   key: (flow_node) @_run
;   (#any-of? @_run "content")
;   value: (flow_node
;     (plain_scalar
;       (string_scalar) @injection.content))
;   (#set! injection.language "river")
; )

; ; extends
; (block_mapping_pair
;   key: (flow_node) @_key_name
;   (#any-of? @_key_name "content")
;   value: (block_node
;     (block_scalar) @injection.content
;     (#set! injection.language "river")
;     (#set! injection.include-children)
;     (#set! injection.combined)
;     (#offset! @injection.content 0 2 0 0)))
;
;

; extends
;; Inject River only if inside alloy > configMap > content
;; Inyectar el lenguaje River dentro del campo alloy > configMap > content
(
  (block_mapping_pair
    key: (flow_node) @_alloy_key
    (#eq? @_alloy_key "alloy")
    value: (block_node
      (block_mapping
        (block_mapping_pair
          key: (flow_node) @_configMap_key
          (#eq? @_configMap_key "configMap")
          value: (block_node
            (block_mapping
              (block_mapping_pair
                key: (flow_node) @_content_key
                (#eq? @_content_key "content")
                value: (block_node
                  (block_scalar) @injection.content
                )
              )
            )
          )
        )
      )
    )
  )
  (#set! injection.language "river")
  (#set! injection.combined)
  (#offset! @injection.content 0 1 0 0)
)



; Catch any block scalar that looks like terraform args with Go template
; there's no jinja2 grammar, so we use twig instead since it's very similar
(block_mapping_pair
  value: [
    (block_node (block_scalar) @injection.content)
    (flow_node (double_quote_scalar) @injection.content)
  ]
  (#set! injection.language "twig")
  (#contains? @injection.content "{{"))
(block_mapping_pair
  value: [
    (block_node (block_scalar) @injection.content)
    (flow_node (double_quote_scalar) @injection.content)
  ]
  (#set! injection.language "twig")
  (#contains? @injection.content "{%")
)



(
  (block_mapping_pair
    key: (flow_node) @_alloy_key
    (#eq? @_alloy_key "data")
    value: (block_node
      (block_mapping
        (block_mapping_pair 
          key: (flow_node) @_configMap_key
          (#eq? @_configMap_key "config.alloy")
          value: (block_node
            (block_scalar) @injection.content
          )
        )       
      )
    )
  )
  (#set! injection.language "river")
  (#set! injection.combined)
  (#offset! @injection.content 0 1 0 0)
)





; (block_mapping_pair
;   value: (flow_node [
;     (string_scalar)
;     (double_quoted_scalar)
;     (single_quoted_scalar)
;   ] @value (#match? @value "\\$\\{.*\\}") (#set! "injection.language" "hcl")))
;
;
;
;

; Inject bash for cmds array elements
(
  (block_mapping_pair
    key: (flow_node (plain_scalar (string_scalar) @_key))
    (#eq? @_key "cmds")
    value: (block_node
      (block_sequence
        (block_sequence_item
          (flow_node
            (plain_scalar (string_scalar) @injection.content)
          )
        )
      )
    )
  )
  (#set! injection.language "gotmpl")
)

; Also handle other scalar types in cmds
(
  (block_mapping_pair
    key: (flow_node (plain_scalar (string_scalar) @_key))
    (#eq? @_key "cmds")
    value: (block_node
      (block_sequence
        (block_sequence_item
          (flow_node
            (double_quote_scalar) @injection.content
          )
        )
      )
    )
  )
  (#set! injection.language "gotmpl")
)

(
  (block_mapping_pair
    key: (flow_node (plain_scalar (string_scalar) @_key))
    (#eq? @_key "cmds")
    value: (block_node
      (block_sequence
        (block_sequence_item
          (block_node
            (block_scalar) @injection.content
          )
        )
      )
    )
  )
  (#set! injection.language "gotmpl")
  (#set! injection.combined)
  (#offset! @injection.content 0 1 0 0)
)




; Inject gotmpl for any value under "vars" section
(block_mapping_pair
  key: (flow_node (plain_scalar (string_scalar) @_section_key))
  value: (block_node
    (block_mapping
      (block_mapping_pair
        value: [
          (block_node (block_scalar) @injection.content)
          (flow_node (plain_scalar) @injection.content)
          (flow_node (double_quote_scalar) @injection.content)
          (flow_node (single_quote_scalar) @injection.content)
        ])))
  (#eq? @_section_key "vars")
  (#set! injection.language "gotmpl"))

; Inject gotmpl for any value under "env" section  
(block_mapping_pair
  key: (flow_node (plain_scalar (string_scalar) @_section_key))
  value: (block_node
    (block_mapping
      (block_mapping_pair
        value: [
          (block_node (block_scalar) @injection.content)
          (flow_node (plain_scalar) @injection.content)
          (flow_node (double_quote_scalar) @injection.content)
          (flow_node (single_quote_scalar) @injection.content)
        ])))
  (#eq? @_section_key "env")
  (#set! injection.language "gotmpl"))

; Handle nested vars (like under includes/terraform/vars)
(block_mapping_pair
  key: (flow_node (plain_scalar (string_scalar) @_nested_key))
  value: (block_node
    (block_mapping
      (block_mapping_pair
        key: (flow_node (plain_scalar (string_scalar) @_section_key))
        value: (block_node
          (block_mapping
            (block_mapping_pair
              value: [
                (block_node (block_scalar) @injection.content)
                (flow_node (plain_scalar) @injection.content) 
                (flow_node (double_quote_scalar) @injection.content)
                (flow_node (single_quote_scalar) @injection.content)
              ])))
        (#eq? @_section_key "vars"))))
  (#set! injection.language "gotmpl"))

; Inject SQL for query property values with proper boundaries
(block_mapping_pair
  key: (flow_node (plain_scalar (string_scalar) @_key))
  value: (block_node (block_scalar) @injection.content)
  (#eq? @_key "query")
  (#set! injection.language "sql")
  (#offset! @injection.content 0 1 0 0))



