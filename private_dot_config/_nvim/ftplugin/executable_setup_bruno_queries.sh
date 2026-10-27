#!/bin/bash
mkdir -p ~/.config/nvim/queries/bruno
cp /home/froa/Projects/tools/tree-sitter-bruno/queries/{highlights,injections,locals,folds,indents}.scm ~/.config/nvim/queries/bruno/
echo "Bruno queries installed to ~/.config/nvim/queries/bruno/"
ls -la ~/.config/nvim/queries/bruno/
