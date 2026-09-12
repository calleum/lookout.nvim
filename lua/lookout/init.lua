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
	},
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

--- Apply git hunks to the current buffer as virtual lines and highlights
---@param buf number
---@param hunks table[]
---@param mode string "additions" or "removals"
function M.apply_hunks(buf, hunks, mode)
	render.clear(buf)

	local virt_hl_group = mode == "additions" and M.config.additions.hl_group or M.config.removals.hl_group
	local virt_prefix = mode == "additions" and M.config.additions.prefix or M.config.removals.prefix

	for _, hunk in ipairs(hunks) do
		local current_line = mode == "additions" and (hunk.old_start - 1) or (hunk.new_start - 1)
		local pending_lines = {}

		for _, diff_line in ipairs(hunk.lines) do
			if mode == "additions" then
				if diff_line.type == "add" then
					table.insert(pending_lines, diff_line.text)
				else
					if #pending_lines > 0 then
						render.show_virtual_lines(buf, current_line, pending_lines, true, virt_hl_group, virt_prefix)
						pending_lines = {}
					end

					if diff_line.type == "remove" then
						-- This physical line was removed in the incoming branch, highlight it red!
						render.highlight_line(buf, current_line, M.config.removals.hl_group)
						current_line = current_line + 1
					elseif diff_line.type == "context" then
						current_line = current_line + 1
					end
				end
			else -- mode == "removals"
				if diff_line.type == "remove" then
					table.insert(pending_lines, diff_line.text)
				else
					if #pending_lines > 0 then
						render.show_virtual_lines(buf, current_line, pending_lines, true, virt_hl_group, virt_prefix)
						pending_lines = {}
					end

					if diff_line.type == "add" then
						-- This physical line was added locally, highlight it green!
						render.highlight_line(buf, current_line, M.config.additions.hl_group)
						current_line = current_line + 1
					elseif diff_line.type == "context" then
						current_line = current_line + 1
					end
				end
			end
		end

		if #pending_lines > 0 then
			render.show_virtual_lines(buf, current_line - 1, pending_lines, false, virt_hl_group, virt_prefix)
		end
	end
end

--- Run git diff to review local changes
---@param revision string|nil
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

--- Run git diff to see incoming changes
---@param revision string
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
