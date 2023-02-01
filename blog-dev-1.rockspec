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
	"glass ~> 1.3.0",
	"cmark ~> 0.29",
	"fun ~> 0.1.3",
	"lua-cjson ~> 2.1",
	"restia",
	"scaffold ~> 1.1.0",
	"shapeshift ~> 1.1.0",
	"skooma ~> 0.3",
	"streamcsv ~> 1.1.0",
}
build = {
	type = "builtin",
	modules = { }
}
