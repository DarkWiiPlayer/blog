local task = require'spooder'.task

local path = table.concat({
	"lib/?.lua",
	"lib/?/init.lua",
	"lua_modules/share/lua/5.4/?.lua",
	"lua_modules/share/lua/5.4/?/init.lua",
	";",
}, ";")

local cpath = table.concat({
	"lua_modules/lib/lua/5.4/?.so",
	"lua_modules/lib/lua/5.4/?/init.so",
	";",
}, ";")

task.robots {
	"curl https://www.ditig.com/robots.txt > static/robots.txt";
}

task.setup {
	description = "Sets up directories and dependencies";
	"mkdir -p lua_modules .luarocks";
	"luarocks install --only-deps *.rockspec";
}

task.clean {
	description = "Removes local rocks";
	'rm -r lua_modules';
}

task.build {
	description = "Builds the page";
	depends = "robots";
	'mkdir -p .luarocks lua_modules';
	'luarocks install --only-deps *.rockspec';
	'tup';
	'rm -rf blog/*';
	string.format(
		[[
			export LUA_PATH='%s'
			export LUA_CPATH='%s'
			lua build.lua --output blog --cname blog.but.gay
		]],
		path, cpath
	)
}

task.deploy {
	description = "Deploys the blog to latest version";
	depends = "build";
	[[
		hash=$(git log -1 --format=%h)
		cd blog
			find . | treh -c
			git add --all
			if git log -1 --format=%s | grep "$hash$"
			then git commit --no-verify --amend --no-edit
			else git commit --no-verify -m "Update blog to $hash"
			fi
			git push --force github page
		cd ../
		git stash pop || true
	]];
}
