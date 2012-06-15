class Myna

  defaults =
    # number (lifespan of the cookie in days from now)
    cookieLifespan: 365
    # string
    cookieName: "myna" + agent
    # natural (ms)
    timeout: 1000
    # string (url)
    baseurl: "http://api.mynaweb.com"
    # natural: 0 = silent, 1 = error, 2 = warn, 3 = info, 4 = debug
    loglevel: 1


  # (U null String)
  token: null

  # String, Hash -> Myna
  #
  # @experiment is the UUID of the experiment
  # @options is a hash of options, containing the same keys as defaults
  constructor: (@experiment, @options) ->
    @options = extend(extend({}, defaults), options)
    @log = Log.Log(@options.loglevel)

  # Utility functions --------------------------------------

  # String -> {token: String, choice: String}
  parseSuggestResponse: (content) ->
    { token: content.token, choice: content.choice }

  # String -> {code: Number, message: String}
  parseErrorResponse: (content) ->
    parts = content.split(/[\r\n]+/)
    code = parseInt(parts[0].replace(/ERROR: /, ""))
    message = parts[1]
    { code: code, message: message }



  # Myna client --------------------------------------------

  # (String, Hash[String,String],
  #  (Any ...) -> Undefined,
  #  (Any ...) -> Undefined) -> Undefined
  doAjax: (path, data, success, error) ->
    @log(LogLevel.DEBUG, "myna.doAjax called")

    ajaxOptions = extend(extend({}, @options), {
      url: @options.baseurl + path
      data: data
      success: success
      error: error
    })

    @log(LogLevel.DEBUG, ajaxOptions)

    JsonP.doJsonP(ajaxOptions)

  # (Any ...) -> Undefined,
  # (Any ...) -> Undefined) -> Undefined
  suggest: (success, error) ->
    @log(LogLevel.DEBUG, "myna.suggest called")

    data = { agent: myna.agent }

    # object string xhr -> void
    successWrapper = (data, msg, xhr) ->
      @log(LogLevel.DEBUG, "myna.suggest successWrapper called")
      @log(LogLevel.DEBUG, data)

      if data.typename == "suggestion"
        response = parseSuggestResponse(data)
        @log(LogLevel.INFO, "Myna suggested " + response.suggestion)

        @log(LogLevel.DEBUG, "Response token stored " + response.token)
        myna.token = response.token

        if success
          success(response)
        else
          @log(LogLevel.WARN, "You should pass a success function to myna.suggest. See the docs for details.")
      else if data.typename == "mynaapierror"
        @log(LogLevel.ERROR, "Myna.suggest returned an API error: " + data.code + " " + data.message)

        if error
          error(data.code, data.message)
      else
        @log(LogLevel.ERROR, "Myna.suggest did something unexpected")
        @log(LogLevel.ERROR, data)
        if error
          error(400, "The Myna client didn't handle this data: " + data)


      # xhr string string -> void
      errorWrapper = (xhr, text, error) ->
        @log(LogLevel.DEBUG, "myna.suggest errorWrapper called")

        response = parseErrorResponse(xhr.responseText)
        @log(LogLevel.ERROR, xhr)
        @log(LogLevel.ERROR, text)
        @log(LogLevel.ERROR, error)
        @log(LogLevel.ERROR, response)
        @log(LogLevel.ERROR, "myna.suggest failed: error " + response.code + " " + response.message)

        if error
          error(response.code, response.message)

    this.doAjax("/suggest", data, successWrapper, errorWrapper)


  # (Number, () -> Any, (Number, String) -> Any) -> Undefined
  reward: (amount, success, error) ->
    @log(LogLevel.DEBUG, "myna.reward called")

    # If this function is used directly as an event handler,
    # the first argument will be an event object.
    # In this case amount, success, and error will actually be undefined.
    if typeof(amount) == "object" and amount.target
      @log(LogLevel.WARN, "You used myna.reward directly as an event handler, which is strictly speaking bad.")
      @log(LogLevel.WARN, "To suppress this message, wrap the call to myna.reward in an anonymous function, e.g.:")
      @log(LogLevel.WARN, "  $(\"foo\").click(function() { myna.reward() })")
      amount = null
      success = null
      error = null


    if !myna.token
      @log(LogLevel.ERROR, "You must call suggest before you call reward.")
      return

    data =
      agent: agent
      token: myna.token
      amount: amount || 1.0

    # string string xhr -> void
    successWrapper = (data, msg, xhr) ->
      @log(LogLevel.DEBUG, "myna.reward successWrapper called")

      myna.token = null
      @log(LogLevel.INFO, "myna.reward succeeded")

      if success
        success()

    # xhr string string -> void
    errorWrapper = (xhr, text, error) ->
      @log(LogLevel.DEBUG, "myna.reward errorWrapper called")

      response = parseErrorResponse(xhr.responseText)
      @log(LogLevel.ERROR, "myna.reward failed: error #{response.code} #{response.message}")

      if error
        error(response.code, response.message)

    myna.doAjax("/reward", data, successWrapper, errorWrapper)


  saveToken: (token) ->
    @log(LogLevel.DEBUG, "myna.saveToken called with token" + token)
    token = token || myna.token

    if token
      createCookie(myna.options.cookieName, token, myna.options.cookieLifespan)
    else
      @log(LogLevel.WARN, "myna.saveToken called with empty token and myna.token also empty")

  loadToken: () ->
    token = readCookie(myna.options.cookieName)

    if !token
      @log(LogLevel.WARN, "myna.loadToken loaded empty token")

  clearToken: () ->
    clearCookie(myna.options.cookieName)