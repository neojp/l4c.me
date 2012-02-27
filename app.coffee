# Module dependencies
http = require 'http'
express = require 'express'
_ = underscore = require 'underscore'
_.str = underscore.str = require 'underscore.string'
fs = require 'fs'
invoke = require 'invoke'
app = module.exports = express.createServer()
im = require 'imagemagick'


# L4C library
l4c = require './lib'
helpers = l4c.helpers
error_handler = l4c.error_handler
middleware = l4c.middleware(app)


# momentjs - pretty dates configuration
# moment = require 'moment'
# moment.lang 'es'


# Mongoose configuration
mongo_session = require 'connect-mongo'
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
	# app.use express.errorHandler()

	app.set 'views', __dirname + '/public/templates'
	app.set 'view engine', 'jade'
	app.set 'strict routing', true

	app.use express.favicon()
	oneYear = 31556926000; # 1 year on milliseconds
	app.use express.static( __dirname + '/public', maxAge: oneYear )
	app.use express.logger( format: ':status ":method :url"' )

	app.use express.bodyParser()
	app.use express.methodOverride()

	app.use express.cookieParser helpers.heart
	app.use express.session( secret: helpers.heart, store: new mongo_session( url: 'mongodb://localhost/l4c/sessions' ))

	app.use passport.initialize()
	app.use passport.session()
	
	app.use app.router
	app.use error_handler
	# app.use express.errorHandler dumpExceptions: true, showStack: true
	# app.use express.errorHandler()


# Route Params
app.param 'page', (req, res, next, id) ->
	if id.match /[0-9]+/
		req.param.page = parseInt req.param.page
		next()
	else
		return next(404)


app.param 'size', (req, res, next, id) ->
	if id in ['p', 'm', 'g', 'o']
		next()
	else
		return next('route')


app.param 'slug', (req, res, next, id) ->
	if id not in ['editar']
		next()
	else
		return next('route')


app.param 'sort', (req, res, next, id) ->
	if id in ['ultimas', 'top']
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
	console.log req.originalUrl

	res.locals
		_: underscore
		body_class: ''
		document_title: 'L4C.me'
		original_url: req.originalUrl
		logged_user: if req.isAuthenticated() then req.user else null
		page: 1,
		helpers: helpers
		photos: []
	
	# res.locals helpers
	next('route')


app.get '/', middleware.hmvc('/fotos/:sort?')


app.get '/fotos/:user/:slug', (req, res, next) ->
	slug = req.param 'slug'
	user = req.param 'user'

	model.photo
		.findOne( slug: slug )
		.populate('_user')
		.populate('_tags')
		.run (err, photo) ->
			return next err  if err
			return next 404 if photo == null

			photo.views += 1
			photo.save()

			locals =
				body_class: 'single'
				# created_at: moment(photo.created_at).fromNow(true)
				slug: slug
				photo: photo
				user: user
			
			res.render 'gallery_single', locals: locals


app.get '/fotos/:user/:slug/sizes/:size', (req, res) ->
	slug = req.param 'slug'
	user = req.param 'user'

	model.photo
		.findOne( slug: slug )
		.populate('_user')
		.populate('_tags')
		.run (err, photo) ->
			return next err  if err
			return next 404 if photo == null

			photo.views += 1
			photo.save()

			locals =
				body_class: 'single sizes'
				photo: photo
				size: req.param 'size'
				slug: slug
				user: user

			res.render 'gallery_single_large', locals: locals


app.get '/fotos/:user/pag/:page?', middleware.paged('/fotos/:user')
app.get '/fotos/:user', (req, res, next) ->
	username = req.param 'user'
	per_page = helpers.pagination
	page = req.param 'page', 1
	user = null
	photos = null

	invoke (data, callback) ->
		model.user.findOne username: username, (err, user) -> callback err, user

	.then (data, callback) ->
		return error_handler(404)(req, res)  if (!data)
		user = data
		
		model.photo.count { _user: user._id }, callback
	
	.and (data, callback) ->
		photos = model.photo
			.find( _user: user._id )
			.limit(per_page)
			.skip(per_page * (page - 1))
			.desc('created_at')
			.populate('_user')
			.run callback

	.rescue (err) ->
		next err  if err
	
	.end user, (data) ->
		count = data[0]
		photos = data[1]
		
		res.locals
			body_class: 'gallery liquid'
			pages: Math.ceil count / per_page
			path: "/fotos/#{user.username}"
			photos: photos
			sort: null
			total: count

		res.render 'gallery'


