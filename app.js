(function() {
  var LocalStrategy, app, express, helpers, middleware, passport, underscore, users, _;

  express = require('express');

  _ = underscore = require('underscore');

  app = module.exports = express.createServer();

  passport = require('passport');

  LocalStrategy = require('passport-local').Strategy;

  users = [
    {
      id: 1337,
      username: 'neojp',
      password: 'password'
    }, {
      id: 666,
      username: 'freddier',
      password: 'password'
    }, {
      id: 161803399,
      username: 'maikel',
      password: 'password'
    }, {
      id: 123,
      username: 'leonidas',
      password: 'password'
    }
  ];

  passport.serializeUser(function(user, next) {
    return next(null, user.id);
  });

  passport.deserializeUser(function(id, next) {
    var user;
    user = _.filter(users, function(i) {
      return i.id === id;
    });
    if (_.size(user)) {
      return next(null, _.first(user));
    } else {
      return next(null, false);
    }
  });

  passport.use(new LocalStrategy(function(username, password, next) {
    return process.nextTick(function() {
      var user;
      user = _.filter(users, function(i) {
        return i.username === username && i.password === password;
      });
      if (_.size(user)) {
        return next(null, _.first(user));
      } else {
        return next(null, false);
      }
    });
  }));

  app.configure(function() {
    var oneYear;
    app.set('views', __dirname + '/public/templates');
    app.set('view engine', 'jade');
    app.set('strict routing', true);
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
        redirection = path + '';
        path_vars = _.filter(path.split('/'), function(i) {
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
      user: req.isAuthenticated() ? req.user : null,
      page: parseInt(req.param('page', 1))
    });
    res.locals(helpers);
    return next('route');
  });

  app.get('/', middleware.hmvc('/fotos'));

  app.get('/fotos/:user/:slug', function(req, res) {
    res.local('body_class', 'single');
    return res.render('gallery_single');
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

  app.get('/fotos/:user/:slug/sizes/:size', function(req, res) {
    res.local('body_class', 'sizes');
    return res.render('gallery_single_large');
  });

  app.get('/fotos/:user', function(req, res) {
    res.local('body_class', 'gallery liquid');
    return res.render('gallery');
  });

  app.get('/fotos/publicar', middleware.auth, function(req, res) {
    return res.render('gallery_upload');
  });

  app.post('/fotos/publicar', middleware.auth, function(req, res) {
    return res.send("POST /fotos/publicar", {
      'Content-Type': 'text/plain'
    });
  });

  app.get('/fotos/:sort/pag/:page?', middleware.paged('/fotos/:sort'));

  app.get('/fotos/:sort', function(req, res, next) {
    var sort;
    sort = req.params.sort;
    res.locals({
      sort: sort,
      path: "/fotos/" + sort,
      body_class: "gallery liquid " + sort
    });
    return res.render('gallery');
  });

  app.get('/fotos/pag/:page?', middleware.paged('/fotos'));

  app.get('/fotos', function(req, res) {
    res.local('path', '/fotos');
    res.local('body_class', 'gallery liquid');
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
    return res.send("GET /registro", {
      'Content-Type': 'text/plain'
    });
  });

  app.post('/registro', function(req, res) {
    return res.send("POST /registro", {
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
