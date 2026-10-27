local git_worktree = require('git-worktree')
local Git = require('git-worktree.git')
local Snacks = require('snacks')
local uv = vim.uv or vim.loop

local force_next_deletion = false

---@module "snacks-worktree"
local snacks_worktree = {}

-- Switch to the selected worktree
-- @param picker Snacks.picker
-- @param item Snacks.picker.Item
-- @return nil
local switch_worktree = function(picker, item)
    local worktree_path = item.path
    if worktree_path == nil then
        vim.print('no worktree selected')
    end

    picker:close()
    git_worktree.switch_worktree(worktree_path)
end

-- Toggle the forced deletion of the next worktree
-- @return nil
local toggle_forced_deletion = function()
    -- redraw otherwise the message is not displayed when in insert mode
    if force_next_deletion then
        print('The next deletion will not be forced')
        vim.fn.execute('redraw')
    else
        print('The next deletion will be forced')
        vim.fn.execute('redraw')
        force_next_deletion = true
    end
end

-- Confirm the deletion of a worktree
-- @param item snacks.picker.Item
-- @param proceed fun(val: string)
-- @return nil
local confirm_worktree_deletion = function(item, proceed)
    local prompt = 'Delete worktree %q?'
    if force_next_deletion then
        prompt = 'Force deletion of worktree %q?'
    end
    Snacks.picker.select({ 'Yes', 'No' }, { prompt = (prompt):format(item.path) }, function(_, idx)
        if idx ~= 1 then
            print("Didn't delete worktree")
            return
        end
        proceed()
    end)
end

-- Confirm the deletion of a branch
-- @return boolean: whether the deletion is confirmed
local confirm_branch_deletion = function()
    local confirmed = vim.fn.input('Worktree deleted, now force deletion of branch? [y/n]: ')

    if string.sub(string.lower(confirmed), 0, 1) == 'y' then
        return true
    end

    print("Didn't delete branch")
    return false
end

local delete_success_handler = function(opts)
    opts = opts or {}
    force_next_deletion = false
    if opts.branch ~= nil and opts.branch ~= 'HEAD' and confirm_branch_deletion() then
        local delete_branch_job = Git.delete_branch_job(opts.branch)
        if delete_branch_job ~= nil then
            delete_branch_job:after_success(vim.schedule_wrap(function()
                print('Branch deleted')
            end))
            delete_branch_job:start()
        end
    end
end

-- Handler for failed deletion
-- @return nil
local delete_failure_handler = function()
    print('Deletion failed, use <C-f> to force the next deletion')
end

-- Delete the selected worktree
-- @param picker Snacks.picker
-- @param item Snacks.picker.Item
-- @return nil
local delete_worktree = function(picker, item)
    if not item then
        Snacks.notify.warn('No worktree to delete', { title = 'Snacks Picker' })
    end
    confirm_worktree_deletion(item, function()
        local worktree_path = item.path
        picker:close()
        if worktree_path ~= nil then
            git_worktree.delete_worktree(worktree_path, force_next_deletion, {
                on_failure = delete_failure_handler,
                on_success = delete_success_handler,
            })
        end
    end)
end

-- Create a prompt to get the path of the new worktree (for existing branch)
-- @param cb fun(path: string): the callback to call with the path
-- @return nil
local create_input_prompt = function(cb)
    vim.ui.input({
        prompt = 'Path to subtree',
    }, function(path)
        if not path or path == '' then
            cb(nil)
            return
        end
        cb(path)
    end)
end

-- Get existing worktrees mapped by branch
-- @return table: mapping of branch names to true
local function get_existing_worktrees()
    local existing_worktrees = {}
    local git_root = Git.toplevel_dir()
    if git_root then
        local handle = io.popen('cd "' .. git_root .. '" && git worktree list --porcelain')
        if handle then
            for line in handle:lines() do
                local path, branch_info = line:match('([^\t]+)\t(.*)')
                if path and branch_info then
                    local branch = branch_info:match('branch ([^\n]+)')
                    if branch then
                        existing_worktrees[branch] = true
                    end
                end
            end
            handle:close()
        end
    end
    return existing_worktrees
end

