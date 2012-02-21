mongoose = require 'mongoose'
helper = require '../helpers'

Schema = mongoose.Schema
ObjectId = Schema.ObjectId

middleware = 
	pre_slug: (next) ->
		doc = this
		slug = doc.slug ? helper.slugify doc.name
		new_slug = slug + ''
		i = 1

		model.count slug: slug, (err, count) ->
			if !count
				doc.slug = slug
				return next()
			
			slug_lookup = (err, count) ->
				if !count
					doc.slug = new_slug
					return next()
				
				i++
				new_slug = "#{slug}-#{i}"
				model.count slug: new_slug, slug_lookup
			
			slug_lookup err, count


comment = new Schema
	_user: [
		type: ObjectId
		ref: 'user'
		required: true
	]
	body:
		type: String
		required: true
	created_at:
		default: Date.now
		type: Date

photo = new Schema
	_tags: [
		type: ObjectId
		ref: 'tag'
	]
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
	name:
		required: true
		type: String
	sizes:
		l: String
		m: String
		s: String
		t: String
		o: String
	slug:
		# required: true
		type: String
		unique: true
	views:
		default: 0
		type: Number

photo.pre 'save', middleware.pre_slug

module.exports = model = mongoose.model 'photo', photo