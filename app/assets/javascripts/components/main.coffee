App.c.main =
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
      hasMore = items.length >= 7
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
                 loc = if activeSearchLocation && ('+'+activeSearchLocation).indexOf(''+App.myPosition?.lat) == 1
                         'in 3 mile radius near you'
                       else
                         'results'
                 subj = activeSearchName
                 subj ||= if loc then '' else activeSearchLocation
                 loc + ' ' + (if subj then "matching \"#{subj}\"" else '')
             else
               "#{filterNames[activeFilter]} restaurants"
      head += '' unless activeSearchLocation

    header = if items.length == 0 && queue.length > 0
               'Calculating results...'
             else if activeLuck
               hasMore = false
               "Try your luck with these #{items.length}..."
             else
               "Showing #{items.length}#{total} #{head}"

    [
      m.component filters

      m '.search-result', config: mapAdjusts.bind(null, items), [
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


mapAdjusts = (items, el, initalle, ctx) ->
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

  if ctx.lastItemCount != items.length
    ctx.lastItemCount = items.length
    coords = items.map (x) ->
      new google.maps.LatLng x.latitude, x.longitude
    App.fitMapTo coords if coords.length
