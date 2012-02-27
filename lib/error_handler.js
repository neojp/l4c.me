var beautify, error500, helper, http;

http = require('http');

beautify = require('beautifyjs').js_beautify;

helper = require('./helpers');

error500 = function(err, req, res) {
  var headers, message, server_error;
  res.statusCode = err.status;
  server_error = http.STATUS_CODES[err.status];
  message = "";
  if (err.message) message += "Error message: " + err.message + "\n\n";
  if (err.errors) {
    message += "Error list:\n" + (beautify(JSON.stringify(err.errors))) + "\n\n";
  }
  if (req.accepts('json')) {
    return res.json({
      error: err
    });
  }
  headers = {
    'Content-Type': 'text/plain'
  };
  return res.send("" + helper.heart + " Error 500: Cannot " + req.method + " " + req.originalUrl + "\n\n" + server_error + "\n" + message + err.stack, headers);
};

module.exports = function(err, req, res, next) {
  var default_error;
  default_error = function(req, res) {
    var method, status, _ref;
    method = req.method;
    status = (_ref = err.status) != null ? _ref : err;
    res.statusCode = status;
    if ('HEAD' === method || req.accepts('json')) return res.end();
    return res.send("" + helper.heart + " Error " + status + ": Cannot " + method + " " + req.originalUrl, {
      'Content-Type': 'text/plain'
    });
  };
  if (typeof err === 'number' && err !== 500) return default_error;
  if (err.status == null) err.status = 500;
  if (err.status !== 500) return default_error(req, res);
  return error500(err, req, res);
};
