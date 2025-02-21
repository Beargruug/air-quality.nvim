-- entry point for the plugin
local M = {}

M.air_quality = require("air_quality.air_quality")

function M.setup(opts)
	M.config.set(opts)
end

M.start = M.air_quality.start
M.stop = M.air_quality.stop

return M
