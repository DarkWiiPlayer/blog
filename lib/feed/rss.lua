local skooma = require 'skooma'
local config = require 'config'

local xml = skooma.env()

local function map(sequence, fun)
	local new = {}
	for key, value in ipairs(sequence) do
		new[key] = fun(value)
	end
	return new
end

return function(posts)
	return tostring(xml.rss{
		version="2.0";
		["xmlns:atom"]="http://www.w3.org/2005/Atom";
		xml.channel {
			xml.title(config.title);
			xml.link "https://blog.but.gay/";
			xml.description(config.description);
			xml.language "en-uk";
			xml.lastBuildDate(os.date());
			map(posts, function(post)
				local link = "https://blog.but.gay"..post.head.uri
				return xml.item {
					xml.title(post.head.title);
					xml.description(post.head.description);
					xml.link(link);
					xml.guid(link);
					xml.pubDate(os.date("%d %b %Y", post.head.timestamp));
				}
			end)
		}
	})
end
