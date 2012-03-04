var express, _, _path;

_ = require('underscore');

_.str = require('underscore.string');

_path = require('path');

express = require('express');

module.exports = function(app) {
  var middleware;
  return middleware = {
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
    },
    static: function(path, options) {
      var urlPrefix;
      if (options == null) options = {};
      _.defaults(options, app.set('static options'));
      urlPrefix = options.urlPrefix;
      return function(req, res, next) {
        var extension, extensions;
        if (_.isString(urlPrefix)) {
          if (!_.str.startsWith(req.url, urlPrefix)) return next();
          req.url = req.url.substring(urlPrefix.length);
        }
        extension = _path.extname(req.url).substring(1);
        if (extension && _.isString(options.ignoreExtensions) && options.ignoreExtensions.length) {
          extensions = options.ignoreExtensions.split(' ');
          extensions = _.compact(extensions);
          if (extension && _.include(extensions, extension)) return next();
        }
        return express.static(path, options)(req, res, next);
      };
    }
  };
};
