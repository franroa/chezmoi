local Path = require('plenary.path')

local Git = require('git-worktree.git')
local Log = require('git-worktree.logger')
local Hooks = require('git-worktree.hooks')
local Config = require('git-worktree.config')
local Jira = require('git-worktree.jira')

local function get_absolute_path(path, git_root)
    -- If branches_dir is configured and path is not absolute, prepend branches_dir
    -- Resolve relative to git_root, not current working directory
    if Config.branches_dir and not Path:new(path):is_absolute() then
        local branches_path = Path:new(git_root, Config.branches_dir, path):absolute()
        return branches_path
    elseif Path:new(path):is_absolute() then
        return path
    else
        return Path:new(git_root, path):absolute()
    end
end

local function change_dirs(path, git_root)
    Log.info('changing dirs:  %s ', path)
    local worktree_path = get_absolute_path(path, git_root)
    local previous_worktree = vim.loop.cwd()
    Config = require('git-worktree.config')

    -- vim.loop.chdir(worktree_path)
    if Path:new(worktree_path):exists() then
        local cmd = string.format('%s %s', Config.change_directory_command, worktree_path)
        Log.debug('Changing to directory  %s', worktree_path)
        vim.cmd(cmd)
    else
        Log.error('Could not change to directory: %s', worktree_path)
    end

    if Config.clearjumps_on_change then
        Log.debug('Clearing jumps')
        vim.cmd('clearjumps')
    end

    print(string.format('Switched to %s', path))
    return previous_worktree
end

local function failure(from, cmd, path, soft_error)
    return function(e)
        local error_message = string.format(
            '%s Failed: PATH %s CMD %s RES %s, ERR %s',
            from,
            path,
            vim.inspect(cmd),
            vim.inspect(e:result()),
            vim.inspect(e:stderr_result())
        )

        if soft_error then
            Log.error(error_message)
        else
            Log.error(error_message)
        end
    end
end

local M = {}

--- SWITCH ---

--Switch the current worktree
---@param path string?
function M.switch(path)
    if path == vim.loop.cwd() then
        return
    end
    
    local root = Git.gitroot_dir()
    if root == nil then
        Log.error('Could not determine git root directory')
        return
    end
    
    -- Resolve path with branches_dir if configured, relative to git root
    local absolute_path = get_absolute_path(path, root)
    
    Git.has_worktree(absolute_path, nil, root, function(found)
        if not found then
            Log.error('Worktree does not exists, please create it first %s ', path)
            return
        end

        vim.schedule(function()
            local prev_path = change_dirs(path, root)
            Hooks.emit(Hooks.type.SWITCH, path, prev_path)
        end)
    end)
end

--- CREATE ---

