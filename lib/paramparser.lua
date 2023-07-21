local arrr = require 'arrr'
local shapeshift = require 'shapeshift'

return function(...)
	local is = shapeshift.is
	local parse = arrr {
		{ "Output directory", "--output", "-o", 'directory' };
		{ "Input directory", "--input", "-i", 'directory' };
		{ "Copy directory", "--copy", "-c", 'directory', 'repeatable' };
		{ "Include unpublished posts", "--unpublished", "-u", nil };
		{ "Set the github pages CNAME", "--cname", nil, 'domain' };
		{ "Delete everything first", "--delete", "-d" };
	}
	local validate = shapeshift.table {
		output = shapeshift.default("output", is.string);
		input = shapeshift.default(".", is.string);
		copy = shapeshift.default({}, shapeshift.all{
			is.table,
			shapeshift.each(is.string)
		});
		cname = shapeshift.any(is.Nil, is.string);
		unpublished = shapeshift.default(false, shapeshift.is.boolean);
		delete = shapeshift.default(false, shapeshift.is.boolean);
	}
	return select(2, assert(validate(parse{...})))
end
