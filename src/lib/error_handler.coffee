http = require 'http'
beautify = require('beautifyjs').js_beautify
helper = require './helpers'

error500 = (err, req, res) ->
	res.statusCode = err.status
	server_error = http.STATUS_CODES[err.status]

	# console.error err
	# console.error server_error
	# console.error err.message
	# console.error err.stack

	message = ""
	message += "Error message: #{err.message}\n\n"  if err.message
	message += "Error list:\n#{beautify JSON.stringify err.errors}\n\n"  if err.errors

	# if req.accepts('html')
	# 	return res.render '500', error: err

	if !req.accepts 'html' && req.accepts 'json'
		return res.json error: err

	headers = 'Content-Type': 'text/plain'
	return res.send "#{helper.heart} Error 500: Cannot #{req.method} #{req.originalUrl}\n\n#{server_error}\n#{message}#{err.stack}", headers


module.exports = (err, req, res, next) ->
	# error 404 or anything that isn't 500
	default_error = (req, res) ->
		method = req.method
		status = err.status ? err
		res.statusCode = status

		return res.end()  if 'HEAD' == method
		return res.json { error:{ status: status } }  if !req.accepts 'html' && req.accepts 'json'
		return res.send "#{helper.heart} Error #{status}: Cannot #{method} #{req.originalUrl}", 'Content-Type': 'text/plain'

	# if err is a number and not 500
	return default_error if typeof err == 'number' && err != 500

	# if err.status is not 500
	err.status ?= 500
	return default_error req, res  if err.status != 500

	# do error 500
	return error500 err, req, res