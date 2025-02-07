-- selection_store_spec.lua

local Store = require("lua.jeeves.store")

describe("Store", function()
	local store

	before_each(function()
		store = Store:new()
	end)

	---------------------------------------------------------------------------
	-- Adding Selections
	---------------------------------------------------------------------------
	describe("Adding Selections", function()
		it("should add a new selection and update mappings", function()
			local id = store:add("file1.txt", { 1, 5 }, "ext1")
			assert.is_number(id)

			local sel = store:get_by_id(id)
			assert.are.equal("file1.txt", sel.filename)
			assert.are.same({ 1, 5 }, sel.range)
			assert.are.equal("ext1", sel.extmark)

			local sel_by_ext = store:get_by_extmark("ext1")
			assert.is_not_nil(sel_by_ext)
			assert.are.equal(id, sel_by_ext.id)

			local fileSels = store:get_by_filename("file1.txt")
			assert.are.equal(1, #fileSels)
			assert.are.same(sel, fileSels[1])
		end)

		it("should assign incrementing unique ids", function()
			local id1 = store:add("file1.txt", { 1, 2 }, "ext1")
			local id2 = store:add("file1.txt", { 3, 4 }, "ext2")
			assert.is_true(id2 > id1)
		end)

		it("should handle nil extmark correctly", function()
			local id = store:add("file_nil.txt", { 1, 3 }, nil)
			local sel = store:get_by_id(id)
			assert.is_not_nil(sel)
			assert.is_nil(sel.extmark)
			local sel_by_ext = store:get_by_extmark(nil)
			assert.is_nil(sel_by_ext)
		end)
	end)

	---------------------------------------------------------------------------
	-- Retrieving Selections
	---------------------------------------------------------------------------
	describe("Retrieving Selections", function()
		it("should retrieve selection by id", function()
			local id = store:add("file2.txt", { 10, 20 }, "ext2")
			local sel = store:get_by_id(id)
			assert.is_not_nil(sel)
			assert.are.equal("file2.txt", sel.filename)
		end)

		it("should retrieve selection by extmark", function()
			local id = store:add("file2.txt", { 10, 20 }, "ext2")
			local sel = store:get_by_extmark("ext2")
			assert.is_not_nil(sel)
			assert.are.equal(id, sel.id)
		end)

		it("should return all selections", function()
			store:add("file3.txt", { 1, 1 }, "ext3")
			store:add("file4.txt", { 2, 2 }, "ext4")
			local all = store:get_all()
			assert.are.equal(2, #all)
		end)

		it("should retrieve selections by filename", function()
			local id1 = store:add("file5.txt", { 1, 3 }, "ext5")
			local id2 = store:add("file5.txt", { 4, 6 }, "ext6")
			local sels = store:get_by_filename("file5.txt")
			assert.are.equal(2, #sels)
			local found = {}
			for _, s in ipairs(sels) do
				found[s.id] = true
			end
			assert.is_true(found[id1])
			assert.is_true(found[id2])
		end)

		it("should return an empty list for non-existent filename", function()
			local sels = store:get_by_filename("nonexistent.txt")
			assert.is_table(sels)
			assert.are.equal(0, #sels)
		end)
	end)

	---------------------------------------------------------------------------
	-- Updating Selections
	---------------------------------------------------------------------------
	describe("Updating Selections", function()
		it("should update range by id", function()
			local id = store:add("file6.txt", { 5, 10 }, "ext6")
			local ok, err = store:update_range_by_id(id, { 7, 12 })
			assert.is_true(ok)

			local sel = store:get_by_id(id)
			assert.are.same({ 7, 12 }, sel.range)
		end)

		it("should return error when updating range for non-existent id", function()
			local ok, err = store:update_range_by_id(999, { 1, 2 })
			assert.is_false(ok)
			assert.are.equal("Selection not found", err)
		end)
	end)

	---------------------------------------------------------------------------
	-- Removing Selections
	---------------------------------------------------------------------------
	describe("Removing Selections", function()
		it("should remove selection by id", function()
			local id = store:add("file7.txt", { 1, 2 }, "ext7")
			local ok, err = store:remove_by_id(id)
			assert.is_true(ok)

			local sel = store:get_by_id(id)
			assert.is_nil(sel)
			sel = store:get_by_extmark("ext7")
			assert.is_nil(sel)
			local fileSels = store:get_by_filename("file7.txt")
			assert.are.equal(0, #fileSels)
		end)

		it("should remove selection by extmark", function()
			local id = store:add("file8.txt", { 3, 4 }, "ext8")
			local ok, err = store:remove_by_extmark("ext8")
			assert.is_true(ok)

			local sel = store:get_by_id(id)
			assert.is_nil(sel)
			sel = store:get_by_extmark("ext8")
			assert.is_nil(sel)
		end)

		it("should return error for removal with non-existent id", function()
			local ok, err = store:remove_by_id(1234)
			assert.is_false(ok)
			assert.are.equal("Selection not found", err)
		end)

		it("should return error for removal with non-existent extmark", function()
			local ok, err = store:remove_by_extmark("nonexistent_ext")
			assert.is_false(ok)
			assert.are.equal("No selection found with that extmark", err)
		end)

		it("should update the file index upon removal", function()
			local id1 = store:add("file9.txt", { 1, 2 }, "ext9")
			local id2 = store:add("file9.txt", { 3, 4 }, "ext10")
			local sels = store:get_by_filename("file9.txt")
			assert.are.equal(2, #sels)

			store:remove_by_id(id1)
			sels = store:get_by_filename("file9.txt")
			assert.are.equal(1, #sels)
			assert.are.equal(id2, sels[1].id)

			store:remove_by_id(id2)
			sels = store:get_by_filename("file9.txt")
			assert.are.equal(0, #sels)
		end)
	end)

	---------------------------------------------------------------------------
	-- Clearing Extmarks
	---------------------------------------------------------------------------
	describe("Clearing Extmarks", function()
		it("should clear extmark by id without removing selection", function()
			local id = store:add("file10.txt", { 1, 5 }, "ext10")
			local ok, err = store:clear_extmark_by_id(id)
			assert.is_true(ok)

			local sel = store:get_by_id(id)
			assert.is_not_nil(sel)
			assert.is_nil(sel.extmark)
			sel = store:get_by_extmark("ext10")
			assert.is_nil(sel)
		end)

		it("should clear extmark by extmark without removing selection", function()
			local id = store:add("file11.txt", { 2, 6 }, "ext11")
			local ok, err = store:clear_extmark_by_extmark("ext11")
			assert.is_true(ok)

			local sel = store:get_by_id(id)
			assert.is_not_nil(sel)
			assert.is_nil(sel.extmark)
			sel = store:get_by_extmark("ext11")
			assert.is_nil(sel)
		end)

		it("should return error when clearing extmark for non-existent id", function()
			local ok, err = store:clear_extmark_by_id(999)
			assert.is_false(ok)
			assert.are.equal("Selection not found", err)
		end)

		it("should return error when clearing extmark for non-existent extmark", function()
			local ok, err = store:clear_extmark_by_extmark("nonexistent_ext")
			assert.is_false(ok)
			assert.are.equal("Selection not found for extmark", err)
		end)
	end)

	---------------------------------------------------------------------------
	-- Clearing the Store
	---------------------------------------------------------------------------
	describe("Clearing the Store", function()
		it("should clear all selections and reset the store", function()
			local id1 = store:add("file12.txt", { 1, 10 }, "ext12")
			local id2 = store:add("file12.txt", { 11, 20 }, "ext13")
			local all = store:get_all()
			assert.are.equal(2, #all)

			store:clear()

			all = store:get_all()
			assert.are.equal(0, #all)
			assert.are.equal(0, store.counter)
			local sels = store:get_by_filename("file12.txt")
			assert.are.equal(0, #sels)

			-- After clearing, the counter should restart at 0 so the next id is 1.
			local id3 = store:add("file12.txt", { 21, 30 }, "ext14")
			assert.are.equal(1, id3)
		end)
	end)
end)
