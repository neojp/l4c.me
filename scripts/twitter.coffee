# twitter module

photo_ids = process.argv.slice 2
_ = underscore = require "underscore"

if !module.parent && _.isEmpty(photo_ids)
	throw new Error('No photo ids were passed')
	return process.exit(1)


# Module dependencies
_.str = underscore.str = require "underscore.string"
invoke = require "invoke"
ntwitter = require "ntwitter"

# L4C Library
config = require "../config.json"
helpers = require "../build/lib/helpers"

# Mongoose configuration
mongo_session = require 'connect-mongo'
mongoose = require 'mongoose'
mongoose.connect config.mongodb.app.url

model = 
	user: require "../build/models/user"
	photo: require "../build/models/photo"


# tweet_photo
module.exports.tweet_photo = tweet_photo = (photo_id, callback) ->
	twit = null
	photo = null
	user = null

	unless _.isFunction callback
		callback = () ->

	invoke (data, callback) ->
		console.log 'init find photo'
		model.photo.findOne _id: photo_id, callback


	.then (data, callback) ->
		console.log 'then find user'
		photo = data
		model.user.findOne _id: photo._user, callback


	.then (data, callback) ->
		console.log 'then verify credentials'
		user = data

		if not user.twitter
			return callback new Error('This user has no twitter account')

		twit = new ntwitter
			consumer_key: config.twitter.consumerKey
			consumer_secret: config.twitter.consumerSecret
			access_token_key: user.twitter.token
			access_token_secret: user.twitter.token_secret

		twit.verifyCredentials callback


	.then (data, callback) ->
		# create photo url
		photo_url = "http://#{_.first(_.keys(config.domains))}/#{user.username}/#{photo.slug}"

		# hashtag
		hashtag = if config.twitter.hashtag then ' ' + config.twitter.hashtag else ''
		
		# tweet format
		box = "▣"
		box_with_circle = "◘"
		box_with_circle2 = "◙"
		calendar = "⌨"
		equis = "⌧"
		tweet_format = "#{box} %s %s%s"
		
		# substract whatever whatever amount of characters we introduced with the heart, hashtag, [pic] and url
		# tweets can't be over 120
		# twitter urls are 20 characters long
		url_length = 20
		length = 120 - (_.str.sprintf(tweet_format, '', '', hashtag).length + url_length)

		# photo names will be truncated with 3 character ellipses
		photo_name = _.str.prune photo.name, length

		# create tweet status
		tweet = _.str.sprintf tweet_format, photo_name, photo_url, hashtag
		console.log 'then tweet status'
		console.log tweet

		# post tweet status
		twit.updateStatus tweet, callback
		console.log "tweet status #{photo._id} - #{photo.slug}"


	.rescue (err) ->
		console.error 'error ----------------->'
		console.error err
		# process.exit(1)
		callback err


	.end null, (data) ->
		# console.log 'end ---------------------------------------> '
		# console.log data
		# process.exit(1)
		console.log "tweet end #{photo._id} - #{photo.slug}"
		callback null, data


if !module.parent
	queue = invoke (data, callback) ->
		callback()

	_.each photo_ids, (value, key, list) ->
		queue.and (data, callback) ->
			tweet_photo value, callback

	queue.rescue (err) ->
		process.exit 1

	queue.end null, (data) ->
		console.log "done"
		process.exit()