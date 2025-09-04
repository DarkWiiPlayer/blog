local fun = require 'fun'
local xml = require "skooma.xml"
local json = require 'cjson'
local restia = require 'restia'
local scaffold = require 'scaffold'
local shapeshift = require 'shapeshift'

-- Project-specific stuff
local rss = require 'feed.rss'
local atom = require 'feed.atom'
local paramparser = require 'paramparser'
local params = paramparser(...)
package.loaded.params = params
local pages = require 'pages'
local templates = require 'templates'
local posts = require 'posts'

local output_tree = {}

for name, content in pairs(scaffold.readdir("static")) do
  scaffold.deep(output_tree, name, content)
end

local function is_image(name)
  if name:downcase():match("^.jpg$") then
    return true
  else
    return false
  end
end

local function render(name, data)
	return templates.main(templates[name], data)
end

local function page(name, data)
	return templates.main(pages[name], data)
end

-- Render Posts
for _, post in ipairs(posts) do
	local body = tostring(render("post", post))

	scaffold.deep(output_tree, post.path, body)
end

scaffold.deep(output_tree, "feeds/all.rss.xml", rss(posts))
scaffold.deep(output_tree, "feeds/all.atom.xml", atom(posts))

if params.delete then
	restia.utils.delete(params.output)
end

do -- Copy blog images
  local function iter_files(tree, callback)
    if getmetatable(tree) == scaffold.lazy then
      callback(tree)
    else
      for _, node in pairs(tree) do
        iter_files(node, callback)
      end
    end
  end

  iter_files(scaffold.readdir("posts", {files = "lazy"}), function(file)
    local name = file.path:match("[^/]+$")
    if name:find(".jpg$") or name:find(".svg$") then
      local path = "/images/" .. name
      scaffold.deep(output_tree, path, file)
    end
  end)
end

local function transform(tab)
	local tr = shapeshift.table(tab, "keep")
	return function(data)
		local success, result = tr(data)
		return result
	end
end

local function drop() return true, nil end

-- Generate Post Metadata
output_tree["posts.json"] = json.encode(
	fun
	.iter(posts)
	:map(transform {
		body = drop;
		head = shapeshift.table({ file = drop }, 'keep');
	})
	:totable()
)

local root = "https://blog.but.gay"
-- Generate sitemap
output_tree["sitemap.xml"] = xml.urlset {
	xmlns="http://www.sitemaps.org/schemas/sitemap/0.9";
	fun.iter(posts)
	:map(function(post)
		return xml.url {
			xml.loc(root .. post.path);
			xml.lastmod(post.head.date);
		}
	end):totable()
}:render()

output_tree["index.html"] = tostring(page("index", output_tree["posts.json"]))

if params.cname then
	output_tree.CNAME = params.cname
end

scaffold.builddir(params.output, output_tree)
