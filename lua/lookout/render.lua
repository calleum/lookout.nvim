local M = {}

local namespace = vim.api.nvim_create_namespace("lookout_diffs")

--- Show virtual lines in a buffer
---@param buf number Buffer handle
---@param line_num number 0-indexed line number where the virtual lines should be attached
---@param lines string[] List of strings representing the added lines
---@param is_above boolean Whether to place the lines above the specified line_num
function M.show_virtual_lines(buf, line_num, lines, is_above)
  local config = require("lookout").config
  local virt_lines = {}
  
  for _, line in ipairs(lines) do
    table.insert(virt_lines, {
      { config.prefix, config.highlight_group },
      { line, config.highlight_group }
    })
  end

  vim.api.nvim_buf_set_extmark(buf, namespace, line_num, 0, {
    virt_lines = virt_lines,
    virt_lines_above = is_above,
  })
end

--- Clear all virtual diff lines in a buffer
---@param buf number Buffer handle
function M.clear(buf)
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
end

return M
