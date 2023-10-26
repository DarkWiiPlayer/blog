local skooma = require 'skooma'
local config = require 'config'

local xml = skooma.env()

local rfc3339 = "%Y-%m-%dT%H:%M:%SZ"

local function map(sequence, fun)
	local new = {}
	for key, value in ipairs(sequence) do
		new[key] = fun(value)
	end
	return new
end

return function(posts)
	return [[<?xml version="1.0" encoding="utf-8"?>]] .. tostring(xml.feed{
		xmlns="http://www.w3.org/2005/Atom";
		xml.id("https://blog.but.gay/");
		xml.title(config.title:gsub("\n$", ""));
		xml.link { rel="alternate", href = "https://blog.but.gay/", type="text/html" };
		xml.link { rel="self", href = "https://blog.but.gay/feeds/all.atom.xml" };
		xml.updated(os.date(rfc3339));
		xml.author(
			xml.name(config.me.name),
			xml.uri(config.me.link)
		);
		xml.generator {
			uri = "https://github.com/darkwiiplayer/blog";
			"Home-grown SSG"
		};
		--xml.description(config.description);
		map(posts, function(post)
			local link = "https://blog.but.gay"..post.head.uri
			return xml.entry {
				xml.id(link);
				xml.title(post.head.title);
				function()
					if post.head.updates then
						return xml.updated(os.date(rfc3339, post.head.updates[#post.head.updates]));
					else
						return xml.updated(os.date(rfc3339, post.head.timestamp));
					end
				end;
				--
				xml.summary(post.head.description);
				xml.content {
					type="html";
					post.body;
				};
				xml.link { href = link };
				--
				xml.published(os.date(rfc3339, post.head.timestamp));
				map(post.head.tags, function(tag)
					return xml.category { term = tag }
				end)
			}
		end)
	})
end
