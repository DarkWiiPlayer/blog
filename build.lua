local arrr = require 'arrr'
local cmark = require 'cmark'
local fun = require 'fun'
local json = require 'cjson'
local restia = require 'restia'
local shapeshift = require 'shapeshift'
local yaml = require 'lyaml'

local params do
	local is = shapeshift.is
	local parse = arrr {
		{ "Output directory", "--output", "-o", 'directory' };
		{ "Input directory", "--input", "-i", 'directory' };
		{ "Copy directory", "--copy", "-c", 'directory', 'repeatable' };
		{ "Delete everything first", "--delete", "-d" };
	}
	local validate = shapeshift.table {
		output = shapeshift.default("output", is.string);
		input = shapeshift.default(".", is.string);
		copy = shapeshift.default({}, shapeshift.all{
			is.table,
			shapeshift.each(is.string)
		});
		delete = shapeshift.default(false, shapeshift.is.boolean);
	}
	params = select(2, assert(validate(parse{...})))
end
package.loaded.params = params

local config = restia.config.bind('config', {
	(require 'restia.config.readfile');
	(require 'restia.config.lua');
	(require 'restia.config.yaml');
})
package.loaded.config = config

local templates = restia.config.bind('templates', {
	(require 'restia.config.skooma');
})
package.loaded.templates = templates

local pages = restia.config.bind('pages', {
	(require 'restia.config.skooma');
})
package.loaded.pages = pages

-- General purpose utility functions

local function split(str, pattern)
	local result = {}
	for item in str:gmatch(pattern) do
		table.insert(result, item)
	end
	return result
end

local function read_post(file)
	local content = io.open(file):read("*a")
	local head, body = restia.utils.frontmatter(content)
	return {
		head = head and yaml.load(head) or {};
		body = cmark.render_html(cmark.parse_document(body, #body, cmark.OPT_DEFAULT), cmark.OPT_DEFAULT);
	}
end

local posts = {}
package.loaded.posts = posts

local tree = {}

for i, path in ipairs(params.copy) do
	restia.utils.deepinsert(tree, restia.utils.fs2tab(path), restia.utils.readdir(path))
end

local validate_head do
	local is = shapeshift.is
	validate_head = shapeshift.table {
		__extra = 'keep';
		title = is.string;
		date = shapeshift.matches("%d%d%d%d%-%d%d%-%d%d");
		file = is.string;
	}
end

local function parsedate(date)
	local year, month, day = date:match("(%d+)%-(%d+)%-(%d+)")
	return os.time {
		year = tonumber(year);
		month = tonumber(month);
		day = tonumber(day);
	}
end

-- Load Posts
for file in restia.utils.files(params.input, "%.md$") do
	local post = read_post(file)
	post.head.file = file

	assert(validate_head(post.head))

	post.head.timestamp = parsedate(post.head.date)

	if "string" == type(post.head.tags) then
		post.head.tags = split(post.head.tags, "%a+")
	end

	post.head.slug = post.head.title
		:gsub(' ', '_')
		:lower()
		:gsub('[^a-z0-9-_]', '')

	post.head.uri = string.format("/%s/%s.html", post.head.date:gsub("%-", "/"), post.head.slug)
	post.path = restia.utils.fs2tab(post.head.uri)

	table.insert(posts, post)
end

table.sort(posts, function(a, b)
	return a.head.timestamp > b.head.timestamp
end)

local function render(name, ...)
	return templates.main(templates[name], ...)
end
local function page(name, ...)
	return templates.main(pages[name], ...)
end

-- Render Posts
for idx, post in ipairs(posts) do
	local body = restia.utils.deepconcat(render("post", post.body, post.head))

	restia.utils.deepinsert(tree, post.path, body)
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

tree["index.html"] = page("index", posts, tree["posts.json"])

restia.utils.builddir(params.output, tree)
