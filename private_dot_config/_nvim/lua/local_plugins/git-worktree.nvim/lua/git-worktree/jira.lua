---@mod git-worktree.jira JIRA integration
---
---@brief [[
--- JIRA integration module for git-worktree.nvim
--- Provides functionality to fetch JIRA issue information and format worktree names
---@brief ]]

local Job = require('plenary.job')
local Log = require('git-worktree.logger')
local Config = require('git-worktree.config')

---@class GitWorktreeJira
local M = {}

--- Format text to be used in branch/directory names
--- Replaces spaces and hyphens with underscores
---@param text string
---@return string
local function format_text(text)
    text = text:gsub(' ', '_')
    text = text:gsub('-', '_')
    return text
end

--- Get JIRA API token from environment or config
---@return string|nil
local function get_jira_token()
    return os.getenv('JIRA_API_TOKEN') or (Config.jira_token) or (vim.g.jira_config and vim.g.jira_config.api_token)
end

--- Get JIRA email from environment or config
---@return string|nil
local function get_jira_email()
    return os.getenv('JIRA_EMAIL') or (Config.jira_email) or (vim.g.jira_config and vim.g.jira_config.email) or os.getenv('USER') .. '@tecnosylva.com'
end

--- Get JIRA URL from environment or config
---@return string|nil
local function get_jira_url()
    return os.getenv('JIRA_URL') or (Config.jira_url) or (vim.g.jira_config and vim.g.jira_config.url)
end

--- Fetch JIRA issue information
---@param issue_key string The JIRA issue key (e.g., "PROJ-123")
---@param callback function Callback function that receives (issue_summary, error)
function M.fetch_issue_info(issue_key, callback)
    local token = get_jira_token()
    local email = get_jira_email()
    local jira_url = get_jira_url()

    if not token then
        Log.error('JIRA_API_TOKEN environment variable or jira_token config not set')
        callback(nil, 'JIRA_API_TOKEN not configured')
        return
    end

    if not jira_url then
        Log.error('JIRA_URL environment variable or jira_url config not set')
        callback(nil, 'JIRA_URL not configured')
        return
    end

    local auth = email .. ':' .. token
    local api_url = jira_url .. '/rest/api/2/issue/' .. issue_key .. '?fields=summary'

    Log.debug('Fetching JIRA issue: %s from %s', issue_key, api_url)

    local job = Job:new {
        command = 'curl',
        args = {
            '-u', auth,
            '-X', 'GET',
            '-H', 'Content-Type: application/json',
            api_url,
        },
        on_stderr = function(_, data)
            Log.debug('JIRA curl stderr: %s', data)
        end,
    }

    job:after(function(j, return_code)
        if return_code ~= 0 then
            local stderr = table.concat(j:stderr_result(), '\n')
            Log.error('JIRA API request failed: %s', stderr)
            callback(nil, 'Failed to fetch JIRA issue: ' .. stderr)
            return
        end

        local stdout = table.concat(j:result(), '')
        Log.debug('JIRA API response: %s', stdout)

        -- Parse JSON response using vim's json utilities
        local success, result = pcall(function()
            return vim.json.decode(stdout)
        end)

        if not success then
            Log.error('Failed to parse JIRA API response: %s', result)
            callback(nil, 'Failed to parse JIRA response')
            return
        end

        if result.errorMessages then
            local error_msg = table.concat(result.errorMessages, ', ')
            Log.error('JIRA API error: %s', error_msg)
            callback(nil, 'JIRA API error: ' .. error_msg)
            return
        end

        if not result.fields or not result.fields.summary then
            Log.error('No summary field in JIRA response')
            callback(nil, 'No summary found in JIRA issue')
            return
        end

        local summary = result.fields.summary
        Log.debug('JIRA issue summary: %s', summary)

        -- Format the summary to be suitable for branch/directory names
        local formatted_summary = format_text(summary)
        Log.debug('Formatted JIRA summary: %s', formatted_summary)

        callback(formatted_summary)
    end)

    job:start()
end

return M
