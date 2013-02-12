# Module dependencies
express           = require 'express'
mongo_session     = require('connect-mongo')(express)
passport          = require 'passport'
passport_facebook = require('passport-facebook').Strategy
passport_local    = require('passport-local').Strategy
passport_twitter  = require('passport-twitter').Strategy


# Initialize app
app            = express()
module.exports = app


# L4C library
config        = require '../config.json'
model         = require './models'


# Express session
app.use express.session {
	key: config.session.key
	secret: config.session.secret
	store: new mongo_session({
		collection: config.session.collection || 'sessions'
		url: config.mongodb.system.url
		# clear_interval: 60 * 1000
		# clear_interval: 3600
	})
	cookie:
		maxAge: config.session.max_age || 30 * 24 * 60 * 60 * 1000 # 30 days
		secure: config.session.secure || false
}


# passport configuration
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


# initialize passport + session
app.use passport.initialize()
app.use passport.session()