function snacks_worktree.create_worktree()
    Snacks.picker {
        all = false,
        finder = 'git_branches',
        format = function(item, _)
            local a = Snacks.picker.util.align
            local ret = {} ---@type snacks.picker.Highlight[]

            -- Get existing worktrees to show which branches are already in use
            local existing_worktrees = get_existing_worktrees()

            -- Mark branch as existing if it's already in a worktree
            local marker = existing_worktrees[item.branch] and '✓' or ' '
            local marker_hl = existing_worktrees[item.branch] and 'SnacksPickerGitBranchCurrent' or 'Normal'

            ret[#ret + 1] = { a(marker, 2), marker_hl }
            ret[#ret + 1] = { a(item.branch, 30, { truncate = true }), 'SnacksPickerGitBranch' }
            ret[#ret + 1] = { ' ' }
            ret[#ret + 1] = { a(item.ref, 10, { truncate = true }), 'SnacksPickerGitCommit' }
            return ret
        end,
        preview = 'git_log',
        confirm = function(picker, item)
            if not item then
                print('No item provided')
            end
            local branch = item.branch
            picker:close()

            -- Check if worktree already exists for this branch
            local existing_worktrees = get_existing_worktrees()
            if existing_worktrees[branch] then
                Snacks.notify.warn('Worktree already exists for branch: ' .. branch, { title = 'Worktree' })
                return
            end

            create_input_prompt(function(name)
                if not name or name == '' then
                    name = branch
                end

                -- Check if the worktree path already exists in the branches directory
                local git_root = Git.toplevel_dir()
                if git_root then
                    local branches_dir = git_root .. '/branches'
                    local worktree_path = branches_dir .. '/' .. name

                    local stat = uv.fs_stat(worktree_path)
                    if stat and stat.type == 'directory' then
                        Snacks.notify.warn('Worktree path already exists: ' .. worktree_path, { title = 'Worktree' })
                        return
                    end
                end

                git_worktree.create_worktree(name, branch, nil)
            end)
        end,
    }
end

-- Get conventional commit prefix via selection
-- @param cb fun(prefix: string|nil): callback with selected prefix or nil if cancelled
-- @return nil
local function select_commit_prefix(cb)
    local prefixes = { 'feat', 'fix', 'chore', 'docs', 'style', 'refactor', 'perf', 'test', 'poc' }

    Snacks.picker.select(prefixes, {
        prompt = 'Select conventional commit prefix (or ESC to skip)',
    }, function(choice)
        cb(choice)
    end)
end

function snacks_worktree.create_new_worktree()
    -- First, select the prefix
    select_commit_prefix(function(prefix)
        if prefix == nil then
            Snacks.notify.info('Cancelled', { title = 'Create Worktree' })
            return
        end

        -- Then prompt for branch name
        vim.ui.input({
            prompt = 'New branch name (will be used as worktree path)',
        }, function(branch)
            if not branch or branch == '' then
                Snacks.notify.info('Cancelled', { title = 'Create Worktree' })
                return
            end

            -- Check if the worktree path already exists
            local git_root = Git.toplevel_dir()
            if git_root then
                local branches_dir = git_root .. '/branches'
                local prefixed_branch = prefix .. '/' .. branch
                local worktree_path = branches_dir .. '/' .. prefixed_branch

                local stat = uv.fs_stat(worktree_path)
                if stat and stat.type == 'directory' then
                    Snacks.notify.warn('Worktree path already exists: ' .. worktree_path, { title = 'Create Worktree' })
                    return
                end
            end

            git_worktree.create_worktree(branch, branch, nil, nil, prefix)
        end)
    end)
end

function snacks_worktree.create_from_jira()
    -- First, select the prefix
    select_commit_prefix(function(prefix)
        if prefix == nil then
            Snacks.notify.info('Cancelled', { title = 'Create Worktree from JIRA' })
            return
        end

        -- Then prompt for JIRA issue key
        vim.ui.input({
            prompt = 'JIRA issue key (e.g., PROJ-123)',
        }, function(jira_issue)
            if not jira_issue or jira_issue == '' then
                Snacks.notify.info('Cancelled', { title = 'Create Worktree from JIRA' })
                return
            end

            -- Create worktree with JIRA issue - branch name will be derived from JIRA
            -- The create function will fetch the JIRA summary and use it to generate branch/path names
            git_worktree.create_worktree(jira_issue, jira_issue, nil, jira_issue, prefix)
        end)
    end)
end

local finder = function(opts, ctx)
    local args = { 'worktree', 'list' }
    local cwd = vim.fs.normalize(opts and opts.cwd or uv.cwd() or '.') or nil
    cwd = Snacks.git.get_root(cwd)
    local current = Git.toplevel_dir()

    -- Merge options with proc-specific config
    local proc_opts = vim.tbl_extend('force', opts or {}, {
        cwd = cwd,
        cmd = 'git',
        args = args,
        ---@param item snacks.picker.finder.Item
        transform = function(item)
            item.cwd = cwd
            local fields = vim.split(string.gsub(item.text, '%s+', ' '), ' ')
            item.path = fields[1]
            item.current = current == item.path
            item.sha = fields[2]
            item.branch = fields[3]
            if item.sha == '(bare)' then
                return false
            end
        end,
    })

    return require('snacks.picker.source.proc').proc(proc_opts, ctx)
end

local format = function(item, _)
    local a = Snacks.picker.util.align
    local ret = {} ---@type snacks.picker.Highlight[]
    if item.current then
        ret[#ret + 1] = { a('', 2), 'SnacksPickerGitBranchCurrent' }
    else
        ret[#ret + 1] = { a('', 2) }
    end
    ret[#ret + 1] = { a(item.branch, 30, { truncate = true }), 'SnacksPickerGitBranch' }
    ret[#ret + 1] = { a(item.sha, 8, { truncate = true }), 'SnacksPickerGitCommit' }
    ret[#ret + 1] = { ' ' }
    ret[#ret + 1] = { a(item.path, 100, { truncate = true }), 'SnacksPickerDirectory' }
    return ret
end

function snacks_worktree.pick_git_worktree()
    if not Snacks then
        return
    end
    local config = {
        all = false,
        preview = 'none',
        finder = finder,
        format = format,
        layout = {
            preview = false,
        },
        confirm = switch_worktree,
        actions = {
            delete_worktree = delete_worktree,
            toggle_forced_deletion = toggle_forced_deletion,
        },
        win = {
            input = {
                keys = {
                    ['<c-d>'] = { 'delete_worktree', mode = { 'n', 'i' } },
                    ['<c-f>'] = { 'toggle_forced_deletion', mode = { 'n', 'i' } },
                },
            },
        },
        ---@param picker snacks.Picker
        on_show = function(picker)
            for i, item in ipairs(picker:items()) do
                if item.current then
                    picker.list:view(i)
                    Snacks.picker.actions.list_scroll_center(picker)
                    break
                end
            end
        end,
    }

    Snacks.picker.pick(config)
end

return snacks_worktree
