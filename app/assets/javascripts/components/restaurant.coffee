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
