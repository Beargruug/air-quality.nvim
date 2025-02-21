local air_quality = require("air_quality")

vim.api.nvim_create_user_command("StartAirQuality", function()
	air_quality.start()
end, {})

vim.api.nvim_create_user_command("StopAirQuality", function()
	air_quality.stop()
end, {})

vim.api.nvim_create_user_command("RefreshAirQuality", function()
	air_quality.refresh()
end, {})
