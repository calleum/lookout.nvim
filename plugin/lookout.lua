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
  if revision == "" then revision = nil end
  lookout.review_diff(revision)
end, { 
  nargs = "?", 
  desc = "Review local changes against revision (shows deleted lines as virtual text)",
  complete = "custom,v:lua.lookout_git_branch_complete"
})

vim.api.nvim_create_user_command("LookoutIncoming", function(opts)
  local revision = opts.args
  lookout.incoming_diff(revision)
end, { 
  nargs = 1, 
  desc = "View incoming additions from another branch (shows added lines as virtual text)",
  complete = "custom,v:lua.lookout_git_branch_complete"
})

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
