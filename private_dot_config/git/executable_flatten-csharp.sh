#!/bin/bash
# Flatten multi-line C# statements for better move detection

flatten_csharp() {
    # Join lines that are continuations (indented or ending with certain chars)
    awk '
    /^[[:space:]]*LogManager\.Configuration\.Variables\[/ {
        line = $0
        getline
        while ($0 ~ /^[[:space:]]+("|\.|\[|\])/) {
            gsub(/^[[:space:]]+/, " ")
            line = line $0
            if (getline <= 0) break
        }
        print line
        next
    }
    { print }
    '
}

# Apply to staged files
git diff --cached --name-only | grep '\.cs$' | while read file; do
    if [ -f "$file" ]; then
        flatten_csharp < "$file" > /tmp/flattened_$$_$(basename "$file")
    fi
done

echo "Flattened C# files created in /tmp/"
