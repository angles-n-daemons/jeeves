local jeeves = require('jeeves')

-- Autocommand for buffer open
vim.api.nvim_create_autocmd('BufReadPost', {
	pattern = '*',
	callback = function()
		jeeves.buffer_open()
	end,
})


-- Autocommand for buffer close
vim.api.nvim_create_autocmd('BufWinLeave', {
	pattern = '*',
	callback = function()
		jeeves.buffer_close()
	end,
})
