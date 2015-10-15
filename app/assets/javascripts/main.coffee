infoHTML = (data) ->
  img = if data.photo then "<img src='#{data.photo}' style='margin:5px 5px 0 0;max-height:70px'>" else ''
  html = "<table><tr><td style='vertical-align:top'>#{img}</td><td>"
  html += data.name + '<br>'
  html += data.address + '<br>'
  html += data.phone + '<br>' if data.phone
  html += "<img src='/assets/uber.jpg' style='max-height:13px'> £#{data.cost}" if data.cost
  html + '</td></tr></table>'


queue = []

drain = ->
  item = queue.shift()
  if item
    App
      .uberCost lat: item.latitude, lng: item.longitude
      .then (x) ->
        m.startComputation()
        item.cost = x
        console.debug 'uber', item.name, x
        m.endComputation()
        setTimeout drain, 50
  else
    setTimeout drain, 200
drain()


sync = (data) -> queue.push data


restaurant =
  controller: (item) ->
    console.debug 'init restaurant'

    sync(item)

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
            m 'img.item-image', src: (item.photo || '/assets/item-1.jpg'), onerror: ctrl.fallbackImageUrl
            m 'span.item-rating', style: {color: 'white'}, (if item.rating > 1 then "#{Math.floor item.rating}%" else 'N/A')
          ]
          m 'strong', item.name
          m 'span', item.address
          m 'span', [
            item.neighborhood
            item.cuisines.join(', ')
            ctrl.price_range()
            item.michelin_status
          ].join(' - ')
          uber
        ]
      ]
    ]


store = []

filters =
  controller: ->
    active: (name) ->
      m.route.parseQueryString(location.search).filter == name

    url: (name) ->
      args = m.route.parseQueryString(location.search)
      args.filter = name
      delete args[""]
      delete args.page
      "/?#{m.route.buildQueryString(args)}"


  view: (ctrl) ->
    m '.search-filter', [
      m 'form', [
        m 'h3', 'Explore Your City'
        m 'ul.filters-icons', [
          m 'li', className: (if ctrl.active('zagat') then 'active' else ''), [
            m 'a', href: ctrl.url('zagat'), 'Zagat'
          ]
          m 'li', className: (if ctrl.active('michelin') then 'active' else ''), [
            m 'a', href: ctrl.url('michelin'), 'Michelin'
          ]
          m 'li', className: (if ctrl.active('timeout') then 'active' else ''), [
            m 'a', href: ctrl.url('timeout'), 'TimeOut'
          ]
          m 'li', className: (if ctrl.active('foodtrack') then 'active' else ''), [
            m 'a', href: ctrl.url('foodtrack'), 'F.Truck'
          ]
          m 'li', className: (if ctrl.active('faisal') then 'active' else ''), [
            m 'a', href: ctrl.url('faisal'), 'Faisal'
          ]
        ]
      ]
    ]


app =
  controller: ->
    data = []
    App.x
      .get(url: location.toString())
      .then (response) -> data = response

    loadMore: ->
      page = if data.length then data[data.length-1].page else 0
      page += 1
      App.x
        .get
          data: App.x.extend(m.route.parseQueryString(location.search), page: page)
          url: location.pathname
        .then (response) -> data = data.concat(response)
    items: -> data


  view: (ctrl) ->
    items = ctrl.items()
    hasMore = items.length && items[items.length-1].page < items[items.length-1].pages

    [
      m.component filters

      m '.search-result', [
        m '.more-filter', [
          m 'span', "#{ctrl.items().length} Restaurants · London"
          m 'br'
          m 'hr'
        ]

        m '.row', [
          ctrl.items().map (item) ->
            item.key = item.id
            m.component restaurant, item
        ]
      ]

      m '.text-center', className: (if hasMore then '' else 'hidden'), [
        m 'a', href: 'javascript:;', onclick: ctrl.loadMore, 'Show more...'
      ]
    ]


top.initApp = ->
  App.initMap()
  m.mount document.querySelector('.map-side-bar'), app
