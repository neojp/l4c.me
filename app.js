// Module dependencies
var express = require('express'),
    _ = underscore = require('underscore'),
    sys = require('sys'),
    app     = module.exports = express.createServer(),
    options = { locals: { _: underscore, sys: sys } };


// Configuration
app.configure(function(){
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');

  app.use(express.favicon());
  app.use(express.bodyParser());
  //app.use(express.logger({ format: ':status ":method :url"' }));
  
  var oneYear = 31556926000; // 1 year on milliseconds
  app.use(express.static(__dirname + '/public', { maxAge: oneYear }));
});


// Routes
app.get('/single/', function(req, res){
  res.render('gallery_single', options);
})

app.all('*', function(req, res){
  res.render('gallery', options);
});

// Only listen on $ node app.js
if (!module.parent) {
  app.listen(10265);
  console.log("Listening on port %d", app.address().port);
}
