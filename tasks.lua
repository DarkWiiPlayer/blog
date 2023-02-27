local task = require'spooder'.task

local path = table.concat({
	"lib/?.lua",
	"lib/?/init.lua",
	"lua_modules/share/lua/5.4/?.lua",
	"lua_modules/share/lua/5.4/?/init.lua",
	";",
}, ";")

local cpath = path:gsub(".lua", ".so"):gsub("/share/", "/lib/")

task.build {
	description = "Builds the page";
	'mkdir -p .luarocks lua_modules';
	'luarocks install --only-deps *.rockspec';
	'tup';
	'rm -rf blog/*';
	string.format(
		[[
			export LUA_PATH='%s'
			export LUA_CPATH='%s'
			lua build.lua --copy css --copy javascript --output blog
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
			then git commit --amend --no-edit
			else git commit -m "Update blog to $hash"
			fi
			git push --force origin page
		cd ../
		git stash pop || true
	]];
}
