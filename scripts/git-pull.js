#!/usr/bin/env node

var http   = require('http')
    exec   = require('child_process').exec,
    dir    = require('path').dirname(__dirname + '../'),
    cmd    = 'cd ' + dir + ' && git pull origin master && npm install && cake build',
    config = require('../config.json');


function output(error, stdout, stderr){
    var s = [];
    if (error)
        s.push(error.toString());

    if (stderr)
        s.push(stderr.toString());

    if (stdout)
        s.push(stdout.toString());

    return s;
}


function userid(gid, uid){
    if (gid) {
      try {
        process.setgid(gid);
        console.log("process.setgid " + gid);
      } catch (_error) {}
    }
    
    if (uid) {
      try {
        process.setuid(uid);
        console.log("process.setuid " + uid);
      } catch (_error) {}
    }
}


console.log("\n" + (new Date()));
userid(config.users.default.gid, config.users.default.uid);


exec(cmd, function(error, stdout, stderr){
    var s = output.apply(this, arguments);
    var r = "\n" + cmd + "\n\n" + s.join("\n") + "\n";
    console.log(r);
});