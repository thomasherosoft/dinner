#= require mithril
#= require isMobile
#= require pubsub
#= require init
#= require map
#= require_tree ./components
#= require_tree ./helpers

app =
  view: ->
    unless m.route() == '/'
      if App.selectedRestaurant
        info = App.infoDOM()
      else
        m.route '/'

    [
      m '.upper-title', className: (if m.route() == '/' then '' else 'hidden'), 'Find new and exciting places to eat in less than 3 minutes'
      m.component App.c.search
      m.component App.c.restaurants

      m '#mobile-info',
        className: (if m.route() == '/' then 'hidden' else '')
        config: hideFooter
        info
    ]


hideFooter = ->
  if m.route() == '/'
    document.querySelector('header > .back').classList.add 'hidden'
    document.querySelector('aside > footer').className = ''
  else
    document.querySelector('header > .back').classList.remove 'hidden'
    document.querySelector('aside > footer').className = 'hidden'
    document.querySelector('main').scrollTop = 0


m.route.mode = 'hash'
m.route document.querySelector('main'), '/',
  '/': app
  '/i': app
