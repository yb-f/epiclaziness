--[[
	Currently a lone function.
	TODO Determine if this file is necessary, or if there are additional functions that should be moved here as well
--]]

local mq = require("mq")

local common = {}

---@param str string
---@param list table
---@return boolean
function common.match_list(str, list)
	for _, v in ipairs(list) do
		if str == v then
			return true
		end
	end
	return false
end

return common
