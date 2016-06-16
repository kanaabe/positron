#
# Library of retrieval, persistance, validation, json view, and domain logic
# for the "users" resource.
#

_ = require 'underscore'
async = require 'async'
db = require '../../lib/db'
request = require 'superagent'
Joi = require 'joi'
debug = require('debug') 'api'
async = require 'async'
bcrypt = require 'bcrypt'
{ ObjectId } = require 'mongojs'
{ ARTSY_URL, SALT, API_URL } = process.env

#
# Retrieval
#
@find = (id, callback) ->
  db.users.findOne { _id: ObjectId(id) }, callback

@fromAccessToken = (accessToken, callback) ->
  # Find via access token from DB if they exist
  bcrypt.hash accessToken, SALT, (err, encryptedAccessToken) ->
    return callback err if err
    db.users.findOne { access_token: encryptedAccessToken }, (err, user) ->
      return callback err if err
      return callback null, user if user
      # Otherwise fetch data from Gravity and flatten it into a Positron user
      async.parallel [
        (cb) ->
          request.get("#{ARTSY_URL}/api/v1/me")
            .set('X-Access-Token': accessToken).end cb
      ], (err, results) ->
        return callback err if err
        user = results[0].body
        save user, accessToken, callback

#
# Persistance
#
@findOrInsert = (id, accessToken, callback) ->
  return callback() unless id?
  db.users.findOne { _id: ObjectId(id) }, (err, user) ->
    return callback err if err
    return callback null, user if user
    request.get("#{ARTSY_URL}/api/v1/user/#{id}")
      .set('X-Access-Token': accessToken)
      .end (err, user) ->
        return callback err if err
        save user.body, accessToken, callback

save = (user, accessToken, callback) ->
  async.parallel [
    (cb) ->
      request.get("#{ARTSY_URL}/api/v1/user/#{user.id}/access_controls")
        .set('X-Access-Token': accessToken).end cb
    (cb) ->
      db.channels.find {user_ids: ObjectId(user.id)}, cb
    (cb) ->
      bcrypt.hash accessToken, SALT, cb
  ], (err, results) ->
    return callback err if err
    user.partner_ids = _.map results[0].body, (partner) ->
      partner.property._id
    user.channel_ids = _.pluck results[1], '_id'
    encryptedAccessToken = results[2]
    db.users.save {
      _id: ObjectId(user.id)
      name: user.name
      email: user.email
      type: user.type
      access_token: encryptedAccessToken
      partner_ids: user.partner_ids
      channel_ids: user.channel_ids
    }, callback

#
# JSON views
#
@present = (data) =>
  _.extend data,
    id: data._id?.toString()
    _id: undefined
    access_token: undefined

#
# Helpers
#
@denormalizedForArticle = (user) ->
  {
    id: user._id
    name: user.name
  }
