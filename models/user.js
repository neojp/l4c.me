var Email, ObjectId, Schema, Url, mongoose, mongooseTypes, user;

mongoose = require('mongoose');

mongooseTypes = require('mongoose-types');

mongooseTypes.loadTypes(mongoose);

Schema = mongoose.Schema;

ObjectId = Schema.ObjectId;

Email = mongoose.SchemaTypes.Email;

Url = mongoose.SchemaTypes.Url;

user = new Schema({
  _photos: [
    {
      type: ObjectId,
      ref: 'photo'
    }
  ],
  clab: String,
  created_at: {
    "default": Date.now,
    type: Date
  },
  email: {
    lowercase: true,
    required: true,
    type: Email,
    unique: true
  },
  password: {
    required: true,
    type: String
  },
  random: {
    "default": Math.random,
    set: function(v) {
      return Math.random();
    },
    type: Number
  },
  url: {
    type: Url
  },
  username: {
    lowercase: true,
    required: true,
    type: String,
    unique: true
  }
});

user.statics.login = function(username, password, next) {
  return this.findOne({
    username: username,
    password: password
  }, function(err, doc) {
    if (err) return next(err, false);
    return next(null, doc);
  });
};

user.statics.deserialize = function(username, next) {
  return this.findOne({
    username: username
  }, function(err, doc) {
    if (err) return next(null, false);
    return next(null, doc);
  });
};

module.exports = mongoose.model('user', user);
