store = []
loading = false

pubsub.subscribe 'search', (args) ->
  query = App.x.extend App.s, (args || {})

  m.startComputation()
  loading = true
  m.endComputation()

  App.x
    .get
      background: true
      data: query
      url: '/restaurants'
    .then (response) ->
      loading = false
      if query.page
        store = store.concat response.slice()
      else
        store = response.slice()
        setTimeout -> pubsub.publish('adjust-filters', store)
        if store.length
          setTimeout ->
            App.centerMap
              lat: store[0].latitude
              lng: store[0].longitude
      m.redraw()


App.c.restaurants =
  controller: ->
    loadMore: ->
      loading = true
      pubsub.publish 'search', page: store[store.length-1].page+1

  view: (ctrl) ->
    head =
      if loading
         'Calculating...'
      else if store.length
         "About #{round_to_nth(store[0].totals,  Math.pow(10, count_num_size(store[0].totals))  ) || store[0].totals} restaurants"
      else
         ''
    moreButton = if store.length && store[store.length-1].page < store[store.length-1].pages
      m 'a.show-more',
        href: 'javascript:;'
        onclick: ctrl.loadMore
        (if loading then 'Loading more... ' else 'Show more...')
        [ m 'i.fa.fa-spin.fa-spinner', className: (if loading then '' else 'hidden') ]
    else
      m '.hidden'

    notFound =
      if store.length == 0 && App.s.query
        m '.not-found', 'No results found'
      else
        m '.hidden'

    m '#restaurants', className: (if m.route() == '/' then '' else 'hidden'), [
      m 'h3', config: mapAdjusts, head
      m 'h4', (if App.s.query && !App.s.type then App.s.query.toUpperCase() else '')

      m.component App.c.filters

      m 'div', [
        m 'h4.results-header', className: (if store.length then '' else 'hidden'), 'Recommended'
        store.filter((_, i) -> i < 5).map (s) ->
          s.key = s.id + s.name
          m.component App.c.restaurant, s
      ]

      m 'div', [
        m 'h4.results-header', className: (if store.length > 5 then '' else 'hidden'), 'More'
        store.filter((_, i) -> i > 4).map (s) ->
          s.key = s.id + s.name
          m.component App.c.restaurant, s
      ]

      notFound
      moreButton
    ]


round_to_nth = (number, nth) ->
  if number % nth >= (nth/2) then parseInt(number / nth) * nth + nth else parseInt(number / nth) * nth

count_num_size = (num) ->
  size = 1
  while num > 1000
    num = num/1000
    size += 1
  size

mapAdjusts = (el, init, ctx) ->
  if ctx.lastItemCount != store.length
    ctx.lastItemCount = store.length
    coords = store.map (x) ->
      new google.maps.LatLng x.latitude, x.longitude
    App.fitMapTo coords if coords.length
    store.forEach (x) ->
      App.adjustUberCircle(x.cost <= 12, lat: x.latitude, lng: x.longitude)
