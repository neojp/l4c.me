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

		footer: () ->
			html = """
				<div id="footer">
					<ul>
						<li id="claborg">
							<a href="http://www.cristalab.org/" target="_blank" rel="nofollow">Cristalab.org</a>
						</li>
						<li id="cristalab">
							<a href="http://cristalab.com/" target="_blank" rel="nofollow">Cristalab</a>
						</li>
						<li id="tiaxime">
							<a href="http://tiaxime.com/" target="_blank" rel="nofollow">Consejos de amor</a>
						</li>
						<li id="github">
							<a href="https://github.com/neojp/l4c.me/" target="_blank" rel="nofollow">Contribuye a Clabie.com en GitHub.com</a>
						</li>
					</ul>
				</div>
			"""
			console.log html
			$('#js').before html

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
			animated = false

			$container = $('#header-profile')
			$trigger = $('#header-gravatar')
			$dropdown = $container.find('ul')
			transition_end = 'transitionend oTransitionEnd webkitTransitionEnd'

			open = (e) ->
				return if animated || active
				
				if e
					e.stopPropagation()
					e.preventDefault()

				animated = true
				active = true

				$container.addClass('active')
				$links = $container.find('ul a').removeAttr('tabindex')
				$trigger.trigger('focus')

				$dropdown.on transition_end, (e) ->
					$dropdown.off()
					animated = false

			close = (e) ->
				return if animated || !active

				if e
					e.stopPropagation()
					e.preventDefault()

				animated = true
				active = false

				$container.removeClass('active')
				$container.find('ul a').attr('tabindex', '-1')
				$trigger.trigger('focus')

				$dropdown.on transition_end, (e) ->
					$dropdown.off()
					animated = false

			$trigger.on 'click.header', (e) ->
				e.preventDefault()

				if !active
					open e
				else
					close e

			$trigger.hoverIntent
				over: open
				out: $.noop

			$body.on 'click.header', (e) -> close e if active
			$body.on 'keyup', (e) -> close e if active && e.which == 27
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
			Site.footer()

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