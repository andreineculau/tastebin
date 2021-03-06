$ () ->
  contentSrc = ''
  $window = $ window
  $body = $ window.document.body
  $theme = $ '#theme'
  $hljsStyle = $ '#hljsStyle'
  $selectedHljsStyle = $ '#selectedHljsStyle'
  $linenosWrapper = $ '#linenosWrapper'
  $linenos = $ '#linenos', $linenosWrapper
  $editorWrapper = $ '#editorWrapper'
  $editor = $ '#editor', $editorWrapper
  $list = $ '#list'
  $rawLink = $ '#rawLink'

  metaKeyName = 'Ctrl'
  metaKeyName = 'Cmd'  if /^Mac/.test navigator.platform
  newTaste = $('#newTaste').html().replace /#{metaKeyName}/g, metaKeyName

  getDomContent = () ->
    $editor[0].innerText

  setContent = (content) ->
    if 'innerText' of $editor[0]
      contentSrc = $editor[0].innerText = content
    else
      content = content.replace
      contentSrc = $editor[0].innerHTML = he.encode content

  wantsToEdit = (evt) ->
    return false  if evt.altKey
    metaKey = evt.ctrlKey
    metaKey = evt.metaKey  if /^Mac/.test navigator.platform
    return false  unless metaKey
    char = String.fromCharCode(evt.which).toLowerCase()
    return false  unless char is 'e'
    true

  maybeStartEditing = (evt) ->
    return true  unless wantsToEdit evt
    evt.preventDefault()
    edit contentSrc
    false

  maybeCancelEditing = (evt) ->
    return true  unless evt.which is 27
    evt.preventDefault()
    hash = window.location.hash.replace /^#/, ''
    tryLoading hash
    false

  cleanupPaste = () ->
    # erase any styling
    setContent getDomContent()

  scheduleCleanupPaste = (evt) ->
    setTimeout cleanupPaste, 100

  keepFocus = (evt) ->
    $editor.focus()

  wantsToSave = (evt) ->
    return false  if evt.altKey
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

    contentSrc = getDomContent().trim().replace(/[ \t\r]+\n/g, '\n')
    contentSrc += '\n'  if contentSrc.length
    setContent contentSrc  if contentSrc isnt getDomContent()
    return true  unless contentSrc.length

    always = () ->
      edit()

    done = (body, status, xhr) ->
      $body.addClass 'loaded'
      if method is 'POST'
        filename = xhr.getResponseHeader 'Location'
      window.location.hash = filename
      $rawLink.html filename
      $rawLink.on 'click', () ->
        window.prompt '', window.location.href.replace(/#.*/, '') + "tastes/#{filename}"

    fail = () ->
      $linenos.html "Failed to save".replace /(.)/g, '$1<br>'
      edit()

    lock null, 'Saving...'
    $body.removeClass 'loaded'
    $.ajax({
      method
      url
      contentType: 'application/octet-stream'
      data: contentSrc
    }).always(always).done(done).fail(fail)
    false

  edit = (content = contentSrc) ->
    $editor.html content
    $editor.attr('contentEditable', 'true').focus()
    $body.addClass 'editing'
    $editor.on 'blur', keepFocus
    $body.off 'keydown', maybeStartEditing
    $body.off 'keydown', disableSave
    $body.on 'keydown', maybeSave
    $body.on 'keydown', maybeCancelEditing

  lock = (content = contentSrc, lines = [], language) ->
    if Array.isArray lines
      if lines.length is 0
        linenosCount = content.split('\n').length
        lines = [1..linenosCount]
    else
      lines = lines.split ''
    $linenos.html lines.join '<br>'
    $editor.html content

    $editor.attr 'contentEditable', 'false'
    $body.removeClass 'editing'
    $editor.off 'blur', keepFocus
    $body.on 'keydown', maybeStartEditing
    $body.on 'keydown', disableSave
    $body.off 'keydown', maybeSave
    $body.off 'keydown', maybeCancelEditing

  list = () ->
    setContent ''
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
      $list.html filesHtml

    fail = () ->

    $body.removeClass 'loaded'
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

    $list.html ''
    if filename.indexOf('.') > 0
      [filename..., language] = filename.split '.'
      filename = filename.join '.'

    done = (body, status, xhr) ->
      $body.addClass 'loaded'
      $rawLink.html filename
      $rawLink.on 'click', () ->
        window.prompt '', window.location.href.replace(/#.*/, '') + "tastes/#{filename}"
      if language?
        try
          high = hljs.highlight language, body
        catch e
          high = {value: body}
      else
        high = hljs.highlightAuto body
        if high.language?
          history.replaceState undefined, undefined, "\##{filename}.#{high.language}"
      lock high.value

    fail = () ->
      setContent ''
      lock null, 'Failed to load...'

    lock '', 'Loading...'
    $body.off 'keydown', maybeStartEditing
    $body.removeClass 'loaded'
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

  $editor.on 'paste', scheduleCleanupPaste

  hash = window.location.hash.replace /^#/, ''
  tryLoading hash
