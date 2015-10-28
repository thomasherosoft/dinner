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
        # TODO move to web worker
        setTimeout -> pubsub.publish('calculate-distance', store)
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
             "About #{round_to_nth(store[0].totals, 10) || 0} restaurants"
           else
             ''
    moreButton = if store.length && store[store.length-1].page < store[store.length-1].pages
      m '.show-more-wrapper', [
        m 'a.show-more',
          href: 'javascript:;'
          onclick: ctrl.loadMore
          (if loading then 'Loading more... ' else 'Show more...')
          [ m 'i.fa.fa-spin.fa-spinner', className: (if loading then '' else 'hidden') ]
      ]
    else
      null

    [
      m 'h3', config: mapAdjusts, head
      m.component App.c.filters
      store.map (s) ->
        s.key = s.name + s.address
        m.component App.c.restaurant, s
      moreButton
    ]

round_to_nth = (number, nth) ->
  if number % nth >= (nth/2) then parseInt(number / nth) * nth + nth else parseInt(number / nth) * nth

mapAdjusts = (el, init, ctx) ->
  if ctx.lastItemCount != store.length
    ctx.lastItemCount = store.length
    coords = store.map (x) ->
      new google.maps.LatLng x.latitude, x.longitude
    App.fitMapTo coords if coords.length
