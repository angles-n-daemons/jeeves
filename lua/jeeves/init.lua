local Store = require('jeeves.store')
local Buffers = require('jeeves.buffers')
local files = require('jeeves.files')

-- Add autocmds for opening and closing buffers

local M = { store = Store:new(), buffers = Buffers:new() }

--- add_selection adds the buffer to the store and highlights it.
M.add_selection = function()
	-- toggle normal mode so that marks are set
	vim.cmd([[ execute "normal! \<ESC>" ]])
	local range = M.buffers:get_visual_line_range()
	local buf = vim.api.nvim_get_current_buf()
	local filename = vim.api.nvim_buf_get_name(0)
	local extmark = M.buffers:highlight_range(buf, range)
	M.store:add(filename, range, extmark)
end

--- remove_selections_under_cursor removes all selections under the cursor.
M.remove_selections_under_cursor = function()
	local extmarks = M.buffers:get_extmarks_at_cursor()
	for _, extmark in ipairs(extmarks) do
		local selection = M.store:get_by_extmark(extmark)
		if selection then
			M.store:remove_by_id(selection.id)
			M.buffers:remove_extmark(0, extmark)
		end
	end
end


--- collect_context collects all the selections in the store
-- and returns them as a string.
-- @return a string containing all the selections.
M.collect_context = function()
	-- update highlights
	local selections = M.store:get_all()
	local context = {}

	for _, selection in ipairs(selections) do
		table.insert(context, files.read_selection(selection))
	end

	return context
end

--- clear removes all selections from the store and clears the highlights.
M.clear = function()
	M.buffers:clear_all_buffers()
	M.store:clear()
end

-- Handles autocmd for buffer open.
M.buffer_open = function()
	local selections = M.store:get_by_filename(vim.api.nvim_buf_get_name(0))
	for _, selection in ipairs(selections) do
		local extmark_id = M.buffers:highlight_range(0, selection.range)
		M.store:update_extmark_by_id(selection.id, extmark_id)
	end
end

-- Handles autocmd for buffer close.
M.buffer_close = function()
	local extmarks = M.buffers:get_extmarks_in_buffer()
	for _, mark in ipairs(extmarks) do
		M.store:update_range_by_extmark(mark[1], { mark[2] + 1, mark[4].end_row })
		M.store:clear_extmark_by_extmark(mark[1])
	end
end

return M
