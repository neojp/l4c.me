_ = underscore = require 'underscore'
_.str = underscore.str = require 'underscore.string'


module.exports =
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
