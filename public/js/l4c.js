var $body, ie;

if (window['ie'] != null) ie = window.ie;

$body = $(document.body);

window.log = function() {
  var newarr;
  log.history = log.history || [];
  log.history.push(arguments);
  if (this.console) {
    arguments.callee = arguments.callee.caller;
    newarr = [].slice.call(arguments);
    if (typeof console.log === 'object') {
      return log.apply.call(console.log, console, newarr);
    } else {
      return console.log.apply(console, newarr);
    }
  }
};

$.getStyle = function(url, callback) {
  $('head').append('<link rel="stylesheet" type="text/css" href="' + url + '">');
  if ($.isFunction(callback)) return callback();
};

$.getScript = function(url, callback, options) {
  var o;
  o = $.extend({}, options, {
    cache: true,
    dataType: 'script',
    url: url,
    success: callback,
    type: 'GET'
  });
  return $.ajax(o);
};

window.Site = $.extend({}, window.Site, {
  ie_fallback: function() {
    return log('Y U NO STOP USING IE!!');
  },
  blank: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==',
  lazyload: function() {
    return $.getScript('/js/jquery.lazyload.min.js', function() {
      return $('img[data-src]').lazyload({
        data_attribute: 'src',
        effect: 'fadeIn',
        failure_limit: 10
      });
    });
  },
  login: function() {
    var active, first, fn;
    first = true;
    active = false;
    fn = function(e) {
      e.stopPropagation();
      $(this).parent().addClass('active');
      active = true;
      if (first) {
        $('#header-login-social img[data-src]').lazyload({
          load: true
        });
        return first = false;
      }
    };
    $('#header aside a.button').hoverIntent({
      over: fn,
      out: $.noop
    });
    $body.one('click.login', function(e) {
      if (active) {
        $('#header aside.active').removeClass('active');
        return active = false;
      }
    });
    $body.on('click.login', 'aside', function(e) {
      return e.stopPropagation();
    });
    return $body.on('click.login', 'aside a.button', fn);
  },
  mobile: function() {
    return navigator.appVersion.toLowerCase().indexOf("mobile") > -1;
  },
  load: function() {
    log('Window on Load');
    return Site.lazyload();
  },
  init: function() {
    log('DOM Ready');
    return Site.login();
  },
  load_scripts: function() {
    return invoke(function(data, callback) {
      return $.getScript('/js/jquery.hoverIntent.minified.js', function() {
        return callback();
      });
    }).rescue(function(err) {
      return log('error: ', err);
    }).end(null, Site.init);
  }
});

$(document).on('ready', Site.load_scripts);

$(window).on('load', Site.load);
