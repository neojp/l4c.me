var ObjectId, Schema, comment, helper, methods, model, mongoose, photo, underscore, _;

mongoose = require('mongoose');

helper = require('../helpers');

_ = underscore = require('underscore');

Schema = mongoose.Schema;

ObjectId = Schema.ObjectId;

methods = {
  set_slug: function(next) {
    var doc, i, new_slug, slug;
    doc = this;
    slug = helper.slugify(doc.name);
    new_slug = slug + '';
    i = 1;
    return model.count({
      slug: new_slug
    }, function(err, count) {
      var slug_lookup;
      if (count === 0) {
        doc.slug = new_slug;
        return next(new_slug);
      } else {
        slug_lookup = function(err, count) {
          if (count === 0) {
            doc.slug = new_slug;
            return doc.save(function() {
              return next(new_slug);
            });
          }
          i++;
          new_slug = "" + slug + "-" + i;
          return model.count({
            slug: new_slug
          }, slug_lookup);
        };
        return slug_lookup(err, count);
      }
    });
  }
};

comment = new Schema({
  _user: [
    {
      type: ObjectId,
      ref: 'user',
      required: true
    }
  ],
  body: {
    type: String,
    required: true
  },
  created_at: {
    "default": Date.now,
    type: Date
  }
});

photo = new Schema({
  _tags: [
    {
      type: ObjectId,
      ref: 'tag'
    }
  ],
  _user: {
    type: ObjectId,
    ref: 'user',
    required: true
  },
  comments: [comment],
  created_at: {
    "default": Date.now,
    required: true,
    type: Date
  },
  description: String,
  ext: {
    type: String,
    "enum": ['gif', 'jpg', 'png']
  },
  name: {
    required: true,
    type: String
  },
  slug: {
    type: String,
    unique: true
  },
  views: {
    "default": 0,
    type: Number
  }
});

photo.pre('save', function(next) {
  if (_.isUndefined(this.slug)) this.slug = this._id;
  return next();
});

photo.methods.set_slug = methods.set_slug;

module.exports = model = mongoose.model('photo', photo);
