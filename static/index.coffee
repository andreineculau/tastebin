$ () ->
  data = ''
  $linenos = $ '#linenos'
  $linenosCode = $ '> code', $linenos
  $editor = $ '#editor'
  $editorCode = $ '> code', $editor
  $style = $ '#style'
  $selectedStyle = $ '#selectedStyle'

  metaKeyName = 'Ctrl'
  metaKeyName = 'Cmd'  if /^Mac/.test navigator.platform

  startEditing = () ->
    edit data
    $editor.off 'dblclick', startEditing

  maybeSave = (evt) ->
    metaKey = evt.ctrlKey
    metaKey = evt.metaKey  if /^Mac/.test navigator.platform
    return true  unless metaKey
    char = String.fromCharCode(evt.which).toLowerCase()
    return true  unless char is 's'
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

    data = $editorCode[0].innerText.trim().replace(/\s+\n/g, '\n')
    data += '\n'  if data.length
    unless data.length
      if data isnt $editorCode[0].innerText
        $editorCode[0].innerText = data
      return true

    always = () ->
      edit()

    done = (responseData, status, xhr) ->
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
      data
    }).always(always).done(done).fail(fail)
    return false

  edit = (content = $editorCode[0].innerText) ->
    $linenosCode.html "#{metaKeyName}+s to Save - Shift+#{metaKeyName}+s to Save As...".replace /(.)/g, '$1<br>'
    $editorCode.html(content).attr('contentEditable', 'true').focus()
    $editor.addClass('editing')
    $(window).on 'keydown', maybeSave

  lock = (content = $editorCode[0].innerText, lines = []) ->
    if Array.isArray lines
      if lines.length is 0
        linenosCount = content.split('\n').length
        lines = [1..linenosCount]
    else
      lines = lines.split ''
    $linenosCode.html lines.join '<br>'
    $editorCode.html(content).attr 'contentEditable', 'false'
    $editor.removeClass('editing')
    $editor.on 'dblclick', startEditing
    $(window).off 'keydown', maybeSave

  tryLoading = (hash) ->
    filename = hash.replace /[^A-Za-z\.]/, ''
    if filename isnt hash
      window.location.hash = "#{filename}"
      return

    unless filename
      lock 'New taste...\nDouble click to start editing'
      return

    [filename, language] = filename.split '.'

    done = (data) ->
      if language?
        try
          high = hljs.highlight language, data
        catch e
          high = {value: data}
      else
        high = hljs.highlightAuto data
        if high.language?
          window.location.hash = "#{filename}.#{high.language}"
          return

      lock high.value

    fail = () ->
      # window.location.hash = ''
      lock '', 'Failed to load...'

    lock '', 'Loading...'
    $editor.off 'dblclick', startEditing
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

  hash = window.location.hash.replace /^#/, ''
  tryLoading hash
