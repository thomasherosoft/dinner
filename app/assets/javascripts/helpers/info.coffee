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

  address = m.trust(data.address.replace(/\s*,\s*/g, '<br>'))
  citymapper = if App.myPosition
                 s = [App.myPosition.lat, App.myPosition.lng].join(',')
                 e = [data.latitude, data.longitude].join(',')
                 f = encodeURIComponent(App.myPosition.address)
                 a = encodeURIComponent(data.address)
                 m 'a',
                   href: "https://citymapper.com/london/?start=#{s}&saddr=#{f}&end=#{e}&eaddr=#{a}"
                   target: '_blank'
                   address
               else
                 address

  phone = if data.phone
            [
              m 'dt', 'phone'
              m 'dd', [
                m 'a', href: "tel:#{data.phone}", data.phone
              ]
            ]
          else
            null

  newlyOpened =
    if data.newly_opened
      m '.newly-opened', 'Newly Opened'
    else
      null

  reviews = (data.reviews || []).slice(0, 2)
  reviewsCount = (data.reviews || []).length + data.reviews_count

  [
    m '.header', style: {backgroundImage: "url(#{data.photo})"}, [
      m '.name', data.name
      m '.info', [
        m 'i.fa.fa-male'
        " #{(data.miles || 0).toFixed(1)} miles"
        (if reviewsCount > 0 then " - #{reviewsCount} reviews" else '')
        (if data.rating > 0 then " - #{data.rating}%" else '')
      ]
      newlyOpened
    ]

    m 'dl.dl-horizontal', [
      phone
      m 'dt', 'address'
      m 'dd', [citymapper]
      m 'dt', 'cuisines'
      m 'dd', data.cuisines.join(', ')
      michelin
      accolades
      uberCost
    ]

    m '.reviews', className: (if reviews.length then '' else 'hidden'), [
      m 'h5', 'Google Reviews'
      reviews.map (review) ->
        t = review.text.slice(0,70).trim().replace(/\s+\S+$/, '...')
        m '.review', [
          m '.rating', ratingDOM(100 * review.rating / 5)
          "#{review.rating} by #{review.author_name}"
          m 'p', unix2date(review.time) + ' ' + t
        ]
    ]
  ]


pubsub.subscribe 'show-info', ({data, bind, permanent}) ->
  div = document.createElement('div')
  m.render div, infoDOM(data)
  App.showInfo div, bind, permanent
