---@class Distance
local Utils = {}

-- Get the distance between two points
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function Utils.GetDistance(x1, y1, x2, y2)
    return math.sqrt(Utils.GetDistanceSquared(x1, y1, x2, y2))
end

-- Get the distance between two points squared
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function Utils.GetDistanceSquared(x1, y1, x2, y2)
    return ((x2 or 0) - (x1 or 0)) ^ 2 + ((y2 or 0) - (y1 or 0)) ^ 2
end

-- Get the distance between two points in 3D
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number
function Utils.GetDistance3D(x1, y1, z1, x2, y2, z2)
    return math.sqrt(Utils.GetDistance3DSquared(x1, y1, z1, x2, y2, z2))
end

-- Get the distance between two points in 3D squared
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number
function Utils.GetDistance3DSquared(x1, y1, z1, x2, y2, z2)
    return ((x2 or 0) - (x1 or 0)) ^ 2 + ((y2 or 0) - (y1 or 0)) ^ 2 + ((z2 or 0) - (z1 or 0)) ^ 2
end

return Utils
