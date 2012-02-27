var underscore, _;

_ = underscore = require('underscore');

_.str = underscore.str = require('underscore.string');

module.exports = {
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
        action: 'crop',
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
  pagination: 20,
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
