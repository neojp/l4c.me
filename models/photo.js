var Email, ObjectId, Schema, comment, fs, helpers, im, invoke, methods, model, model_tag, mongoose, mongooseTypes, photo, underscore, util, _;

mongoose = require('mongoose');

mongooseTypes = require('mongoose-types');

mongooseTypes.loadTypes(mongoose);

helpers = require('../lib/helpers');

_ = underscore = require('underscore');

im = require('imagemagick');

invoke = require('invoke');

model_tag = require('./tag');

fs = require('fs');

util = require('util');

Schema = mongoose.Schema;

ObjectId = Schema.ObjectId;

Email = mongoose.SchemaTypes.Email;

methods = {
  set_slug: function(next) {
    var doc, i, new_slug, slug;
    doc = this;
    slug = helpers.slugify(doc.name);
    new_slug = slug + '';
    i = 1;
    return model.count({
      slug: new_slug
    }, function(err, count) {
      var slug_lookup;
      if (count === 0) {
        doc.slug = new_slug;
        return doc.save(function(err) {
          if (err) return next(err);
          return next(new_slug);
        });
      } else {
        slug_lookup = function(err, count) {
          if (count === 0) {
            doc.slug = new_slug;
            return doc.save(function(err) {
              if (err) return next(err);
              return next(doc.slug);
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
  },
  set_tags: function(tags, next) {
    var doc, photo_tags, queue;
    doc = this;
    queue = null;
    photo_tags = [];
    if (_.isArray(tags)) {
      tags = tags;
    } else if (_.isString(tags)) {
      tags = _.str.trim(tags);
      tags = tags.length > 0 ? tags.split(' ') : [];
    } else if (!tags.length) {
      return next();
    }
    _.each(tags, function(tag, index) {
      var fn;
      console.log("each tags: ", tag);
      fn = function(data, callback) {
        var name, slug;
        name = tag;
        slug = helpers.slugify(tag);
        return model_tag.findOne({
          slug: slug
        }, function(err, tag) {
          if (err) return callback(err);
          if (tag) {
            console.log("tag update:start " + tag.name);
            tag.count = tag.count + 1;
            return tag.save(function(err) {
              console.log("tag update:save " + tag.name);
              photo_tags.push(tag);
              return callback(err);
            });
          } else {
            console.log("tag create:start " + name);
            tag = new model_tag;
            tag.name = name;
            tag.slug = slug;
            tag.count = 1;
            return tag.save(function(err) {
              console.log("tag create:save " + tag.name);
              photo_tags.push(tag);
              return callback(err);
            });
          }
        });
      };
      if (!index) {
        return queue = invoke(fn);
      } else {
        return queue.and(fn);
      }
    });
    queue.then(function(data, callback) {
      if (!photo_tags.length) return callback();
      console.log("photo update tags");
      photo_tags = _.sortBy(photo_tags, function(tag) {
        return tag.name;
      });
      doc._tags = _.pluck(photo_tags, '_id');
      return doc.save(callback);
    });
    queue.rescue(next);
    return queue.end(null, function(data) {
      return next(null, photo_tags);
    });
  },
  resize_photo: function(size, next) {
    var doc, path;
    if (_.isString(size)) {
      size = helpers.image.sizes[size];
    } else if (_.isObject(size)) {
      size = size;
    } else {
      return next(new Error('Image size required'));
    }
    doc = this;
    path = "public/uploads/" + doc._id + "_" + size.size + "." + doc.ext;
    return im[size.action]({
      dstPath: path,
      format: doc.ext,
      height: size.height,
      srcPath: "public/uploads/" + doc._id + "_o." + doc.ext,
      width: size.width
    }, function(err, stdout, stderr) {
      console.log("photo resize " + size.size);
      return next(err, path);
    });
  },
  resize_photos: function(next) {
    var doc, index, queue;
    doc = this;
    queue = invoke();
    index = 0;
    _.each(helpers.image.sizes, function(size, key) {
      if (!index) {
        queue = invoke(function(data, callback) {
          return doc.resize_photo(size, callback);
        });
      } else {
        queue.and(function(data, callback) {
          return doc.resize_photo(size, callback);
        });
      }
      return index++;
    });
    queue.rescue(next);
    return queue.end(null, function(data) {
      return next(null, data);
    });
  },
  upload_photo: function(file, next) {
    var alternate_upload, doc, upload_path;
    console.log('photo upload', file.path);
    doc = this;
    upload_path = "" + __dirname + "/../public/uploads/" + doc._id + "_o." + doc.ext;
    alternate_upload = function(path1, path2) {
      var origin, upload;
      origin = fs.createReadStream(path1);
      upload = fs.createWriteStream(path2);
      return util.pump(origin, upload, function(err) {
        return fs.unlink(path1, function(err) {
          return next(err);
        });
      });
    };
    return fs.rename(file.path, upload_path, function(err) {
      if (err) return alternate_upload(file.path, upload_path);
      return next(err);
    });
  },
  pretty_date: function() {
    return helpers.pretty_date(this.created_at);
  }
};

comment = new Schema({
  _user: {
    type: ObjectId,
    ref: 'user'
  },
  body: {
    type: String,
    required: true
  },
  created_at: {
    "default": Date.now,
    type: Date
  },
  guest: {
    "default": true,
    type: Boolean
  },
  user: {
    name: String,
    email: Email
  }
});

comment.virtual('pretty_date').get(methods.pretty_date);

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

photo.virtual('pretty_date').get(methods.pretty_date);

photo.methods.set_slug = methods.set_slug;

photo.methods.set_tags = methods.set_tags;

photo.methods.resize_photo = methods.resize_photo;

photo.methods.resize_photos = methods.resize_photos;

photo.methods.upload_photo = methods.upload_photo;

module.exports = model = mongoose.model('photo', photo);