--create a worktree
---@param path string
---@param branch string
---@param upstream? string
---@param jira_issue? string
---@param prefix? string
function M.create(path, branch, upstream, jira_issue, prefix)
    local root = Git.gitroot_dir()
    if root == nil then
        Log.error('Could not determine git root directory')
        return
    end
    
    -- Resolve path with branches_dir if configured, relative to git root
    local absolute_path = get_absolute_path(path, root)
    
    local schedule = function(work_path, work_branch, found_branch, work_upstream, found_upstream)
        local create_wt_job =
            Git.create_worktree_job(work_path, work_branch, found_branch, work_upstream, found_upstream, root)
        create_wt_job:after_success(function()
            vim.schedule(function()
                Hooks.emit(Hooks.type.CREATE, path, branch, upstream)
                M.switch(path)
            end)
        end)
        create_wt_job:start()
    end

    local proceed_with_creation = function()
        Git.has_worktree(absolute_path, branch, root, function(found)
            if found then
                Log.error('Cannot create worktree: path "%s" or branch "%s" already exists.', path, branch)
                vim.notify(
                    string.format('Worktree at "%s" or branch "%s" already exists', path, branch),
                    vim.log.levels.WARN
                )
                return
            end

            if branch == '' then
                -- detached head
                schedule(absolute_path, nil, false, nil, false)
                return
            end

            if upstream == nil then
                Git.has_branch(branch, nil, root, function(found_branch)
                    schedule(absolute_path, branch, found_branch, nil, false)
                end)
                return
            end

            Git.has_branch(upstream, { '--all' }, root, function(found_upstream)
                if found_upstream and branch == upstream then
                    -- if a remote branch, default to `basename $branch` like git does
                    branch = branch:match('([^/]+)$')
                end
                Git.has_branch(branch, nil, root, function(found_branch)
                    if found_upstream and found_branch then
                        Log.error('Branch "%s" already exists', branch)
                        return
                    end
                    schedule(absolute_path, branch, found_branch, upstream, found_upstream)
                end)
            end)
        end)
    end

    -- Add prefix to path and branch if provided (but not for JIRA-derived names, which will be prefixed in JIRA section)
    if not jira_issue or jira_issue == '' then
        if prefix and prefix ~= '' then
            path = prefix .. '/' .. path
            branch = prefix .. '/' .. branch
            -- Recalculate absolute_path with the new prefixed path
            absolute_path = get_absolute_path(path, root)
        end
    end
    
    -- If JIRA issue is provided, fetch the summary and use it to generate branch/path names
     if jira_issue and jira_issue ~= '' then
         Log.info('Fetching JIRA issue information for: %s', jira_issue)
         vim.notify('Fetching JIRA issue information...', vim.log.levels.INFO)
         
         Jira.fetch_issue_info(jira_issue, function(issue_summary, error)
             if error then
                 Log.error('Failed to fetch JIRA issue: %s', error)
                 vim.notify('Failed to fetch JIRA issue: ' .. error, vim.log.levels.ERROR)
                 -- Continue without JIRA summary
                 proceed_with_creation()
                 return
             end
             
               if issue_summary then
                   -- If path equals jira_issue (from create_from_jira), use JIRA summary as path/branch
                   if path == jira_issue and branch == jira_issue then
                       -- Create branch/path from JIRA issue key and summary
                       path = jira_issue .. '_' .. issue_summary
                       branch = path
                       
                       -- Apply prefix if provided
                       if prefix and prefix ~= '' then
                           path = prefix .. '/' .. path
                           branch = prefix .. '/' .. branch
                       end
                       Log.info('Using JIRA-derived path/branch: %s', path)
                   else
                       -- Append JIRA issue key and summary to the existing path
                       path = path .. '/' .. jira_issue .. '_' .. issue_summary
                       Log.info('Using JIRA-enhanced path: %s', path)
                   end
                   vim.notify('Creating worktree: ' .. path, vim.log.levels.INFO)
                   -- Update the absolute_path for creation
                   absolute_path = get_absolute_path(path, root)
               end
              
              proceed_with_creation()
         end)
     else
         proceed_with_creation()
     end
end

--- DELETE ---

--Delete a worktree
---@param path string
---@param force boolean
---@param opts any
function M.delete(path, force, opts)
    if not opts then
        opts = {}
    end

    local root = Git.gitroot_dir()
    if root == nil then
        Log.error('Could not determine git root directory')
        return
    end

    -- Resolve path with branches_dir if configured, relative to git root
    local absolute_path = get_absolute_path(path, root)
    
    local branch = Git.parse_head(absolute_path)

    Git.has_worktree(absolute_path, nil, root, function(found)
        if not found then
            Log.error('Worktree %s does not exist', path)
            return
        end

        local delete = Git.delete_worktree_job(absolute_path, force, root)
        delete:after_success(vim.schedule_wrap(function()
            Log.info('delete after success')
            Hooks.emit(Hooks.type.DELETE, path)
            if opts.on_success then
                opts.on_success { branch = branch }
            end
        end))

        delete:after_failure(function(e)
            Log.info('delete after failure')
            -- callback has to be called before failure() because failure()
            -- halts code execution
            if opts.on_failure then
                opts.on_failure(e)
            end

            failure(delete.cmd, vim.loop.cwd())(e)
        end)
        Log.info('delete start job')
        delete:start()
    end)
end

return M
