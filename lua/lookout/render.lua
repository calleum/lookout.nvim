local M = {}

local namespace = vim.api.nvim_create_namespace("lookout_diffs")

--- Show virtual lines in a buffer
---@param buf number Buffer handle
---@param line_num number 0-indexed line number where the virtual lines should be attached
---@param lines string[] List of strings representing the added lines
---@param is_above boolean Whether to place the lines above the specified line_num
---@param hl_group string Highlight group name
---@param prefix string Prefix string
function M.show_virtual_lines(buf, line_num, lines, is_above, hl_group, prefix)
  local virt_lines = {}
  
  for _, line in ipairs(lines) do
    table.insert(virt_lines, {
      { prefix, hl_group },
      { line, hl_group }
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
