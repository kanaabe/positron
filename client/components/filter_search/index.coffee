_ = require 'underscore'
React = require 'react'
{ label, input, div, button, a, h1, h2 } = React.DOM
moment = require 'moment'
sd = require('sharify').data
ArticleList = require '../article_list/index.coffee'

module.exports = FilterSearch = React.createClass

  componentDidMount: ->
    @addAutocomplete()

  addAutocomplete: ->
    @engine = new Bloodhound
      datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value')
      queryTokenizer: Bloodhound.tokenizers.whitespace
      remote:
        url: @props.url
        filter: @props.filter
    @engine.initialize()

  search: ->
    term = @refs.searchQuery.getDOMNode().value
    @engine.get term, ([total, count, results]) =>
      @props.searchResults results

  selected: (article) ->
    @props.selected article, 'select'

  render: ->
    div { className: 'filter-search__container' },
      div { className: 'filter-search__header-container' },
        div { className: 'filter-search__header-text' }, @props.headerText
        input {
          className: 'filter-search__input bordered-input'
          placeholder: @props.placeholder
          onKeyUp: @search
          ref: 'searchQuery'
        }
      if @props.articles.length
        ArticleList {
          articles: @props.articles
          checkable: true
          selected: @selected
        }
      else
        div { className: 'filter-search__empty' }, "No Articles"
