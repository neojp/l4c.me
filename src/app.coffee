# Module dependencies
_ = underscore = require 'underscore'
_.str = underscore.str = require 'underscore.string'
invoke = require 'invoke'
express = require 'express'
nodejs_url  = require 'url'


# L4C library
config = require('../config.json')
app = module.exports.app = express.createServer()
lib = require './lib'
helpers = lib.helpers
error_handler = lib.error_handler
middleware = lib.middleware(app)


# Mongoose configuration
mongo_session = require 'connect-mongo'
mongoose = require 'mongoose'
mongoose.connect config.mongodb
model = require './models'


# Passport configuration
passport = require 'passport'
passport_local = require('passport-local').Strategy
passport_twitter = require('passport-twitter').Strategy
passport_facebook = require('passport-facebook').Strategy

passport.serializeUser (user, next) ->
	model.user.serialize user, next

passport.deserializeUser (id, next) ->
	model.user.deserialize id, next

passport.use new passport_local (username, password, next) ->
	model.user.login username, password, next

passport.use new passport_facebook config.facebook, (token, tokenSecret, profile, next) ->
	model.user.facebook token, tokenSecret, profile, next

passport.use new passport_twitter config.twitter, (token, tokenSecret, profile, next) ->
	model.user.twitter token, tokenSecret, profile, next


# Express configuration
app.configure ->
	app.set 'views', __dirname + '/../views'
	app.set 'view engine', 'jade'
	app.set 'strict routing', true
	app.set 'static options',
		maxAge: 31556926000 # 1 year on milliseconds
		ignoreExtensions: 'styl coffeee'

	app.enable 'view cache'

	app.use express.favicon()
	app.use middleware.static( __dirname + '/../public' )
	app.use middleware.static( app.set('views'), urlPrefix: '/templates' )

	app.use express.logger helpers.logger_format
	app.use express.bodyParser()
	app.use express.methodOverride()
	app.use express.cookieParser helpers.heart
	app.use express.session( secret: helpers.heart, store: new mongo_session( url: config.mongodb + '/sessions' ))
	app.use passport.initialize()
	app.use passport.session()
	app.use app.router
	app.use error_handler(404)  # 404 handler

app.configure 'development', ->
	app.use express.errorHandler dumpExceptions: true, showStack: true  #development handler
	express.errorHandler.title = "L4C.me &hearts;"

app.configure 'production', ->
	app.use error_handler  # public 500 handler


# Route Params
app.param 'page', (req, res, next, id) ->
	if id.match /[0-9]+/
		req.param.page = parseInt req.param.page
		next()
	else
		return error_handler(404)(req, res)


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

	model.user.findOne username: id, (err, user) ->
		return next('route') if err || user == null
		next()


# Routes
app.all '*', middleware.redirect_subdomain, middleware.remove_trailing_slash, (req, res, next) ->
	res.locals
		_: underscore
		body_class: ''
		document_title: 'L4C.me'
		helpers: helpers
		logged_user: if req.isAuthenticated() then req.user else null
		original_url: req.originalUrl
		page: 1
		photos: []
		res: res
		sort: null
		query_vars: nodejs_url.parse(req.url, true).query
		google_analytics: config.google_analytics
	
	# res.locals helpers
	next('route')


app.get '/500', (req, res) ->
	throw new Error('test')
	res.send ''

app.get '/', middleware.hmvc('/fotos/:sort?')


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
			body_class: "gallery #{sort}"
			pages: Math.ceil count / per_page
			path: "/fotos/#{sort}"
			photos: photos
			sort: sort
			total: count

		res.render 'gallery'


# TODO: Show list of users with his latest 6 photos
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
			body_class: "gallery #{sort}"
			pages: Math.ceil count / per_page
			path: "/fotos/#{sort}"
			photos: photos
			sort: sort
			total: count

		res.render 'gallery'


app.get '/feed/:user', (req, res) ->
	user = req.param 'user'
	res.send "GET /feed/#{user}", 'Content-Type': 'text/plain'


app.get '/login', (req, res, next) ->
	if (req.isAuthenticated())
		return res.redirect '/'
	
	res.local 'failed', not _.isUndefined(res.local('query_vars').failed)
	res.render 'login'


app.post '/login', passport.authenticate('local', failureRedirect: '/login?failed'), (req, res, next) ->
	flash = req.flash 'auth_redirect'
	url = if _.size flash then _.first flash else '/profile'
	res.redirect url


