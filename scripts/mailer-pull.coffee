# Module dependencies
_ = underscore = require "underscore"
_.str = underscore.str = require "underscore.string"
invoke = require "invoke"
imap = require("imap").ImapConnection
mailparser = require("mailparser").MailParser
fs = require "fs"


# L4C Library
config = require "../config.json"
helpers = require "../build/lib/helpers"


# Mongoose configuration
mongo_session = require 'connect-mongo'
mongoose = require 'mongoose'
mongoose.connect config.mongodb

model = 
	user: require "../build/models/user"
	photo: require "../build/models/photo"






server = new imap
	username: config.mailer.username
	password: config.mailer.password
	host: config.mailer.imap.host
	port: config.mailer.imap.port
	secure: config.mailer.imap.secure



die = (err) ->
	console.error 'dead server'
	process.exit 1



server.connect (err) ->
	return die err if err

	server.openBox 'INBOX', false, (err, box) ->
		return die err if err
		get_new_emails()



get_new_emails = ->
	server.search ['UNSEEN', ['SINCE', 'January 1, 2012']], (err, results) ->
		return die err if err

		options =
			markSeen: false
			request:
				body: 'full'
				headers: false

		fetch = server.fetch(results, options)
		
		fetch.on 'message', (msg) ->
			parser = new mailparser

			parser.on 'end', (data) ->
				data.id = msg.seqno
				upload_photo(data)  if data.attachments.length

			msg.on 'data', (data) ->
				parser.write data.toString()

			msg.on 'end', ->
				console.log 'Finished message:'
				parser.end()

		fetch.on 'end', ->
			console.log 'Done fetching all messages!'
			setTimeout get_new_emails, 10 * 1000

			# server.logout () ->
			# 	process.exit 1


tmp_dir = __dirname + "/../tmp/"
upload_photo = (data) ->
	uid = _.uniqueId()
	email = _.first(data.from).address
	name = data.subject
	description = data.text
	attachment = _.first(data.attachments)
	file_ext = helpers.image.extensions[attachment.contentType]

	attachment = _.find data.attachments, (x) ->
		return not _.isUndefined helpers.image.extensions[x.contentType]

	file_path = tmp_dir + uid + '__' + attachment.generatedFileName
	fs.writeFile file_path, attachment.content, ->

		photo = new model.photo
		queue = invoke (data, callback) ->
			console.log "photo from email: find user by email - #{email}"
			model.user.findOne email: email, (err, user) -> callback err, user

		.then (user, callback) ->
			photo.name = name
			photo.description = description  if description && description != ''
			photo.ext = file_ext
			photo.slug = 'from mail: ' + uid + ' - ' + photo.name
			photo._user = user._id
			photo.save (err) ->
				console.log "photo from email: create - #{name}"
				callback err

		# image upload - move file from /tmp to /public/uploads
		# image manipulation - resize & crop images asynchronously
		.then (data, callback) ->
			console.log "photo from email: create tmp file - #{file_path}"
			
			photo.upload_photo file_path, (err) ->
				return callback err  if err
				photo.resize_photos callback

		# set photo slug
		queue.and (data, callback) ->
			photo.set_slug (photo_slug) ->
				console.log "photo from email: set slug - #{photo_slug}"
				callback null, photo_slug

		# rescue
		.rescue (err) ->
			console.log "photo from email: error"
			console.error err  if err
		
		# end
		.end null, (data) ->
			console.log "photo from email: end"