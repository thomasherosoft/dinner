shown = false
App.s.filters = {}

CUISINES = ['all', 'Afghani', 'African', 'Algerian', 'American', 'Arabian', 'Argentine', 'Asian', 'Australian', 'Austrian', 'BBQ', 'Bangladeshi', 'Belgian', 'Bengali',  'Brasserie', 'Brazilian', 'Breakfast', 'British', 'Bubble Tea', 'Burger', 'Burmese', 'Cambodian', 'Canadian', 'Cantonese', 'Caribbean', 'Central Asian', 'Chinese', 'Coffee and Tea', 'Colombian', 'Contemporary', 'Continental', 'Crepes', 'Cuban', 'Cypriot', 'Dim Sum', 'Eastern European', 'Ethiopian', 'European', 'Filipino', 'Fish and Chips', 'French', 'Georgian', 'German', 'Greek', 'Hawaiian', 'Indian', 'Indonesian', 'International', 'Iranian', 'Irish', 'Italian', 'Jamaican', 'Japanese', 'Jewish', 'Juices', 'Kazakh', 'Kebab', 'Korean', 'Kyrgyz', 'Latin American', 'Lebanese', 'Lithuanian', 'Malaysian', 'Mauritian', 'Mediterranean', 'Mexican', 'Middle Eastern', 'Modern European', 'Mongolian', 'Moroccan', 'Nepalese', 'Nigerian', 'Pakistani', 'Persian', 'Peruvian', 'Pizza', 'Polish', 'Portuguese',  'Ramen', 'Romanian', 'Russian', 'Sandwich', 'Scandinavian', 'Scottish', 'Seafood', 'Singaporean', 'Somali', 'South African', 'South Indian', 'Spanish', 'Sri Lankan', 'Steakhouse', 'Street Food', 'Sushi', 'Swedish', 'Syrian', 'Taiwanese', 'Tapas', 'Tex-Mex', 'Thai', 'Tibetan', 'Turkish', 'Ukrainian', 'Vegetarian', 'Venezualan', 'Vietnamese']


loadState = ->
  try
    App.s.filters = JSON.parse localStorage.getItem('filters')
  catch e
  App.s.filters ||= {}

saveState = (e) ->
  list = e.target.parentNode.querySelector('.filters-list')
  App.s.filters =
    location: list.querySelector('.location').value
    cuisine: list.querySelector('.cuisine').value
    rating: list.querySelector('.rating').value
  try
    localStorage.setItem 'filters', JSON.stringify(App.s.filters)
  catch e

App.c.filters =
  controller: ->
    loadState()

    reset: (e) ->
      App.s.filters = {}
      pubsub.publish 'search'
      localStorage.removeItem('filters')

    save: (e) ->
      saveState(e)
      pubsub.publish 'search'
      shown = false

    toggle: ->
      loadState() unless shown
      shown = !shown


  view: (ctrl) ->
    m '.filters', className: (if App.s.query then '' else 'hidden'), [
      m 'a.reset',
        className: (if App.s.filters && Object.keys(App.s.filters).length then '' else 'hidden')
        href: 'javascript:;'
        onclick: ctrl.reset
        [
          'Reset'
          m 'i.fa.fa-refresh'
        ]

      m 'h3', onclick: ctrl.toggle, 'Filters', [
        m "i.fa.fa-caret-#{if shown then 'up' else 'down'}"
      ]

      m 'dl.filters-list', className: (if shown then '' else 'hidden'), [
        m 'dt', 'Location'
        m 'dd', [
          m 'select.location', value: App.s.filters.location, [
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
          m 'select.cuisine', value: App.s.filters.cuisine, [
            CUISINES.map (x) ->
              m 'option', x
          ]
          ]

        m 'dt', 'Rating'
        m 'dd', [
          m 'select.rating', value: App.s.filters.rating, [
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
