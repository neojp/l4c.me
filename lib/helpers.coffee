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

	logger_format: (tokens, req, res) ->
		status = res.statusCode
		color = 
			if status >= 500 then 31
			else if status >= 400 then 33
			else if status >= 300 then 36
			else 32

		d = moment()
		date = d.format 'YYYY/MM/DD HH:mm:ss ZZ'

		ip_address = req.headers['x-forwarded-for'] ? req.connection.remoteAddress

		return '' +
			'\033[' + color + 'm' + res.statusCode +
			' \033[90m' + date + '  ' +
			' \033[90m' + req.method +
			' \033[0m' + req.originalUrl +
			' \033[90m' + (new Date - req._startTime) + 'ms' +
			'          \033[90m' + ip_address +
			'\033[0m'

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