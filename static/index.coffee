$ () ->
  currentContent = ''
  $window = $ window
  $body = $ window.document.body
  $theme = $ '#theme'
  $hljsStyle = $ '#hljsStyle'
  $selectedHljsStyle = $ '#selectedHljsStyle'
  $linenos = $ '#linenos'
  $linenosCode = $ '> code:first', $linenos
  $editor = $ '#editor'
  $editorCode = $ '> code:first', $editor
  $list = $ '#list'

  metaKeyName = 'Ctrl'
  metaKeyName = 'Cmd'  if /^Mac/.test navigator.platform
  newTaste = $('#newTaste').html().replace /#{metaKeyName}/g, metaKeyName

  getDomContent = () ->
    $editorCode[0].innerText

  setDomContent = (content) ->
    if 'innerText' of $editorCode[0]
      $editorCode[0].innerText = content
    else
      content = content.replace
      $editorCode[0].innerHTML = he.encode content

  wantsToEdit = (evt) ->
    metaKey = evt.ctrlKey
    metaKey = evt.metaKey  if /^Mac/.test navigator.platform
    return false  unless metaKey
    char = String.fromCharCode(evt.which).toLowerCase()
    return false  unless char is 'e'
    true

  maybeStartEditing = (evt) ->
    return true  unless wantsToEdit evt
    startEditing evt

  maybeCancelEditing = (evt) ->
    return true  unless evt.which is 27
    evt.preventDefault()
    hash = window.location.hash.replace /^#/, ''
    tryLoading hash
    false

  cleanupPaste = () ->
    # erase any styling
    setDomContent getDomContent()

  scheduleCleanupPaste = (evt) ->
    setTimeout cleanupPaste, 100

  keepFocus = () ->
    $editorCode.focus()

  wantsToSave = (evt) ->
    metaKey = evt.ctrlKey
    metaKey = evt.metaKey  if /^Mac/.test navigator.platform
    return false  unless metaKey
    char = String.fromCharCode(evt.which).toLowerCase()
    return false  unless char is 's'
    true

  disableSave = (evt) ->
    return true  unless wantsToSave evt
    evt.preventDefault()
    false

  maybeSave = (evt) ->
    return true  unless wantsToSave evt
    evt.preventDefault()

    if evt.shiftKey
      method = 'PUT'
      filename = ''
      loop
        promptFilename = window.prompt 'Please enter a filename', filename
        return  unless promptFilename?
        filename = promptFilename.replace /[^A-Za-z0-9\-_]/, ''
        break  if filename is promptFilename
      url = "tastes/#{filename}"
    else
      method = 'POST'
      url = 'tastes/'

    currentContent = getDomContent().trim().replace(/\s+\n/g, '\n')
    currentContent += '\n'  if currentContent.length
    setDomContent currentContent  if currentContent isnt getDomContent()
    return true  unless currentContent.length

    always = () ->
      edit()

    done = (body, status, xhr) ->
      if method is 'POST'
        window.location.hash = xhr.getResponseHeader 'Location'
      else
        window.location.hash = filename

    fail = () ->
      $linenosCode.html "Failed to save".replace /(.)/g, '$1<br>'

    lock null, 'Saving...'
    $.ajax({
      method
      url
      contentType: 'application/octet-stream'
      data: currentContent
    }).always(always).done(done).fail(fail)
    false

  edit = (content) ->
    content ?= getDomContent()
    $list.hide()
    $linenosCode.html "Esc - #{metaKeyName}+s - Shift+#{metaKeyName}+s".replace /(.)/g, '$1<br>'
    $editorCode.html content
    $editorCode.attr('contentEditable', 'true').focus()
    $editorCode.on 'blur', keepFocus
    $body.addClass 'editing'
    $body.off 'keydown', disableSave
    $body.on 'keydown', maybeSave
    $body.on 'keydown', maybeCancelEditing

  lock = (content, lines = []) ->
    content ?= getDomContent()
    if Array.isArray lines
      if lines.length is 0
        linenosCount = content.split('\n').length
        lines = [1..linenosCount]
    else
      lines = lines.split ''
    $linenosCode.html lines.join '<br>'
    $editorCode.html content

    $editorCode.attr 'contentEditable', 'false'
    $editorCode.off 'blur', keepFocus
    $body.removeClass 'editing'
    $body.on 'keydown', maybeStartEditing
    $body.on 'keydown', disableSave
    $body.off 'keydown', maybeSave
    $body.off 'keydown', maybeCancelEditing

  list = () ->
    always = () ->
      lock newTaste, ''

    done = (body, status, xhr) ->
      files = body.split '\n'
      files = files.map (file) ->
        [date, time, filename] = file.split ' '
        {
          date
          time
          filename
        }
      filesHtml = files.map ({date, time, filename}) ->
        return ''  unless filename?.length
        "#{date} #{time} <a href=\"\##{filename}\" class=\"hljs-string\">#{filename}</a>\n"
      filesHtml = filesHtml.join ''
      $list.html(filesHtml).css 'display', ''

    fail = () ->

    $.ajax({
      method: 'GET'
      url: 'tastes/'
    }).always(always).done(done).fail(fail)

  tryLoading = (hash) ->
    filename = hash.replace /[^A-Za-z0-9\-_\.]/, ''
    if filename isnt hash
      window.location.hash = "#{filename}"
      return

    unless filename
      list()
      return

    $list.hide()
    if filename.indexOf('.') > 0
      [filename..., language] = filename.split '.'
      filename = filename.join '.'

    done = (body, status, xhr) ->
      currentContent = body
      if language?
        try
          high = hljs.highlight language, currentContent
        catch e
          high = {value: currentContent}
      else
        high = hljs.highlightAuto currentContent
        if high.language?
          history.replaceState undefined, undefined, "\##{filename}.#{high.language}"
          # window.location.hash = "#{filename}.#{high.language}"
          # return

      lock high.value

    fail = () ->
      # window.location.hash = ''
      lock '', 'Failed to load...'

    lock '', 'Loading...'
    $body.off 'keydown', maybeStartEditing
    $body.off 'keydown', maybeCancelEditing
    $.ajax({
      url: "tastes/#{filename}"
    }).done(done).fail(fail)

  window.onpopstate = (evt) ->
    hash = evt.target.location.hash.replace /^#/, ''
    tryLoading hash

  $theme.on 'change', (evt) ->
    theme = this.value
    $.cookie 'theme', theme
    window.location.reload true

  localTheme = $.cookie 'theme'
  if localTheme?
    $("> option[value=\"#{localTheme}\"]", $theme).prop 'selected', 'selected'

  $hljsStyle.on 'change', (evt) ->
    hljsStyle = this.value
    href = $selectedHljsStyle.attr 'href'
    href = href.split('/').slice(0, -1).concat(["#{hljsStyle}.css"]).join '/'
    $selectedHljsStyle.attr 'href', href
    window.localStorage.setItem 'hljsStyle', hljsStyle

  localHljsStyle = window.localStorage.getItem 'hljsStyle'
  if localHljsStyle?
    $("> option[value=\"#{localHljsStyle}\"]", $hljsStyle).prop 'selected', 'selected'

  $editorCode.on 'paste', scheduleCleanupPaste

  hash = window.location.hash.replace /^#/, ''
  tryLoading hash
