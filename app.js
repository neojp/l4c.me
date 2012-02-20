(function() {
  var CommentSchema, Email, LocalStrategy, ObjectId, Photo, PhotoSchema, Schema, Tag, TagSchema, Url, User, UserSchema, app, express, helpers, middleware, mongoose, mongooseTypes, passport, underscore, _;

  express = require('express');

  _ = underscore = require('underscore');

  app = module.exports = express.createServer();

  mongoose = require('mongoose');

  mongooseTypes = require('mongoose-types');

  mongooseTypes.loadTypes(mongoose);

  mongoose.connect('mongodb://localhost/l4c');

  Schema = mongoose.Schema;

  ObjectId = Schema.ObjectId;

  Email = mongoose.SchemaTypes.Email;

  Url = mongoose.SchemaTypes.Url;

  UserSchema = new Schema({
    _photos: [
      {
        type: ObjectId,
        ref: 'Photo'
      }
    ],
    clab: String,
    created_at: {
      "default": Date.now,
      type: Date
    },
    email: {
      lowercase: true,
      required: true,
      type: Email,
      unique: true
    },
    password: {
      required: true,
      type: String
    },
    username: {
      lowercase: true,
      required: true,
      type: String,
      unique: true
    }
  });

  CommentSchema = new Schema({
    _user: [
      {
        type: ObjectId,
        ref: 'User',
        required: true
      }
    ],
    body: {
      type: String,
      required: true
    },
    created_at: {
      "default": Date.now,
      type: Date
    }
  });

  PhotoSchema = new Schema({
    _tags: [
      {
        type: ObjectId,
        ref: 'Tag'
      }
    ],
    _user: [
      {
        type: ObjectId,
        ref: 'User',
        required: true
      }
    ],
    comments: [CommentSchema],
    created_at: {
      "default": Date.now,
      required: true,
      type: Date
    },
    description: String,
    name: {
      required: true,
      type: String
    },
    sizes: {
      m: String,
      s: String,
      o: String
    },
    slug: {
      required: true,
      type: String,
      unique: true
    },
    views: {
      "default": 0,
      type: Number
    }
  });

  TagSchema = new Schema({
    count: {
      "default": 0,
      type: Number
    },
    name: {
      lowercase: true,
      type: String,
      required: true,
      unique: true
    }
  });

  Photo = mongoose.model('Photo', PhotoSchema);

  Tag = mongoose.model('Tag', TagSchema);

  User = mongoose.model('User', UserSchema);

  passport = require('passport');

  LocalStrategy = require('passport-local').Strategy;

  passport.serializeUser(function(user, next) {
    return next(null, user.username);
  });

  passport.deserializeUser(function(username, next) {
    var model;
    model = mongoose.model('User');
    return model.findOne({
      username: username
    }, function(err, doc) {
      if (err) return next(null, false);
      return next(null, doc);
    });
  });

  passport.use(new LocalStrategy(function(username, password, next) {
    var model;
    model = mongoose.model('User');
    console.log('local strategy', username, password, model);
    return model.findOne({
      username: username,
      password: password
    }, function(err, doc) {
      if (err) return next(err, false);
      return next(null, doc);
    });
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
    app.use(express.cookieParser());
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(express.session({
      secret: '♥'
    }));
    app.use(passport.initialize());
    app.use(passport.session());
    return app.use(app.router);
  });

  middleware = {
    auth: function(req, res, next) {
      if (req.isAuthenticated()) return next();
      req.flash('auth_redirect', req.originalUrl);
      return res.redirect('/login');
    },
    hmvc: function(path) {
      return function(req, res, next) {
        var callback, route;
        route = app.match.get(path);
        route = _.filter(route, function(i) {
          return i.path === path;
        });
        route = _.first(route);
        callback = _.last(route.callbacks);
        if (_.isFunction(callback)) {
          return callback(req, res);
        } else {
          return next('route');
        }
      };
    },
    paged: function(path) {
      return function(req, res, next) {
        var i, page, path_var, path_vars, redirection;
        redirection = path.replace('?', '');
        path_vars = _.filter(redirection.split('/'), function(i) {
          return i.charAt(0) === ':';
        });
        for (path_var in path_vars) {
          i = path_vars[path_var];
          redirection = redirection.replace(i, req.params[i.substring(1)]);
        }
        page = parseInt(req.param('page', 1));
        res.local('page', page);
        if (page === 1) return res.redirect(redirection, 301);
        return middleware.hmvc(path)(req, res, next);
      };
    },
    remove_trailing_slash: function(req, res, next) {
      var length, url;
      url = req.originalUrl;
      length = url.length;
      if (length > 1 && url.charAt(length - 1) === '/') {
        url = url.substring(0, length - 1);
        return res.redirect(url, 301);
      }
      return next();
    }
  };

  helpers = {
    slugify: function(str) {
      var character, from, i, to, _ref;
      str = str.replace(/^\s+|\s+$/g, '');
      str = str.toLowerCase();
      from = "àáäâèéëêìíïîòóöôùúüûñç®©·/_,:;";
      to = "aaaaeeeeiiiioooouuuuncrc------";
      _ref = from.split('');
      for (i in _ref) {
        character = _ref[i];
        str = str.replace(new RegExp(character, 'g'), to.charAt(i));
      }
      str = str.replace(new RegExp('™', 'g'), 'tm');
      str = str.replace(/[^a-z0-9 -]/g, '');
      str = str.replace(/\s+/g, '-');
      return str = str.replace(/-+/g, '-');
    }
  };

  app.param('page', function(req, res, next, id) {
    if (id.match(/[0-9]+/)) {
      req.param.page = parseInt(req.param.page);
      return next();
    } else {
      return next(404);
    }
  });

  app.param('size', function(req, res, next, id) {
    if (id === 'p' || id === 'm' || id === 'o') {
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
    if (id === 'ultimas' || id === 'top' || id === 'galeria') {
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
    res.locals({
      _: underscore,
      body_class: '',
      url: req.originalUrl,
      user: req.isAuthenticated() ? req.user : null,
      page: 1
    });
    res.locals(helpers);
    return next('route');
  });

  app.get('/', middleware.hmvc('/fotos/:sort?'));

  app.get('/fotos/:user/:slug', function(req, res) {
    res.locals({
      body_class: 'single',
      photo: {
        user: req.param('user'),
        slug: req.param('slug')
      }
    });
    return res.render('gallery_single');
  });

  app.get('/fotos/:user/:slug/sizes/:size', function(req, res) {
    res.local('body_class', 'sizes');
    return res.render('gallery_single_large');
  });

  app.get('/fotos/:user', function(req, res) {
    res.local('body_class', 'gallery liquid');
    return res.render('gallery');
  });

  app.get('/fotos/:sort/pag/:page?', middleware.paged('/fotos/:sort?'));

  app.get('/fotos/ultimas', function(req, res) {
    return res.redirect('/fotos', 301);
  });

  app.get('/fotos/:sort?', function(req, res, next) {
    var sort;
    sort = req.param('sort', 'ultimas');
    res.locals({
      sort: sort,
      path: "/fotos/" + sort,
      body_class: "gallery liquid " + sort
    });
    return res.render('gallery');
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

  app.get('/login', function(req, res) {
    if (req.isAuthenticated()) return res.redirect('/');
    return res.render('login');
  });

  app.post('/login', passport.authenticate('local', {
    failureRedirect: '/login'
  }), function(req, res) {
    var flash, url;
    flash = req.flash('auth_redirect');
    url = _.size(flash) ? _.first(flash) : '/';
    return res.redirect(url);
  });

  app.get('/logout', function(req, res) {
    req.logout();
    return res.redirect('/');
  });

  app.get('/registro', function(req, res) {
    return res.render('register');
  });

  app.post('/registro', function(req, res) {
    var d, model, u;
    d = req.body;
    model = mongoose.model('User');
    u = new model;
    u.clab = d.clab;
    u.email = d.email;
    u.password = d.password;
    u.username = d.username;
    return u.save(function(err) {
      if (err) throw new Error(err);
      return res.redirect("/perfil");
    });
  });

  app.get('/fotos/publicar', middleware.auth, function(req, res) {
    return res.render('gallery_upload');
  });

  app.post('/fotos/publicar', middleware.auth, function(req, res) {
    return res.send("POST /fotos/publicar", {
      'Content-Type': 'text/plain'
    });
  });

  app.get('/fotos/:user/:slug/editar', middleware.auth, function(req, res) {
    var slug, user;
    user = req.param('user');
    slug = req.param('slug');
    return res.send("PUT /fotos/" + user + "/" + slug + "/editar", {
      'Content-Type': 'text/plain'
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

  if (!module.parent) {
    app.listen(3000);
    console.log("Listening on port %d", app.address().port);
  }

}).call(this);
