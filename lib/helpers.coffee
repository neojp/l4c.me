_ = underscore = require 'underscore'
_.str = underscore.str = require 'underscore.string'
gravatar = require 'gravatar'

marked = require 'marked'
marked.setOptions
	gfm: true
	pedantic: false
	sanitize: true

moment = require 'moment'
moment.lang 'es'


module.exports =
	gravatar: (email, size) ->
		gravatar.url email, { s: size }

	heart: '♥'

	image:
		extensions:
			'image/jpeg': 'jpg'
			'image/pjpeg': 'jpg'
			'image/gif': 'gif'
			'image/png': 'png'

		sizes:
			l:
				action: 'resize'
				height: 728
				size: 'l'
				width: 970
			m:
				action: 'resize'
				height: 450
				size: 'm'
				width: 600
			s:
				action: 'crop'
				height: 190
				size: 's'
				width: 190
			t:
				action: 'crop'
				height: 75
				size: 't'
				width: 100

	markdown: (str) ->
		marked(str) if _.isString(str)

	pagination: 20

	pretty_date: (date) ->
		moment(date).fromNow(true)

	random_query: () ->
		rand = Math.random()
		random = [
			{ random: $gte: rand }
			{ random: $lte: rand }
		]

	slugify: (str) ->
		str = str.replace /^\s+|\s+$/g, ''
		str = str.toLowerCase()

		# remove accents, swap ñ for n, etc
		from = "àáäâèéëêìíïîòóöôùúüûñç®©·/_,:;"
		to   = "aaaaeeeeiiiioooouuuuncrc------"

		for i, character of from.split ''
			str = str.replace new RegExp(character, 'g'), to.charAt i
		
		# trademark sign
		str = str.replace new RegExp('™', 'g'), 'tm'

		# remove invalid chars
		str = str.replace /[^a-z0-9 -]/g, ''

		# collapse whitespace and replace by -
		str = str.replace /\s+/g, '-'
		
		# collapse dashes
		str = str.replace /-+/g, '-'