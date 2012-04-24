var Schema, mongoose, tag;

mongoose = require('mongoose');

Schema = mongoose.Schema;

tag = new Schema({
  count: {
    "default": 0,
    type: Number
  },
  name: {
    lowercase: true,
    type: String,
    required: true
  },
  slug: {
    lowercase: true,
    type: String,
    required: true,
    unique: true
  }
});

module.exports = mongoose.model('tag', tag);
