task 'build:stylus', 'Watch Stylus source files and build CSS files', ->

	# script
	command = ['node_modules/stylus/bin/stylus']
	
	# option arguments
	options = [

		# add nib support
		'--use', 'nib',

		# watch and compress
		'--compress',
		'--watch',

		# Output files on /public
		'--out',
		'public'
	]

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
		console.log 'child process terminated due to receipt of code ' + code



task 'build:coffee-src', 'Watch CoffeeScript source files and build JS files', ->

	# script
	command = ['node_modules/coffee-script/bin/coffee']

	# option arguments
	options = [
		# watch and compress
		'--bare',
		'--watch',
		'--compile'
	]

	# list of files to compile
	files = [
		'app',
		'lib/',
		'models'
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
		console.log 'child process terminated due to receipt of code ' + code



task 'build:coffee-static', 'Watch CoffeeScript source files and build JS files', ->

	# script
	command = ['node_modules/coffee-script/bin/coffee']

	# option arguments
	options = [
		# watch and compress
		'--bare',
		'--watch',
		'--compile',

		# Output files on /public/js
		'--output',
		'public/js/'
	]

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
		console.log 'child process terminated due to receipt of code ' + code



task 'supervisor', 'Watch source files and restart the server upon changes', ->

	# script
	command = ['node_modules/supervisor/lib/cli-wrapper.js']

	# option arguments
	options = [
		'--watch',
		'.,lib,models',
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
		console.log 'child process terminated due to receipt of code ' + code



task 'mkdir', 'Create directories and set permissions', ->
	fs   = require 'fs'
	path = require 'path'

	directories = ['public/uploads', 'logs']

	directories.forEach (dir) ->
		fs.mkdirSync dir unless path.existsSync dir
		fs.chmodSync dir, parseInt '0777'



task 'start', 'Build and run all scripts', ->
	invoke 'mkdir'

	setTimeout (-> invoke 'build:stylus'), 0
	setTimeout (-> invoke 'build:coffee-src'), 1000
	setTimeout (-> invoke 'build:coffee-static'), 2000
	setTimeout (-> invoke('supervisor')), 3000