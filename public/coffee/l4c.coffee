(($) ->

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

		#
		disabled: () ->
			$('a.disabled').on 'click', (e) ->
				e.preventDefault()
				e.stopPropagation()

		# add ie fallback elements
		ie_fallback: () ->
			log 'Y U NO STOP USING IE!! ლ(ಠ益ಠლ)'
		
		# base64 - 1x1 pixel transparent image
		blank: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='

		# load images only when scrolled over
		lazyload: () ->
			$('img[data-src]').lazyload
				data_attribute: 'src'
				effect: 'fadeIn'
				failure_limit: 10

		# logged in dropdown on header
		logged_header: () ->
			active = false

			$container = $('#header-profile')
			$trigger = $('#header-gravatar')

			open = (e) ->
				e.stopPropagation()
				e.preventDefault()
				return if active

				active = true
				$container.addClass('active')
				
				$links = $container.find('ul a').removeAttr('tabindex')
				$links.eq(0).trigger('focus')

			close = (e) ->
				if !active
					return

				$container.removeClass('active')
				$container.find('ul a').attr('tabindex', '-1')
				$trigger.trigger('focus')
				active = false

			$trigger.on 'click.header', (e) ->
				e.preventDefault()

				if !active
					open e
				else
					close e

			$trigger.hoverIntent
				over: open
				out: $.noop

			$body.on 'click.header', -> close 'click.login' if active
			$body.on 'keyup', (e) -> close 'click.login' if active && e.which == 27
			$container.on 'click.header', (e) -> e.stopPropagation()

		# check if current browser is safari mobile
		mobile: () ->
			navigator.appVersion.toLowerCase().indexOf("mobile") > -1

		# profile form
		profile: () ->
			$pass = $('#password-container')
			$change = $('#change-password')

			$change.on 'change', (e) ->
				checked = this.checked
				$pass.toggleClass 'hidden', !checked
				$(this).parent().toggleClass 'hidden', checked
				
				if checked
					$('.password').trigger 'focus'
				else
					$('.change-password-trigger').trigger 'focus'

			$('.change-password-trigger').on 'click', (e) ->
				e.stopPropagation()
				e.preventDefault()
				log this
				
				change = $change[0]
				change.checked = !change.checked
				$change.trigger 'change'

			$('.cancel').on 'click', 'a', (e) ->
				e.preventDefault()
				$('.change-password-trigger').trigger 'click'


		#########################################################################


		# window.onload event
		load: () ->
			log 'Window on Load'
			Site.lazyload()

		# document.ready event
		init: () ->
			log 'DOM Ready'
			Site.logged_header()
			Site.profile()
			Site.disabled()


	#############################################################################


	# document.ready
	Site.init()

	# window.load
	if $('body').hasClass('js-ready')
		Site.load()
	else
		$(window).on 'load', Site.load

)(jQuery)