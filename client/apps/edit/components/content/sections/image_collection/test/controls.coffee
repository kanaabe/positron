_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
{ resolve } = require 'path'
Backbone = require 'backbone'
React = require 'react'
ReactDOM = require 'react-dom'
ReactTestUtils = require 'react-addons-test-utils'
Artwork = require '../../../../../../../models/artwork'
fixtures = require '../../../../../../../../test/helpers/fixtures'
{ fabricate } = require 'antigravity'
r =
  find: ReactTestUtils.scryRenderedDOMComponentsWithClass
  simulate: ReactTestUtils.Simulate

describe 'ImageCollectionControls', ->

  beforeEach (done) ->
    global.Image = class Image
      constructor: ->
        setTimeout => @onload()
      onload: ->
      width: 120
      height: 90
    benv.setup =>
      benv.expose
        $: benv.require 'jquery'
        _: benv.require 'underscore'
        Bloodhound: (Bloodhound = sinon.stub()).returns(
          initialize: ->
          ttAdapter: ->
        )
      $.fn.typeahead = sinon.stub()
      $.fn.offset = sinon.stub().returns(top: 200)
      Backbone.$ = $
      sinon.stub Backbone, 'sync'
      @Controls = benv.require (
        resolve(__dirname, '../components/controls')
      )
      UrlArtworkInput = benv.require (
        resolve(__dirname, '../components/url_artwork_input.coffee')
      )
      UrlArtworkInput.__set__ 'setState', sinon.stub()
      @Controls.__set__ 'UrlArtworkInput', React.createFactory UrlArtworkInput
      @Controls.__set__ 'Autocomplete', sinon.stub()
      @Controls.__set__ 'gemup', @gemup = sinon.stub()
      @props = {
        section: new Backbone.Model {
          type: 'image_collection'
          layout: 'overflow_fillwidth'
          images: []
        }
        images: []
        setProgress: @setProgress = sinon.stub()
        onChange: @onChange = sinon.stub()
        channel: { hasFeature: @hasFeature = sinon.stub().returns(true), isEditorial: sinon.stub().returns(true)}
      }
      @component = ReactDOM.render React.createElement(@Controls, @props), (@$el = $ "<div></div>")[0], =>
      done()

  afterEach ->
    benv.teardown()
    Backbone.sync.restore()

  it 'renders all fields', ->
    $(ReactDOM.findDOMNode(@component)).html().should.containEql 'overflow_fillwidth'
    $(ReactDOM.findDOMNode(@component)).html().should.containEql 'column_width'
    $(ReactDOM.findDOMNode(@component)).html().should.containEql 'image_set'
    $(ReactDOM.findDOMNode(@component)).html().should.containEql 'dashed-file-upload-container'
    $(ReactDOM.findDOMNode(@component)).html().should.containEql 'placeholder="Search for artwork by title"'
    $(ReactDOM.findDOMNode(@component)).html().should.containEql 'placeholder="Add artwork url"'

  it 'sets layout to overflow_fillwidth by default', ->
    $(ReactDOM.findDOMNode(@component)).find('a[name="overflow_fillwidth"]').data('active').should.eql true

  it 'changes layout on layout button click', ->
    r.simulate.click(r.find(@component, 'layout')[1], {target: {name:'column_width'}})
    @component.props.section.get('layout').should.eql 'column_width'
    @component.forceUpdate()
    $(ReactDOM.findDOMNode(@component)).find('a[name="column_width"]').data('active').should.eql true
    @onChange.called.should.eql true

  it 'can toggle from image_collection to image_set on layout button click', ->
    r.simulate.click(r.find(@component, 'layout')[2], {target: {name:'image_set'}})
    @component.forceUpdate()
    @component.props.section.get('type').should.eql 'image_set'
    @component.props.section.toJSON().should.not.containEql 'image_collection'
    @component.props.section.toJSON().should.not.containEql 'layout'
    $(ReactDOM.findDOMNode(@component)).find('a[name="image_set"]').data('active').should.eql true
    @onChange.called.should.eql true

  it 'can toggle from image_set to image_collection on layout button click', ->
    @component.props.section.unset 'layout'
    @component.props.section.set 'type', 'image_set'
    r.simulate.click(r.find(@component, 'layout')[1], {target: {name:'column_width'}})
    @component.forceUpdate()
    @component.props.section.get('type').should.eql 'image_collection'
    @component.props.section.get('layout').should.eql 'column_width'
    $(ReactDOM.findDOMNode(@component)).find('a[name="column_width"]').data('active').should.eql true
    @onChange.called.should.eql true

  it 'does not display image_set option unless channel has feature', ->
    @component.props.channel.hasFeature = sinon.stub().returns(false)
    @component.forceUpdate()
    r.find(@component, 'layout').length.should.eql 2
    $(ReactDOM.findDOMNode(@component)).html().should.not.containEql 'image_set'

  it 'saves image info after upload', (done) ->
    @component.setState = sinon.stub()
    @component.upload target: files: ['foo']
    @gemup.args[0][1].done('fooza')
    setTimeout =>
      @component.props.section.get('images')[0].type.should.equal 'image'
      @component.props.section.get('images')[0].url.should.equal 'fooza'
      @component.props.section.get('images')[0].width.should.equal 120
      @component.props.section.get('images')[0].height.should.equal 90
      done()

  it 'saves an artwork by url', ->
    input = r.find(@component, 'bordered-input')[1]
    input.value = 'http://artsy.net/artwork/skull7'
    r.simulate.change input
    r.simulate.click r.find(@component, 'esis-byurl-button')[0]
    Backbone.sync.args[0][2].success fabricate 'artwork'
    @component.props.section.get('images')[0].type.should.eql 'artwork'
    @onChange.called.should.eql true

  it '#addArtworkFromUrl updates the section images', ->
    @component.addArtworkFromUrl([{type:'image', url:'image.com'}, {type: 'artwork', image:'artwork.jpg'}])
    @component.props.section.get('images')[0].should.eql {type:'image', url: 'image.com'}
    @component.props.section.get('images')[1].should.eql {type: 'artwork', image:'artwork.jpg'}
