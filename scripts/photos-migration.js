// Module dependencies
var _ = underscore = require('underscore'),
    invoke = require('invoke'),
    spawn = require('child_process').spawn;


// L4C Library
var config = require('../config.json'),
    helpers = require('../build/lib/helpers');


// Mongoose configuration
var mongo_session = require('connect-mongo'),
    mongoose = require('mongoose'),
    Schema = mongoose.Schema,
    ObjectId = Schema.ObjectId;

mongoose.connect(config.mongodb.app.url);


// L4C Models
var model = {
	photo: require('../build/models/photo')
};



// Move photo.ext to photo.image.ext
function fix_photo_ext(next) {
	console.log('fix_photo_ext()');

	function mongodb_shell_script(){
		var fixed = 0;

		// get photos that have "photo.ext"
		var photos = db.photos.find({ ext: { $exists: 1 } }).toArray();
		var total = photos.length - 1;

		// exit script if there are no photos
		if (total < 0) {
			print('Done - Total: 0  Fixed: 0')
			return;
		}

		// loop through the photos
		photos.forEach(function(photo, i){
			// double check if photo.ext exists
			if (photo.ext) {
				// if photo.image doesn't exist, create an empty object
				if (!photo.image)
					photo.image = {};
				
				// move photo.ext to photo.image.ext
				photo.image.ext = photo.ext;
				delete photo.ext;

				// save and increment total of fixed photos
				db.photos.save(photo);
				fixed++;
			}

			// if it's the last photo, print statistics
			if (total == i) {
				print('Done - Total: ' + (total + 1) + '  Fixed: ' + fixed);
			}
		});
	};


	// parse db info and create the parameters
	var c = config.mongodb.app;
	var args = [];
	
	if (c.user)
		args.push('-u', c.user);
	
	if (c.password)
		args.push('-p', c.password);

	var host_db = c.host + (c.port ? ':' + c.port : '') + '/' + c.db;
	args.push(host_db);

	args.push('--eval');
	args.push('f = ' + mongodb_shell_script.toString() + '; f();');

	// run mongo script in a child process
	var proc = spawn('mongo', args);

	proc.stdout.on('data', function(data){
		console.log('stdout: ' + data);
	});

	proc.stderr.on('data', function(data){
		console.log('stderr: ' + data);
		process.exit();
	});

	proc.on('exit', function(code){
		console.log('exit with code: ' + code);

		if (_.isFunction(next))
			next();
	});

}



function fix_photo_dimensions(){
	console.log('fix_photo_dimensions()');

	var args = {
		$or: [
			{ 'image.height': { $exists: false } },
			{ 'image.width': { $exists: false } }
		]
	};

	model.photo.find(args, function(err, photos){
		if (err)
			throw err;

		var fixed = 0;
		var total = photos.length - 1;

		var queue = invoke(function(data, callback){
			callback();
		});

		_.each(photos, function(photo, i){
			if (i == 0) {
				console.log('------------ start ------------');
				console.log('');
				console.log('');
			}

			queue.then(function(data, callback){
				console.log(i + ': ' + photo.slug + ' -- start');
				photo.set_image_data(function(err, photo){
					if (err)
						return callback(err);

					console.log(photo.slug + ' -- end');
					console.log('');
					console.log('');

					fixed++;

					if (total == i) {
						console.log('------------ end ------------');
						console.log('')
						console.log('')
						console.log('');
						console.log('End - Total: ' + (total + 1) + '  Fixed: ' + fixed);
						process.exit();
					}

					callback(null, photo);
				});
			});
		});

		queue.rescue(function(err){
			console.log('');
			console.log('');
			console.log('');
			console.log('------------ error ------------');
			console.log(err);
			console.log('');
			console.log('');
			console.log('');
			
			process.exit();
		});

		queue.end(null, function(data){
			if (photos.length <= 0) {
				console.log('');
				console.log('End - Total: ' + (total + 1) + '  Fixed: ' + fixed);
				process.exit();
			}
		});
	});
}



// Execute code
invoke(function(data, callback){
	fix_photo_ext(callback);
})
.then(function(data, callback){
	console.log('');
	console.log('');
	console.log('-------------------------');
	console.log('');
	console.log('');
	callback();
})
.end(null, function(){
	fix_photo_dimensions();
});