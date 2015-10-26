queue = []

drain = ->
  item = queue.shift()
  if item
    if item.miles
      drain()
    else
      App
        .distance lat: item.latitude, lng: item.longitude
        .then (miles) ->
          m.startComputation()
          item.miles = miles
          if miles && miles <= 50
            time = miles / 9 * 60
            item.cost = Math.round(2.5 + 1.25*miles + 0.25*time)
            App.adjustUberCircle(item.cost <= 12, lat: item.latitude, lng: item.longitude)
            item.cost = 5 if item.cost < 5
          m.endComputation()
          setTimeout drain, 50
        , (status) ->
          queue.push item unless status
          m.redraw() unless queue.length
          setTimeout drain, 100
  else
    setTimeout drain, 100
drain()

pubsub.subscribe 'reset-distance-queue', ->
  queue = []

pubsub.subscribe 'calculate-distance', (x, reset=true) ->
  queue = [] if reset
  if Array.isArray(x)
    x.forEach (i) -> queue.push i
  else
    queue.push x
