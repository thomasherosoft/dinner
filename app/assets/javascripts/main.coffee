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
  post = queue.shift()
  if post && post.placeid
    App
      .getPlace post.placeid
      .then (data) ->
        App.x
          .put data: data, url: "/posts/#{post.id}"
          .then ->
            $.extend(post, data)
            setTimeout drain, 50
            App
              .uberCost lat: post.latitude, lng: post.longitude
              .then (x) ->
                m.startComputation()
                post.cost = x
                m.endComputation()
      , ->
        queue.push post
        console.error 'getPlace', arguments
        setTimeout drain, 100
  else
    setTimeout drain, 100
drain()


sync = (data) -> queue.push data


restaurant =
  controller: (post) ->
    console.debug 'init restaurant'

    sync(post)

    marker = App.newMarker
      position:
        lat: post.latitude
        lng: post.longitude
      title: post.name

    showInfo = (center=false) ->
      if center
        App.centerMap lat: post.latitude, lng: post.longitude
      fn = -> App.showInfo infoHTML(post), marker
      if post.cost
        fn()
      else
        App
          .uberCost lat: post.latitude, lng: post.longitude
          .then (x) ->
            m.startComputation()
            post.cost = x
            m.endComputation()
            fn()
          , fn

    marker.addListener 'mouseout', -> App.closeInfo()
    marker.addListener 'mouseover', -> showInfo()
    marker.addListener 'click', -> showInfo()

    showInfo: ->
      m.redraw.strategy('none')
      showInfo('center')
    onunload: -> marker.setMap(null)
    fallbackImageUrl: (e) ->
      e.target.src = '/assets/item-1.jpg'


  view: (ctrl, post)->
    imageUrl = if post.image_present
                 "/post_images/#{post.id}.jpg"
               else
                 '/assets/item-1.jpg'
    uber = if post.cost
             [
               ' - '
               m 'span', [
                 m 'img', src: '/assets/uber.jpg', style: {maxHeight: '13px'}
                 " £#{post.cost}"
               ]
             ]
           else
             null

    m '.col-md-12.item-widget', [
      m 'figcaption', [
        m 'a', href: 'javascript:;', onclick: ctrl.showInfo, [
          m 'figure', [
            m 'img.item-image', src: imageUrl, onerror: ctrl.fallbackImageUrl
            m 'span.item-rating', style: {color: 'white'}, (if post.rating > 1 then "#{Math.floor post.rating}%" else 'N/A')
          ]
          m 'strong', post.name
          m 'span', post.address
          m 'span', [
            post.neighborhood
            post.price_range
            post.michelin_status + ' star' + (if +post.michelin_status > 1 then 's' else '')
          ].join(' - ')
          uber
        ]
      ]
    ]



filters =
  view: ->
    m '.search-filter'



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
    posts: -> data


  view: (ctrl) ->
    posts = ctrl.posts()
    hasMore = posts.length && posts[posts.length-1].page < posts[posts.length-1].pages

    [
      m.component filters

      m '.search-result', [
        m '.more-filter', [
          m 'span', "#{ctrl.posts().length} Restaurants · London"
          m 'br'
          m 'hr'
        ]

        m '.row', [
          ctrl.posts().map (post) ->
            post.key = post.id
            m.component restaurant, post
        ]
      ]

      m '.text-center', className: (if hasMore then '' else 'hidden'), [
        m 'a', href: 'javascript:;', onclick: ctrl.loadMore, 'Show more...'
      ]
    ]


top.initApp = ->
  App.initMap()
  m.mount document.querySelector('.map-side-bar'), app
