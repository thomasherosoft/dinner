top.jsCookies =
  get: (name)->
    if document.cookie.length > 0
      start = document.cookie.indexOf(name + '=')
      if start != -1
        start = start + name.length + 1
        end = document.cookie.indexOf(';', start)
        if (end == -1)
          c_end = document.cookie.length
        unescape document.cookie.substring(start, c_end)
    else
      ''

  set: (name, value) ->
    document.cookie = name + '=' + escape(value) + '; path=/; expires=Tue Nov 02 2038 14:47:20 GMT'
