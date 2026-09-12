if vim.g.loaded_lookout then
  return
end
vim.g.loaded_lookout = true

local lookout = require("lookout")
local render = require("lookout.render")

vim.api.nvim_create_user_command("LookoutClear", function()
  render.clear(0)
end, { desc = "Clear all virtual diffs from lookout" })

vim.api.nvim_create_user_command("LookoutReview", function(opts)
  local revision = opts.args
  if revision == "" then
    revision = "HEAD" -- default to comparing against HEAD
  end
  lookout.review_diff(revision)
end, { 
  nargs = "?", 
  desc = "Fetch git diff against a revision (default HEAD) and render virtual lines",
  complete = "custom,v:lua.lookout_git_branch_complete" -- basic autocompletion could be added later
})

vim.api.nvim_create_user_command("LookoutDemo", function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1] - 1

  render.show_virtual_lines(0, current_line, {
    "function new_feature()",
    "  print('This code is purely virtual!')",
    "  print('Your LSP cannot see this, so it will not complain.')",
    "end"
  }, false)
end, { desc = "Show demo virtual diff lines at the cursor" })

-- Simple autocompletion for branches/refs
_G.lookout_git_branch_complete = function(ArgLead, CmdLine, CursorPos)
  local out = vim.fn.systemlist("git branch --format='%(refname:short)'")
  table.insert(out, "HEAD")
  local matches = {}
  for _, v in ipairs(out) do
    if v:find("^" .. vim.pesc(ArgLead)) then
      table.insert(matches, v)
    end
  end
  return matches
end
