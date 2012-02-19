# Module dependencies
express = require('express')
_ = underscore = require('underscore')
app = module.exports = express.createServer()


# Configuration
app.configure ->
	app.set 'views', __dirname + '/public/templates'
	app.set 'view engine', 'jade'
	app.set 'strict routing', true

	# app.use express.favicon()
	app.use express.bodyParser()
	app.use express.logger( format: ':status ":method :url"' )
	
	oneYear = 31556926000; # 1 year on milliseconds
	app.use express.static( __dirname + '/public', maxAge: oneYear )


# Middleware
middleware =
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
		redirection = path + ''
		path_vars = _.filter path.split('/'), (i) -> i.charAt(0) == ':'

		for path_var, i of path_vars
			redirection = redirection.replace i, req.params[ i.substring(1) ]
		
		page = parseInt req.param 'page', 1
		
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


# Route Params
app.param 'page', (req, res, next, id) ->
	if id.match /[0-9]+/
		req.param.page = parseInt req.param.page
		next()
	else
		return next(404)


app.param 'size', (req, res, next, id) ->
	if id in ['p', 'm', 'o']
		next()
	else
		return next('route')


app.param 'slug', (req, res, next, id) ->
	if id not in ['editar']
		next()
	else
		return next('route')


app.param 'sort', (req, res, next, id) ->
	if id in ['ultimas', 'top', 'galeria']
		next()
	else
		return next('route')


app.param 'user', (req, res, next, id) ->
	if id not in ['ultimas', 'top', 'galeria', 'pag']
		next()
	else
		return next('route')


# Routes
app.all '*', middleware.remove_trailing_slash, (req, res, next) ->
	res.locals
		_: underscore
		body_class: ''
	
	next('route')


app.get '/', (req, res) ->
	res.local 'body_class', 'home gallery'
	res.render 'gallery'


app.get '/fotos/:user/:slug', (req, res) ->
	res.local 'body_class', 'single'
	res.render 'gallery_single'


app.get '/fotos/:user/:slug/editar', (req, res) ->
	user = req.param 'user'
	slug = req.param 'slug'
	res.send "PUT /fotos/#{user}/#{slug}/editar", 'Content-Type': 'text/plain'


app.put '/fotos/:user/:slug', (req, res) ->
	user = req.param 'user'
	slug = req.param 'slug'
	res.send "PUT /fotos/#{user}/#{slug}", 'Content-Type': 'text/plain'


app.delete '/fotos/:user/:slug', (req, res) ->
	user = req.param 'user'
	slug = req.param 'slug'
	res.send "DELETE /fotos/#{user}/#{slug}", 'Content-Type': 'text/plain'


app.get '/fotos/:user/:slug/sizes/:size', (req, res) ->
	res.local 'body_class', 'sizes'
	res.render 'gallery_single_large'


app.get '/fotos/:user', (req, res) ->
	res.local 'body_class', 'gallery liquid'
	res.render 'gallery'


app.get '/fotos/publicar', (req, res) ->
	res.render 'gallery_upload'


app.post '/fotos/publicar', (req, res) ->
	res.send "POST /fotos/publicar", 'Content-Type': 'text/plain'


app.get '/fotos/:sort/pag/:page?', middleware.paged('/fotos/:sort')
app.get '/fotos/:sort', (req, res, next) ->
	sort = req.params.sort
	page = parseInt req.param 'page', 1

	res.send "GET /fotos/#{sort}/pag/#{page}", 'Content-Type': 'text/plain'


app.get '/fotos/pag/:page?', middleware.paged('/fotos')
app.get '/fotos', (req, res) ->
	res.send "GET /fotos", 'Content-Type': 'text/plain'
	# res.local 'body_class', 'gallery liquid'
	# res.render 'gallery'


app.get '/tags/:tag/pag/:page?', middleware.paged('/tags/:tag')
app.get '/tags/:tag', (req, res) ->
	tag = req.params.tag
	page = parseInt req.param 'page', 1

	res.send "GET /tags/#{tag}/pag/#{page}", 'Content-Type': 'text/plain'


app.get '/tags', (req, res) ->
	res.send "GET /fotos/tags", 'Content-Type': 'text/plain'


app.get '/perfil', (req, res) ->
	res.send "GET /perfil", 'Content-Type': 'text/plain'


app.put '/perfil', (req, res) ->
	res.send "PUT /perfil", 'Content-Type': 'text/plain'


app.get '/login', (req, res) ->
	res.send "GET /login", 'Content-Type': 'text/plain'


app.post '/login', (req, res) ->
	res.send "POST /login", 'Content-Type': 'text/plain'


app.get '/registro', (req, res) ->
	res.send "GET /registro", 'Content-Type': 'text/plain'


app.post '/registro', (req, res) ->
	res.send "POST /registro", 'Content-Type': 'text/plain'


app.get '/logout', (req, res) ->
	res.send "GET /perfil", 'Content-Type': 'text/plain'


app.get '/tweets', (req, res) ->
	res.send "GET /tweets", 'Content-Type': 'text/plain'


# app.all '*', (req, res) ->
# 	res.render 'gallery'


# Only listen on $ node app.js
if (!module.parent)
	app.listen 3000
	console.log "Listening on port %d", app.address().port
