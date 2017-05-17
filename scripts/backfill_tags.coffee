path = require 'path'
debug = require('debug') 'api'
fs = require 'fs'
csv = require 'csv'
_s = require 'underscore.string'
async = require 'async'
_ = require 'underscore'

# Setup environment variables
env = require 'node-env-file'
switch process.env.NODE_ENV
  when 'test' then env path.resolve __dirname, '../.env.test'
  when 'production', 'staging' then ''
  else env path.resolve __dirname, '../.env'

Article = require '../api/apps/articles/model/index.coffee'

fs.readFile 'scripts/tmp/magazine.csv', (err, result) ->
  console.log err if err
  # console.log result
  csv.parse result, (err, data) ->
    console.log err if err
    newData = data.map (row, i) ->
      return if i is 0
      if row[3].length and row[5].length
        topics = _s.join ',', row[3], row[5]
      else if row[5].length
        topics = row[5]
      else
        topics = row[3]
      id = row[1]
        .replace('https://writer.artsy.net/articles/', '')
        .replace('/edit', '')

      return {
        topics: topics
        internalTags: row[4]
        verticals: row[2]
        id: id
      }

    cbs = newData.map (article) -> (cb) ->
      Article.backfillTags article, (result) ->
        cb(result)

    async.series cbs, (err, result) ->
      console.log err
      console.log result
