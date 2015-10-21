store = []
activeFilter = 'michelin'
activeSearchName = activeSearchLocation = null
activeLuck = false
selectedRestaurantID = null


ratingDOM = (percents) ->
  out = []
  for i in [1..Math.floor(percents/20)]
    out.push m 'i.fa.fa-star'
  out.push m 'i.fa.fa-star-half-o' if percents % 20
  if out.length < 5
    for i in [1..(5-out.length)]
      out.push m 'i.fa.fa-star-o'
  out


zp = (v) ->
  if v < 10 then "0#{v}" else v


unix2date = (stamp) ->
  t = new Date stamp*1000
  [
    zp(t.getDate())
    zp(t.getMonth()+1)
    t.getFullYear()
  ].join('/')


infoDOM = (data) ->
  michelin = if data.michelin_status == 'yes' then null else data.michelin_status
  if michelin
    michelin = [
      m 'dt', 'Michelin rated'
      m 'dd', michelin
    ]

  accolades = []
  accolades.push 'Zagat' if data.zagat_status
  accolades.push 'TimeOut Top100' if data.timeout_status
  if accolades.length
    accolades = [
      m 'dt', 'accolades'
      m 'dd.accolades', accolades.join(', ')
    ]

  if data.cost
    uberCost = [
      m 'dt', 'uber cost'
      m 'dd', [
        m 'img', src: '/assets/uber.jpg', style: {maxHeight: '16px'}
        " £#{data.cost}"
      ]
    ]

  reviews = (data.reviews || []).slice(0, 2)
  [
    m '.header', style: {backgroundImage: "url(#{data.photo})"}, [
      m '.name', data.name
      m '.info', [
        "#{(data.miles || 0).toFixed(1)} miles"
        " - #{(data.reviews || []).length} reviews"
      ]
      m '.rating', ratingDOM(data.rating)
      " #{data.rating}%"
    ]

    m 'dl.dl-horizontal', [
      m 'dt', 'phone'
      m 'dd', [
        m 'a', href: "tel:#{data.phone}", data.phone
      ]
      m 'dt', 'address'
      m 'dd', m.trust(data.address.replace(/\s*,\s*/g, '<br>'))
      m 'dt', 'cuisines'
      m 'dd', data.cuisines.join(', ')
      michelin
      accolades
      uberCost
    ]

    m '.reviews', className: (if reviews.length then '' else 'hidden'), [
      m 'h5', 'Reviews'
      reviews.map (review) ->
        t = review.text.slice(0,200)
        t += '...' if t.length < review.text.length
        m '.review', [
          m '.rating', ratingDOM(100 * review.rating / 5)
          "#{review.rating} by #{review.author_name}"
          m 'p', unix2date(review.time) + ' ' + t
        ]
    ]
  ]


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

sync = (data) -> queue.push data


restaurant =
  controller: (item) ->
    marker = App.newMarker
      position:
        lat: item.latitude
        lng: item.longitude
      title: item.name

    showInfo = (center=false, permanent=false) ->
      fn = ->
        if center
          App.centerMap lat: item.latitude, lng: item.longitude
        div = document.createElement('div')
        m.render div, infoDOM(item)
        App.showInfo div, marker, permanent
      if !item.google_place_id || item.reviews
        fn()
      else
        App.getPlace(item.google_place_id).then (x) ->
          item.reviews = x.reviews
          fn()

    marker.addListener 'mouseout', -> App.closeInfo()
    marker.addListener 'mouseover', -> showInfo()
    marker.addListener 'click', -> showInfo(false, true)

    marker: marker
    showInfo: ->
      selectedRestaurantID = item.id
      showInfo('center', true)
    onunload: -> marker.setMap(null)
    fallbackImageUrl: (e) ->
      e.target.src = '/assets/item-1.jpg'

    price_range: ->
      (item.price_range_currency for i in [1..item.price_range]).join('')


  viewHandler: (item, marker, el, init, ctx) ->
    unless init
      marker.addListener 'click', ->
        document.body.scrollTop = el.offsetTop - document.body.clientHeight/2 + el.clientHeight/2
        m.startComputation()
        selectedRestaurantID = item.id
        m.endComputation()


  view: (ctrl, item)->
    uber = if item.cost
             [
               ' - '
               m 'span', [
                 m 'img', src: '/assets/uber.jpg', style: {maxHeight: '13px'}
                 " £#{item.cost}"
               ]
             ]
           else
             null

    m '.col-md-12.item-widget',
      className: (if item.id == selectedRestaurantID then 'selected' else '')
      config: restaurant.viewHandler.bind(null, item, ctrl.marker)
      [
        m 'figcaption', [
          m 'a', href: 'javascript:;', onclick: ctrl.showInfo, [
            m 'figure', [
              m 'img.item-image', src: (item.photo || '/assets/item-1.jpg'), onerror: App.imageFallback
              m 'span.item-rating', style: {color: 'white'}, (if item.rating > 1 then "#{Math.floor item.rating}%" else 'N/A')
            ]
            m 'strong', item.name
            m 'span', item.address
            m 'span', [
              item.neighborhood
              item.cuisines.join(', ')
              ctrl.price_range()
              (if item.michelin_status == 'yes' then '' else item.michelin_status)
            ].join(' - ')
            uber
          ]
        ]
      ]


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


filterNames =
  michelin: 'Michelin'
  zagat: 'Zagat'
  timeout: 'TimeOut'
  foodtruck: 'F.Truck'
  faisal: 'Faisal'
  deliveroo: 'Deliveroo'

