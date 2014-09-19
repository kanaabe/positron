#
# Sets up intial project settings, middleware, mounted apps, and
# global configuration such as overriding Backbone.sync and
# populating sharify data
#

express = require 'express'
Backbone = require 'backbone'
sharify = require 'sharify'
path = require 'path'
fs = require 'fs'
helperMiddleware = require './helper_middleware'

module.exports = (app) ->

  # Inject some configuration & constant data into sharify
  sd = sharify.data =
    API_URL: process.env.API_URL
    NODE_ENV: process.env.NODE_ENV
    SPOOKY_URL: process.env.SPOOKY_URL
    # TODO: This is a sensitive Spooky App token and we'll want to hide this
    # on the server. Potential solution involves adding the on the
    # Positron-server-side and proxying to Spooky—then maybe having Positron
    # do user-level-auth (with Gravity?). Or adding user-level auth to Spooky.
    SPOOKY_TOKEN: process.env.SPOOKY_TOKEN
    JS_EXT: (if 'production' is process.env.NODE_ENV then '.min.js' else '.js')
    CSS_EXT: (if 'production' is process.env.NODE_ENV then '.min.css' else '.css')

  # Override Backbone to use server-side sync
  Backbone.sync = require 'backbone-super-sync'
  Backbone.sync.editRequest = (req) ->
    req.query 'token': process.env.SPOOKY_TOKEN

  # Mount sharify
  app.use sharify

  # Mount helpers
  app.use helperMiddleware

  # Development only
  if 'development' is sd.NODE_ENV
    # Compile assets on request in development
    app.use require('stylus').middleware
      src: path.resolve(__dirname, '../')
      dest: path.resolve(__dirname, '../public')
    app.use require('browserify-dev-middleware')
      src: path.resolve(__dirname, '../')
      transforms: [require('jadeify'), require('caching-coffeeify')]

  # Test only
  if 'test' is sd.NODE_ENV
    # Mount fake API server
    app.use '/__api', require('../test/helpers/integration.coffee').api

  # Mount apps
  app.use '/', require '../apps/list'
  # TODO: Replace with proper app that renders errors
  app.use (err, req, res, next) ->
    console.log err
    res.status(err.status).send err.body

  # Mount static middleware for sub apps, components, and project-wide
  fs.readdirSync(path.resolve __dirname, '../apps').forEach (fld) ->
    app.use express.static(path.resolve __dirname, "../apps/#{fld}/public")
  fs.readdirSync(path.resolve __dirname, '../components').forEach (fld) ->
    app.use express.static(path.resolve __dirname, "../components/#{fld}/public")
  app.use express.static(path.resolve __dirname, '../public')