# lookout.nvim

Git diffs as virtual text in the buffer.

## Requirements

- Neovim 0.8+ (0.10+ for async diffs via `vim.system`)
- git

## Installation

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "calleum/lookout.nvim",
  opts = {},
}
```

No keymaps are set for you.

## Usage

Two commands. Both operate on the current buffer's file.

`LookoutReview [revision]`

Shows your local changes against a revision.

Deleted lines appear as virtual text where they used to be, highlighted red.

Added lines are highlighted green in place. Defaults to `HEAD`.

```
:LookoutReview
:LookoutReview main
```

`LookoutIncoming {revision}`

The reverse: shows what another branch would change to this file.

Added lines appear as virtual text, highlighted green.

Lines the branch deletes are highlighted red in place.

```
:LookoutIncoming main
```

Both commands take a branch, tag, or any git revision.

Completion is wired up: `<Tab>` gives you local branches plus `HEAD`.

`LookoutClear`

Removes all virtual text and highlights from the current buffer.

## Configuration

Nothing is required. Pass a table to `setup` (or `opts` in lazy.nvim) to change the highlight groups and prefixes used for virtual lines:

```lua
{
  "calleum/lookout.nvim",
  opts = {
    additions = {
      hl_group = "DiffAdd", -- highlight for added lines
      prefix = "+ ",        -- prefix on virtual text lines
    },
    removals = {
      hl_group = "DiffDelete", -- highlight for removed lines
      prefix = "- ",
    },
  },
}
```

The defaults are the standard diff highlight groups, so it matches your colorscheme without any setup.

## How it works

`git diff` runs for the current file, the unified diff is parsed into hunks, and the hunks are rendered as extmarks: `virt_lines` for lines that do not exist in the buffer, line highlights for lines that do.
Each render clears the previous one, so the buffer always shows exactly one diff.
