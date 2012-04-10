var Email, ObjectId, Schema, Url, encrypt_password, helpers, mongoose, mongooseTypes, user;

mongoose = require('mongoose');

mongooseTypes = require('mongoose-types');

mongooseTypes.loadTypes(mongoose);

helpers = require('../lib/helpers');

Schema = mongoose.Schema;

ObjectId = Schema.ObjectId;

Email = mongoose.SchemaTypes.Email;

Url = mongoose.SchemaTypes.Url;

encrypt_password = function(password) {
  return require('crypto').createHash('sha1').update(password + helpers.heart).digest('hex');
};

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
    set: encrypt_password,
    type: String
  },
  random: {
    "default": Math.random,
    index: true,
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

user.statics.encrypt_password = encrypt_password;

user.statics.login = function(username, password, next) {
  password = encrypt_password(password);
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
