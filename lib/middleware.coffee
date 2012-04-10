_ = require 'underscore'
_.str = require 'underscore.string'
_path = require 'path'
express = require 'express'

module.exports = (app) -> middleware =
	# auth: (path = '/') -> (req, res, next) ->
	# 	passport.authenticate 'local', sucessRedirect: path, failureRedirect: '/login'

	auth: (req, res, next) ->
		if req.isAuthenticated()
			return next()
		
		req.flash 'auth_redirect', req.originalUrl
		res.redirect('/login')

	hmvc: (path) -> (req, res, next) ->
		route = app.match(path)
		route = _.filter route, (i) -> i.path == path
		route = _.first route
		callback = _.last route.callbacks
		
		if _.isFunction callback
			callback(req, res)
		else
			next('route')
	

	paged: (path) -> (req, res, next) ->
		redirection = path.replace '?', ''
		path_vars = _.filter redirection.split('/'), (i) -> i.charAt(0) == ':'

		for path_var, i of path_vars
			redirection = redirection.replace i, req.params[ i.substring(1) ]
		
		page = parseInt req.param 'page', 1
		res.local 'page', page
		
		if page == 1
			return res.redirect redirection, 301
		
		middleware.hmvc(path)(req, res, next)
	

	remove_trailing_slash: (req, res, next) ->
		url = req.originalUrl
		length = url.length
		
		if length > 1 && url.charAt(length - 1) == '/'
			url = url.substring 0, length - 1
			return res.redirect url, 301
		
		next()

	# extends express.static with a url prefix to map static files
	# eg. static(_dirname + '/views', { urlPrefix: '/templates', maxAge: 31556926000 })
	# will look for urls like this: /templates/layout.jade and send the file: _dirname + '/views/layout.jade'
	static: (path, options = {}) ->
		_.defaults options, app.set('static options')
		urlPrefix = options.urlPrefix

		(req, res, next) ->
			if _.isString urlPrefix
				return next()  if not _.str.startsWith req.url, urlPrefix
				req.url = req.url.substring urlPrefix.length

			extension = _path.extname(req.url).substring(1)
			if extension && _.isString(options.ignoreExtensions) && options.ignoreExtensions.length
				extensions = options.ignoreExtensions.split(' ')
				extensions = _.compact extensions
				return next() if extension && _.include extensions, extension
			
			express.static( path, options )(req, res, next)