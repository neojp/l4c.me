var http = require('http'),
    execFile = require('child_process').execFile;
    i = 0,
    timer = null,
    delay = 60 * 1000;

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

// request options
var options = {
    host: 'clabie.com',
    port: 80,
    path: '/',
    method: 'HEAD'
};


function clabie_check(){
    console.log('clabie_check', i, ' - ', new Date());
    i++;

    // start request
    var req = http.request(options, function(res){
        clearTimeout(timer);

        // console.log('STATUS:' + res.statusCode);
        // console.log('HEADERS:' + JSON.stringify(res.headers));

        console.log(res.statusCode);
        
        if (res.statusCode == 200) {
            console.log('');
            setTimeout(clabie_check, delay);
            return;
        }

        // restart clabie
        execFile(__dirname + '/forever-restart.js', null, null, function(error, stdout, stderr){
            var s = output.apply(this, arguments);
            var r = s.join("\n");
            console.log('');
            console.log(r);

            setTimeout(clabie_check, delay);
        });
    });

    req.on('error', function(e){
        if (e.code === 'ECONNRESET')
            console.log('Timeout ERROR');

        console.log('problem with request: ' + e.message);
        setTimeout(clabie_check, delay);
    });

    req.end();


    // Abort if clabie is not loading after 10 seconds
    timer = setTimeout(function(){
        console.log('Forced timeout');

        if (req.abort)
            req.abort();
    }, 10 * 1000);
}

clabie_check();