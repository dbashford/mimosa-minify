color = require('ansi-color').set
growl = require 'growl'
require 'date-utils'

class Logger

  isDebug: false
  isStartup: true

  setDebug: (@isDebug = true) ->
  setConfig: (config) -> @config = config.growl
  buildDone: (@isStartup = false) =>

  _log: (logLevel, message, color, growlTitle = null) ->
    if growlTitle?
      imageUrl = switch logLevel
        when 'success' then "#{__dirname}/assets/success.png"
        when 'error' then "#{__dirname}/assets/failed.png"
        when 'fatal' then "#{__dirname}/assets/failed.png"
        else ''

      growl message, {title: growlTitle, image: imageUrl}

    message = @_wrap(message, color)

    if logLevel is 'error' or logLevel is 'warn' or logLevel is 'fatal'
      console.error message
    else
      console.log message

  _wrap: (message, textColor) -> color("#{new Date().toFormat('HH24:MI:SS')} - #{message}", textColor)

  blue:  (message) => console.log color(message, "blue+bold")
  green: (message) => console.log color(message, "green+bold")
  red:   (message) => console.log color(message, "red+bold")

  error: (message) => @_log 'error', message, 'red+bold', 'Error'
  warn:  (message) => @_log 'warn',  message, 'yellow'
  info:  (message) => console.log "#{new Date().toFormat('HH24:MI:SS')} - #{message}"
  fatal: (message) => @_log 'fatal', "FATAL: #{message}", 'red+bold+underline', "Fatal Error"
  debug: (message) => @_log 'debug', "#{message}", 'blue' if @isDebug

  success: (message, options) =>
    title = if options is true
      "Success"
    else if @config
      s = @config.onSuccess
      if @isStartup and not @config.onStartup
        null
      else if not options or
        (options.isJavascript and s.javascript) or
        (options.isCSS and s.css) or
        (options.isTemplate and s.template) or
        (options.isCopy and s.copy)
          "Success"
      else
        null
    else
      "Success"

    @_log 'success', message, 'green+bold', title

  defaults: ->
    growl:
      onStartup: false
      onSuccess:
        javascript: true
        css: true
        template: true
        copy: true

  placeholder: ->
    """
    \t

      # growl:
        # onStartup: false       # Controls whether or not to Growl when assets successfully
                                 # compile/copy on startup, If you've got 100 CoffeeScript files,
                                 # and you do a clean and then start watching, you'll get 100 Growl
                                 # notifications.  This is set to false by default to prevent that.
                                 # Growling for every successful file on startup can also cause
                                 # EMFILE issues. See watch.throttle
        # onSuccess:             # Controls whether to Growl when assets successfully compile/copy
          # javascript: true     # growl on successful compilation? will always send on failure
          # css: true            # growl on successful compilation? will always send on failure
          # template: true       # growl on successful compilation? will always send on failure
          # copy: true           # growl on successful copy?
    """

  validate: (config) ->
    errors = []
    if config.growl?
      if typeof config.growl is "object" and not Array.isArray(config.growl)
        if config.growl.onStartup?
          unless typeof config.growl.onStartup is "boolean"
            errors.push "growl.onStartup must be boolean"
        if config.growl.onSuccess?
          succ = config.growl.onSuccess
          if typeof succ is "object" and not Array.isArray(succ)
            for type in ["javascript", "css", "template", "copy"]
              if succ[type]?
                unless typeof succ[type] is "boolean"
                  errors.push "growl.onSuccess.#{type} must be boolean."
          else
            errors.push "growl.onSuccess must be an object."
      else
        errors.push "lint configuration must be an object."
    errors

module.exports = new Logger
