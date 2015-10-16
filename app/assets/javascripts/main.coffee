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
activeFilter = 'michelin'
activeSearch = null

load = (args={}) ->
  args.filter && activeFilter = args.filter
  activeSearch = args.search if args.search != null
  App.x
    .get
      data:
        filter: activeFilter
        search: activeSearch
        page: args.page
      url: location.toString()
    .then (response) ->
      if args.page
        store = store.concat(response)
      else
        store = response
        if store.length
          App.centerMap
            lat: store[0].latitude
            lng: store[0].longitude


filterNames =
  michelin: 'Michelin'
  zagat: 'Zagat'
  timeout: 'TimeOut'
  foodtruck: 'F.Truck'
  faisal: 'Faisal'

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


  view: (ctrl) ->
    hasMore = store.length && store[store.length-1].page < store[store.length-1].pages
    total = store[0]?.totals
    total && total = " of #{total}"

    if activeSearch
      head = "results matching \"#{activeSearch}\""
    else
      head = "#{filterNames[activeFilter]} restaurants"

    [
      m.component filters

      m '.search-result', [
        m '.more-filter', [
          m 'span', "Showing #{store.length}#{total} #{head} in London"
          m 'br'
          m 'hr'
        ]

        m '.row', [
          store.map (item) ->
            item.key = item.id
            m.component restaurant, item
        ]
      ]

      m '.text-center', className: (if hasMore then '' else 'hidden'), [
        m 'a', href: 'javascript:;', onclick: ctrl.loadMore, 'Show more...'
      ]
    ]


search =
  controller: ->
    search: (v) ->
      load search: v

  view: (ctrl) ->
    m 'input.form-control',
      onkeyup: m.withAttr('value', ctrl.search)
      placeholder: 'Search Restaurant Name'
      value: (activeSearch || '')


top.initApp = ->
  App.initMap()

  load().then ->
    m.mount document.querySelector('.map-side-bar'), app
    m.mount document.querySelector('#search-form'), search
