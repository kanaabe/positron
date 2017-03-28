_ = require 'underscore'
{ db, fixtures, fabricate, empty } = require '../../../test/helpers/db'
app = require '../../../'
request = require 'superagent'
{ ObjectId } = require 'mongojs'

describe 'tags endpoints', ->

  beforeEach (done) ->
    empty =>
      fabricate 'users', {}, (err, @user) =>
        @server = app.listen 5000, ->
          done()

  afterEach ->
    @server.close()

  it 'gets a list of tags by query', (done) ->
    fabricate 'tags', [
      { name: 'Asia' }
      { name: 'Berlin' }
      {}
    ], (err, tags) =>
      request
        .get("http://localhost:5000/tags?q=Asia&count=true")
        .end (err, res) ->
          res.body.total.should.equal 3
          res.body.count.should.equal 1
          res.body.results[0].name.should.equal 'Asia'
          done()

  it 'gets a list of tags by type', (done) ->
    fabricate 'tags', [
      { name: 'Asia', type: 'topic' }
      { name: 'Berlin', type: 'internal'}
      {}
    ], (err, tags) =>
      request
        .get("http://localhost:5000/tags?type=topic&count=true")
        .end (err, res) ->
          res.body.total.should.equal 3
          res.body.count.should.equal 2
          res.body.results[0].name.should.equal 'Show Reviews'
          res.body.results[1].name.should.equal 'Asia'
          done()

  it 'gets a single tag', (done) ->
    fabricate 'tags', [
      {
        _id: ObjectId('55356a9deca560a0137aa4b7')
        name: 'Asia'
      }
    ], (err, sections) =>
      request
        .get("http://localhost:5000/tags/55356a9deca560a0137aa4b7")
        .end (err, res) ->
          res.body.name.should.equal 'Asia'
          done()