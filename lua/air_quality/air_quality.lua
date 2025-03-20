local M = {}

local win = nil
local buf = nil
local timer = nil

local function create_window()
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Fetch Data" })

	local width = 27
	local height = 4
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		row = 0,
		col = vim.o.columns - width,
		style = "minimal",
		border = "rounded",
	}
	win = vim.api.nvim_open_win(buf, false, opts)
end

local function fetch_data()
	local endpoint = "https://air-quality-inspector.vercel.app/api/data"
	local cmd = "curl -s " .. endpoint
	local result = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		return nil, "Fehler beim Abruf der Daten: " .. result
	end

	local ok, data = pcall(vim.fn.json_decode, result)
	if not ok then
		return nil, "Fehler beim Parsen der Daten"
	end

	return data, nil
end

local function fetch_github_data()
	local config_file = io.open("config.json", "r")
	if not config_file then
		return nil, "Failed to open config file"
	end

	local config_content = config_file:read("*a")
	config_file:close()

	local ok, config = pcall(vim.fn.json_decode, config_content)
	if not ok or not config.repo then
		return nil, "Failed to parse config file"
	end

	local headers = {
		"-H 'Accept: application/vnd.github+json'",
		"-H 'X-GitHub-Api-Version: 2022-11-28'",
	}
	local endpoint = "/repos/" .. config.repo .. "/pulls"

	local headers_str = table.concat(headers, " ")

	local cmd = "gh api " .. headers_str .. " " .. endpoint

	local result = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		return nil, "Fehler beim Abruf der Daten: " .. result
	end

	local ok2, data = pcall(vim.fn.json_decode, result)
	if not ok2 then
		return nil, "Fehler beim Parsen der Daten"
	end

	return data, nil
end

local function update_window()
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local data, err = fetch_data()
	local gh_data, gh_err = fetch_github_data()

	if gh_err then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { gh_err })
		return
	end
	if err then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { err })
		return
	end

	if not data then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "No Data" })
		return
	end

	local temp = data.temperature.celsius_degree or "--"
	local hum = data.humidity.humidity or "--"
	local quality = data.quality.quality or "--"
	local quality_disp = type(quality) == "number" and tostring(quality) or "--"

	local lines = {
		"Temperatur: " .. temp .. " ℃",
		"Humidity: " .. hum .. " %",
		"AirQuality: " .. quality_disp .. " ppm",
		"Open PR's: " .. #gh_data,
	}
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

local function setUpAfterCreateMaceWindow()
	update_window()
	if timer then
		timer:stop()
		timer:close()
	end
	timer = vim.loop.new_timer()
	timer:start(
		300000,
		300000,
		vim.schedule_wrap(function()
			update_window()
		end)
	)
end

function M.start()
	create_window()
	vim.defer_fn(function()
		setUpAfterCreateMaceWindow()
	end, 10)
end

function M.refresh()
	update_window()
end

function M.stop()
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
	buf = nil
end

return M
