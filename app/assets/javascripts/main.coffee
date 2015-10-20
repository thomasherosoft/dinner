store = []
activeFilter = 'michelin'
activeSearchName = activeSearchLocation = null
selectedRestaurantID = null


infoHTML = (data) ->
  img = if data.photo then "<img onerror='this.parentNode.removeChild(this)' src='#{data.photo}' style='margin:5px 5px 0 0;max-height:70px'>" else ''
  html = "<table><tr><td style='vertical-align:top'>#{img}</td><td>"
  html += data.name + '<br>'
  html += data.address + '<br>'
  html += "<a href= 'tel:"+ data.phone + "'>" + data.phone + "</a>" + '<br>' if data.phone
  html += "<img src='/assets/uber.jpg' style='max-height:13px'> £#{data.cost}" + '<br>' if data.cost
  if data.michelin_status && data.michelin_status != 'yes'
    html += data.michelin_status + '<br>'
  html += data.rating + '% rated' if data.rating
  html + '</td></tr></table>'


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
      if center
        App.centerMap lat: item.latitude, lng: item.longitude
      App.showInfo infoHTML(item), marker, permanent

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
      url: location.toString()
    .then (response) ->
      activeFilter = args.filter
      activeSearchName = args.search_name
      activeSearchLocation = args.search_location
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

  view: (ctrl) ->
    m '.search-filter', [
      m 'form', [
        m 'h3', 'Explore Your City'
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
      hasMore = items.length >= 20
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
                 "results matching \"#{activeSearchName || activeSearchLocation}\""
             else
               "#{filterNames[activeFilter]} restaurants"
      head += ' in London'

    header = if items.length == 0 && queue.length > 0
               'Calculating results...'
             else
               "Showing #{items.length}#{total} #{head}"

    [
      m.component filters

      m '.search-result', config: mapAdjusts, [
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


mapAdjusts = (el, init, ctx) ->
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


debouncedLoad = App.x.debounce 100, load

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
      name = ''
      perform()

    clear_location: (e) ->
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

    useMyPosition: ->
      if App.myPosition
        App.centerMap App.myPosition
        location = 'My Location'
        perform()


  view: (ctrl) ->
    m 'form.form-inline', onsubmit: ((e) -> e.preventDefault()), [
      m '.search-group', [
        m 'i.fa.fa-search'
        m 'input.form-control',
          onkeyup: m.withAttr('value', ctrl.search_name)
          placeholder: 'Search Restaurant Name or Cuisine'
          value: ctrl.search_name()
        m 'i.fa.fa-times',
          className: (if ctrl.search_name() then '' else 'transparent')
          onclick: ctrl.clear_name
      ]

      m '.search-group', [
        m 'i.fa.fa-location-arrow.location', onclick: ctrl.useMyPosition
        m 'input.form-control.location',
          onkeyup: m.withAttr('value', ctrl.search_location)
          placeholder: 'Location'
          value: ctrl.search_location()
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
