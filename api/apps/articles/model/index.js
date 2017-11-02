//
// Library of retrieval, persistance, validation, json view, and domain logic
// for the "articles" resource.
//
import _ from 'underscore'
import async from 'async'
import cloneDeep from 'lodash.clonedeep'
import schema from './schema.coffee'
import Joi from '../../../lib/joi.coffee'
import retrieve from './retrieve.coffee'
import { ObjectId } from 'mongojs'
import moment from 'moment'
const db = require('../../../lib/db.coffee')
const { onPublish, generateSlugs, generateKeywords,
  sanitizeAndSave, onUnpublish } = require('./save.coffee')
const { removeFromSearch, deleteArticleFromSailthru } = require('./distribute.coffee')

//
// Retrieval
//
export const where = (input, callback) => {
  return Joi.validate(input, schema.querySchema, { stripUnknown: true }, (err, input) => {
    if (err) { return callback(err) }
    return mongoFetch(input, callback)
  })
}

export const mongoFetch = (input, callback) => {
  const { query, limit, offset, sort, count } = retrieve.toQuery(input)
  const cursor = db.articles
    .find(query)
    .skip(offset || 0)
    .sort(sort)
    .limit(limit)
  async.parallel([
    cb => cursor.toArray(cb),
    cb => {
      if (!count) { return cb() }
      return db.articles.count(cb)
    },
    (cb) => {
      if (!count) { return cb() }
      return cursor.count(cb)
    }
  ], (err, results) => {
    const [articles, total, articleCount] = results
    if (err) { return callback(err) }
    return callback(null, {
      results: articles,
      total,
      count: articleCount
    })
  })
}

export const find = (id, callback) => {
  const query = ObjectId.isValid(id) ? { _id: ObjectId(id) } : { slugs: id }
  db.articles.findOne(query, callback)
}

//
// Persistence
//
export const save = (input, accessToken, options, callback) => {
  // Validate the input with Joi
  const validationOptions = _.extend({ stripUnknown: true }, options.validation)
  Joi.validate(input, schema.inputSchema, validationOptions, (err, input) => {
    if (err) { return callback(err) }

    // Find the original article or create an empty one
    const articleId = (input.id || input._id) ? (input.id || input._id).toString() : null
    find(articleId, (err, article) => {
      if (article == null) { article = {} }
      if (err) { return callback(err) }

      // Create a new article by merging the values of input and article
      const modifiedArticle = _.extend(cloneDeep(article), input)

      generateKeywords(input, modifiedArticle, (err, modifiedArticle) => {
        if (err) { return callback(err) }

        // Eventually convert these to Joi custom extensions
        modifiedArticle.updated_at = new Date()
        if (input.hero_section && input.hero_section.type === 'fullscreen') {
          modifiedArticle.title = modifiedArticle.hero_section.title
        }
        if (input.author) { modifiedArticle.author = input.author }

        // Handle publishing, unpublishing, published, draft
        const publishing = (modifiedArticle.published && !article.published) || (modifiedArticle.scheduled_publish_at && !article.published)
        const unPublishing = article.published && !modifiedArticle.published
        const hasSlugs = modifiedArticle.slugs && modifiedArticle.slugs.length > 0
        if (publishing) {
          return onPublish(modifiedArticle, sanitizeAndSave(callback))
        } else if (unPublishing) {
          return onUnpublish(modifiedArticle, sanitizeAndSave(callback))
        } else if (!publishing && !hasSlugs) {
          return generateSlugs(modifiedArticle, sanitizeAndSave(callback))
        } else {
          return sanitizeAndSave(callback)(null, modifiedArticle)
        }
      })
    })
  })
}

export const publishScheduledArticles = callback => {
  db.articles.find({ scheduled_publish_at: { $lt: new Date() } }, (err, articles) => {
    if (err) { return callback(err, []) }
    if (articles.length === 0) { return callback(null, []) }
    async.map(articles, (article, cb) => {
      article = _.extend(article, {
        published: true,
        published_at: moment(article.scheduled_publish_at).toDate(),
        scheduled_publish_at: null
      })
      return onPublish(article, sanitizeAndSave(cb))
    }
    , (err, results) => {
      if (err) { return callback(err, []) }
      return callback(null, results)
    })
  })
}

