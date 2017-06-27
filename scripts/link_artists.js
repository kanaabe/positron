const _ = require('underscore')
const _s = require('underscore.string')
const fs = require('fs')
const path = require('path')
const env = require('node-env-file')
const token = ''
const request = require('superagent')


switch (process.env.NODE_ENV) {
  case 'test':
    env(path.resolve(__dirname, '../.env.test'))
    break
  case 'production':
  case 'staging':
    break
  default:
    env(path.resolve(__dirname, '../.env'))
}

const ARTISTLIST = require('./artist_list.js')

function getArtistInfo (artist) {
  return new Promise((resolve, reject) => {
    var slug = _s.slugify(artist)
    // First check if the slug exists
    request
      .get('https://api.artsy.net/api/v1/artist/' + slug)
      .send({access_token: token})
      .end((err, res)=>{
        if(err){
          console.log('there was an error...continuing')
          var url = "https://api.artsy.net/api/search?xapp_token=" + token + "&type=artist&q=" + artist
          request
            .get(encodeURIComponent(url))
            .end((err, res) => {
              if(err){
                console.log(err)
                console.log('there was an error...cant find')
                resolve(null)
              }else{
                console.log(res)
                // artist = {
                //   name: artist
                //   slug: slug
                //   type: 'artist'
                // }
                // return resolve(artist)
              }
            })
        }else{
          artist = {
            name: artist,
            slug: slug,
            type: 'artist'
          }
          console.log('found ' + artist.name + ' via slug' )
          return resolve(artist)
        }
      })



  })
}

(async function () {
  try {
    var artists = []
    // Copy Data Tasks
    for (var i = 0; i <= ARTISTLIST.length; i++) {
      var artist = ARTISTLIST[i]
      var artist = await getArtistInfo(artist)
      artists.push(artist)
    }
    console.log(artists)
    console.log('Completed Fetching All Artists')
  } catch (err) {
    console.log(err)
  }
}())