_ = underscore = require 'underscore'
_.str = underscore.str = require 'underscore.string'
gravatar = require 'gravatar'
colors = require 'colors'

marked = require 'marked'
marked.setOptions
	gfm: true
	pedantic: false
	sanitize: true

moment = require 'moment'
moment.lang 'es'


module.exports =
	format_number: (num) ->
		p = (num + '').split ''
		p.reverse().reduce(
			(acc, num, i, orig) ->
				num + (if i && !(i % 3) then "," else "") + acc
			""
		)
	
	gravatar: (email, size) ->
		gravatar.url email, { s: size }

	heart: '♥'

	image:
		blank: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
		
		extensions:
			'image/jpeg': 'jpg'
			'image/pjpeg': 'jpg'
			'image/gif': 'gif'
			'image/png': 'png'

		sizes:
			l:
				action: 'resize'
				height: 720
				size: 'l'
				width: 960
			m:
				action: 'resize'
				height: 540
				size: 'm'
				width: 720
			s:
				action: 'crop'
				height: 128
				size: 's'
				width: 170
			t:
				action: 'crop'
				height: 75
				size: 't'
				width: 100

	logger_format: (tokens, req, res) ->
		status = res.statusCode
		color  =
			if status >= 500
				'red'
			else if status >= 400
				'yellow'
			else if status >= 300
				'cyan'
			else
				'green'

		status     = colors[color] status
		date       = colors.grey moment().format 'YYYY/MM/DD HH:mm:ss ZZ'
		method     = colors.grey req.method
		url        = colors.white req.originalUrl
		time       = colors.grey (new Date() - req._startTime) + 'ms'
		ip_address = colors.grey req.headers['x-forwarded-for'] ? req.connection.remoteAddress

		return "#{status}  #{date}   #{method}  #{url}  #{time}          #{ip_address}"

	markdown: (str) ->
		if _.isString(str)
			html = marked(str)
			return html = html.replace /<a /g, '<a rel="nofollow" target="_blank" '

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

	yuno: 'ლ(ಠ益ಠლ)'