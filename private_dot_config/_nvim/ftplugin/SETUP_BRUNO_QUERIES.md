# Setting up Bruno Tree-Sitter Queries in Neovim

The Bruno queries have been automatically configured in your Neovim ftplugin.

## What was done:

1. Created enhanced query files in `/home/froa/Projects/tools/tree-sitter-bruno/queries/`:
   - `highlights.scm` - Enhanced syntax highlighting
   - `injections.scm` - Language injections (JSON, XML, GraphQL, etc.)
   - `locals.scm` - Variable tracking and definitions
   - `folds.scm` - Code folding support
   - `indents.scm` - Indentation rules

2. Updated `/home/froa/.config/nvim/ftplugin/bruno.lua` to automatically:
   - Create the queries directory structure
   - Copy all query files to `~/.config/nvim/queries/bruno/`
   - Set up proper tree-sitter language registration

## How to activate:

Simply open a Bruno file (*.bru) in Neovim. The ftplugin will automatically:
- Detect the Bruno filetype
- Copy the query files if they don't exist
- Register the queries for proper syntax highlighting and other features

## Manual setup (if needed):

If you want to manually copy the files without opening Neovim, run:

```bash
mkdir -p ~/.config/nvim/queries/bruno && \
cp /home/froa/Projects/tools/tree-sitter-bruno/queries/{highlights,injections,locals,folds,indents}.scm ~/.config/nvim/queries/bruno/
```

## Verify setup:

```bash
ls -la ~/.config/nvim/queries/bruno/
```

Should show:
- folds.scm
- highlights.scm
- indents.scm
- injections.scm
- locals.scm

## Query files explained:

- **highlights.scm**: Provides syntax highlighting with:
  - HTTP method highlighting (get, post, put, delete, etc.)
  - Auth type highlighting (auth:basic, auth:bearer, etc.)
  - Script type highlighting (script:pre-request, script:post-response)
  - Body type highlighting (body:json, body:xml, etc.)
  - Variable section highlighting (vars, vars:secret, etc.)

- **injections.scm**: Enables language-specific syntax highlighting inside blocks:
  - JSON in body:json and body:graphql:vars
  - XML in body:xml
  - SPARQL in body:sparql
  - GraphQL in body:graphql
  - JavaScript in script:pre-request and script:post-response
  - Markdown in docs

- **locals.scm**: Tracks variable definitions and references for:
  - Variable definitions in vars sections
  - Variable references using {{...}} syntax
  - Script variable names

- **folds.scm**: Enables code folding for:
  - All section types (headers, query, body, etc.)
  - Nested structures (dictionaries, arrays, textblocks)
  - All authentication and body type sections

- **indents.scm**: Provides proper indentation for:
  - Content inside textblocks, dictionaries, and arrays

