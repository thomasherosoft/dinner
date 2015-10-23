top.App =
  x:
    extend: ->
      h = {}
      [].slice.call(arguments).forEach (x) -> Object.keys(x).forEach (k) -> h[k] = x[k]
      h
    del: (args) -> m.request App.x.extend config: csrf, method: 'DELETE', args
    get: (args) -> m.request App.x.extend config: xhr, method: 'GET', args
    post: (args) -> m.request App.x.extend config: csrf, method: 'POST', args
    put: (args) -> m.request App.x.extend config: csrf, method: 'PUT', args

csrf = (x) ->
  x.setRequestHeader 'X-CSRF-Token', document.querySelector('meta[name="csrf-token"]').content
  x.setRequestHeader 'X-Requested-For', location.pathname

xhr = (x) ->
  x.setRequestHeader 'X-Requested-With', 'XMLHttpRequest'
  x.setRequestHeader 'X-Requested-For', location.pathname

App.x.debounce = (wait, fn, immediate=false) ->
  timeout = args = context = timestamp = result = null

  later = ->
    last = Date.now() - timestamp
    if last < wait && last >= 0
      timeout = setTimeout later, wait - last
    else
      timeout = null
      unless immediate
        result = fn.apply context, args
        context = args = null unless timeout

  ->
    context = this
    args = arguments
    timestamp = Date.now()
    callNow = immediate && !timeout
    timeout = setTimeout(later, wait) unless timeout
    if callNow
      result = fn.apply(context, args)
      context = args = null
    result


App.imageFallback = (e) ->
  e.target.src = '/assets/item-1.jpg'
