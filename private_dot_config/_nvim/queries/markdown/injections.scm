; Inject diff highlighting for documents containing "; Everything below it will be ignored."
((document) @injection.content
  (#match? @injection.content ".*; Everything below it will be ignored\\..*")
  (#set! injection.language "diff"))
