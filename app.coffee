# Module dependencies
express = require 'express'
_ = underscore = require 'underscore'
helper = require './helpers'
app = module.exports = express.createServer()
im = require 'imagemagick'
fs = require 'fs'

moment = require 'moment'
moment.lang 'es'

# Mongoose configuration
mongoose = require 'mongoose'
mongoose.connect 'mongodb://localhost/l4c'
model = require './models'


# Passport configuration
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy

passport.serializeUser (user, next) ->
	next null, user.username

passport.deserializeUser (username, next) ->
	model.user.deserialize username, next

passport.use new LocalStrategy (username, password, next) ->
	model.user.login username, password, next


# Express configuration
app.configure ->
	app.set 'views', __dirname + '/public/templates'
	app.set 'view engine', 'jade'
	app.set 'strict routing', true

	app.use express.favicon()
	oneYear = 31556926000; # 1 year on milliseconds
	app.use express.static( __dirname + '/public', maxAge: oneYear )
	app.use express.logger( format: ':status ":method :url"' )

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
		
		req.flash 'auth_redirect', req.originalUrl
		res.redirect('/login')
	
	err: (err, req, res, next) ->
		if !err && flash = req.flash('err')
			return next flash, req, res, next
		
		next err, req, res, next
	

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


# Route Params
app.param 'page', (req, res, next, id) ->
	if id.match /[0-9]+/
		req.param.page = parseInt req.param.page
		next()
	else
		return next(404)


app.param 'size', (req, res, next, id) ->
	if id in ['p', 'm', 'l', 'o']
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
		document_title: 'L4C.me'
		url: req.originalUrl
		user: if req.isAuthenticated() then req.user else null
		page: 1
	
	res.locals helper
	next('route')


app.get '/', middleware.hmvc('/fotos/:sort?')


app.get '/fotos/:user/:slug', (req, res) ->
	slug = req.param 'slug'
	user = req.param 'user'

	model.photo
		.findOne( slug: slug )
		.populate('_user')
		.run (err, photo) ->
			if err
				res.send "NOT FOUND 404 /fotos/#{user}/#{slug}", 404

			photo.views += 1
			photo.save()

			locals =
				body_class: 'single'
				created_at: moment(photo.created_at).fromNow(true)
				slug: slug
				photo: photo
				user: user
			
			res.render 'gallery_single', locals: locals


app.get '/fotos/:user/:slug/sizes/:size', (req, res) ->
	res.locals
		body_class: 'sizes'
		photo:
			user: req.param 'user'
			slug: req.param 'slug'
		size: req.param 'size'
	
	res.render 'gallery_single_large'


app.get '/fotos/:user/pag/:page?', middleware.paged('/fotos/:user')
app.get '/fotos/:user', (req, res) ->
	user = req.param 'user'

	res.locals
		body_class: 'gallery liquid'
		path: "/fotos/#{user}"
		sort: null

	res.render 'gallery'


app.get '/fotos/:sort/pag/:page?', middleware.paged('/fotos/:sort?')
app.get '/fotos/ultimas', (req, res) -> res.redirect '/fotos', 301
app.get '/fotos/:sort?', (req, res, next) ->
	sort = req.param 'sort', 'ultimas'
	
	res.locals
		body_class: "gallery liquid #{sort}"
		path: "/fotos/#{sort}"
		sort: sort
	
	res.render 'gallery'


app.get '/tags/:tag/pag/:page?', middleware.paged('/tags/:tag')
app.get '/tags/:tag', (req, res) ->
	tag = req.params.tag
	page = parseInt req.param 'page', 1

	res.send "GET /tags/#{tag}/pag/#{page}", 'Content-Type': 'text/plain'


app.get '/tags', (req, res) ->
	res.send "GET /tags", 'Content-Type': 'text/plain'


app.get '/feed/:user', (req, res) ->
	user = req.param 'user'
	res.send "GET /feed/#{user}", 'Content-Type': 'text/plain'


