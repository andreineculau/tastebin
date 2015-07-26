$ () ->
  currentContent = ''
  $window = $ window
  $body = $ window.document.body
  $style = $ '#style'
  $selectedStyle = $ '#selectedStyle'
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

  startEditing = (evt) ->
    evt.preventDefault()
    window.getSelection()?.removeAllRanges()
    edit currentContent
    $body.off 'dblclick', startEditing
    false

  maybeCancelEditing = (evt) ->
    return true  unless evt.which is 27
    evt.preventDefault()
    hash = window.location.hash.replace /^#/, ''
    tryLoading hash
    false

  cleanupPaste = () ->
    # erase any style
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
    $editorCode.html(content).attr('contentEditable', 'true').focus()
    $editorCode.on 'blur', keepFocus
    $editor.addClass('editing')
    $body.off 'keydown', disableSave
    $body.on 'keydown', maybeSave

  lock = (content, lines = []) ->
    content ?= getDomContent()
    if Array.isArray lines
      if lines.length is 0
        linenosCount = content.split('\n').length
        lines = [1..linenosCount]
    else
      lines = lines.split ''
    $linenosCode.html lines.join '<br>'
    $editorCode.html(content).attr 'contentEditable', 'false'
    $editorCode.off 'blur', keepFocus
    $editor.removeClass('editing')
    $body.on 'dblclick', startEditing
    $body.on 'keydown', maybeCancelEditing
    $body.on 'keydown', disableSave
    $body.off 'keydown', maybeSave

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
      url: 'tastes'
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
    $body.off 'dblclick', startEditing
    $body.off 'keydown', maybeCancelEditing
    $.ajax({
      url: "tastes/#{filename}"
    }).done(done).fail(fail)

  window.onpopstate = (evt) ->
    hash = evt.target.location.hash.replace /^#/, ''
    tryLoading hash

  $style.on 'change', (evt) ->
    style = this.value
    href = $selectedStyle.attr 'href'
    href = href.split('/').slice(0, -1).concat(["#{style}.css"]).join '/'
    $selectedStyle.attr 'href', href
    window.localStorage.setItem 'style', style

  localStyle = window.localStorage.getItem 'style'
  if localStyle?
    $("> option[value=\"#{localStyle}\"]", $style).prop('selected', 'selected').change()

  $editorCode.on 'paste', scheduleCleanupPaste

  hash = window.location.hash.replace /^#/, ''
  tryLoading hash
