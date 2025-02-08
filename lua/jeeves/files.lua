local M = {}

M.read_selection = function(selection)
	local filename = selection.filename
	local range = selection.range
	local start_line = range[1]
	local end_line = range[2]

	local file = io.open(filename, "r")
	if file then
		local lines = { filename .. ":" .. start_line .. "-" .. end_line }
		for i = 1, end_line do
			local line = file:read("*line")
			if i >= start_line then
				table.insert(lines, line)
			end
		end
		file:close()
		return {
			filename = filename .. ":" .. start_line .. "-" .. end_line,
			content = table.concat(lines, "\n"),
			filetype = 'misc',
		}
	end
	error("Could not read file: " .. filename)
end

return M
