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

window.Site = {
  ie_fallback: function() {
    return log('Y U NO STOP USING IE!!');
  },
  blank: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAMAAAAoyzS7AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////AAAAVcLTfgAAAAF0Uk5TAEDm2GYAAAAMSURBVHjaYmAACDAAAAIAAU9tWeEAAAAASUVORK5CYII=',
  header: function() {
    return $('#header').on('click', 'aside a.button', function(e) {
      return $(this).parent().toggleClass('active');
    });
  },
  mobile: function() {
    return navigator.appVersion.toLowerCase().indexOf("mobile") > -1;
  },
  load: function() {
    return log('Window on Load');
  },
  init: function() {
    log('DOM Ready');
    Site.header();
    return $(window).bind('load', Site.load);
  }
};

Site.init();
