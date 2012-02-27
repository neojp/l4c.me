var LocalStrategy, app, error_handler, express, fs, helpers, http, im, invoke, l4c, middleware, model, mongo_session, mongoose, passport, underscore, _;

http = require('http');

express = require('express');

_ = underscore = require('underscore');

_.str = underscore.str = require('underscore.string');

fs = require('fs');

invoke = require('invoke');

app = module.exports = express.createServer();

im = require('imagemagick');

l4c = require('./lib');

helpers = l4c.helpers;

error_handler = l4c.error_handler;

middleware = l4c.middleware(app);

mongo_session = require('connect-mongo');

mongoose = require('mongoose');

mongoose.connect('mongodb://localhost/l4c');

model = require('./models');

passport = require('passport');

LocalStrategy = require('passport-local').Strategy;

passport.serializeUser(function(user, next) {
  return next(null, user.username);
});

passport.deserializeUser(function(username, next) {
  return model.user.deserialize(username, next);
});

passport.use(new LocalStrategy(function(username, password, next) {
  return model.user.login(username, password, next);
}));

app.configure(function() {
  var oneYear;
  app.set('views', __dirname + '/public/templates');
  app.set('view engine', 'jade');
  app.set('strict routing', true);
  app.use(express.favicon());
  oneYear = 31556926000;
  app.use(express.static(__dirname + '/public', {
    maxAge: oneYear
  }));
  app.use(express.logger({
    format: ':status ":method :url"'
  }));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.cookieParser(helpers.heart));
  app.use(express.session({
    secret: helpers.heart,
    store: new mongo_session({
      url: 'mongodb://localhost/l4c/sessions'
    })
  }));
  app.use(passport.initialize());
  app.use(passport.session());
  app.use(app.router);
  return app.use(error_handler);
});

app.param('page', function(req, res, next, id) {
  if (id.match(/[0-9]+/)) {
    req.param.page = parseInt(req.param.page);
    return next();
  } else {
    return next(404);
  }
});

app.param('size', function(req, res, next, id) {
  if (id === 'p' || id === 'm' || id === 'g' || id === 'o') {
    return next();
  } else {
    return next('route');
  }
});

app.param('slug', function(req, res, next, id) {
  if (id !== 'editar') {
    return next();
  } else {
    return next('route');
  }
});

app.param('sort', function(req, res, next, id) {
  if (id === 'ultimas' || id === 'top') {
    return next();
  } else {
    return next('route');
  }
});

app.param('user', function(req, res, next, id) {
  if (id !== 'ultimas' && id !== 'top' && id !== 'galeria' && id !== 'pag' && id !== 'publicar') {
    return next();
  } else {
    return next('route');
  }
});

app.all('*', middleware.remove_trailing_slash, function(req, res, next) {
  console.log(req.originalUrl);
  res.locals({
    _: underscore,
    body_class: '',
    document_title: 'L4C.me',
    original_url: req.originalUrl,
    logged_user: req.isAuthenticated() ? req.user : null,
    page: 1,
    helpers: helpers,
    photos: []
  });
  return next('route');
});

app.get('/', middleware.hmvc('/fotos/:sort?'));

app.get('/fotos/:user/:slug', function(req, res, next) {
  var slug, user;
  slug = req.param('slug');
  user = req.param('user');
  return model.photo.findOne({
    slug: slug
  }).populate('_user').populate('_tags').run(function(err, photo) {
    var locals;
    if (err) return next(err);
    if (photo === null) return next(404);
    photo.views += 1;
    photo.save();
    locals = {
      body_class: 'single',
      slug: slug,
      photo: photo,
      user: user
    };
    return res.render('gallery_single', {
      locals: locals
    });
  });
});

app.get('/fotos/:user/:slug/sizes/:size', function(req, res) {
  var slug, user;
  slug = req.param('slug');
  user = req.param('user');
  return model.photo.findOne({
    slug: slug
  }).populate('_user').populate('_tags').run(function(err, photo) {
    var locals;
    if (err) return next(err);
    if (photo === null) return next(404);
    photo.views += 1;
    photo.save();
    locals = {
      body_class: 'single sizes',
      photo: photo,
      size: req.param('size'),
      slug: slug,
      user: user
    };
    return res.render('gallery_single_large', {
      locals: locals
    });
  });
});

app.get('/fotos/:user/pag/:page?', middleware.paged('/fotos/:user'));

