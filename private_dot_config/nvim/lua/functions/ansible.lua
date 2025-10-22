local M = {}

function M.encrypt_value_with_vault()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if #lines == 0 then
    vim.notify("Buffer is empty", vim.log.levels.WARN)
    return
  end

  local key, value, line_num, indent = nil, nil, nil, ""

  for i, line in ipairs(lines) do
    local ind, k, v = line:match("^(%s*)([%w_]+):%s*(.+)$")
    if k and v then
      if v:match("^!vault") then
        vim.notify("Value is already encrypted", vim.log.levels.WARN)
        return
      end
      key, value, line_num, indent = k, v, i, ind or ""
      break
    end
  end

  if not key or not value then
    vim.notify("No key-value pair found in buffer", vim.log.levels.ERROR)
    return
  end

  local vault_password_file = vim.fn.getenv("ANSIBLE_VAULT_PASSWORD_FILE")
  local temp_password = nil
  local should_delete_temp = false

  if vault_password_file and vault_password_file ~= "" and vim.fn.filereadable(vault_password_file) == 1 then
    temp_password = vault_password_file
  else
    vim.fn.inputsave()
    local password = vim.fn.inputsecret("Vault password: ")
    vim.fn.inputrestore()

    if not password or #password == 0 then
      vim.notify("Password required for encryption", vim.log.levels.ERROR)
      return
    end

    temp_password = vim.fn.tempname()
    should_delete_temp = true
    local password_file = io.open(temp_password, "w")
    if not password_file then
      vim.notify("Failed to create password file", vim.log.levels.ERROR)
      return
    end
    password_file:write(password)
    password_file:close()
  end

  local cmd = string.format(
    "echo '%s' | ansible-vault encrypt_string --vault-password-file=%s --encrypt-vault-id=default --stdin-name='%s'",
    value:gsub("'", "'\"'\"'"),
    temp_password,
    key
  )
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if should_delete_temp then
    vim.fn.delete(temp_password)
  end

  if exit_code ~= 0 then
    vim.notify("ansible-vault encrypt_string failed: " .. result, vim.log.levels.ERROR)
    return
  end

  local encrypted_lines = vim.split(result, "\n")
  local vault_lines = {}

  for _, line in ipairs(encrypted_lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed and trimmed ~= "" then
      table.insert(vault_lines, trimmed)
    end
  end

  if #vault_lines == 0 then
    vim.notify("Failed to parse encrypted output", vim.log.levels.ERROR)
    return
  end

  local new_lines = {}
  for i, line in ipairs(lines) do
    if i == line_num then
      -- First line: key: !vault |
      table.insert(new_lines, indent .. key .. ": !vault |")
      -- Subsequent lines: indented vault content
      for j, vault_line in ipairs(vault_lines) do
        -- Skip the first line if it contains the key (ansible-vault output format)
        if not (j == 1 and vault_line:match("^" .. key .. ":")) then
          table.insert(new_lines, indent .. "  " .. vault_line)
        end
      end
    else
      table.insert(new_lines, line)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
  vim.api.nvim_buf_set_option(bufnr, "modified", true)

  vim.notify("Value encrypted with ansible-vault", vim.log.levels.INFO)
end

function M.decrypt_value_with_vault()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if #lines == 0 then
    vim.notify("Buffer is empty", vim.log.levels.WARN)
    return
  end

  local vault_entries = {}
  local current_entry = nil

  for i, line in ipairs(lines) do
    local k = line:match("^([%w_]+):%s*!vault%s*|%s*$")
    if k then
      if current_entry then
        table.insert(vault_entries, current_entry)
      end
      current_entry = {
        key = k,
        start_line = i,
        end_line = i,
        vault_lines = {},
      }
    elseif current_entry then
      if line:match("^%s*%$ANSIBLE_VAULT") then
        table.insert(current_entry.vault_lines, line:match("^%s*(.*)"))
        current_entry.end_line = i
      elseif line:match("^%s*%x+%s*$") then
        table.insert(current_entry.vault_lines, line:match("^%s*(.*)"))
        current_entry.end_line = i
      elseif line:match("^%s*$") then
        table.insert(vault_entries, current_entry)
        current_entry = nil
      elseif not line:match("^%s+") then
        table.insert(vault_entries, current_entry)
        current_entry = nil
      end
    end
  end

  if current_entry then
    table.insert(vault_entries, current_entry)
  end

  if #vault_entries == 0 then
    vim.notify("No encrypted vault values found", vim.log.levels.ERROR)
    return
  end

  local vault_password_file = vim.fn.getenv("ANSIBLE_VAULT_PASSWORD_FILE")
  local temp_password = nil
  local should_delete_temp = false

  if vault_password_file and vault_password_file ~= "" and vim.fn.filereadable(vault_password_file) == 1 then
    temp_password = vault_password_file
  else
    vim.fn.inputsave()
    local password = vim.fn.inputsecret("Vault password: ")
    vim.fn.inputrestore()

    if not password or #password == 0 then
      vim.notify("Password required for decryption", vim.log.levels.ERROR)
      return
    end

    temp_password = vim.fn.tempname()
    should_delete_temp = true
    local password_file = io.open(temp_password, "w")
    if not password_file then
      vim.notify("Failed to create password file", vim.log.levels.ERROR)
      return
    end
    password_file:write(password)
    password_file:close()
  end

  local decrypted_entries = {}
  local failed_entries = {}

  for _, entry in ipairs(vault_entries) do
    local temp_file = vim.fn.tempname()
    local vault_content = table.concat(entry.vault_lines, "\n")

    local file = io.open(temp_file, "w")
    if not file then
      table.insert(failed_entries, entry.key)
      goto continue
    end
    file:write(vault_content)
    file:close()

    local cmd = string.format("ansible-vault decrypt --vault-password-file=%s --output=- %s", temp_password, temp_file)
    local result = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error

    vim.fn.delete(temp_file)

    if exit_code == 0 then
      local decrypted_value = result:gsub("\n+$", ""):gsub("\n", " ")
      entry.decrypted_value = decrypted_value
      table.insert(decrypted_entries, entry)
    else
      table.insert(failed_entries, entry.key)
    end

    ::continue::
  end

  if should_delete_temp then
    vim.fn.delete(temp_password)
  end

  if #decrypted_entries == 0 then
    vim.notify("Failed to decrypt any vault values", vim.log.levels.ERROR)
    return
  end

  table.sort(decrypted_entries, function(a, b)
    return a.start_line > b.start_line
  end)

  local new_lines = vim.deepcopy(lines)

  for _, entry in ipairs(decrypted_entries) do
    local replacement = entry.key .. ": " .. entry.decrypted_value

    for i = entry.end_line, entry.start_line, -1 do
      table.remove(new_lines, i)
    end
    table.insert(new_lines, entry.start_line, replacement)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
  vim.api.nvim_buf_set_option(bufnr, "modified", true)

  local success_count = #decrypted_entries
  local fail_count = #failed_entries

  if fail_count > 0 then
    vim.notify(
      string.format(
        "Decrypted %d vault values, failed %d: %s",
        success_count,
        fail_count,
        table.concat(failed_entries, ", ")
      ),
      vim.log.levels.WARN
    )
  else
    vim.notify(string.format("Successfully decrypted %d vault values", success_count), vim.log.levels.INFO)
  end
end

return M
