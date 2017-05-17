path = require 'path'
debug = require('debug') 'api'
fs = require 'fs'

# Setup environment variables
env = require 'node-env-file'
switch process.env.NODE_ENV
  when 'test' then env path.resolve __dirname, '../.env.test'
  when 'production', 'staging' then ''
  else env path.resolve __dirname, '../.env'

Article = require '../api/apps/articles/model/index.coffee'
