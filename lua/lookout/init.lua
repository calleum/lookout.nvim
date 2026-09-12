local render = require("lookout.render")
local git = require("lookout.git")

local M = {}

M.config = {
  highlight_group = "DiffAdd",
  prefix = "+ ",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

--- Apply git hunks to the current buffer as virtual lines
---@param buf number
---@param hunks table[]
function M.apply_hunks(buf, hunks)
  render.clear(buf)

  for _, hunk in ipairs(hunks) do
    local current_line = hunk.old_start - 1 -- 0-indexed, line we are matching against in the original file
    local pending_adds = {}

    for _, diff_line in ipairs(hunk.lines) do
      if diff_line.type == "add" then
        table.insert(pending_adds, diff_line.text)
      else
        -- When we hit a context or remove line, we attach any accumulated additions 
        -- ABOVE the line we are currently at in the buffer.
        if #pending_adds > 0 then
          render.show_virtual_lines(buf, current_line, pending_adds, true)
          pending_adds = {}
        end

        if diff_line.type == "context" or diff_line.type == "remove" then
          current_line = current_line + 1
        end
      end
    end

    -- If the hunk ends with additions, attach them below the last processed line
    if #pending_adds > 0 then
      render.show_virtual_lines(buf, current_line - 1, pending_adds, false)
    end
  end
end

--- Run git diff against a revision and apply virtual text
---@param revision string Git revision (e.g., 'main' or 'HEAD')
function M.review_diff(revision)
  local buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(buf)

  if file_path == "" then
    vim.notify("Buffer has no file name", vim.log.levels.ERROR)
    return
  end

  git.get_file_diff(revision, file_path, function(hunks)
    M.apply_hunks(buf, hunks)
  end)
end

return M
-- test modification
