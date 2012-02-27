_ = require 'underscore'

module.exports = (app) -> middleware =
	# auth: (path = '/') -> (req, res, next) ->
	# 	passport.authenticate 'local', sucessRedirect: path, failureRedirect: '/login'

	auth: (req, res, next) ->
		if req.isAuthenticated()
			return next()
		
		req.flash 'auth_redirect', req.originalUrl
		res.redirect('/login')
	
	
	# err: (err, req, res, next) ->
	# 	if !err && flash = req.flash('err')
	# 		return next flash, req, res, next
		
	# 	next err, req, res, next
	

	hmvc: (path) -> (req, res, next) ->
		route = app.match.get(path)
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