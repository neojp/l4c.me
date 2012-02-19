(function() {
  var app, express, middleware, underscore, _;

  express = require('express');

  _ = underscore = require('underscore');

  app = module.exports = express.createServer();

  app.configure(function() {
    var oneYear;
    app.set('views', __dirname + '/public/templates');
    app.set('view engine', 'jade');
    app.set('strict routing', true);
    app.use(express.favicon());
    app.use(express.bodyParser());
    app.use(express.logger({
      format: ':status ":method :url"'
    }));
    oneYear = 31556926000;
    return app.use(express.static(__dirname + '/public', {
      maxAge: oneYear
    }));
  });

  middleware = {
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
        if (page === 1) return res.redirect(redirection, 301);
        return middleware.hmvc(path)(req, res, next);
      };
    },
    remove_trailing_slash: function(req, res, next) {
      var url;
      url = req.originalUrl;
      length(url.length);
      if (length > 1 && url.charAt(length - 1) === '/') {
        url = url.substring(0, length - 1);
        return res.redirect(url, 301);
      }
      return next();
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
    if (id !== 'ultimas' && id !== 'top' && id !== 'galeria' && id !== 'pag') {
      return next();
    } else {
      return next('route');
    }
  });

  app.all('*', middleware.remove_trailing_slash, function(req, res, next) {
    res.locals({
      _: underscore,
      body_class: ''
    });
    return next('route');
  });

  app.get('/', function(req, res) {
    res.local('body_class', 'home gallery');
    return res.render('gallery');
  });

  app.get('/fotos/:user/:slug', function(req, res) {
    res.local('body_class', 'single');
    return res.render('gallery_single');
  });

  app.get('/fotos/:user/:slug/editar', function(req, res) {
    var slug, user;
    user = req.param('user');
    slug = req.param('slug');
    return res.send("PUT /fotos/" + user + "/" + slug + "/editar", {
      'Content-Type': 'text/plain'
    });
  });

  app.put('/fotos/:user/:slug', function(req, res) {
    var slug, user;
    user = req.param('user');
    slug = req.param('slug');
    return res.send("PUT /fotos/" + user + "/" + slug, {
      'Content-Type': 'text/plain'
    });
  });

  app["delete"]('/fotos/:user/:slug', function(req, res) {
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

  app.get('/fotos/publicar', function(req, res) {
    return res.render('gallery_upload');
  });

  app.post('/fotos/publicar', function(req, res) {
    return res.send("POST /fotos/publicar", {
      'Content-Type': 'text/plain'
    });
  });

  app.get('/fotos/:sort/pag/:page?', middleware.paged('/fotos/:sort'));

  app.get('/fotos/:sort', function(req, res, next) {
    var page, sort;
    sort = req.params.sort;
    page = parseInt(req.param('page', 1));
    return res.send("GET /fotos/" + sort + "/pag/" + page, {
      'Content-Type': 'text/plain'
    });
  });

  app.get('/fotos/pag/:page?', middleware.paged('/fotos'));

  app.get('/fotos', function(req, res) {
    return res.send("GET /fotos", {
      'Content-Type': 'text/plain'
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
    return res.send("GET /fotos/tags", {
      'Content-Type': 'text/plain'
    });
  });

  app.get('/perfil', function(req, res) {
    return res.send("GET /perfil", {
      'Content-Type': 'text/plain'
    });
  });

  app.put('/perfil', function(req, res) {
    return res.send("PUT /perfil", {
      'Content-Type': 'text/plain'
    });
  });

  app.get('/login', function(req, res) {
    return res.send("GET /login", {
      'Content-Type': 'text/plain'
    });
  });

  app.post('/login', function(req, res) {
    return res.send("POST /login", {
      'Content-Type': 'text/plain'
    });
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

  app.get('/logout', function(req, res) {
    return res.send("GET /perfil", {
      'Content-Type': 'text/plain'
    });
  });

  app.get('/tweets', function(req, res) {
    return res.send("GET /tweets", {
      'Content-Type': 'text/plain'
    });
  });

  if (!module.parent) {
    app.listen(3000);
    console.log("Listening on port %d", app.address().port);
  }

}).call(this);
