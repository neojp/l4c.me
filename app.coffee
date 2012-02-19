# Module dependencies
express = require('express')
_ = underscore = require('underscore')
app = module.exports = express.createServer()
passport = require('passport')
LocalStrategy = require('passport-local').Strategy

# Passport configuration
users = [
		id: 1337
		username: 'neojp',
		password: 'password'
	,
		id: 666
		username: 'freddier',
		password: 'password'
	,
		id: 161803399
		username: 'maikel',
		password: 'password'
	,
		id: 123
		username: 'leonidas',
		password: 'password'
]


passport.serializeUser (user, next) ->
	next null, user.id


passport.deserializeUser (id, next) ->
	user = _.filter users, (i) -> i.id == id
	if _.size user
		next null, _.first user
	else
		next null, false


passport.use new LocalStrategy (username, password, next) ->
	process.nextTick () ->
		user = _.filter users, (i) -> i.username == username && i.password == password
		if _.size user
			next null, _.first user
		else
			next null, false


# Configuration
app.configure ->
	app.set 'views', __dirname + '/public/templates'
	app.set 'view engine', 'jade'
	app.set 'strict routing', true

	oneYear = 31556926000; # 1 year on milliseconds
	app.use express.static( __dirname + '/public', maxAge: oneYear )
	app.use express.logger( format: ':status ":method :url"' )

	# app.use express.favicon()

	app.use express.cookieParser()
	app.use express.bodyParser()
	app.use express.methodOverride()
	app.use express.session secret: '♥'

	app.use passport.initialize()
	app.use passport.session()
	
	app.use app.router


# Middleware
middleware =
	# auth: (path = '/') -> (req, res, next) ->
	# 	passport.authenticate 'local', sucessRedirect: path, failureRedirect: '/login'
	
	auth: (req, res, next) ->
		if req.isAuthenticated()
			return next()
		
		# console.log req.originalUrl
		req.flash 'auth_redirect', req.originalUrl
		res.redirect('/login')
	

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


# Helpers
helpers =
	slugify: (str) ->
		str = str.replace /^\s+|\s+$/g, ''
		str = str.toLowerCase()

		# remove accents, swap ñ for n, etc
		from = "àáäâèéëêìíïîòóöôùúüûñç®©·/_,:;"
		to   = "aaaaeeeeiiiioooouuuuncrc------"

		for i, character of from.split ''
			str = str.replace new RegExp(character, 'g'), to.charAt i
		
		# trademark sign
		str = str.replace new RegExp('™', 'g'), 'tm'

		# remove invalid chars
		str = str.replace /[^a-z0-9 -]/g, ''

		# collapse whitespace and replace by -
		str = str.replace /\s+/g, '-'
		
		# collapse dashes
		str = str.replace /-+/g, '-'


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
	if id not in ['ultimas', 'top', 'galeria', 'pag', 'publicar']
		next()
	else
		return next('route')


# Routes
app.all '*', middleware.remove_trailing_slash, (req, res, next) ->
	res.locals
		_: underscore
		body_class: ''
		user: if req.isAuthenticated() then req.user else null
		page: parseInt req.param 'page', 1
	
	res.locals helpers

	next('route')


app.get '/', middleware.hmvc('/fotos')


app.get '/fotos/:user/:slug', (req, res) ->
	res.local 'body_class', 'single'
	res.render 'gallery_single'


app.get '/fotos/:user/:slug/editar', middleware.auth, (req, res) ->
	user = req.param 'user'
	slug = req.param 'slug'
	res.send "PUT /fotos/#{user}/#{slug}/editar", 'Content-Type': 'text/plain'


app.put '/fotos/:user/:slug', middleware.auth, (req, res) ->
	user = req.param 'user'
	slug = req.param 'slug'
	res.send "PUT /fotos/#{user}/#{slug}", 'Content-Type': 'text/plain'


app.delete '/fotos/:user/:slug', middleware.auth, (req, res) ->
	user = req.param 'user'
	slug = req.param 'slug'
	res.send "DELETE /fotos/#{user}/#{slug}", 'Content-Type': 'text/plain'


app.get '/fotos/:user/:slug/sizes/:size', (req, res) ->
	res.local 'body_class', 'sizes'
	res.render 'gallery_single_large'


app.get '/fotos/:user', (req, res) ->
	res.local 'body_class', 'gallery liquid'
	res.render 'gallery'


app.get '/fotos/publicar', middleware.auth, (req, res) ->
	res.render 'gallery_upload'


app.post '/fotos/publicar', middleware.auth, (req, res) ->
	res.send "POST /fotos/publicar", 'Content-Type': 'text/plain'


app.get '/fotos/:sort/pag/:page?', middleware.paged('/fotos/:sort')
app.get '/fotos/:sort', (req, res, next) ->
	sort = req.params.sort
	res.locals
		sort: sort
		path: "/fotos/#{sort}"
		body_class: "gallery liquid #{sort}"
	
	res.render 'gallery'


app.get '/fotos/pag/:page?', middleware.paged('/fotos')
app.get '/fotos', (req, res) ->
	res.local 'path', '/fotos'
	# res.send "GET /fotos", 'Content-Type': 'text/plain'
	res.local 'body_class', 'gallery liquid'
	res.render 'gallery'


app.get '/tags/:tag/pag/:page?', middleware.paged('/tags/:tag')
app.get '/tags/:tag', (req, res) ->
	tag = req.params.tag
	page = parseInt req.param 'page', 1

	res.send "GET /tags/#{tag}/pag/#{page}", 'Content-Type': 'text/plain'


app.get '/tags', (req, res) ->
	res.send "GET /tags", 'Content-Type': 'text/plain'


app.get '/perfil', middleware.auth, (req, res) ->
	res.send "GET /perfil", 'Content-Type': 'text/plain'


app.put '/perfil', middleware.auth, (req, res) ->
	res.send "PUT /perfil", 'Content-Type': 'text/plain'


app.get '/login', (req, res) ->
	if (req.isAuthenticated())
		return res.redirect '/'
	
	res.render 'login'
	# res.send "GET /login", 'Content-Type': 'text/plain'


app.post '/login', passport.authenticate('local', failureRedirect: '/login'), (req, res) ->
	flash = req.flash('auth_redirect')
	url = if _.size flash then _.first flash else '/'
	res.redirect url


app.get '/logout', (req, res) ->
	req.logout()
	res.redirect '/'
	# res.send "GET /perfil", 'Content-Type': 'text/plain'


app.get '/registro', (req, res) ->
	res.send "GET /registro", 'Content-Type': 'text/plain'


app.post '/registro', (req, res) ->
	res.send "POST /registro", 'Content-Type': 'text/plain'


app.get '/tweets', middleware.auth, (req, res) ->
	res.send "GET /tweets", 'Content-Type': 'text/plain'


# app.all '*', (req, res) ->
# 	res.render 'gallery'


# Only listen on $ node app.js
if (!module.parent)
	app.listen 3000
	console.log "Listening on port %d", app.address().port