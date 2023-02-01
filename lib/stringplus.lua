local _string = {}

function _string.split(str, pattern)
	local result = {}
	for item in str:gmatch(pattern) do
		table.insert(result, item)
	end
	return result
end

return setmetatable(_string, {__index=_G.string})
