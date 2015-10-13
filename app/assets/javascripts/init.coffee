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