app.get '/login/facebook', passport.authenticate('facebook', { scope: config.facebook.permissions })
app.get '/login/facebook/callback', passport.authenticate('facebook', failureRedirect: '/login'), (req, res, next) ->
	flash = req.flash 'auth_redirect'
	url = if _.size flash then _.first flash else '/profile'
	res.redirect url

app.get '/login/facebook/remove', middleware.auth, (req, res, next) ->
	model.user.update({ _id: req.user._id }, { $unset: { facebook: 1} }, false, -> res.redirect('/profile'))


app.get '/login/twitter', passport.authenticate('twitter')
app.get '/login/twitter/callback', passport.authenticate('twitter', failureRedirect: '/login'), (req, res, next) ->
	flash = req.flash 'auth_redirect'
	url = if _.size flash then _.first flash else '/profile'
	res.redirect url
	# res.redirect '/userinfo'

app.get '/login/twitter/remove', middleware.auth, (req, res, next) ->
	model.user.update({ _id: req.user._id }, { $unset: { twitter: 1} }, false, -> res.redirect('/profile'))

	# model.user
	# 	.findOne( _id: req.user._id )
	# 	.run (err, user) ->
	# 		user.twitter = null
	# 		user.save -> res.redirect('/userinfo')

app.get '/userinfo', (req, res, next) ->
	res.json req.user


app.get '/logout', (req, res, next) ->
	req.logout()
	res.redirect '/'


app.get '/registro', (req, res, next) -> res.redirect '/register'
app.get '/register', (req, res, next) ->
	res.render 'register'


app.post '/register', (req, res, next) ->
	d = req.body
	u = new model.user
	
	invoke (data, callback) ->
		# u.clab = d.clab  if d.clab_boolean == 'yes'
		u.email = d.email
		u.password = d.password
		u.username = d.username
		u.save (err) -> callback err
	
	.rescue (err) ->
		next err  if err
	
	.end null, (data) ->
		passport.authenticate('local', successRedirect: '/profile', failureRedirect: '/register?failed')(req, res)


# Logged in user routes
app.post '/comment', (req, res, next) ->
	comment =
		body: req.body.comment
		guest: true
		user:
			email: req.body.email
			name: req.body.name
	
	if req.user
		delete comment.user
		comment._user = req.user._id
		comment.guest = false

	console.log comment

	invoke (data, callback) ->
		# model.photo.update({ slug: req.body.photo }, { $push: { comments: comment } }, false, callback)
		# model.photo.update({ slug: req.body.photo }, { $push: { comments: comment } }, false, callback)
		model.photo.findOne({ slug: req.body.photo }, callback).populate('_user')

	.then (data, callback) ->
		data.comments.push comment
		data.save callback

	.rescue (err) ->
		next err

	.end null, (photo) ->
		# return res.json photo
		res.redirect "/#{photo._user.username}/#{photo.slug}#c#{_.last(photo.comments)._id}"


app.get '/fotos/publicar', middleware.auth, (req, res) ->
	res.locals
		body_class: 'upload'

	res.render 'gallery_upload'


app.post '/fotos/publicar', middleware.auth, (req, res, next) ->
	user = req.user
	name = req.body.name
	description = req.body.description

	file = req.files.file
	file_ext = helpers.image.extensions[file.type]
	file_path = ""

	photo = new model.photo

	queue = invoke (data, callback) ->
		photo.name = name
		photo.description = description  if description && description != ''
		photo.ext = file_ext
		photo._user = user._id
		photo.save (err) ->
			console.log "photo create - #{name}"
			callback err

	# image upload - move file from /tmp to /public/uploads
	# image manipulation - resize & crop images asynchronously
	.then (data, callback) ->
		photo.upload_photo file.path, (err) ->
			return callback err  if err
			photo.resize_photos callback

	# set photo slug
	queue.and (data, callback) ->
		photo.set_slug (photo_slug) ->
			console.log "photo set slug - #{photo_slug}"
			callback null, photo_slug

	# rescue
	.rescue (err) ->
		console.log "photo error"
		next err  if err
	
	# end
	.end null, (data) ->
		# redirect
		console.log "photo end - redirect"
		res.redirect "/#{user.username}/#{photo.slug}"


app.get '/profile', middleware.auth, (req, res) ->
	res.locals
		body_class: 'profile'
		user: req.user
	res.render 'profile'


