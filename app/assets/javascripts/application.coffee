#= require mithril
#= require pubsub
#= require init
#= require map
#= require_tree ./components
#= require_tree ./helpers

'search filters restaurants'.split(/\s+/).forEach (c) ->
  m.mount document.getElementById(c), App.c[c]
