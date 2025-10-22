local M = {}

function find_last_node_before_node_ancestor(parent_types, type_to_find, current_node, last_node_found)
  if not current_node then
    return nil
  end

  if vim.tbl_contains(type_to_find, current_node:type()) then
    last_node_found = current_node
  end

  if vim.tbl_contains(parent_types, current_node:type()) then
    return last_node_found
  end

  local parent = current_node:parent()

  return find_last_node_before_node_ancestor(parent_types, type_to_find, parent, last_node_found)
end

function M.apply_action(action, apply_on_target)
  local resource = nil

  if apply_on_target then
    local current_node = vim.treesitter.get_node({ ignore_injections = false })
    local terraform_resource = find_last_node_before_node_ancestor({ "config_file" }, { "block" }, current_node, nil)

    if not terraform_resource then
      return
    end

    -- local function_text = vim.treesitter.get_node_text(function_node, 0)
    -- if vim.startswith(function_text, "async ") then
    --   return
    -- end

    local raw_resource_type = vim.treesitter.get_node_text(terraform_resource:child(1), 0)
    local resource_type = raw_resource_type:gsub('^"', ""):gsub('"$', "")

    local raw_resource_name = vim.treesitter.get_node_text(terraform_resource:child(2), 0)
    local resource_name = raw_resource_name:gsub('^"', ""):gsub('"$', "")

    if not (vim.treesitter.get_node_text(terraform_resource:child(0), 0) == "resource") then
      vim.notify("Not a resource", vim.log.levels.WARN)
      return
    end

    resource = resource_type .. "." .. resource_name
  end

  require("overseer").run_template({
    name = "Taskfile Task",
    params = {
      region = vim.env.TSYL_REGION,
      tier = vim.env.TSYL_TIER,
      domain = vim.env.TSYL_DOMAIN,
      module = vim.env.TSYL_MODULE,
      action = action,
      target = resource,
    },
  }, function(task)
    if task then
      require("overseer").run_action(task, "open float")
    end
  end)
  -- require("overseer").run_template({ name = "Terraform Apply Target" }, function(task)
  --   if task then
  --     require("overseer").run_action(task, "open float")
  --   end
  -- end)
end

return M
