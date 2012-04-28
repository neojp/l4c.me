ie = window.ie if window['ie']?
$body = $(document.body)

window.log = () ->
	log.history = log.history || []
	log.history.push arguments

	if this.console
		arguments.callee = arguments.callee.caller
		newarr = [].slice.call arguments
		if typeof console.log == 'object'
			log.apply.call console.log, console, newarr
		else
			console.log.apply console, newarr

# get css style
$.getStyle = (url, callback) ->
	$('head').append('<link rel="stylesheet" type="text/css" href="' + url + '">')
	callback()  if $.isFunction callback

# Override getScript to use cached files, current version of jQuery doesn't allow this.
$.getScript = ( url, callback, options ) ->
	o = $.extend({}, options,
		cache: true
		dataType: 'script'
		url: url
		success: callback
		type: 'GET'
	);

	return $.ajax(o);


#############################################################################


window.Site = $.extend {}, window.Site,
	
	# add ie fallback elements
	ie_fallback: () ->
		log 'Y U NO STOP USING IE!!'
	
	# base64 - 1x1 pixel transparent image
	blank: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='

	# load images only when scrolled over
	lazyload: () ->
		$.getScript '/js/jquery.lazyload.min.js', () ->
			$('img[data-src]').lazyload
				data_attribute: 'src'
				effect: 'fadeIn'
				failure_limit: 10

	# login button on header
	login: () ->
		first = true
		active = false

		$aside = $('#header aside')
		$trigger = $('#header-login-trigger')
		$close = $('#header a.close')

		open = (e) ->
			e.stopPropagation()
			return if active

			$aside.addClass('active')
			active = true

			if first
				$aside.find('img[data-src]').lazyload( load: true )
				first = false

		close = (e) ->
			if active
				$aside.removeClass('active')
				active = false

		$trigger
			.on('click.login', open)
			.hoverIntent
				over: open
				out: $.noop

		$close.on 'click.login', close
		$body.on 'click.login', -> $close.trigger 'click.login' if active
		
		$body.on 'click.login', 'aside', (e) -> e.stopPropagation()

	# check if current browser is safari mobile
	mobile: () ->
		navigator.appVersion.toLowerCase().indexOf("mobile") > -1

	# register form
	register: () ->
		$pass = $('#password-container')
		$('#change-password').on 'change', (e) ->
			$pass.toggleClass 'hidden', this.checked


	#############################################################################


	# window.onload event
	load: () ->
		log 'Window on Load'
		Site.lazyload()

	# document.ready event
	init: () ->
		log 'DOM Ready'
		Site.login()
		Site.register()


	#############################################################################


	# load 3rd party scripts
	load_scripts: () ->
		invoke (data, callback) ->
			# hoverIntent
			$.getScript '/js/jquery.hoverIntent.minified.js', -> callback()
		
		.rescue (err) ->
			log 'error: ', err
		
		.end null, Site.init


#############################################################################


$(document).on 'ready', Site.load_scripts
$(window).on 'load', Site.load