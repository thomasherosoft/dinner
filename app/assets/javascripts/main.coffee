infoHTML = (data) ->
  img = if data.photo then "<img onerror='this.parentNode.removeChild(this)' src='#{data.photo}' style='margin:5px 5px 0 0;max-height:70px'>" else ''
  html = "<table><tr><td style='vertical-align:top'>#{img}</td><td>"
  html += data.name + '<br>'
  html += data.address + '<br>'
  html += data.phone + '<br>' if data.phone
  html += "<img src='/assets/uber.jpg' style='max-height:13px'> £#{data.cost}" if data.cost
  html + '</td></tr></table>'


queue = []

drain = ->
  item = queue.shift()
  if item && !item.miles
    App
      .distance lat: item.latitude, lng: item.longitude
      .then (miles) ->
        m.startComputation()
        item.miles = miles
        if miles && miles <= 50
          time = miles / 9 * 60
          item.cost = Math.round(2.5 + 1.25*miles + 0.25*time)
          item.cost = 5 if item.cost < 5
        m.endComputation()
        setTimeout drain, 50
  else
    setTimeout drain, 200
drain()

sync = (data) -> queue.push data


restaurant =
  controller: (item) ->
    console.debug 'init restaurant'

    marker = App.newMarker
      position:
        lat: item.latitude
        lng: item.longitude
      title: item.name

    showInfo = (center=false) ->
      if center
        App.centerMap lat: item.latitude, lng: item.longitude
      App.showInfo infoHTML(item), marker

    marker.addListener 'mouseout', -> App.closeInfo()
    marker.addListener 'mouseover', -> showInfo()
    marker.addListener 'click', -> showInfo()

    showInfo: ->
      m.redraw.strategy('none')
      showInfo('center')
    onunload: -> marker.setMap(null)
    fallbackImageUrl: (e) ->
      e.target.src = '/assets/item-1.jpg'

    price_range: ->
      (item.price_range_currency for i in [1..item.price_range]).join('')


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

    m '.col-md-12.item-widget', [
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
          ].join(' - ')
          uber
        ]
      ]
    ]


top.store = []
activeFilter = 'michelin'
activeSearch = null

load = (args={}) ->
  args.filter ||= activeFilter
  args.search = activeSearch if !args.search && args.search != ''
  App.x
    .get
      data: args
      url: location.toString()
    .then (response) ->
      activeFilter = args.filter
      activeSearch = args.search
      if args.page
        top.store = store.concat response.slice()
      else
        top.store = response.slice()
        if store.length
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
    loadMore: ->
      page = if store.length then store[store.length-1].page else 0
      page += 1
      load page: page

    filtered: ->
      if activeFilter == 'deliveroo'
        store.filter (item) ->
          item.miles && item.miles <= 2
      else
        store


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
      head = if activeSearch
               if items[0]?.found_by
                 "#{items[0].found_by} restaurants"
               else
                 "results matching \"#{activeSearch}\""
             else
               "#{filterNames[activeFilter]} restaurants"
      head += ' in London'

    [
      m.component filters

      m '.search-result', config: mapAdjusts, [
        m '.more-filter', [
          m 'span', "Showing #{items.length}#{total} #{head}"
          m 'br'
          m 'hr'
        ]

        m '.row', [
          items.map (item) ->
            item.key = item.id
            m.component restaurant, item
        ]
      ]

      m '.text-center.has-show-more', className: (if hasMore then '' else 'hidden'), [
        m 'a.show-more', href: 'javascript:;', onclick: ctrl.loadMore, 'Show more...'
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
    search: (v) ->
      debouncedLoad search: v

  view: (ctrl) ->
    m 'input.form-control',
      onkeyup: m.withAttr('value', ctrl.search)
      placeholder: 'Search Restaurant Name or Cuisine'


top.initApp = ->
  App.initMap()

  load().then ->
    m.mount document.querySelector('.map-side-bar'), app
    m.mount document.querySelector('#search-form'), search
