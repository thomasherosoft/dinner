shown = false
App.s.filters = {}

CUISINES = ['all', 'Afghani', 'African', 'Algerian', 'American', 'Arabian', 'Argentine', 'Asian', 'Australian', 'Austrian', 'BBQ', 'Bangladeshi', 'Belgian', 'Bengali',  'Brasserie', 'Brazilian', 'Breakfast', 'British', 'Bubble Tea', 'Burger', 'Burmese', 'Cambodian', 'Canadian', 'Cantonese', 'Caribbean', 'Central Asian', 'Chinese', 'Coffee and Tea', 'Colombian', 'Contemporary', 'Continental', 'Crepes', 'Cuban', 'Cypriot', 'Dim Sum', 'Eastern European', 'Ethiopian', 'European', 'Filipino', 'Fish and Chips', 'French', 'Georgian', 'German', 'Greek', 'Hawaiian', 'Indian', 'Indonesian', 'International', 'Iranian', 'Irish', 'Italian', 'Jamaican', 'Japanese', 'Jewish', 'Juices', 'Kazakh', 'Kebab', 'Korean', 'Kyrgyz', 'Latin American', 'Lebanese', 'Lithuanian', 'Malaysian', 'Mauritian', 'Mediterranean', 'Mexican', 'Middle Eastern', 'Modern European', 'Mongolian', 'Moroccan', 'Nepalese', 'Nigerian', 'Pakistani', 'Persian', 'Peruvian', 'Pizza', 'Polish', 'Portuguese',  'Ramen', 'Romanian', 'Russian', 'Sandwich', 'Scandinavian', 'Scottish', 'Seafood', 'Singaporean', 'Somali', 'South African', 'South Indian', 'Spanish', 'Sri Lankan', 'Steakhouse', 'Street Food', 'Sushi', 'Swedish', 'Syrian', 'Taiwanese', 'Tapas', 'Tex-Mex', 'Thai', 'Tibetan', 'Turkish', 'Ukrainian', 'Vegetarian', 'Venezualan', 'Vietnamese']


valueOnly = (k,v) ->
  if v == 'all' || v == 'anywhere'
    delete App.s.filters[k]
  else
    App.s.filters[k] = v

loadState = ->
  try
    App.s.filters = JSON.parse jsCookies.get('filters')
  catch e
  App.s.filters ||= {}

saveFilters = ->
  try
    jsCookies.set 'filters', JSON.stringify(App.s.filters)
  catch e

saveState = (e) ->
  list = e.target.parentNode.querySelector('.filters-list')
  valueOnly 'location', list.querySelector('.location').value
  valueOnly 'cuisine', list.querySelector('.cuisine').value
  valueOnly 'rating', list.querySelector('.rating').value
  saveFilters()


App.c.filters =
  controller: ->
    loadState()

    remove: (key, e) ->
      delete App.s.filters[key]
      saveFilters()
      pubsub.publish 'search'

    save: (e) ->
      saveState(e)
      pubsub.publish 'search'
      shown = false

    toggle: ->
      loadState() unless shown
      shown = !shown


  view: (ctrl) ->
    filtersApplied = []
    if App.s.filters.rating
      filtersApplied.push m('.btn', onclick: ctrl.remove.bind(null, 'rating'), [
        App.s.filters.rating
        m 'i.fa.fa-times'
      ])
    if App.s.filters.location
      filtersApplied.push m('.btn', onclick: ctrl.remove.bind(null, 'location'), [
        App.s.filters.location
        m 'i.fa.fa-times'
      ])
    if App.s.filters.cuisine
      filtersApplied.push m('.btn', onclick: ctrl.remove.bind(null, 'cuisine'), [
        'Cuisine',
        m 'i.fa.fa-times'
      ])

    m '.filters', className: (if App.s.query then '' else 'hidden'), [
      m '.header', [
        m '.btn', className: (if shown then 'pushed' else ''), onclick: ctrl.toggle, 'Filters'

        filtersApplied
      ]


      m 'dl.filters-list', className: (if shown then '' else 'hidden'), [
        m 'dt', 'Location'
        m 'dd', [
          m 'select.location', value: (App.s.filters.location || 'anywhere'), [
            m 'option', 'anywhere'
            m 'option', '1 mile'
            m 'option', '2 miles'
            m 'option', '3 miles'
          ]
          m '.tooltip', [
            m 'i.fa.fa-question-circle'
            m '.tooltip-text', 'Default view is 0.5 mile radius from your location.'
          ]
        ]

        m 'dt', 'Cuisine'
        m 'dd', [
          m 'select.cuisine', value: (App.s.filters.cuisine || 'all'), [
            CUISINES.map (x) ->
              m 'option', x
          ]
          ]

        m 'dt', 'Rating'
        m 'dd', [
          m 'select.rating', value: (App.s.filters.rating || 'all'), [
            m 'option', 'all'
            m 'option', '90%+'
            m 'option', '80%+'
          ]
        ]
      ]

      m 'button',
        className: (if shown then '' else 'hidden')
        onclick: ctrl.save
        'Save'
    ]
