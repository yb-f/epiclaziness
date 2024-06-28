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
