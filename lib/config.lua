local glass = require 'glass'
return glass.bind('config', {
	(require 'glass.raw');
	(require 'glass.lua');
	(require 'glass.yaml');
	(require 'glass.csv');
})
