#!/usr/bin/env node

'use strict';

// stdlib
var path = require('path');

// 3rd-party
var _     = require('underscore');
var yaml  = require('js-yaml');

////////////////////////////////////////////////////////////////////////////////

var options = (function (cli) {
  cli.addArgument(['--locals'], {action: 'store', required: false});
  cli.addArgument(['--input'],  {action: 'store', required: true});

  return cli.parseArgs();
}(new (require('argparse').ArgumentParser)));

////////////////////////////////////////////////////////////////////////////////

var jade_filters = require('jade/lib/filters');

jade_filters.stylus_nowrap = function(str, options){
  var ret;
  str = str.replace(/\\n/g, '\n');
  var stylus = require('stylus');
  stylus(str, options).render(function(err, css){
    if (err) throw err;
    ret = css.replace(/\n/g, '\\n');
  });
  return ret; 
}

////////////////////////////////////////////////////////////////////////////////

var locals  = options.locals ? require(path.resolve(options.locals)) : {};
var input = options.input ? require(path.resolve(options.input))['glyphs'] : {};

// Create a reverse-lookup input[code]=css-name
var input_backup = _.clone(input);
for (var k in input_backup) {
	input[input_backup[k]] = k;
}

// Go through all character definitions and check if they exists in the original font
_.each(locals.glyphs, function(i){
	var charcode = i.from ? i.from : i.code;
	var msg = null;
	// Check if the character name is defined in the original font
	if (input[i.css] == undefined) {
		// Character name is missing in original font.
		// Idetify the original character name using the character code.
		var charname = input[charcode];
		// If original character name could be identified by character code,
		// print a regular expression for sed which can be applied in order
		// to change the definition.
		if (charname) {
			msg = 's/css: ' + i.css + '$/css: ' + charname + '/g';
		}
		// In this case the characters does not match and something is not
		// in sync. Manual investigation is required.
		else {
			msg = i.css + ' and ' + charcode.toString(16) + ' unknown in original entypo font-family!';
		}
	}
	else if (input[i.css] != charcode) {
		msg = i.css + ' does not match original definition: 0x' + charcode.toString(16) + ' <> 0x' + input[i.css].toString(16);
	}
	if (msg) {
		console.log(msg);
	} else {
		delete input[i.css];
		delete input[charcode];
	}
	if (i.code > 0xFFFF) {
		var sed = function(from,to) {
			console.log('s/^    code: 0x' + from.toString(16) + '$/    code: 0x' + to.toString(16) + '\\n    from: 0x' + from.toString(16) + '/g');
		}
		var newcode = i.code & 0xFFFF;
		if (input_backup[newcode] == undefined) {
			console.log('Use 0x' + newcode.toString(16) + ' instead of 0x' + i.code.toString(16) + ' for "' + i.css + '" otherwise you run in trouble with some browsers.');
			sed(i.code, newcode);
		}
		else {
			console.log('Character code 0x' + i.code.toString(16) + ' > 0xFFFF result in issues for some browsers for "' + i.css + '", but 0x' + newcode.toString(16) + ' is already reserved by "' + input_backup[newcode] + '"');
			for (var stp = 1; stp < 0x1FF; stp++) {
				_.each([newcode + stp, newcode - stp], function(testcode) {
					if (stp < 0xFF && input_backup[testcode] == undefined) {
						console.log('Use 0x' + testcode.toString(16) + ' instead for "' + i.css + '"');
						sed(i.code, testcode);
						input_backup[testcode] = 'testcode ' + i.css;
						stp = 0x1FF;
					}
				});
			}
		}
	}
});
if (input.length) {
	console.log('Following characters are not defined in ' + options.ocals + ':' + input);
}
