#!/usr/bin/env node

var http     = require('http')
    execFile = require('child_process').execFile,
    invoke   = require('../node_modules/invoke/lib/invoke'),
    config   = require('../config.json');


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


http.createServer(function (req, res) {
    
    invoke(function(data, callback){
        execFile(__dirname + '/git-pull.js', null, null, function(error, stdout, stderr){
            var s = output.apply(this, arguments);
            var r = s.join("\n");

            res.writeHead(200, { 'Content-Type': 'text/text' });
            res.write(r);
            callback();
        });
    })
    .end(null, function(data){
        execFile(__dirname + '/forever-restart.js', null, null, function(error, stdout, stderr){
            var s = output.apply(this, arguments);
            var r = s.join("\n");

            res.end(r);
        });
    });

}).listen(config.port_git);