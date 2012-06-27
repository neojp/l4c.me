option '-w', '--watch', 'Watch files for changes and rebuild them'

task 'build', 'Build all source files', ->
	invoke 'mkdir'

	setTimeout (-> invoke 'build:stylus'), 0
	setTimeout (-> invoke 'build:coffee-src'), 1000
	setTimeout (-> invoke 'build:coffee-static'), 2000



task 'build:stylus', 'Look for Stylus source files and build CSS files', (o) ->

	console.log "\n=== BUILD: STYLUS ==="

	# script
	command = ['node_modules/stylus/bin/stylus']
	
	# option arguments
	options = [

		# add nib support
		'--use', 'nib',

		# watch and compress
		'--compress',
		
		# Output files to /public
		'--out',
		'public'
	]

	# watch files
	if (o.watch)
		options.push '--watch'

	# list of files to compile
	files = [
		'public/stylus/l4c.styl'
	]

	# merge args & files
	args = [].concat command, options, files

	# spawn the new process
	spawn = require('child_process').spawn
	proc = spawn 'node', args

	# log output and errors
	logBuffer = (buffer) -> console.log buffer.toString()
	proc.stdout.on 'data', logBuffer
	proc.stderr.on 'data', logBuffer

	# exit process
	proc.on 'exit', (code, signal) ->
		process.exit(1) if code > 0
		# console.log 'child process terminated due to receipt of code ' + code



task 'build:coffee-src', 'Watch CoffeeScript source files and build JS files', (o) ->

	console.log "\n=== BUILD: COFFEESCRIPT-SRC (Server side) ==="

	# script
	command = ['node_modules/coffee-script/bin/coffee']

	# option arguments
	options = [
		# watch and compress
		'--bare',
		'--compile',

		# Output files to /build
		'--output',
		'build/'
	]

	# watch files
	if (o.watch)
		options.push '--watch'

	# list of files to compile
	files = [
		'src'
	]

	# merge args & files
	args = [].concat command, options, files

	# spawn the new process
	spawn = require('child_process').spawn
	proc = spawn 'node', args

	# log output and errors
	logBuffer = (buffer) -> console.log buffer.toString()
	proc.stdout.on 'data', logBuffer
	proc.stderr.on 'data', logBuffer

	# exit process
	proc.on 'exit', (code, signal) ->
		process.exit(1) if code > 0
		# console.log 'child process terminated due to receipt of code ' + code



task 'build:coffee-static', 'Watch CoffeeScript source files and build JS files', (o) ->

	console.log "\n=== BUILD: COFFEESCRIPT-STATIC (Client side) ==="

	# script
	command = ['node_modules/coffee-script/bin/coffee']

	# option arguments
	options = [
		# watch and compress
		'--bare',
		'--compile',

		# Output files on /public/js
		'--output',
		'public/js/'
	]

	# watch files
	if (o.watch)
		options.push '--watch'

	# list of files to compile
	files = [
		'public/coffee/'
	]

	# merge args & files
	args = [].concat command, options, files

	# spawn the new process
	spawn = require('child_process').spawn
	proc = spawn 'node', args

	# log output and errors
	logBuffer = (buffer) -> console.log buffer.toString()
	proc.stdout.on 'data', logBuffer
	proc.stderr.on 'data', logBuffer

	# exit process
	proc.on 'exit', (code, signal) ->
		process.exit(1) if code > 0
		# console.log 'child process terminated due to receipt of code ' + code



task 'supervisor', 'Watch source files and restart the server upon changes', (o) ->

	console.log "\n=== SUPERVISOR ==="

	# script
	command = ['node_modules/supervisor/lib/cli-wrapper.js']

	# option arguments
	options = [
		'--watch',
		'.,build/,build/lib/,build/models/',

		'--exec',
		'node',
		
		'app.js'
	]

	# merge args & files
	args = [].concat command, options

	# spawn the new process
	spawn = require('child_process').spawn
	proc = spawn 'node', args

	# log output and errors
	logBuffer = (buffer) -> console.log buffer.toString()
	proc.stdout.on 'data', logBuffer
	proc.stderr.on 'data', logBuffer

	# exit process
	proc.on 'exit', (code, signal) ->
		process.exit(1) if code > 0
		# console.log 'child process terminated due to receipt of code ' + code



task 'mkdir', 'Create directories and set permissions', ->
	
	console.log "\n=== MKDIR ===\n"

	fs   = require 'fs'
	path = require 'path'
	directories = ['public/uploads', 'logs', 'build']

	directories.forEach (dir) ->
		fs.mkdirSync dir unless path.existsSync dir
		fs.chmodSync dir, parseInt '0777'



task 'start', 'Build and run all scripts', (options) ->
	options.watch = true
	setTimeout (-> invoke 'build'), 0
	setTimeout (-> invoke('supervisor')), 3000