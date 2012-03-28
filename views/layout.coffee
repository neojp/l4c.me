doctype 5
html lang: 'es', ->
	head ->
		meta charset: 'utf-8'
		title "#{@document_title} &hearts;"
		link rel: 'stylesheet', href: '/l4c.css'
		meta name: 'description', value: 'L4C'
		script src: '/js/modernizr-1.7.min.js'
	
	body class: @body_class || '', ->
		script -> '''document.body.className += ' js-enable ';'''

		div '#overflow', ->
		
			header ->
				div '.wrap', ->
					p '#logo', ->
						a href: '/', title: 'L4C.me', ->
							img src: '/images/logo.png', alt: '', tabindex: -1, width: 96, height: 49
					
					div '#nav-aside.clearfix', ->
						nav ->
							ul '.menu', ->
								classname = ''

								classsname = 'active' if @original_url == '/'
								li class: classname, ->
									a href: "/" , -> 'Inicio'
								
								classsname = 'active' if @original_url == '/fotos/publicar'
								li class: classname, ->
									a href:"/fotos/publicar", -> 'Subir'
								
								if (@logged_user)
									classsname = 'active' if @original_url.indexOf "/#{@logged_user.username}" != -1
									li class: classname, ->
										a href:"/#{@logged_user.username}", -> 'Mis Fotos'

								if (@original_url not in ['/', '/fotos/publicar']) && (@logged_user && @original_url.indexOf("/#{@logged_user.username}") == -1)
									classname = 'active'

								li class: classname, ->
									a href:"/fotos", -> 'galeria'

						hr class: 'hidden'

						if @logged_user
							aside ->
								p ->
									'Hola '
									a '.username', href: "/#{@logged_user.username}", -> @logged_user.username
									', puedes editar tu '
									a '.profile', href: "/perfil/", -> 'perfil'
									' o '
									a '.logout', href: "/logout/", -> 'salir'
						else
							aside ->
								form method: "post", action: "/login", ->
									p ->
										input type: "text", name: "username", placeholder: "Username", tabindex: 1
										input type: "password", name: "password", placeholder: "Password", tabindex: 2
										button type: "submit", tabindex: 3, -> 'Submit'
			
			hr class: 'hidden'

			section '#inner', ->
				div '#wrap.wrap', ->
					p '#message', ->
						text 'No te pierdas lo nuevo de L4C, un concurso nuevo cada mes. '
						a '.more', href: "/concursos/", -> 'Leer m&aacute;s'
						a '.close', -> 'Cerrar [x]'
				
					hr '.hidden'

					div '#container.clearfix', -> @body
			
			hr class: 'hidden'
			
			footer ->
				ul ->
					li '#claborg', ->
						a href: "http://www.cristalab.org/", -> 'Cristalab.org'
					li '#cristalab', ->
						a href: "http://cristalab.com/", -> 'Cristalab'
					li '#l4c', ->
						a href: "http://l4c.me/", -> 'Sube tus im&aacute;genes'
					li '#tiaxime', ->
						a href: "http://tiaxime.come/", -> 'Consejos de amor'
					li '#dotgaia', ->
						a href: "http://dotgaia.com/", -> 'dotGaia.com'
					li '#p3', ->
						a href: "http://puls3.com/", -> 'Puls3.com'
			
			section '#js', ->
				script ->
					'''
					Site = {};
					window.onload = function(){ document.body.className += ' js-ready '; }
					'''
				
				script '#analytics', ->
					'''
					var _gaq = _gaq || []; _gaq.push(['_setAccount', 'UA-1102463-13']); _gaq.push(['_trackPageview']); (function() { var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true; ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js'; var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s); })();
					'''