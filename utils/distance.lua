local mq = require('mq')

local Utils = {}

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function Utils.GetDistance(x1, y1, x2, y2)
    return math.sqrt(Utils.GetDistanceSquared(x1, y1, x2, y2))
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function Utils.GetDistanceSquared(x1, y1, x2, y2)
    return ((x2 or 0) - (x1 or 0)) ^ 2 + ((y2 or 0) - (y1 or 0)) ^ 2
end

return Utils
