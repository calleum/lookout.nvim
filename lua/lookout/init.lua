local render = require("lookout.render")
local git = require("lookout.git")

local M = {}

M.config = {
  additions = {
    hl_group = "DiffAdd",
    prefix = "+ ",
  },
  removals = {
    hl_group = "DiffDelete",
    prefix = "- ",
  }
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

--- Apply git hunks to the current buffer as virtual lines
---@param buf number
---@param hunks table[]
---@param mode string "additions" or "removals"
function M.apply_hunks(buf, hunks, mode)
  render.clear(buf)
  
  local hl_group = mode == "additions" and M.config.additions.hl_group or M.config.removals.hl_group
  local prefix = mode == "additions" and M.config.additions.prefix or M.config.removals.prefix

  for _, hunk in ipairs(hunks) do
    -- If applying additions (e.g. diffing against future state), buffer is the OLD state.
    -- If applying removals (e.g. diffing against past state), buffer is the NEW state.
    local current_line = mode == "additions" and (hunk.old_start - 1) or (hunk.new_start - 1)
    local pending_lines = {}

    for _, diff_line in ipairs(hunk.lines) do
      if mode == "additions" then
        if diff_line.type == "add" then
          table.insert(pending_lines, diff_line.text)
        else
          if #pending_lines > 0 then
            render.show_virtual_lines(buf, current_line, pending_lines, true, hl_group, prefix)
            pending_lines = {}
          end
          if diff_line.type == "context" or diff_line.type == "remove" then
            current_line = current_line + 1
          end
        end
      else -- mode == "removals"
        if diff_line.type == "remove" then
          table.insert(pending_lines, diff_line.text)
        else
          if #pending_lines > 0 then
            render.show_virtual_lines(buf, current_line, pending_lines, true, hl_group, prefix)
            pending_lines = {}
          end
          if diff_line.type == "context" or diff_line.type == "add" then
            current_line = current_line + 1
          end
        end
      end
    end

    if #pending_lines > 0 then
      render.show_virtual_lines(buf, current_line - 1, pending_lines, false, hl_group, prefix)
    end
  end
end

--- Run git diff to review local changes (shows removals as virtual text)
---@param revision string|nil Git revision to compare against (defaults to HEAD)
function M.review_diff(revision)
  local buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(buf)

  if file_path == "" then
    vim.notify("Buffer has no file name", vim.log.levels.ERROR)
    return
  end

  git.get_file_diff({ revision or "HEAD" }, file_path, function(hunks)
    M.apply_hunks(buf, hunks, "removals")
  end)
end

--- Run git diff to see incoming changes from another branch (shows additions as virtual text)
---@param revision string The incoming branch/revision
function M.incoming_diff(revision)
  local buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(buf)

  if file_path == "" then
    vim.notify("Buffer has no file name", vim.log.levels.ERROR)
    return
  end
  
  if not revision or revision == "" then
    vim.notify("LookoutIncoming requires a target revision", vim.log.levels.ERROR)
    return
  end

  git.get_file_diff({ "HEAD.." .. revision }, file_path, function(hunks)
    M.apply_hunks(buf, hunks, "additions")
  end)
end

return M
