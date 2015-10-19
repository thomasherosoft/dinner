store = []
activeFilter = 'michelin'
activeSearch = null
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
          unless status
            queue.push item
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
  args.search = activeSearch if !args.search && args.search != ''
  App.x
    .get
      data: args
      url: location.toString()
    .then (response) ->
      activeFilter = args.filter
      activeSearch = args.search
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
          item.miles && item.miles <= 2
        else
          item.miles


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

    header = if items.length == 0 && queue.length
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
            item.key = item.id
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
    clear: (e) ->
      if activeSearch
        activeSearch = ''
        e.target.parentNode.parentNode
          .querySelector('input').value = ''
        load search: ''

    search: (v) ->
      unless activeSearch == v
        debouncedLoad search: v

  view: (ctrl) ->
    m '.input-group', [
      m '.input-group-addon', [ m 'i.fa.fa-search' ]
      m 'input.form-control',
        onkeyup: m.withAttr('value', ctrl.search)
        placeholder: 'Search Restaurant Name or Cuisine'
      m '.input-group-addon',
        className: (if activeSearch then '' else 'transparent')
        onclick: ctrl.clear
        [ m 'i.fa.fa-times' ]
    ]


top.initApp = ->
  App.initMap().then ->
    load().then ->
      m.mount document.querySelector('.map-side-bar'), app
      m.mount document.querySelector('#search-form'), search
