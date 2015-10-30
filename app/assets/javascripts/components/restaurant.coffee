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
        App.s.selectedRestaurantID = item.id
        m.endComputation()


  view: (ctrl, item)->
    u_cost = if item.cost then item.cost else "N/A"
    uber =  [
              m 'span', [
                m 'img', src: '/assets/uber.jpg', style: {maxHeight: '13px'}
                " £#{u_cost}"
              ]
            ]
    price_range = if ctrl.price_range() then ctrl.price_range() else "N/A"

    m 'figure.restaurant',
      className: (if item.id == App.s.selectedRestaurantID then 'selected' else '')
      config: App.c.restaurant.viewHandler.bind(null, item, ctrl.marker)
      [
        m 'a', href: 'javascript:;', onclick: ctrl.showInfo, [
          m 'figcaption', [
            m 'img.item-image', src: (item.photo || '/assets/item-1.jpg'), onerror: App.imageFallback
            m '.item-rating', (if item.rating > 1 then "#{Math.floor item.rating}%" else 'N/A')
          ]
          m '.title', [
            m 'strong', item.name
          ]
          m '.divider'
        ]
        m '.info', [
          # console.log item
          # console.log ctrl
          if item.rating
            m 'span.rst_rating', [
              m 'strong', "Rating:" 
              m 'span', "#{item.rating}%"
            ]
          if item.address
            m 'span', [
              m 'strong', "Address:" 
              m 'span', item.address
            ]
          if item.neighborhood 
            m 'span', [
              m 'strong', "Neighborhood:" 
              m 'span', item.neighborhood
            ]
          if item.cuisines.join(', ') 
            m 'span', [
              m 'strong', "Cuisines:" 
              m 'span', item.cuisines.join(', ')
            ]
          m 'span', [
            m 'strong', "Price range:" 
            m 'span', price_range
          ] 
          if item.michelin_status && item.michelin_status != "yes" 
            m 'span', [
              m 'strong', "Michelin status:" 
              m 'span', item.michelin_status
            ]
          uber
          # m 'span', [
          #   item.neighborhood
          #   item.cuisines.join(', ')
          #   ctrl.price_range()
          #   (if item.michelin_status == 'yes' then '' else item.michelin_status)
          # ].filter((x) -> x ).join(' - ')
        ]
      ]
