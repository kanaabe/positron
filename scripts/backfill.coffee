path = require 'path'
debug = require('debug') 'api'

# Setup environment variables
env = require 'node-env-file'
env path.resolve __dirname, '../.env'

Article = require '../api/apps/articles/model/index.coffee'
Article.updateArticles (err, results) ->
  console.log "Completed processing #{results} articles."
  return process.exit(err) if err
  return process.exit()