app.put '/profile', middleware.auth, (req, res) ->
	has_update = false
	updated = {}

	updated.username = req.body.username  if req.user.username != req.body.username && has_update = true
	updated.email = req.body.email  if req.user.email != req.body.email && has_update = true

	if req.body['change-password'] == 'yes'
		p = model.user.encrypt_password req.body.password
		updated.password = p  if req.user.password != p && has_update = true

	if has_update
		model.user.update({ _id: req.user._id }, { $set: updated }, false, -> res.redirect('/profile'))
	else
		res.redirect('/profile')


app.get '/tweets', middleware.auth, (req, res) ->
	res.send "GET /tweets", 'Content-Type': 'text/plain'


app.get '/:user/:slug', (req, res, next) ->
	slug = req.param 'slug'
	username = req.param 'user'
	
	user = null
	photo = null
	myphotos = []
	morephotos = []

	invoke (data, callback) ->
		model.photo
			.findOne( slug: slug )
			.populate('_user')
			.populate('comments._user')
			.run (err, data) ->
				return callback err  if err
				return error_handler(404)(req, res)  if data == null || data._user.username != username

				user = data._user
				photo = data
				photo.views += 1
				photo.save callback

	# more user photos
	.then (data, callback) ->
		model.photo
			.find( _user: user._id )
			.notEqualTo('_id', photo._id)
			.$or( helpers.random_query() )
			# .desc('created_at')
			.limit(6)
			.run callback

	# random photos
	.and (data, callback) ->
		model.photo
			.find()
			.notEqualTo('_user', photo._user._id)
			.$or( helpers.random_query() )
			# .desc('created_at')
			.limit(6)
			.populate('_user')
			.run callback

	# prev / next photos from user
	.and (data, callback) ->
		# console.log 'photo', photo
		photo.prev_next(callback)

	.rescue (err) ->
		next err

	.end null, (data) ->
		photo.prev = data[2][0]
		photo.next = data[2][1]
		
		res.locals
			body_class: 'user single'
			photo: photo
			photos:
				from_user: data[0]
				from_all: data[1]
			slug: slug
			user: user
			username: user.username
		
		res.render 'gallery_single', { layout: false }


app.get '/:user/:slug/sizes/:size', (req, res) ->
	slug = req.param 'slug'
	user = req.param 'user'

	model.photo
		.findOne( slug: slug )
		.populate('_user')
		.run (err, photo) ->
			return next err  if err
			return error_handler(404)(req, res)  if !photo

			photo.views += 1
			photo.save()

			locals =
				body_class: 'user sizes'
				photo: photo
				size: req.param 'size'
				slug: slug
				user: user

			res.render 'gallery_sizes', { layout: false, locals: locals }


app.get '/:user/pag/:page?', middleware.paged('/:user')
app.get '/:user', (req, res, next) ->
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
			body_class: 'gallery user'
			pages: Math.ceil count / per_page
			path: "/#{user.username}"
			photos: photos
			sort: null
			total: count
			user: user

		res.render 'gallery'


app.get '/:user/:slug/editar', middleware.auth, (req, res) ->
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
			.run callback

	.then (data, callback) ->
		photo.resize_photos(404)(req, res)  if !data
		return error_handler(403)(req, res)  if !_.isEqual user._id, req.user._id
		photo = data

	.rescue (err) ->
		next err  if err
	
	.end user, (data) ->
		res.locals
			body_class: 'single edit'
			path: "/#{user.username}/#{photo.slug}/editar"
			photo: photo
			slug: slug
			user: username

		res.render 'gallery_single'


app.put '/:user/:slug', middleware.auth, (req, res) ->
	user = req.param 'user'
	slug = req.param 'slug'
	res.send "PUT /#{user}/#{slug}", 'Content-Type': 'text/plain'


app.delete '/:user/:slug', middleware.auth, (req, res) ->
	user = req.param 'user'
	slug = req.param 'slug'
	res.send "DELETE /#{user}/#{slug}", 'Content-Type': 'text/plain'



module.exports.listen = listen = () ->
	server = express.createServer()
	available_apps =
		app: app

	_.each config.domains, (value, key, list) ->
		if available_apps[value]
			server.use express.vhost key, available_apps[value]
	
	server.listen config.port || 3000, ->
		console.log "Listening on port %d \n\n", server.address().port
		user = config.users.default
		
		if user.gid
			try
				process.setgid user.gid
				console.log "process.setgid #{user.gid}"

		if user.uid
			try
				process.setuid user.uid
				console.log "process.setuid #{user.uid}"

		if user.umask
			try
				process.setumask user.umask
				console.log "process.setumask #{user.umask}"

# Only listen on $ node app.js
if (!module.parent)
	listen()
