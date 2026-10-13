-- Utils.lua
-- Berisi utilitas umum yang digunakan di seluruh plugin

local HttpService = game:GetService("HttpService")
local Utils = {}

Utils.debounce = function(fn, wait)
	local cooldown = false
	return function(...)
		if cooldown then return end
		cooldown = true
		local result = fn(...)
		task.wait(wait)
		cooldown = false
		return result
	end
end

Utils.formatDuration = function(seconds)
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", mins, secs)
end

Utils.validateJSON = function(str)
	local success, result = pcall(function()
		return HttpService:JSONDecode(str)
	end)
	return success, result
end

Utils.deepCopy = function(obj)
	if type(obj) ~= "table" then return obj end
	local res = setmetatable({}, getmetatable(obj))
	for k, v in pairs(obj) do res[Utils.deepCopy(k)] = Utils.deepCopy(v) end
	return res
end

Utils.countTokens = function(str)
	if not str or #str == 0 then return 0 end
	return math.ceil(#str / 4)
end

return Utils
