local Store = {}
Store.__index = Store

-- Create a new selection store.
-- It maintains:
--   - self.selections: a table mapping unique id -> selection.
--   - self.extmark_to_id: mapping extmark -> id.
--   - self.file_index: mapping filename -> list of ids for quick lookups.
--   - self.counter: used to generate unique ids.
function Store:new()
	local self = setmetatable({}, Store)
	self.selections = {} -- [id] = { id, filename, range, extmark }
	self.extmark_to_id = {} -- [extmark] = id
	self.file_index = {} -- [filename] = { id1, id2, ... }
	self.counter = 0
	return self
end

--- Adds a new selection.
-- @param filename The filename associated with the selection.
-- @param range A table {start_line, end_line} defining the range.
-- @param extmark The extmark identifier (can be nil).
-- @return The unique id assigned to this selection.
function Store:add(filename, range, extmark)
	self.counter = self.counter + 1
	local id = self.counter
	local selection = {
		id = id,
		filename = filename,
		range = range,
		extmark = extmark,
	}
	self.selections[id] = selection

	-- Update the extmark mapping (if an extmark is provided)
	if extmark then
		self.extmark_to_id[extmark] = id
	end

	-- Update the file index.
	if not self.file_index[filename] then
		self.file_index[filename] = {}
	end
	table.insert(self.file_index[filename], id)

	return id
end

--- Removes a selection given its unique id.
-- @param id The unique identifier of the selection.
-- @return true on success, or false and an error message.
function Store:remove_by_id(id)
	local selection = self.selections[id]
	if not selection then
		return false, "Selection not found"
	end

	-- Remove the extmark mapping if an extmark exists.
	if selection.extmark then
		self.extmark_to_id[selection.extmark] = nil
	end

	-- Remove from the file index.
	local file_list = self.file_index[selection.filename]
	if file_list then
		for i, sel_id in ipairs(file_list) do
			if sel_id == id then
				table.remove(file_list, i)
				break
			end
		end
		if #file_list == 0 then
			self.file_index[selection.filename] = nil
		end
	end

	self.selections[id] = nil
	return true
end

--- Removes a selection given its extmark.
-- @param extmark The extmark associated with the selection.
-- @return true on success, or false and an error message.
function Store:remove_by_extmark(extmark)
	local id = self.extmark_to_id[extmark]
	if not id then
		return false, "No selection found with that extmark"
	end
	return self:remove_by_id(id)
end

--- Returns a list of all selections.
function Store:get_all()
	local all = {}
	for _, sel in pairs(self.selections) do
		table.insert(all, sel)
	end

	-- Returns elements sorted by filename and then by range.
	table.sort(all, function(a, b)
		if a.filename == b.filename then
			return a.range[1] < b.range[1]
		end
		return a.filename < b.filename
	end)

	return all
end

--- Retrieves a selection by its unique id.
-- @param id The unique id.
-- @return The selection table or nil if not found.
function Store:get_by_id(id)
	return self.selections[id]
end

--- Retrieves a selection by its extmark.
-- @param extmark The extmark identifier.
-- @return The selection table or nil if not found.
function Store:get_by_extmark(extmark)
	local id = self.extmark_to_id[extmark]
	if id then
		return self.selections[id]
	end
	return nil
end

--- Retrieves all selections for a given filename.
-- @param filename The filename to filter by.
-- @return A list of selection tables (or an empty list if none exist).
function Store:get_by_filename(filename)
	local ids = self.file_index[filename]
	if not ids then
		return {}
	end
	local selections = {}
	for _, id in ipairs(ids) do
		local sel = self.selections[id]
		if sel then
			table.insert(selections, sel)
		end
	end
	return selections
end

--- Updates the range for a selection identified by its unique id.
-- @param id The unique id.
-- @param new_range A table {start_line, end_line} with the new range.
-- @return true on success, or false and an error message.
function Store:update_range_by_extmark(extmark_id, new_range)
	local id = self.extmark_to_id[extmark_id]
	if not id then
		return false, "Extmark not found"
	end
	local selection = self.selections[id]
	if not selection then
		return false, "Selection not found"
	end
	selection.range = new_range
	return true
end

--- Clears (removes) the extmark from a selection identified by its unique id.
-- The selection remains in the store.
-- @param id The unique id.
-- @return true on success, or false and an error message.
function Store:clear_extmark_by_id(id)
	local selection = self.selections[id]
	if not selection then
		return false, "Selection not found"
	end
	if selection.extmark then
		self.extmark_to_id[selection.extmark] = nil
		selection.extmark = nil
	end
	return true
end

--- Clears the extmark from a selection identified by its extmark.
-- @param extmark The extmark identifier.
-- @return true on success, or false and an error message.
function Store:clear_extmark_by_extmark(extmark)
	local id = self.extmark_to_id[extmark]
	if not id then
		return false, "Selection not found for extmark"
	end
	return self:clear_extmark_by_id(id)
end

--- Updates the extmark of a selection by its id.
-- @param id The id of the selection to update.
-- @param new_extmark The new extmark to set for the selection.
-- @return boolean, string Returns true if the update is successful, or false and an error message if the selection is not found.
function Store:update_extmark_by_id(id, new_extmark)
	local selection = self.selections[id]
	if not selection then
		return false, "Selection not found"
	end

	-- Remove the old extmark to id mapping
	if selection.extmark then
		self.extmark_to_id[selection.extmark] = nil
	end

	-- Update the extmark
	selection.extmark = new_extmark

	-- Add the new extmark to id mapping
	self.extmark_to_id[new_extmark] = id

	return true
end

--- Clears all selections and resets the store.
function Store:clear()
	self.selections = {}
	self.extmark_to_id = {}
	self.file_index = {}
	self.counter = 0
end

return Store
