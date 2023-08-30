package = "blog"
version = "dev-1"
source = {
	url = ""
}
description = {
	homepage = "https://darkwiiplayer.github.io/blog",
	license = "Proprietary"
}
dependencies = {
	"arrr ~> 2.2",
	"cmark ~> 0.29",
	"fun ~> 0.1",
	"glass ~> 1.3",
	"lua-cjson ~> 2.1",
	"restia",
	"rgbstr",
	"scaffold ~> 1.1",
	"shapeshift ~> 1.1",
	"skooma",
	"streamcsv ~> 1.1",
}
build = {
	type = "builtin",
	modules = { }
}
