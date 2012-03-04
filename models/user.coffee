mongoose = require 'mongoose'
mongooseTypes = require 'mongoose-types'
mongooseTypes.loadTypes mongoose

Schema = mongoose.Schema
ObjectId = Schema.ObjectId
Email = mongoose.SchemaTypes.Email
Url = mongoose.SchemaTypes.Url

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
		required: true
		type: Email,
		unique: true
	password:
		required: true
		type: String
	random:
		default: Math.random
		index: true
		set: (v) -> Math.random()
		type: Number
	url:
		type: Url
	username:
		lowercase: true
		required: true
		type: String
		unique: true

user.statics.login = (username, password, next) ->
	@findOne
			username: username
			password: password
		, (err, doc) ->
			return next err, false if err
			next null, doc

user.statics.deserialize =  (username, next) ->
	@findOne
			username: username
		, (err, doc) ->
			return next null, false if err
			next null, doc

module.exports = mongoose.model 'user', user