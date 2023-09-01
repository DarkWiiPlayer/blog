local cmark = require 'cmark'
local restia = require 'restia'
local params = require 'params'
local yaml = require 'lyaml'
local shapeshift = require 'shapeshift'
local string = require 'stringplus'

local function parsedate(date)
	local year, month, day = date:match("(%d+)%-(%d+)%-(%d+)")
	return os.time {
		year = tonumber(year);
		month = tonumber(month);
		day = tonumber(day);
	}
end

local validate_head do
	local is = shapeshift.is
	validate_head = shapeshift.table {
		__extra = 'keep';
		title = is.string;
		date = shapeshift.matches("%d%d%d%d%-%d%d%-%d%d");
		file = is.string;
		published = shapeshift.default(false, shapeshift.matches("^true$"))
	}
end

local function read_post(file)
	local content = io.open(file):read("*a")
	local head, body = restia.utils.frontmatter(content)
	return {
		head = head and yaml.load(head) or {};
		body = cmark.render_html(cmark.parse_document(body, #body, cmark.OPT_DEFAULT), cmark.OPT_DEFAULT + cmark.OPT_UNSAFE);
	}
end

local posts = {}

for file in restia.utils.files(params.input, "^./posts/.*%.md$") do
	print("Reading post "..file.."...")
	local post = read_post(file)
	post.head.file = file

	assert(validate_head(post.head))

	post.head.timestamp = parsedate(post.head.date)

	if "string" == type(post.head.tags) then
		post.head.tags = string.split(post.head.tags, "[%a-]+")
	end

	for key, tag in ipairs(post.head.tags) do
		post.head.tags[key] = string.lower(tag)
	end

	post.head.slug = post.head.title
		:gsub(' ', '_')
		:lower()
		:gsub('[^a-z0-9-_]', '')

	post.head.uri = string.format("/%s/%s.html", post.head.date:gsub("%-", "/"), post.head.slug)
	post.path = post.head.uri

	if post.head.published or params.unpublished then
		table.insert(posts, post)
	end
end

table.sort(posts, function(a, b)
	return a.head.timestamp > b.head.timestamp
end)

return posts
