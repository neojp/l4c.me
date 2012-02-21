var LocalStrategy, app, express, fs, helper, im, middleware, model, mongoose, passport, underscore, _;

express = require('express');

_ = underscore = require('underscore');

helper = require('./helpers');

app = module.exports = express.createServer();

im = require('imagemagick');

fs = require('fs');

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
  err: function(err, req, res, next) {
    var flash;
    if (!err && (flash = req.flash('err'))) return next(flash, req, res, next);
    return next(err, req, res, next);
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

app.param('page', function(req, res, next, id) {
  if (id.match(/[0-9]+/)) {
    req.param.page = parseInt(req.param.page);
    return next();
  } else {
    return next(404);
  }
});

app.param('size', function(req, res, next, id) {
  if (id === 'p' || id === 'm' || id === 'l' || id === 'o') {
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
    document_title: 'L4C.me',
    url: req.originalUrl,
    user: req.isAuthenticated() ? req.user : null,
    page: 1
  });
  res.locals(helper);
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
  res.locals({
    body_class: 'sizes',
    photo: {
      user: req.param('user'),
      slug: req.param('slug')
    },
    size: req.param('size')
  });
  return res.render('gallery_single_large');
});

app.get('/fotos/:user/pag/:page?', middleware.paged('/fotos/:user'));

app.get('/fotos/:user', function(req, res) {
  var user;
  user = req.param('user');
  res.locals({
    body_class: 'gallery liquid',
    path: "/fotos/" + user,
    sort: null
  });
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
    body_class: "gallery liquid " + sort,
    path: "/fotos/" + sort,
    sort: sort
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
  if (d.clab_boolean === 'yes') u.clab = d.clab;
  u.email = d.email;
  u.password = d.password;
  u.username = d.username;
  return u.save(function(err) {
    if (err) return next(err);
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
  var description, file, name, photo, tags, user;
  user = req.user;
  name = req.body.name;
  description = req.body.description;
  tags = req.body.tags;
  file = req.files.file;
  photo = new model.photo;
  photo.name = name;
  if (description && description !== '') photo.description = description;
  photo._user = user._id;
  return photo.save(function(err) {
    var extensions, file_ext, file_path, id;
    if (err) return next(err);
    res.redirect("/fotos/" + user.username + "/" + photo.slug);
    extensions = {
      'image/jpeg': 'jpg',
      'image/pjpeg': 'jpg',
      'image/gif': 'gif',
      'image/png': 'png'
    };
    id = photo._id;
    file_ext = extensions[file.type];
    file_path = "public/uploads/" + id + "_o." + file_ext;
    return fs.rename(file.path, "" + __dirname + "/" + file_path, function(err) {
      var i, size, sizes, _results;
      if (err) return next(err);
      sizes = {
        l: {
          action: 'resize',
          height: 728,
          width: 970
        },
        m: {
          action: 'resize',
          height: 450,
          width: 600
        },
        s: {
          action: 'crop',
          height: 190,
          width: 190
        },
        t: {
          action: 'crop',
          height: 100,
          width: 75
        }
      };
      _results = [];
      for (size in sizes) {
        i = sizes[size];
        _results.push(im[i.action]({
          dstPath: "public/uploads/" + id + "_" + size + "." + file_ext,
          format: file_ext,
          height: i.height,
          srcPath: file_path,
          width: i.width
        }, function(err, stdout, stderr) {}));
      }
      return _results;
    });
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
