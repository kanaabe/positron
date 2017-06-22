_ = require 'underscore'
rewire = require 'rewire'
{ fabricate, empty } = require '../../../../test/helpers/db'
Retrieve = rewire '../../model/retrieve'
express = require 'express'
gravity = require('antigravity').server
app = require('express')()
sinon = require 'sinon'
_ = require 'underscore'
Joi = require 'joi'
Joi.objectId = require('joi-objectid') Joi
schema = require '../../model/schema.coffee'
{ ObjectId } = require 'mongojs'

describe 'Retrieve', ->

  before (done) ->
    app.use '/__gravity', gravity
    @server = app.listen 5000, ->
      done()

  after ->
    @server.close()

  beforeEach (done) ->
    empty ->
      fabricate 'articles', _.times(10, -> {}), ->
        done()

  describe '#toQuery', ->

<<<<<<< HEAD
    it 'aggregates the query for all_by_author', ->
      { query } = Retrieve.toQuery {
        all_by_author: ObjectId '5086df098523e60002000017'
=======
    it 'type casts ids', (done) ->
      Retrieve.toQuery {
        author_id: '5086df098523e60002000018'
        published: true
      }, (err, query) =>
        query.author_id.should.containEql ObjectId '5086df098523e60002000018'
        done()

    it 'aggregates the query for all_by_author', (done) ->
      Retrieve.toQuery {
        all_by_author: '5086df098523e60002000017'
>>>>>>> e47fe321250be31e6fdd380a547192231c2e5705
        published: true
      }
      query['$or'][0].author_id.should.containEql ObjectId '5086df098523e60002000017'
      query['$or'][1].contributing_authors['$elemMatch'].should.be.ok()
      query['$or'][1].contributing_authors['$elemMatch'].id.should.containEql ObjectId '5086df098523e60002000017'

    it 'aggregates the query for vertical', ->
      { query } = Retrieve.toQuery {
        vertical: '55356a9deca560a0137bb4a7'
        published: true
      }
      query.vertical['$elemMatch'].should.be.ok()
      query.vertical['$elemMatch'].id.should.containEql ObjectId '55356a9deca560a0137bb4a7'

    it 'aggregates the query for artist_id', ->
      { query } = Retrieve.toQuery {
        artist_id: '5086df098523e60002000016'
        published: true
      }
      query['$or'][0].primary_featured_artist_ids.should.containEql ObjectId '5086df098523e60002000016'
      query['$or'][1].featured_artist_ids.should.containEql ObjectId '5086df098523e60002000016'
      query['$or'][2].biography_for_artist_id.should.containEql ObjectId '5086df098523e60002000016'

    it 'uses Regex in thumbnail_title for q', ->
      { query } = Retrieve.toQuery {
        q: 'Thumbnail Title 101'
        published: true
      }
      query.hasOwnProperty('thumbnail_title').should.be.true()
      query.thumbnail_title['$regex'].should.be.ok()


    it 'ignores q if it is empty', ->
      { query } = Retrieve.toQuery {
        q: ''
        published: true
      }
      query.hasOwnProperty('thumbnail_title').should.be.false()

    it 'aggregates the query for has_video', ->
      { query } = Retrieve.toQuery {
        has_video: true
        published: true
      }
      query['$or'][1]['hero_section.type'].should.be.ok()
      query['$or'][1]['hero_section.type'].should.equal 'video'
      query['$or'][0].sections['$elemMatch'].should.be.ok()
      query['$or'][0].sections['$elemMatch'].type.should.equal 'video'

    it 'finds articles by multiple fair ids', ->
      { query } = Retrieve.toQuery {
        fair_ids: ['5086df098523e60002000016','5086df098523e60002000015']
        published: true
<<<<<<< HEAD
      }
      query.fair_ids['$elemMatch'].should.be.ok()
      query.fair_ids['$elemMatch']['$in'][0].should.containEql ObjectId '5086df098523e60002000016'
      query.fair_ids['$elemMatch']['$in'][1].should.containEql ObjectId '5086df098523e60002000015'
=======
      }, (err, query) =>
        query.fair_ids['$elemMatch'].should.be.ok()
        query.fair_ids['$elemMatch']['$in'][0].toString().should.equal '5086df098523e60002000016'
        query.fair_ids['$elemMatch']['$in'][1].toString().should.equal '5086df098523e60002000015'
        done()
>>>>>>> e47fe321250be31e6fdd380a547192231c2e5705

    it 'finds articles by multiple ids', ->
      { query } = Retrieve.toQuery {
        ids: ['54276766fd4f50996aeca2b8', '54276766fd4f50996aeca2b7']
        published: true
<<<<<<< HEAD
      }
      query._id['$in'].should.be.ok()
      query._id['$in'][0].should.containEql ObjectId '54276766fd4f50996aeca2b8'
      query._id['$in'][1].should.containEql ObjectId '54276766fd4f50996aeca2b7'
=======
      }, (err, query) =>
        query._id['$in'].should.be.ok()
        query._id['$in'][0].toString().should.equal '54276766fd4f50996aeca2b8'
        query._id['$in'][1].toString().should.equal '54276766fd4f50996aeca2b7'
        done()
>>>>>>> e47fe321250be31e6fdd380a547192231c2e5705

    it 'finds scheduled articles', ->
      { query } = Retrieve.toQuery {
        scheduled: true
      }
      query.scheduled_publish_at.should.have.keys '$ne'
