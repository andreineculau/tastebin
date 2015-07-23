fs = require 'fs'
debug = require('debug') 'tastebin'
express = require 'express'
morgan = require 'morgan'
serveStatic = require 'serve-static'
rawBody = require 'raw-body'
mediaTyper = require 'media-typer'

module.exports = exports = (config = {}) ->
  config.stylesHtml = ['\n']
  for style in config.styles
    selected = ''
    selected = ' selected'  if style is config.style
    config.stylesHtml.push "<option#{selected} value=\"#{style}\">#{style}</option>\n"
  config.stylesHtml = config.stylesHtml.join ''

  app = express.Router({strict: true})
  {saveFile} = exports

  app.use morgan config.morgan.format

  app.get '/', (req, res, next) ->
    res.render 'index', {config}

  app.post '/tastes/', (req, res, next) ->
    loop
      filename = config.generate()
      break  unless fs.existsSync(filename)
    relPath = "tastes/#{filename}"
    saveFile relPath, req, res, (err) ->
      return next err  if err?
      res.status(201).location("#{filename}").send()

  app.put '/tastes/:filename', (req, res, next) ->
    relPath = "tastes/#{req.params.filename}"
    fs.exists relPath, (exists) ->
      return res.status(409).send()  if exists
      saveFile relPath, req, res, (err) ->
        return next err  if err?
        res.status(204).send()

  app.use '/tastes', serveStatic 'tastes'
  app.use serveStatic 'static'
  app


exports.saveFile = (relPath, req, res, next) ->
  contentType = req.headers['content-type']
  encoding = 'utf-8'
  encoding = mediaTyper.parse(contentType).parameters.charset  if contentType?
  rawBody req, {
    length: req.headers['content-length']
    limit: '1mb'
    encoding
  }, (err, data) ->
    return next err  if err?
    fs.writeFile relPath, data, {encoding}, next
