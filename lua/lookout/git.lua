local M = {}

--- Parse unified git diff output into hunks
---@param output_lines string[]
---@return table[]
function M.parse_diff(output_lines)
  local hunks = {}
  local current_hunk = nil

  for _, line in ipairs(output_lines) do
    local old_start, old_count, new_start, new_count = line:match("@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
    
    if old_start then
      current_hunk = {
        old_start = tonumber(old_start),
        old_count = tonumber(old_count == "" and 1 or old_count),
        new_start = tonumber(new_start),
        new_count = tonumber(new_count == "" and 1 or new_count),
        lines = {}
      }
      table.insert(hunks, current_hunk)
    elseif current_hunk then
      local prefix = line:sub(1, 1)
      local content = line:sub(2)
      
      -- Only process diff lines, ignore headers (which don't start with space, +, or -)
      if prefix == " " then
        table.insert(current_hunk.lines, { type = "context", text = content })
      elseif prefix == "+" then
        table.insert(current_hunk.lines, { type = "add", text = content })
      elseif prefix == "-" then
        table.insert(current_hunk.lines, { type = "remove", text = content })
      end
    end
  end

  return hunks
end

--- Get diff for the current file against a target revision
---@param revision string Git revision (e.g., "HEAD", "main")
---@param file_path string Absolute path to the file
---@param callback function Called with the parsed hunks
function M.get_file_diff(revision, file_path, callback)
  -- Run git diff <revision> -- <file_path>
  local cmd = { "git", "diff", revision, "--", file_path }
  
  if vim.fn.has("nvim-0.10") == 1 then
    vim.system(cmd, { text = true }, function(obj)
      if obj.code == 0 or obj.code == 1 then
        local lines = vim.split(obj.stdout, "\n", { trimempty = true })
        local hunks = M.parse_diff(lines)
        vim.schedule(function()
          callback(hunks)
        end)
      else
        vim.schedule(function()
          vim.notify("Git diff failed: " .. (obj.stderr or ""), vim.log.levels.ERROR)
        end)
      end
    end)
  else
    -- Fallback for Neovim < 0.10
    local output = vim.fn.systemlist(cmd)
    if vim.v.shell_error == 0 or vim.v.shell_error == 1 then
      local hunks = M.parse_diff(output)
      callback(hunks)
    else
      vim.notify("Git diff failed", vim.log.levels.ERROR)
    end
  end
end

return M
