mongoose = require 'mongoose'
mongooseTypes = require 'mongoose-types'
mongooseTypes.loadTypes mongoose
invoke = require 'invoke'

helpers = require '../lib/helpers'

Schema = mongoose.Schema
ObjectId = Schema.ObjectId
Email = mongoose.SchemaTypes.Email
# Url = mongoose.SchemaTypes.Url

encrypt_password = (password) ->
	require('crypto').createHash('sha1').update(password + helpers.heart).digest('hex')

validate_url = (v) ->
	/^(https?|ftp):\/\/(((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:)*@)?(((\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]))|((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?)(:\d*)?)(\/((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)+(\/(([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)*)*)?)?(\?((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|[\uE000-\uF8FF]|\/|\?)*)?(\#((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|\/|\?)*)?$/i.test(v)

user = new Schema
	_photos: [
		type: ObjectId
		ref: 'photo'
	]
	clab: String
	created_at:
		default: Date.now
		type: Date
	email:
		lowercase: true
		# required: true
		type: Email,
		# unique: true
		get: (v) -> v || ''
	facebook:
		id: String
		email: Email
		username: String
	password:
		# required: true
		set: encrypt_password
		type: String
	random:
		default: Math.random
		index: true
		set: (v) -> Math.random()
		type: Number
	twitter:
		id: String
		token: String
		token_secret: String
		username: String
	url:
		type: String
		# validate: [validate_url, 'Please enter a valid URL']
	username:
		lowercase: true
		# required: true
		type: String
		# unique: true

user.statics.encrypt_password = encrypt_password


user.statics.login = (username, password, next) ->
	password = encrypt_password(password)
	@findOne
			username: username
			password: password
		, (err, doc) ->
			return next err, false if err
			next null, doc


user.statics.serialize = (user, next) ->
	next null, user._id


user.statics.deserialize = (id, next) ->
	@findOne
			_id: id
		, (err, doc) ->
			return next null, false if err || doc == null
			next null, doc


user.statics.facebook = (token, tokenSecret, profile, next) ->
	model = this
	model.findOne
			'facebook.id': profile.id
		, (err, doc) ->
			return next null, doc unless err || doc == null

			model.findOne
					'email': profile._json.email
				, (err, doc) ->
					url = profile._json.website.split("\r\n")[0]
					facebook =
						email: profile._json.email
						id: profile.id
						username: profile.username

					if doc
						doc.facebook = facebook
						doc.url = url  if !doc.url && url
						doc.save()
						return next null, doc

					else
						u = new (mongoose.model 'user')
						u.email = facebook.email
						u.facebook = facebook
						u.url = url  if url
						u.username = profile.username
						u.save()
						next null, u


user.statics.twitter = (token, tokenSecret, profile, next) ->
	model = this
	model.findOne
			'twitter.id': profile.id
		, (err, doc) ->
			return next null, doc unless err || doc == null

			model.findOne
					'username': profile._json.screen_name
			, (err, doc) ->
				url = profile._json.url?
				twitter =
					id: profile.id
					token: token
					token_secret: tokenSecret
					username: profile._json.screen_name

				if doc
					doc.twitter = twitter
					doc.url = url  if !doc.url && url
					doc.save()
					return next null, doc

				else
					u = new (mongoose.model 'user')
					u.twitter = twitter
					u.username = twitter.username
					u.url = url  if url
					u.save()
					next null, u


module.exports = mongoose.model 'user', user