app.get '/fotos/:sort/pag/:page?', middleware.paged('/fotos/:sort?')
app.get '/fotos/ultimas', (req, res) -> res.redirect '/fotos', 301
app.get '/fotos/:sort?', (req, res, next) ->
	sort = req.param 'sort', 'ultimas'
	page = req.param 'page', 1
	per_page = helpers.pagination
	photos = null
	query = {}

	invoke (data, callback) ->
		model.photo.count query, callback

	.and (data, callback) ->
		photos = model.photo
			.find(query)
			.limit(per_page)
			.skip(per_page * (page - 1))
			.populate('_user')
		
		photos.desc('created_at')  if sort == 'ultimas'
		photos.desc('views', 'created_at')  if sort == 'top'
		photos.run callback

	.rescue (err) ->
		next err  if err
	
	.end null, (data) ->
		count = data[0]
		photos = data[1]

		res.locals
			body_class: "gallery liquid #{sort}"
			pages: Math.ceil count / per_page
			path: "/fotos/#{sort}"
			photos: photos
			sort: sort
			total: count

		res.render 'gallery'


app.get '/fotos/galeria/pag/:page?', middleware.paged('/fotos/galeria')
app.get '/fotos/galeria', (req, res, next) ->
	sort = 'galeria'
	page = req.param 'page', 1
	per_page = helpers.pagination
	photos = null
	query = {}

	invoke (data, callback) ->
		model.photo.count query, callback

	.and (data, callback) ->
		model.photo
			.find(query)
			.desc('created_at')
			.limit(per_page)
			.skip(per_page * (page - 1))
			.populate('_user')
			.run callback

	.rescue (err) ->
		next err  if err
	
	.end null, (data) ->
		count = data[0]
		photos = data[1]

		res.locals
			body_class: "gallery liquid #{sort}"
			total: Math.ceil count / per_page
			path: "/fotos/#{sort}"
			sort: sort
			photos: photos

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
	
	invoke (data, callback) ->
		u.clab = d.clab  if d.clab_boolean == 'yes'
		u.email = d.email
		u.password = d.password
		u.username = d.username
		u.save (err) -> callback err
	
	.rescue (err) ->
		next err  if err
	
	.end null, (data) ->
		passport.authenticate('local', successRedirect: '/perfil', failureRedirect: '/')(req, res)


# Logged in user routes
app.get '/fotos/publicar', middleware.auth, (req, res) ->
	res.render 'gallery_upload'


app.post '/fotos/publicar', middleware.auth, (req, res, next) ->
	user = req.user
	name = req.body.name
	description = req.body.description
	tags = _.str.trim req.body.tags
	tags = if tags.length > 0 then tags.split(' ') else []

	file = req.files.file
	file_ext = helpers.image.extensions[file.type]
	file_path = ""

	photo = new model.photo
	photo_tags = []


	queue = invoke (data, callback) ->
		photo.name = name
		photo.description = description  if description && description != ''
		photo.ext = file_ext
		photo._user = user._id
		photo.save (err) ->
			console.log "photo create - #{name}"
			callback err

	# image upload - move file from /tmp to /public/uploads
	.then (data, callback) ->
		photo.upload_photo file, callback

	# image manipulation - resize & crop images asynchronously
	.and (data, callback) ->
		photo.resize_photos callback

	# tags - create tag and update tags count
	if tags.length > 0
		queue.and (data, callback) ->
			photo.set_tags tags, callback 

	# set photo slug
	queue.then (data, callback) ->
		photo.set_slug (photo_slug) ->
			console.log "photo set slug - #{photo_slug}"
			callback null, photo_slug

	# rescue
	.rescue (err) ->
		console.log "photo error"
		next err  if err
	
	# end
	.end null, (photo_slug) ->
		# redirect
		console.log "photo end - redirect"
		res.redirect "/fotos/#{user.username}/#{photo_slug}"


app.get '/fotos/:user/:slug/editar', middleware.auth, (req, res) ->
	slug = req.param 'slug'
	username = req.param 'user'
	user = null
	photo = null

	invoke (data, callback) ->
		model.user.findOne username: username, (err, user) -> callback err, user

	.then (data, callback) ->
		return error_handler(404)(req, res)  if (!data)
		user = data
		model.photo
			.findOne( _user: user._id, slug: slug )
			.populate('_user')
			.populate('_tags')
			.run callback

	.then (data, callback) ->
		photo.resize_photos (404)(req, res)  if !data
		return error_handler(403)(req, res)  if !_.isEqual user._id, req.user._id
		photo = data

	.rescue (err) ->
		next err  if err
	
	.end user, (data) ->
		res.locals
			body_class: 'single edit'
			path: "/fotos/#{user.username}/#{photo.slug}/editar"
			photo: photo
			slug: slug
			user: username

		res.render 'gallery_single'


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


# 404 errors fallback
app.all '*', error_handler(404)


# Only listen on $ node app.js
if (!module.parent)
	app.listen 3000
	console.log "Listening on port %d", app.address().port