app.get '/login', (req, res, next) ->
	if (req.isAuthenticated())
		return res.redirect '/'
	
	res.render 'login'


app.post '/login', passport.authenticate('local', failureRedirect: '/login'), (req, res, next) ->
	flash = req.flash('auth_redirect')
	url = if _.size flash then _.first flash else '/'
	res.redirect url


app.get '/logout', (req, res, next) ->
	req.logout()
	res.redirect '/'


app.get '/registro', (req, res, next) ->
	res.render 'register'


app.post '/registro', (req, res, next) ->
	d = req.body
	
	u = new model.user
	u.clab = d.clab  if d.clab_boolean == 'yes'
	u.email = d.email
	u.password = d.password
	u.username = d.username
	u.save (err) ->
		return next err if err
		passport.authenticate('local', successRedirect: '/perfil', failureRedirect: '/')(req, res)


# Logged in user routes
app.get '/fotos/publicar', middleware.auth, (req, res) ->
	res.render 'gallery_upload'


app.post '/fotos/publicar', middleware.auth, (req, res, next) ->
	user = req.user
	name = req.body.name
	description = req.body.description

	extensions =
		'image/jpeg': 'jpg'
		'image/pjpeg': 'jpg'
		'image/gif': 'gif'
		'image/png': 'png'

	file = req.files.file
	file_ext = extensions[file.type]

	photo = new model.photo
	photo.name = name
	photo.description = description if description && description != ''
	photo.ext = file_ext
	photo._user = user._id
	photo.save (err) ->
		return next err if err

		# redirect
		photo.set_slug (photo_slug) ->
			res.redirect "/fotos/#{user.username}/#{photo_slug}"


		# image upload & manipulation
		id = photo._id
		file_path = "public/uploads/#{id}_o.#{file_ext}"


		# move file from /tmp to /public/uploads
		fs.rename file.path, "#{__dirname}/#{file_path}", (err) ->
			return next err if err

			sizes =
				l:
					action: 'resize'
					height: 728
					width: 970
				m:
					action: 'resize'
					height: 450
					width: 600
				s:
					action: 'crop'
					height: 190
					width: 190
				t:
					action: 'crop'
					height: 75
					width: 100
		
			# resize image 4 times async, save filename once it's done
			for size, i of sizes
				filename = "#{id}_#{size}.#{file_ext}"
				((size, i, filename) ->
					im[i.action]
						dstPath: "public/uploads/#{filename}"
						format: file_ext
						height: i.height
						srcPath: file_path
						width: i.width
					, (err, stdout, stderr) ->
						# photo.sizes[size] = filename
						# photo.save()
				)(size, i, filename)
		

		# tags
		tags = []
		tag_list = req.body.tags.split ' '
		tags_count = tag_list.length

		for tag, i in tag_list
			tag_name = tag.toLowerCase()

			((tag_name, i) ->
				model.tag.findOne name: tag_name, (err, tag) ->
					return next err if err

					if tag
						tag.count = tag.count + 1
						tag.save (err) ->
							tags.push tag

							if i == tags_count - 1
								photo._tags = _.pluck tags, '_id'
								photo.save()
					else
						tag = new model.tag
						tag.name = tag_name
						tag.count = 1
						tag.save (err) ->
							tags.push tag

							if i == tags_count - 1
								photo._tags = _.pluck tags, '_id'
								photo.save()
			)(tag_name, i)



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


app.get '/perfil', middleware.auth, (req, res) ->
	res.send "GET /perfil", 'Content-Type': 'text/plain'


app.put '/perfil', middleware.auth, (req, res) ->
	res.send "PUT /perfil", 'Content-Type': 'text/plain'


app.get '/tweets', middleware.auth, (req, res) ->
	res.send "GET /tweets", 'Content-Type': 'text/plain'


# app.all '*', (req, res) ->
# 	res.render 'gallery'


# Only listen on $ node app.js
if (!module.parent)
	app.listen 3000
	console.log "Listening on port %d", app.address().port