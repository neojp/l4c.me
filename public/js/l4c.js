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
    var $aside, $close, $trigger, active, close, first, open;
    first = true;
    active = false;
    $aside = $('#header aside');
    $trigger = $('#header-login-trigger');
    $close = $('#header a.close');
    open = function(e) {
      e.stopPropagation();
      if (active) return;
      $aside.addClass('active');
      active = true;
      if (first) {
        $aside.find('img[data-src]').lazyload({
          load: true
        });
        return first = false;
      }
    };
    close = function(e) {
      if (active) {
        $aside.removeClass('active');
        return active = false;
      }
    };
    $trigger.on('click.login', open).hoverIntent({
      over: open,
      out: $.noop
    });
    $close.on('click.login', close);
    $body.on('click.login', function() {
      if (active) return $close.trigger('click.login');
    });
    return $body.on('click.login', 'aside', function(e) {
      return e.stopPropagation();
    });
  },
  mobile: function() {
    return navigator.appVersion.toLowerCase().indexOf("mobile") > -1;
  },
  register: function() {
    var $pass;
    $pass = $('#password-container');
    return $('#change-password').on('change', function(e) {
      return $pass.toggleClass('hidden', this.checked);
    });
  },
  load: function() {
    log('Window on Load');
    return Site.lazyload();
  },
  init: function() {
    log('DOM Ready');
    Site.login();
    return Site.register();
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
