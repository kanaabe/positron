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

# fs.readFile 'scripts/tmp/magazine.csv', (err, result) ->
#   console.log err if err
#   csv.parse result, (err, data) ->
#     console.log err if err
#     newData = data.map (row, i) ->
#       return if i is 0

#       getVerticalObject = (name, tracking_tags) ->
#         if tracking_tags.includes('podcast')
#           name = 'podcast'
#         switch name
#           when 'Art', 'art' then name: 'Art', id: '591ea921faef6a3a8e7fe1ae'
#           when 'Market','market' then name: 'Art Market', id: '591ea947faef6a3a8e7fe1af'
#           when 'visual culture', 'Visual Culture' then name: 'Visual Culture', id: '591ea97afaef6a3a8e7fe1b0'
#           when 'creativity','Creativity' then name: 'Creativity', id: '591eaa6bfaef6a3a8e7fe1b1'
#           when 'news','News' then name: 'News', id: '591eaa7dfaef6a3a8e7fe1b2'
#           when 'podcast', 'Podcast' then name: 'Podcast', id: '592ee8bdfaef6a3a8e7fe1b3'
#           else null

#       # Topic Tags
#       if row[4].length and row[5].length
#         topics = _s.join ',', row[4], row[5]
#       else if row[5].length
#         topics = row[5]
#       else
#         topics = row[4]

#       # ID
#       id = row[1]
#         .replace('https://writer.artsy.net/articles/', '')
#         .replace('/edit', '')

#       # Tracking Tags
#       if row[6].length and row[8].length
#         tracking = _s.join ',', row[6], row[8]
#       else if row[8].length
#         tracking = row[8]
#       else
#         tracking = row[6]

#       tags = if topics.length then topics.split(',') else []
#       tracking = if tracking.length then tracking.split(',') else []
#       # Create the object
#       obj = {
#         id: id
#         article:
#           tags: tags
#           tracking_tags: tracking
#           vertical: getVerticalObject row[3], tracking
#       }
#       return obj
#     newData = _.compact newData
#     console.log newData.length
#     async.mapSeries newData, (article, callback) ->
#       Article.backfillTags article, callback
#     , (err, result) ->
#       # console.log result
#       console.log err
#       console.log "Completed updating " + result.length + " articles."
#       process.exit()


Article.removeTags (err, results) ->
  console.log results
  console.log 'completed removing tags'
  process.exit()