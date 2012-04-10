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

window.Site = {
	
	# add ie fallback elements
	ie_fallback: () ->
		log 'Y U NO STOP USING IE!!'
	
	# base64 - 1x1 pixel transparent image
	blank: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAMAAAAoyzS7AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////AAAAVcLTfgAAAAF0Uk5TAEDm2GYAAAAMSURBVHjaYmAACDAAAAIAAU9tWeEAAAAASUVORK5CYII='

	header: () ->
		$('#header').on 'click', 'aside a.button', (e) ->
			$(this).parent().toggleClass('active')

	# check if current browser is safari mobile
	mobile: () ->
		return navigator.appVersion.toLowerCase().indexOf("mobile") > -1

	# window.onload event
	load: () ->
		log 'Window on Load'

	# document.ready event
	init: () ->
		log 'DOM Ready'
		Site.header();
		$(window).bind 'load', Site.load

}

Site.init()