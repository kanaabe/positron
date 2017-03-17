#
# Allows an admin to log in as another user
#

_ = require 'underscore'
sd = require('sharify').data
debug = require('debug') 'client'
fs = require 'fs'
pug = require 'pug'

render = (req, res, locals) ->
  res.send pug.compile(
    fs.readFileSync(f = __dirname + '/page.pug'),
    filename: f
    cache: true
  ) _.extend res.locals, locals, referrer: req.get('referrer')

errorHandler = (err, req, res, next) ->
  debug err.stack, err.message
  return res.redirect '/logout' if err.status is 401
  render req, res, error: err

module.exports = (app) ->
  app.set 'views', __dirname
  app.set 'view engine', 'pug'
  app.get '*', (req, res, next) ->
    err = new Error "Page Not Found"
    err.status = 404
    render req, res, error: err
  app.use errorHandler