app.get('/fotos/:user', function(req, res, next) {
  var page, per_page, photos, user, username;
  username = req.param('user');
  per_page = helpers.pagination;
  page = req.param('page', 1);
  user = null;
  photos = null;
  return invoke(function(data, callback) {
    return model.user.findOne({
      username: username
    }, function(err, user) {
      return callback(err, user);
    });
  }).then(function(data, callback) {
    if (!data) return error_handler(404)(req, res);
    user = data;
    return model.photo.count({
      _user: user._id
    }, callback);
  }).and(function(data, callback) {
    return photos = model.photo.find({
      _user: user._id
    }).limit(per_page).skip(per_page * (page - 1)).desc('created_at').populate('_user').run(callback);
  }).rescue(function(err) {
    if (err) return next(err);
  }).end(user, function(data) {
    var count;
    count = data[0];
    photos = data[1];
    res.locals({
      body_class: 'gallery liquid',
      pages: Math.ceil(count / per_page),
      path: "/fotos/" + user.username,
      photos: photos,
      sort: null,
      total: count
    });
    return res.render('gallery');
  });
});

app.get('/fotos/:sort/pag/:page?', middleware.paged('/fotos/:sort?'));

app.get('/fotos/ultimas', function(req, res) {
  return res.redirect('/fotos', 301);
});

app.get('/fotos/:sort?', function(req, res, next) {
  var page, per_page, photos, query, sort;
  sort = req.param('sort', 'ultimas');
  page = req.param('page', 1);
  per_page = helpers.pagination;
  photos = null;
  query = {};
  return invoke(function(data, callback) {
    return model.photo.count(query, callback);
  }).and(function(data, callback) {
    photos = model.photo.find(query).limit(per_page).skip(per_page * (page - 1)).populate('_user');
    if (sort === 'ultimas') photos.desc('created_at');
    if (sort === 'top') photos.desc('views', 'created_at');
    return photos.run(callback);
  }).rescue(function(err) {
    if (err) return next(err);
  }).end(null, function(data) {
    var count;
    count = data[0];
    photos = data[1];
    res.locals({
      body_class: "gallery liquid " + sort,
      pages: Math.ceil(count / per_page),
      path: "/fotos/" + sort,
      photos: photos,
      sort: sort,
      total: count
    });
    return res.render('gallery');
  });
});

app.get('/fotos/galeria/pag/:page?', middleware.paged('/fotos/galeria'));

app.get('/fotos/galeria', function(req, res, next) {
  var page, per_page, photos, query, sort;
  sort = 'galeria';
  page = req.param('page', 1);
  per_page = helpers.pagination;
  photos = null;
  query = {};
  return invoke(function(data, callback) {
    return model.photo.count(query, callback);
  }).and(function(data, callback) {
    return model.photo.find(query).desc('created_at').limit(per_page).skip(per_page * (page - 1)).populate('_user').run(callback);
  }).rescue(function(err) {
    if (err) return next(err);
  }).end(null, function(data) {
    var count;
    count = data[0];
    photos = data[1];
    res.locals({
      body_class: "gallery liquid " + sort,
      total: Math.ceil(count / per_page),
      path: "/fotos/" + sort,
      sort: sort,
      photos: photos
    });
    return res.render('gallery');
  });
});

app.get('/tags/:tag/pag/:page?', middleware.paged('/tags/:tag'));

app.get('/tags/:tag', function(req, res) {
  var page, tag;
  tag = req.params.tag;
  page = parseInt(req.param('page', 1));
  return res.send("GET /tags/" + tag + "/pag/" + page, {
    'Content-Type': 'text/plain'
  });
});

app.get('/tags', function(req, res) {
  return res.send("GET /tags", {
    'Content-Type': 'text/plain'
  });
});

app.get('/feed/:user', function(req, res) {
  var user;
  user = req.param('user');
  return res.send("GET /feed/" + user, {
    'Content-Type': 'text/plain'
  });
});

app.get('/login', function(req, res, next) {
  if (req.isAuthenticated()) return res.redirect('/');
  return res.render('login');
});

app.post('/login', passport.authenticate('local', {
  failureRedirect: '/login'
}), function(req, res, next) {
  var flash, url;
  flash = req.flash('auth_redirect');
  url = _.size(flash) ? _.first(flash) : '/';
  return res.redirect(url);
});

app.get('/logout', function(req, res, next) {
  req.logout();
  return res.redirect('/');
});

app.get('/registro', function(req, res, next) {
  return res.render('register');
});

