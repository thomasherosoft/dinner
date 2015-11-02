App.c.restaurant =
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
        pubsub.publish 'show-info', data: item, bind: marker, permanent: permanent
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
      App.s.selectedRestaurantID = item.id
      showInfo('center', true)
    onunload: ->
      marker.setMap(null)
    fallbackImageUrl: (e) ->
      e.target.src = '/assets/item-1.jpg'

    price_range: ->
      (item.price_range_currency for i in [1..item.price_range]).join('')


  viewHandler: (item, marker, el, init, ctx) ->
    unless init
      marker.addListener 'click', ->
        document.body.scrollTop = el.offsetTop - document.body.clientHeight/2 + el.clientHeight/2
        m.startComputation()
        App.s.selectedRestaurantID = item.id
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

    topRated =
      if item.rating >= 82 && ((item.reviews || []).length + item.reviews_count) >= 30
        m '.top-rated', [
          ' Top Rated '
          m '.tooltip', [
            m 'sup', [m 'i.fa.fa-asterisk', style: 'font-size: 12px']
            m '.tooltip-text', 'Restaurants that have 82%+ rating and >30 reviews are top rated'
          ]
        ]
      else
        null

    newlyOpened =
      if item.newly_opened
        m '.newly-opened', 'Newly Opened'
      else
        null

    m 'figure.restaurant',
      className: (if item.id == App.s.selectedRestaurantID then 'selected' else '')
      config: App.c.restaurant.viewHandler.bind(null, item, ctrl.marker)
      [
        m 'a', href: 'javascript:;', onclick: ctrl.showInfo, [
          m 'figcaption', [
            m 'img.item-image', src: (item.photo || '/assets/item-1.jpg'), onerror: App.imageFallback
            m '.item-rating', (if item.rating > 1 then "#{Math.floor item.rating}%" else 'N/A')
            topRated
            newlyOpened
          ]
          m 'strong', item.name
          m 'span', item.address
          m 'span', [
            item.neighborhood
            item.cuisines.join(', ')
            ctrl.price_range()
            (if item.michelin_status == 'yes' then '' else item.michelin_status)
          ].filter((x) -> x ).join(' - ')
          uber
        ]
      ]
