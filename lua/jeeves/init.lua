local Store = require('jeeves.store')
local Highlighter = require('jeeves.highlighter')


-- Add autocmds for opening and closing buffers

local M = { store = Store:new(), highlighter = Highlighter:new() }

M.add_selection = function()
	vim.cmd([[ execute "normal! \<ESC>" ]])
	local range = M.highlighter:get_visual_line_range()
	local buf = vim.api.nvim_get_current_buf()
	local filename = vim.api.nvim_buf_get_name(0)
	local extmark = M.highlighter:highlight_range(buf, range)
	M.store:add(filename, range, extmark)
end

M.remove_selections_under_cursor = function()
	local extmarks = M.highlighter:get_extmarks_at_cursor()
	for _, extmark in ipairs(extmarks) do
		local selection = M.store:get_by_extmark(extmark)
		if selection then
			M.store:remove_by_id(selection.id)
			M.highlighter:remove_extmark(0, extmark)
		end
	end
end

M.collect_context = function()
end

M.clear = function()
	M.highlighter:clear_all_buffers()
	M.store:clear()
end

return M
