; ; First, match the text fields in ALL rows.
(document
 (row
  (field
    (text) @keyword)))

; Then, match the same text fields but ONLY in rows that
; follow another row (i.e., not the first one) and assign
; them to a special capture group that clears the highlight.
(document
 (row)
 (row
  (field
    (text) @attribute)))


