mongoose = require 'mongoose'
mongooseTypes = require 'mongoose-types'
mongooseTypes.loadTypes mongoose

helpers = require '../lib/helpers'
_ = underscore = require 'underscore'
invoke = require 'invoke'
fs = require 'fs'
util = require 'util'
nodejs_path = require 'path'

Schema = mongoose.Schema
ObjectId = Schema.ObjectId
Email = mongoose.SchemaTypes.Email

methods =
	set_slug: (next) ->
		doc = this
		slug = helpers.slugify doc.name
		new_slug = slug + ''
		i = 1

		model.count slug: new_slug, (err, count) ->
			if count == 0
				doc.slug = new_slug
				doc.save (err) ->
					return next err  if err
					next new_slug
			
			else
				slug_lookup = (err, count) ->
					if count == 0
						doc.slug = new_slug
						return doc.save (err) ->
							return next err  if err
							next doc.slug
					
					i++
					new_slug = "#{slug}-#{i}"
					model.count slug: new_slug, slug_lookup
				
				slug_lookup err, count

	resize_photo: (size, src, next) ->
		if _.isFunction src
			next = src
			src = null

		if _.isString size
			size = helpers.image.sizes[size]
		else if _.isObject size
			size = size
		else
			return next new Error 'Image size required'

		doc = this
		dest = nodejs_path.normalize "#{__dirname}/../../public/uploads/#{doc._id}_#{size.size}.#{doc.ext}"
		src = nodejs_path.normalize "#{__dirname}/../../public/uploads/#{doc._id}_o.#{doc.ext}"  if _.isNull src

		callback = (err, stdout, stderr) ->
			console.log "photo #{size.action} end #{size.size}", stdout, stderr
			next err, dest

		# imagemagick module
		imagemagick = ->
			im = require 'imagemagick'
			im[size.action]
				dstPath: dest
				filter: 'Cubic'  #  Lagrange is only available on v6.3.7-1
				format: doc.ext
				height: size.height
				srcPath: src
				width: size.width
			, callback

		# graphicsmagick module
		graphicsmagick = (src, dest) ->
			gm = require 'gm'
			if size.action == 'resize'
				console.log "photo resize start #{size.size} - #{src} -> #{dest}"
				gm(src).autoOrient().resize(size.width, size.height).write(dest, callback)
			else if size.action == 'crop'
				console.log "photo crop start #{size.size} - #{src} -> #{dest}"
				gm(src).autoOrient().thumb size.width, size.height, dest, 80 , ->
					gm(dest).crop(size.width, size.height).write(dest, callback)
			else
				next new Error "No hay accion disponible: #{size.action}"

		# resize or crop images
		graphicsmagick(src, dest)


	resize_photos: (next) ->
		doc = this
		queue = invoke()
		index = 0
		
		_.each helpers.image.sizes, (size, key) ->
			if !index
				queue = invoke (data, callback) -> doc.resize_photo size, callback
			else
				queue.and (data, callback) -> doc.resize_photo size, callback
			
			index++

		queue.rescue next
		queue.end null, (data) -> next(null, data)

	upload_photo: (file_path, next) ->
		doc = this
		console.log 'photo upload', file_path, '->', "#{doc._id}_o.#{doc.ext}"

		upload_path = nodejs_path.normalize "#{__dirname}/../../public/uploads/#{doc._id}_o.#{doc.ext}"

		alternate_upload = (path1, path2) ->
			origin = fs.createReadStream path1
			upload = fs.createWriteStream path2
			util.pump origin, upload, (err) ->
				fs.unlink path1, (err) -> next err

		fs.rename file_path, upload_path, (err) ->
			return alternate_upload file_path, upload_path if err
			next err

	pretty_date: () ->
		helpers.pretty_date this.created_at

	prev_next: (next) ->
		photo = this
		created_at = photo.created_at

		invoke (data, callback) ->
			model.findOne({ _user: photo._user, created_at: { $lt: created_at } }, { slug: 1 })
				.desc('created_at')
				.run callback

		.and (data, callback) ->
			model.findOne({ _user: photo._user, created_at: { $gt: created_at } }, { slug: 1 })
				.asc('created_at')
				.run callback

		.end null, (data) ->
			next(null, data)

comment = new Schema
	_user:
		type: ObjectId
		ref: 'user'
	body:
		type: String
		required: true
	created_at:
		default: Date.now
		type: Date
	guest:
		default: true
		type: Boolean
	user:
		name: String
		email: Email

comment.virtual('pretty_date').get methods.pretty_date


photo = new Schema
	_user:
		type: ObjectId
		ref: 'user'
		required: true
	comments: [ comment ]
	created_at:
		default: Date.now
		required: true
		type: Date
	description: String
	ext:
		type: String
		enum: ['gif', 'jpg', 'png']
	name:
		required: true
		type: String
	random:
		default: Math.random
		index: true
		set: (v) -> Math.random()
		type: Number
	# sizes:
	# 	l: String
	# 	m: String
	# 	s: String
	# 	t: String
	# 	o: String
	slug:
		# required: true
		type: String
		# unique: true
	views:
		default: 0
		type: Number

# virtual: pretty_date
photo.virtual('pretty_date').get methods.pretty_date


# photo.pre 'save', middleware.pre_slug
# photo.pre 'save', (next) ->
# 	if _.isUndefined this.slug
# 		this.slug = this._id
	
# 	next()


photo.methods.set_slug = methods.set_slug
photo.methods.resize_photo = methods.resize_photo
photo.methods.resize_photos = methods.resize_photos
photo.methods.upload_photo = methods.upload_photo
photo.methods.prev_next = methods.prev_next

module.exports = model = mongoose.model 'photo', photo
