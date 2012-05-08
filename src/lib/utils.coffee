app.get '/random', middleware.auth, (req, res, next) ->
	return next() if req.user.username != 'neojp'

	model.user.find {}, (err, data) ->
		return next err if err
		_.each data, (item, index) ->
			item.random = index
			item.save()

		res.json data


app.get '/resize_images', middleware.auth, (req, res, next) ->
	return next() if req.user.username != 'neojp'

	model.photo.find {}, (err, photos) ->
		return next err if err
		
		_.each photos, (photo, index) ->
			photo.resize_photos()

		res.json photos