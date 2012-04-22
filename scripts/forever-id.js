#!/usr/bin/env node

var fs   = require('fs'),
    util = require('util'),
    exec = require('child_process').exec,
    fid,
    cmd;


function trim (str) {
    var str = str.replace(/^\s\s*/, ''),
        ws = /\s/,
        i = str.length;
    while (ws.test(str.charAt(--i)));
    return str.slice(0, i + 1);
}


fid = fs.readFileSync(process.argv[3]).toString();
cmd = 'forever list -p ' + process.argv[2];

exec(cmd, function(error, stdout, stderr){
    var r = / [0-9]+ /g;
    var ids = stdout.match(r);

    if (ids && ids.length) {
        ids = ids.map(trim);
        if (ids.indexOf(fid) >= 0)
            console.log(process.argv[4]);
    }
});