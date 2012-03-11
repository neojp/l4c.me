var gravatar, marked, moment, underscore, _;

_ = underscore = require('underscore');

_.str = underscore.str = require('underscore.string');

gravatar = require('gravatar');

marked = require('marked');

marked.setOptions({
  gfm: true,
  pedantic: false,
  sanitize: true
});

moment = require('moment');

moment.lang('es');

module.exports = {
  format_number: function(num) {
    var p;
    p = (num + '').split('');
    return p.reverse().reduce(function(acc, num, i, orig) {
      return num + (i && !(i % 3) ? "," : "") + acc;
    }, "");
  },
  gravatar: function(email, size) {
    return gravatar.url(email, {
      s: size
    });
  },
  heart: '♥',
  image: {
    extensions: {
      'image/jpeg': 'jpg',
      'image/pjpeg': 'jpg',
      'image/gif': 'gif',
      'image/png': 'png'
    },
    sizes: {
      l: {
        action: 'resize',
        height: 728,
        size: 'l',
        width: 970
      },
      m: {
        action: 'resize',
        height: 450,
        size: 'm',
        width: 600
      },
      s: {
        action: 'crop',
        height: 190,
        size: 's',
        width: 190
      },
      t: {
        action: 'crop',
        height: 75,
        size: 't',
        width: 100
      }
    }
  },
  logger_format: function(tokens, req, res) {
    var color, d, date, ip_address, status, _ref;
    status = res.statusCode;
    color = status >= 500 ? 31 : status >= 400 ? 33 : status >= 300 ? 36 : 32;
    d = moment();
    date = d.format('YYYY/MM/DD HH:mm:ss ZZ');
    ip_address = (_ref = req.headers['x-forwarded-for']) != null ? _ref : req.connection.remoteAddress;
    return '' + '\033[' + color + 'm' + res.statusCode + ' \033[90m' + date + '  ' + ' \033[90m' + req.method + ' \033[0m' + req.originalUrl + ' \033[90m' + (new Date - req._startTime) + 'ms' + '          \033[90m' + ip_address + '\033[0m';
  },
  markdown: function(str) {
    if (_.isString(str)) return marked(str);
  },
  pagination: 20,
  pretty_date: function(date) {
    return moment(date).fromNow(true);
  },
  random_query: function() {
    var rand, random;
    rand = Math.random();
    return random = [
      {
        random: {
          $gte: rand
        }
      }, {
        random: {
          $lte: rand
        }
      }
    ];
  },
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
