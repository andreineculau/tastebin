fs = require 'fs'
debug = require('debug') 'tastebin'
express = require 'express'
morgan = require 'morgan'
serveStatic = require 'serve-static'
rawBody = require 'raw-body'
mediaTyper = require 'media-typer'
execFile = require('child_process').execFile

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
    do () ->
      shCmd = [
        "ls -tA | tail -n +#{config.maxLifetimeCount} | xargs rm"
        "rm -rf `find ./ -mtime +#{config.maxLifetimeDays}`"
      ]
      if config.maxLifetimeIgnoreFilenames?.length
        shCmd.unshift "touch #{config.maxLifetimeIgnoreFilenames}"
      shCmd = shCmd.join '; '
      execOptions = {cwd: "#{__dirname}/tastes/"}
      execFile '/bin/sh', ['-c', shCmd], execOptions
    res.render 'index', {config}

  app.get '/tastes/', (req, res, next) ->
    unless config.maxListCount? and config.maxListCount > 0
      res.status(200).set('Content-Type', 'text/plain').send()
      return
    maxListCount = config.maxListCount + 1
    shCmd = "ls -tl | head -#{maxListCount} | tail -n +2 | tr -s ' ' | cut -d' ' -f6,7,8"
    execOptions = {cwd: "#{__dirname}/tastes/"}
    execFile '/bin/sh', ['-c', shCmd], execOptions, (err, stdout, stderr) ->
      return next err  if err?
      res.status(200).set('Content-Type', 'text/plain').send stdout

  app.post '/tastes/', (req, res, next) ->
    loop
      filename = config.generate()
      break  unless fs.existsSync(filename)
    relPath = "tastes/#{filename}"
    saveFile relPath, req, res, (err) ->
      return next err  if err?
      res.status(201).location("#{filename}").send()

  app.put '/tastes/:filename', (req, res, next) ->
    if req.params.filename.length > config.maxFilenameLength
      return res.status(414).send()
    relPath = "tastes/#{req.params.filename}"
    fs.exists relPath, (exists) ->
      return res.status(409).send()  if exists
      saveFile relPath, req, res, (err) ->
        return next err  if err?
        res.status(204).send()

  app.use '/tastes', serveStatic 'tastes', {dotfiles: 'allow'}
  app.use serveStatic 'static'
  app


exports.saveFile = (relPath, req, res, next) ->
  contentType = req.headers['content-type']
  encoding = 'utf-8'
  encoding = mediaTyper.parse(contentType).parameters.charset  if contentType?
  rawBody req, {
    length: req.headers['content-length']
    limit: config.maxSize
    encoding
  }, (err, data) ->
    return next err  if err?
    fs.writeFile relPath, data, {encoding}, next
