local html = require 'skooma.html'
local rgbstr = require 'rgbstr'

local function tag(name)
	local colour = { rgbstr.bytes(name, 16, .3, .5) }
	return html.postTag(html.a {
		name;
		href = "/?tag="..name;
		style = "--color: rgb("..table.concat(colour, ', ')..")";
	})
end

return function(tags)
	if tags then
		local list = { gap=".4", style="justify-content: flex-start" }
		for _, name in ipairs(tags) do
			table.insert(list, tag(name))
		end
		return {
			html.flexRow(list);
			html.verticalSpacer();
		}
	end
end
