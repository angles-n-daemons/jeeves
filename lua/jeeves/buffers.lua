local Buffers = {}
Buffers.__index = Buffers

--- Creates a new Highlighter.
--- @param ns_name (optional) a string for the namespace name; defaults to "jeeves_highlighter"
function Buffers:new(ns_name)
	local self = setmetatable({}, Buffers)
	self.ns = vim.api.nvim_create_namespace(ns_name or "jeeves")
	return self
end

--- Highlights a range in a buffer.
--- Assumes that the provided range is a table {start_line, end_line} in 1-indexed numbers.
--- In Neovim, extmark rows are 0-indexed and the end_line is exclusive.
--- @param buf number: the buffer number.
--- @param range table: a table {start_line, end_line} (e.g. {1, 5} to highlight lines 1–5).
--- @param jeeves_id (optional) an identifier for the selection (could be stored in opts if needed).
--- @return number: the extmark id.
function Buffers:highlight_range(buf, range)
	local start_line = range[1] - 1
	local end_line = range[2]
	local opts = {
		end_line = end_line,
		hl_group = "todo",
	}
	local extmark_id = vim.api.nvim_buf_set_extmark(buf, self.ns, start_line, 0, opts)
	return extmark_id
end

-- Gets the visual selection range.
-- @return table: the start and end line.
function Buffers:get_visual_line_range()
	local start_pos  = vim.fn.getpos("'<")
	local end_pos    = vim.fn.getpos("'>")

	local start_line = start_pos[2]
	local end_line   = end_pos[2]

	return { start_line, end_line }
end

--- Retrieves all extmarks at the current cursor position.
-- @return table: a list of extmark ids.
function Buffers:get_extmarks_in_buffer()
	return vim.api.nvim_buf_get_extmarks(0, self.ns, 0, -1, { details = true })
end

--- Retrieves all extmarks for the current buffer.
-- @return table: a list of extmark ids.
function Buffers:get_extmarks_at_cursor()
	-- Get the current cursor position (note: row is 0-indexed)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_row = cursor_pos[1] - 1

	local extmarks = self:get_extmarks_in_buffer()

	local found_marks = {}
	for _, mark in ipairs(extmarks) do
		local id = mark[1]
		local start_row = mark[2]
		local end_row = mark[4].end_row

		if Buffers.is_cursor_inside_extmark(cursor_row, start_row, end_row) then
			table.insert(found_marks, id)
		end
	end

	return found_marks
end

-- Helper function to check if the cursor is within the extmark range.
-- @param cursor_row number: the cursor row (0-indexed).
-- @param start_row number: the start row of the extmark (0-indexed).
-- @param end_row number: the end row of the extmark (0-indexed).
-- @return boolean: true if the cursor is inside the extmark, false otherwise.
function Buffers.is_cursor_inside_extmark(cursor_row,
					  start_row,
					  end_row)
	if cursor_row >= start_row and cursor_row < end_row then
		return true
	end

	return false
end

--- Removes an extmark from a buffer.
-- @param buf number: the buffer number.
-- @param extmark_id number: the extmark id.
function Buffers:remove_extmark(buf, extmark_id)
	vim.api.nvim_buf_del_extmark(buf, self.ns, extmark_id)
end

--- Clears all extmarks created by this Highlighter in all buffers.
function Buffers:clear_all_buffers()
	-- Get a list of all buffers.
	local buffers = vim.api.nvim_list_bufs()
	for _, buf in ipairs(buffers) do
		-- Only clear buffers that are currently loaded.
		if vim.api.nvim_buf_is_loaded(buf) then
			-- Clear the namespace from the entire buffer (from line 0 to the end).
			vim.api.nvim_buf_clear_namespace(buf, self.ns, 0, -1)
		end
	end
end

return Buffers
