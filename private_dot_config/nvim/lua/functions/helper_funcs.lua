function is_remote_file()
  local filepath = vim.fn.expand("%")
  return filepath:match("^[%w-]+://") ~= nil
end

function split_str(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

function contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function index_of(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end
  return nil
end

function join(table, separator)
  local joined_string = ""

  for _, table_section in pairs(table) do
    joined_string = joined_string .. separator .. table_section
  end

  return joined_string
end

function filter(unfiltered_table, filter_function)
  local filtered_table = {}
  for key, table_element in pairs(unfiltered_table) do
    local filter_result = filter_function(table_element)

    if filter_result ~= nil then
      table.insert(filtered_table, filter_result)
    end
  end

  return filtered_table
end

function copy_into(table, table_to_merge)
  table = table ~= nil and table or {}
  for k, v in pairs(table_to_merge) do
    if type(v) == "table" then
      table[k] = copy_into(table[k], v)
    else
      table[k] = v
    end
  end

  return table
end

function deep_map(table, callback)
  for k, v in pairs(table) do
    if type(v) == "table" then
      table[k] = deep_map(v, callback)
    else
      table[k] = callback(k, v)
    end
  end

  return table
end

function map(table, callback)
  for k, v in pairs(table) do
    table[k] = callback(k, v)
  end

  return table
end

function read_file(path)
  local open = io.open
  local file = open(path, "r") -- r read mode and b binary mode
  local content = file:read("*a") -- *a or *all reads the whole file
  file:close()
  return content
end

function string_to_table(str)
  local t = {}
  for i = 1, #str do
    t[i] = str:sub(i, i)
  end

  return t
end
