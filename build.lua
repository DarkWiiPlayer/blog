local csv = require 'streamcsv'
local fun = require 'fun'
local json = require 'cjson'
local restia = require 'restia'
local scaffold = require 'scaffold'
local shapeshift = require 'shapeshift'

-- Project-specific stuff
local paramparser = require 'paramparser'
local params = paramparser(...)
package.loaded.params = params
local config = require 'config'
local pages = require 'pages'
local templates = require 'templates'
local posts = require 'posts'

local tree = {}

for i, path in ipairs(params.copy) do
	scaffold.deep(tree, path, scaffold.readdir(path))
end

local function render(name, data)
	return templates.main(templates[name], data)
end

local function page(name, data)
	return templates.main(pages[name], data)
end

-- Render Posts
for idx, post in ipairs(posts) do
	local body = tostring(render("post", post))

	scaffold.deep(tree, post.path, body)
end

if params.delete then
	restia.utils.delete(params.output)
end

local function transform(tab)
	return function(data)
		local success, result = shapeshift.table(tab, "keep")(data)
		return result
	end
end

local function drop() return true, nil end

-- Generate Post Metadata
tree["posts.json"] = json.encode(
	fun
	.iter(posts)
	:map(transform {
		body = drop;
		head = shapeshift.table({ file = drop }, 'keep');
	})
	:totable()
)

tree["index.html"] = tostring(page("index", tree["posts.json"]))

scaffold.builddir(params.output, tree)
