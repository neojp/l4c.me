# Module dependencies
_     = underscore     = require 'underscore'
_.str = underscore.str = require 'underscore.string'
_.mixin _.str.exports()

express  = require 'express'
mongoose = require 'mongoose'
url      = require 'url'
util     = require 'util'


# Initialize app
app            = express()
module.exports = app


# L4C library
config        = require '../config.json'
lib           = require './lib'
error_handler = lib.error_handler
helpers       = lib.helpers
middleware    = lib.middleware(app)


# mongodb connection
mongoose.connect config.mongodb.app.url


# template engine - jade
app.set 'view engine', 'jade'
app.set 'views', __dirname + '/../views'


# static files
app.set 'static options',
	maxAge: 31556926000 # 1 year on milliseconds
	ignoreExtensions: 'styl coffeee'

app.use middleware.static( __dirname + '/../public' )
app.use middleware.static( app.get('views'), urlPrefix: '/templates' )


# logging
app.use express.logger helpers.logger_format


# query string parser
app.use express.query()


# form support
app.use express.bodyParser()
app.use express.methodOverride()


# cookies
app.use express.cookieParser()


# sessions
app.use require './session'


# csrf
# app.use express.csrf()


# add X-Response-Time header
app.use express.responseTime()


# custom middleware
app.use middleware.redirect_subdomain
app.use middleware.remove_trailing_slash


# global & default template variables
app.use (req, res, next) ->
	url_domain    = 'http://' + config.domain

	res.locals._blank               = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
	res.locals._                    = underscore
	res.locals.body_class           = ''
	res.locals.document_description = ''
	res.locals.document_image       = url_domain + '/images/logo.png'
	res.locals.document_title       = config.info.name
	res.locals.document_url         = url_domain
	res.locals.site_domain          = 'http://' + config.domain
	res.locals.site_name            = config.info.name
	res.locals.helpers              = helpers
	res.locals.logged_user          = if req.isAuthenticated() then req.user else null
	res.locals.original_url         = req.originalUrl
	res.locals.page                 = 1
	res.locals.photos               = []
	res.locals.pretty               = true
	res.locals.res                  = res
	res.locals.sort                 = null
	res.locals.query_vars           = url.parse(req.url, true).query
	res.locals.google_analytics     = config.google_analytics
	res.locals.twitter_config       =
		hashtag: config.twitter.hashtag
		username: config.twitter.username
	
	next()


# router
app.set 'strict routing', true
app.use app.router
app.use require './routes'


# 404 error handler
app.use error_handler(404)


# development configuration
app.configure 'development', () ->
	app.use express.errorHandler dumpExceptions: true, showStack: true
	express.errorHandler.title = config.info.name


# production configuration
app.configure 'production', () ->
	app.use error_handler


# listen
listen = () ->
	# Create HTTP server with your app
	http   = require 'http'
	server = http.createServer app

	# Listen to port 3000
	server.listen config.port || 3000, () ->
		user = config.users.default
		port = server.address().port

		console.log util.format("Server started on port %d \n\n", port), { port: port }

		if user.gid
			try
				process.setgid user.gid
				console.log "process.setgid #{user.gid}"

		if user.uid
			try
				process.setuid user.uid
				console.log "process.setuid #{user.uid}"

		if config.umask
			try
				process.setumask config.umask
				console.log "process.setumask #{config.umask}"


# export listen
module.exports.listen = listen


# Only listen on $ node app.js
if (!module.parent)
	listen()