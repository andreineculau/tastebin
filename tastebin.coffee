#!/usr/bin/env coffee

debug = require('debug') 'tastebin'
express = require 'express'
mustacheExpress = require 'mustache-express'
config = require './config'
router = require('./index') config

for serverConfig in config.listenOn
  app = express()
  app.engine 'mustache', mustacheExpress()
  app.set 'view engine', 'mustache'
  app.set 'view cache', false
  app.set 'x-powered-by', false
  app.set 'views', "#{__dirname}/static"
  app.set 'strict routing', true
  if serverConfig.headers?
    app.use (req, res, next) ->
      res.set serverConfig.headers
      next()
  app.use config.subpath, router

  module = require serverConfig.module

  if serverConfig.options?
    server = module.createServer serverConfig.options, app
  else
    server = module.createServer app

  server.listen serverConfig.port, () ->
    address = server.address().address
    port = server.address().port
    debug "Server listening on #{serverConfig.protocol}://#{address}:#{port}"