export const unqueue = callback => {
  db.articles.find({ $or: [ { weekly_email: true }, { daily_email: true } ] }, (err, articles) => {
    if (err) { return callback(err, []) }
    if (articles.length === 0) { return callback(null, []) }
    async.map(articles, (article, cb) => {
      article = _.extend(article, {
        weekly_email: false,
        daily_email: false
      })
      return onPublish(article, sanitizeAndSave(cb))
    }
    , (err, results) => {
      if (err) { return callback(err, []) }
      return callback(null, results)
    })
  })
}

//
// Destroy
//
export const destroy = (id, callback) => {
  find(id, (err, article) => {
    if (err) { return callback(err) }
    if (!article) { return callback(new Error('Article not found.')) }
    deleteArticleFromSailthru(_.last(article.slugs), () => {
      db.articles.remove({ _id: ObjectId(id) }, (err, res) => {
        if (err) { return callback(err) }
        removeFromSearch(id.toString())
        return callback(null)
      })
    })
  })
}

//
// JSON views
//
export const presentCollection = (articles) => {
  const results = _.map(articles.results, present)
  return {
    total: articles.total,
    count: articles.count,
    results
  }
}

export const present = (article) => {
  if (!article) { return {} }
  const id = article._id ? article._id.toString() : null
  const scheduled_publish_at = article.scheduled_publish_at ? moment(article.scheduled_publish_at).toISOString() : null
  const published_at = article.published_at ? moment(article.published_at).toISOString() : null
  const updated_at = article.updated_at ? moment(article.updated_at).toISOString() : null
  return _.extend(article, {
    id,
    _id: id,
    slug: _.last(article.slugs),
    slugs: undefined,
    published_at,
    scheduled_publish_at,
    updated_at
  })
}

export const getSuperArticleCount = (id) => {
  return new Promise((resolve, reject) => {
    if (!ObjectId.isValid(id)) { return resolve(0) }
    db.articles.find({ 'super_article.related_articles': ObjectId(id) }).count((err, count) => {
      if (err) { return reject(err) }
      resolve(count)
    })
  })
}

// const fs = require('fs')
const s = require('underscore.string')

export const backfill = (callback) => {
  db.articles.find({
    published: true,
    channel_id: ObjectId('5759e3efb5989e6f98f77993')
  }).toArray((err, articles) => {
    if (err) { return callback(err) }

    if (articles.length === 0) { return callback(null, []) }

    console.log(`There are ${articles.length} articles to go through...`)

    async.mapSeries(articles, (article, cb) => {
      let resave = false

      const basicText = [
        '58adcfbd2f576100116db86f',
        '5899161089131c001122396c',
        '585bf702eec5660011f983e7',
        '5614478fb51644060020546a',
        '554a9f15cebe5506004d455c',
        '554a9f15cebe5506004d455c',
        '559b1b2b5376100600ff0bc7',
        '566f41135e8cd1060096c29b',
        '5954212508f3ab00173d23f0',
        '5978e6e74c20750017e55e46',
        '56cc637409d5550600556b03',
        '5600c9503bb90a06009518e0',
        '5978e6e74c20750017e55e46',
        '596cc8970d19fe00171a0084',
        '56d4e895215a6b0600c5e7f6',
        '566f2891bb32b30600b0cb1d',
        '565deaffbb8d980600589da9',
        '553e30f264c2ed06001a880e',
        '552e8d31b63c46060080384a',
        '5536b7662ac3060600ccd39d',
        '55350e327340cd0600a0212d',
        '5696770f9d721c0600720a52',
        '58459e56104093001189a7d1',
        '5846e1fdc137140011634711',
        '566f41135e8cd1060096c29b',
        '5846e12cc137140011634710',
        '584b0ee3e751080011bc1ad5',
        '5670592a8f2b3a0600fa9431',
        '56705903d68cc60600d2fe67',
        '566b428fda41120600c3e2d6',
        '5669d52f7934dd060052250e',
        '56705903d68cc60600d2fe67',
        '566f41135e8cd1060096c29b'
      ]

      if (_.contains(basicText, article._id.toString())) {
        console.log('Found a manual basic text header')
        article.type = 'feature'
        article.hero_section = {
          type: 'basic',
          url: ''
        }
      }

      if (article.hero_section) {
      }
      
      if (resave) {
        console.log('---------------------')
        console.log('---------------------')
        console.log('---------------------')
        console.log('---------------------')
        console.log('---------------------')
        console.log('---------------------')
        console.log(`Saving article: ${article.slugs[article.slugs.length - 1]}`)
        // console.log(article.sections)
        // cb()
        db.articles.save(article, cb)
      } else {
        cb()
      }
    }, (err, results) => {
      console.log('DONE')
      // console.log(err)
    })
  })
}
