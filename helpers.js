var underscore, _;

_ = underscore = require('underscore');

_.str = underscore.str = require('underscore.string');

module.exports = {
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
