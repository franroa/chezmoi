## [2.0.1] - 2024-08-07

### Fix

- Telescope display error

## [2.0.0] - 2024-07-18

### Chore

- Mv test repo to spec dir
- Fix stylua
- Luachecks
- Add name to commit-lint
- Refactor tests to hopefully pass

### Ci

- Add commit-lint workflow
- Switch to vusted for testing
- Add plenary install
- Add test for switching normal repo
- Add windows-latest test
- Add busted test to nix check
- Add bused tests
- Add type-check
- Add style check
- Add dependabot.yml
- Add convential commit checker
- Add luarocks release

### Docs

- Initial readme update
- Update plugin help docs
- Update readme
- Update changelog

### Feat

- V2 refactor
- Add ability to run luarocks non nix

### Fix

- Add hook to update current buffer on switch

### Refactor

- Stylua fixes and start to build from core
- Config
- Lost code
- Basic switch working
- Create worktree
- Delete worktree
- Delete worktree
- Add back in telescope
- To plenary test and other
- Final rework

### Test

- Add git ops tests

## [1.0.0] - 2023-11-17

### Fix

- Typo in README.md

### Chore

- Renamed :w to wip.lua
- Removed file
- Nixify
- Create LICENSE

### Ci

- Add luarocks release uploader

### Feat

- *(delete)* Allowed for deleting the buffer
- *(worktree-swap)* Better swapping and sane defaults
- *(create)* If rebase fails, we don't stop the creation process
- *(switch)* Clear jumps on switch.  Can be configured
- *(status)* Added a status line printer
- *(readme)* Effectively correct
- *(on_tree_change)* Better interfacing with on_tree_change
- *(set_push)* Push so I can push with Git push

### Feta

- *(first-commit)* It "sorta" works.

### Fix

- *(indenting)* Tree shitter to the rescue
- *(status)* Status was 8 / 7 at some point.
- *(create_worktree)* Allows for worktree to also create the branch.
- Pass opts to git_worktrees
- Always return absolute git dir
- Merge mistake to prevent errors
- :Telescope git_worktree