app.post('/registro', function(req, res, next) {
  var d, u;
  d = req.body;
  u = new model.user;
  return invoke(function(data, callback) {
    if (d.clab_boolean === 'yes') u.clab = d.clab;
    u.email = d.email;
    u.password = d.password;
    u.username = d.username;
    return u.save(function(err) {
      return callback(err);
    });
  }).rescue(function(err) {
    if (err) return next(err);
  }).end(null, function(data) {
    return passport.authenticate('local', {
      successRedirect: '/perfil',
      failureRedirect: '/'
    })(req, res);
  });
});

app.get('/fotos/publicar', middleware.auth, function(req, res) {
  return res.render('gallery_upload');
});

app.post('/fotos/publicar', middleware.auth, function(req, res, next) {
  var description, file, file_ext, file_path, name, photo, photo_tags, queue, tags, user;
  user = req.user;
  name = req.body.name;
  description = req.body.description;
  tags = _.str.trim(req.body.tags);
  tags = tags.length > 0 ? tags.split(' ') : [];
  file = req.files.file;
  file_ext = helpers.image.extensions[file.type];
  file_path = "";
  photo = new model.photo;
  photo_tags = [];
  queue = invoke(function(data, callback) {
    photo.name = name;
    if (description && description !== '') photo.description = description;
    photo.ext = file_ext;
    photo._user = user._id;
    return photo.save(function(err) {
      console.log("photo create - " + name);
      return callback(err);
    });
  }).then(function(data, callback) {
    return photo.upload_photo(file, callback);
  }).and(function(data, callback) {
    return photo.resize_photos(callback);
  });
  if (tags.length > 0) {
    queue.and(function(data, callback) {
      return photo.set_tags(tags, callback);
    });
  }
  return queue.then(function(data, callback) {
    return photo.set_slug(function(photo_slug) {
      console.log("photo set slug - " + photo_slug);
      return callback(null, photo_slug);
    });
  }).rescue(function(err) {
    console.log("photo error");
    if (err) return next(err);
  }).end(null, function(photo_slug) {
    console.log("photo end - redirect");
    return res.redirect("/fotos/" + user.username + "/" + photo_slug);
  });
});

app.get('/fotos/:user/:slug/editar', middleware.auth, function(req, res) {
  var photo, slug, user, username;
  slug = req.param('slug');
  username = req.param('user');
  user = null;
  photo = null;
  return invoke(function(data, callback) {
    return model.user.findOne({
      username: username
    }, function(err, user) {
      return callback(err, user);
    });
  }).then(function(data, callback) {
    if (!data) return error_handler(404)(req, res);
    user = data;
    return model.photo.findOne({
      _user: user._id,
      slug: slug
    }).populate('_user').populate('_tags').run(callback);
  }).then(function(data, callback) {
    if (!data) photo.resize_photos(404.(req, res));
    if (!_.isEqual(user._id, req.user._id)) return error_handler(403)(req, res);
    return photo = data;
  }).rescue(function(err) {
    if (err) return next(err);
  }).end(user, function(data) {
    res.locals({
      body_class: 'single edit',
      path: "/fotos/" + user.username + "/" + photo.slug + "/editar",
      photo: photo,
      slug: slug,
      user: username
    });
    return res.render('gallery_single');
  });
});

app.put('/fotos/:user/:slug', middleware.auth, function(req, res) {
  var slug, user;
  user = req.param('user');
  slug = req.param('slug');
  return res.send("PUT /fotos/" + user + "/" + slug, {
    'Content-Type': 'text/plain'
  });
});

app["delete"]('/fotos/:user/:slug', middleware.auth, function(req, res) {
  var slug, user;
  user = req.param('user');
  slug = req.param('slug');
  return res.send("DELETE /fotos/" + user + "/" + slug, {
    'Content-Type': 'text/plain'
  });
});

app.get('/perfil', middleware.auth, function(req, res) {
  return res.send("GET /perfil", {
    'Content-Type': 'text/plain'
  });
});

app.put('/perfil', middleware.auth, function(req, res) {
  return res.send("PUT /perfil", {
    'Content-Type': 'text/plain'
  });
});

app.get('/tweets', middleware.auth, function(req, res) {
  return res.send("GET /tweets", {
    'Content-Type': 'text/plain'
  });
});

app.all('*', error_handler(404));

if (!module.parent) {
  app.listen(3000);
  console.log("Listening on port %d", app.address().port);
}