filters =
  controller: ->
    filter: (name) ->
      queue = []
      load filter: name

    luck: (e) ->
      spinner = e.target.children[0]
      spinner.classList.remove('hidden')
      queue = []
      load(luck: true).then ->
        spinner.classList.add('hidden')


  view: (ctrl) ->
    m '.search-filter', [
      m 'form', [
        m 'h3', 'Explore Your City', [
          m 'span',
            onclick: ctrl.luck
            style: {cursor: 'pointer', marginLeft: '2em'}
            "I'm feeling lucky"
            [ m 'i.fa.fa-spin.fa-spinner.hidden', style: {marginLeft: '.5em'} ]
        ]
        m 'ul.filters-icons', [
          Object.keys(filterNames).map (name) ->
            m 'li', className: (if activeFilter == name then 'active' else ''), [
              m 'a', href: 'javascript:;', onclick: ctrl.filter.bind(null, name), filterNames[name]
            ]
        ]
      ]
    ]


app =
  controller: ->
    loadMore: (e) ->
      e.target.classList.add 'in-progress'
      page = if store.length then store[store.length-1].page else 0
      page += 1
      load(page: page).then ->
        e.target?.classList.remove 'in-progress'

    filtered: ->
      store.filter (item) ->
        if activeFilter == 'deliveroo'
          +item.miles >= 0 && item.miles <= 2
        else if App.myPosition
          +item.miles >= 0
        else
          true


  view: (ctrl) ->
    items = ctrl.filtered()

    if activeFilter == 'deliveroo'
      hasMore = items.length >= 7
      total = ''
      head = 'Deliveroo restaurants in your delivery area'
    else
      hasMore = items.length && items[items.length-1].page < items[items.length-1].pages

      total = items[0]?.totals || 0
      total = if total then " of #{total}" else ''
      head = if activeSearchName || activeSearchLocation
               if items[0]?.found_by
                 "#{items[0].found_by} restaurants"
               else
                 loc = if activeSearchLocation && ('+'+activeSearchLocation).indexOf(''+App.myPosition?.lat) == 1
                         'in 3 mile radius near you'
                       else
                         'results'
                 subj = activeSearchName
                 subj ||= if loc then '' else activeSearchLocation
                 loc + ' ' + (if subj then "matching \"#{subj}\"" else '')
             else
               "#{filterNames[activeFilter]} restaurants"
      head += ' in London' unless activeSearchLocation

    header = if items.length == 0 && queue.length > 0
               'Calculating results...'
             else if activeLuck
               hasMore = false
               "Try your luck with these #{items.length}..."
             else
               "Showing #{items.length}#{total} #{head}"

    [
      m.component filters

      m '.search-result', config: mapAdjusts.bind(null, items), [
        m '.more-filter', [
          m 'span', header
          m 'br'
          m 'hr'
        ]

        m '.row', [
          items.map (item) ->
            item.key = [item.id, item.name, item.address].join()
            m.component restaurant, item
        ]
      ]

      m '.text-center.has-show-more', className: (if hasMore then '' else 'hidden'), [
        m 'a.show-more',
          href: 'javascript:;'
          onclick: ctrl.loadMore
          'Show more... '
          [ m 'i.fa.fa-spin.fa-spinner' ]
      ]
    ]


mapAdjusts = (items, el, initalle, ctx) ->
  if activeFilter == 'deliveroo'
    unless ctx.deliveroo
      App.showMe()
      ctx.deliveroo = App.drawCircle
        strokeColor: 'blue'
        strokeOpacity: 0.7
        strokeWeight: 3
        radius: 2*1609
        fillColor: 'blue'
        fillOpacity: 0.1
  else if ctx.deliveroo
    ctx.deliveroo.setMap(null)
    ctx.deliveroo = null

  if ctx.lastItemCount != items.length
    ctx.lastItemCount = items.length
    coords = items.map (x) ->
      new google.maps.LatLng x.latitude, x.longitude
    App.fitMapTo coords if coords.length

search =
  controller: ->
    name = location = ''

    perform = ->
      loc = if location == 'My Location' then [App.myPosition.lat, App.myPosition.lng].join(',') else location
      queue = []
      load
        search_name: name
        search_location: loc
    debounced = App.x.debounce 250, perform

    clear_name: (e) ->
      e.target.parentNode.querySelector('input').value = ''
      name = ''
      perform()

    clear_location: (e) ->
      e.target.parentNode.querySelector('input').value = ''
      location = ''
      perform()

    search_name: (val) ->
      if val || val == ''
        name = val
        debounced()
      name

    search_location: (val) ->
      if val || val == ''
        location = val
        debounced()
      location

    useMyPosition: (e) ->
      if App.myPosition
        App.centerMap App.myPosition
        e.target.parentNode.querySelector('input')
          .value = location = 'My Location'
        perform()


  view: (ctrl) ->
    m 'form.form-inline', onsubmit: ((e) -> e.preventDefault()), [
      m '.search-group', [
        m 'i.fa.fa-search'
        m 'input.form-control',
          onkeyup: m.withAttr('value', ctrl.search_name)
          placeholder: 'Search Restaurant Name or Cuisine'
        m 'i.fa.fa-times',
          className: (if ctrl.search_name() then '' else 'transparent')
          onclick: ctrl.clear_name
      ]

      m '.search-group', [
        m 'i.fa.fa-location-arrow.location', onclick: ctrl.useMyPosition
        m 'input.form-control.location',
          onkeyup: m.withAttr('value', ctrl.search_location)
          placeholder: 'Location'
        m 'i.fa.fa-times',
          className: (if ctrl.search_location() then '' else 'transparent')
          onclick: ctrl.clear_location
      ]
    ]


top.initApp = ->
  App.initMap().then ->
    load().then ->
      m.mount document.querySelector('.map-side-bar'), app
      m.mount document.querySelector('#search-form'), search
