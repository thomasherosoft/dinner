store = []
activeFilter = 'michelin'
activeSearchName = activeSearchLocation = null
activeLuck = false
selectedRestaurantID = null




load = (args={}) ->
  args.filter ||= activeFilter
  args.search_name = activeSearchName if !args.search_name && args.search_name != ''
  args.search_location = activeSearchLocation if !args.search_location && args.search_location != ''
  App.x
    .get
      data: args
      url: location.pathname
    .then (response) ->
      activeFilter = args.filter
      activeSearchName = args.search_name
      activeSearchLocation = args.search_location
      activeLuck = args.luck
      if args.page
        store = store.concat response.slice()
      else
        store = response.slice()
        queue = [] if args.search
        if store.length
          setTimeout ->
            App.centerMap
              lat: store[0].latitude
              lng: store[0].longitude
      store.forEach (x) -> sync(x)
