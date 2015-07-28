fs = require 'fs'
path = require 'path'
execFile = require('child_process').execFile
execFileSync = require('child_process').execFileSync
debug = require('debug') 'tastebin'

express = require 'express'
morgan = require 'morgan'
serveStatic = require 'serve-static'
rawBody = require 'raw-body'
mediaTyper = require 'media-typer'
cookieParser = require 'cookie-parser'

module.exports = exports = (config = {}) ->
  defaultTheme = config.theme

  config.hljsStyles ?= execFileSync('/bin/sh', ['-c', "ls"], {cwd: "#{__dirname}/static/bower_components/highlightjs/styles"}).toString().trim().split '\n'
  config.hljsStylesHtml = ['\n']
  for hljsStyle in config.hljsStyles
    hljsStyle = hljsStyle.replace /\.css$/, ''
    selected = ''
    selected = ' selected'  if hljsStyle is config.hljsStyle
    config.hljsStylesHtml.push "<option#{selected} value=\"#{hljsStyle}\">#{hljsStyle}</option>\n"
  config.hljsStylesHtml = config.hljsStylesHtml.join ''
  config.hljsStylesHtml = ''  if config.hljsStyles.length <= 1

  app = express.Router {strict: true}
  {saveFile} = exports

  app.use morgan config.morgan.format

  app.get '/', cookieParser(), (req, res, next) ->
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
    config.theme = defaultTheme
    config.theme = req.cookies.theme  if req.cookies?.theme in config.themes

    tpl = "#{__dirname}/static/#{config.theme}.mustache"
    unless fs.existsSync tpl
      res.clearCookie 'theme'
      config.theme = defaultTheme
      tpl = "#{__dirname}/static/#{config.theme}.mustache"

    config.themesHtml = ['\n']
    for theme in config.themes
      selected = ''
      selected = ' selected'  if theme is config.theme
      config.themesHtml.push "<option#{selected} value=\"#{theme}\">#{theme}</option>\n"
    config.themesHtml = config.themesHtml.join ''
    config.themesHtml = ''  if config.themes.length <= 1

    res.render tpl, {config}

  app.get '/tastes/', (req, res, next) ->
    unless config.maxListCount? and config.maxListCount > 0
      res.status(200).set('Content-Type', 'text/plain').send()
      return
    maxListCount = config.maxListCount + 1
    shCmd = "TIME_STYLE=long-iso ls -tl | head -#{maxListCount} | tail -n +2 | tr -s ' ' | cut -d' ' -f6,7,8"
    execOptions = {cwd: "#{__dirname}/tastes/"}
    execFile '/bin/sh', ['-c', shCmd], execOptions, (err, stdout, stderr) ->
      return next err  if err?
      res.status(200).set('Content-Type', 'text/plain').send stdout

  app.post '/tastes/', (req, res, next) ->
    loop
      filename = config.generate()
      break  unless fs.existsSync(filename)
    relPath = "tastes/#{filename}"
    saveFile relPath, config, req, res, (err) ->
      return next err  if err?
      res.status(201).location("#{filename}").send()

  app.put '/tastes/:filename', (req, res, next) ->
    if req.params.filename.length > config.maxFilenameLength
      return res.status(414).send()
    if "/#{req.params.filename}" isnt path.resolve '/', req.params.filename
      return res.status(400).send()
    relPath = "tastes/#{req.params.filename}"
    fs.exists relPath, (exists) ->
      return res.status(409).send()  if exists
      saveFile relPath, config, req, res, (err) ->
        return next err  if err?
        res.status(204).send()

  app.use '/tastes', serveStatic config.tastesDir, {dotfiles: 'allow'}
  app.use serveStatic 'static'
  app


exports.saveFile = (relPath, config, req, res, next) ->
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
