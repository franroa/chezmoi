-- Setup Bruno queries for Neovim
-- This script should be sourced from your nvim config

local queries_dir = vim.fn.expand("~/.config/nvim/queries/bruno")
local source_dir = "/home/froa/Projects/tools/tree-sitter-bruno/queries"

-- Create the directory if it doesn't exist
vim.fn.mkdir(queries_dir, "p")

-- List of query files to copy
local query_files = {
    "highlights.scm",
    "injections.scm",
    "locals.scm",
    "folds.scm",
    "indents.scm"
}

-- Copy each file
for _, file in ipairs(query_files) do
    local source = source_dir .. "/" .. file
    local dest = queries_dir .. "/" .. file
    
    -- Read source file
    local source_file = io.open(source, "r")
    if source_file then
        local content = source_file:read("*a")
        source_file:close()
        
        -- Write to destination
        local dest_file = io.open(dest, "w")
        if dest_file then
            dest_file:write(content)
            dest_file:close()
            print("Copied " .. file .. " to " .. dest)
        else
            print("Error: Could not write to " .. dest)
        end
    else
        print("Error: Could not read " .. source)
    end
end

print("Bruno queries setup complete!")
