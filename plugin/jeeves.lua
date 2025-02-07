vim.api.nvim_create_user_command("StartLLMIC", function()
	require('llmic').test()
end, {})
