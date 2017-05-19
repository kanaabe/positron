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

      getVerticalObject = (name) ->
        switch name
          when 'art' then name: 'Art', id: '591ea921faef6a3a8e7fe1ae'
          when 'market' then name: 'Market', id: '591ea947faef6a3a8e7fe1af'
          when 'visual culture' then name: 'Visual Culture', id: '591ea97afaef6a3a8e7fe1b0'
          when 'creativity' then name: 'Creativity', id: '591eaa6bfaef6a3a8e7fe1b1'
          when 'news' then name: 'News', id: '591eaa7dfaef6a3a8e7fe1b2'

      return {
        article:
          tags: topics.split(',')
          tracking_tags: row[4].split(',')
          vertical: getVerticalObject row[2]
        id: id
      }
    newData = _.compact newData
    async.mapSeries newData, (article, callback) ->
      Article.backfillTags article, callback
    , (err, result) ->
      console.log result
      console.log err
      console.log "Completed updating " + result.length + " articles."
