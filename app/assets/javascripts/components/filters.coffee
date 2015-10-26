shown = false
App.s.filters = {}

CUISINES = ['all', 'Afghani', 'African', 'Algerian', 'American', 'Amish', 'Arabian', 'Argentine', 'Asian', 'Australian', 'Austrian', 'BBQ', 'Bakery', 'Balti', 'Bangladeshi', 'Bar Food', 'Belgian', 'Bengali', 'Beverages', 'Biryani', 'Brasserie', 'Brazilian', 'Breakfast', 'British', 'Bubble Tea', 'Burger', 'Burmese', 'Cafe', 'Cambodian', 'Canadian', 'Cantonese', 'Caribbean', 'Central Asian', 'Chinese', 'Coffee and Tea', 'Colombian', 'Contemporary', 'Continental', 'Cream', 'Crepes', 'Cuban', 'Curry', 'Cypriot', 'Deli', 'Desserts', 'Dim', 'Dim Sum', 'Diner', 'Drinks Only', 'Eastern', 'Eastern European', 'Ethiopian', 'European', 'Fast', 'Fast Food', 'Filipino', 'Finger Food', 'Fish and Chips', 'Food', 'French', 'Fusion', 'Georgian', 'German', 'Greek', 'Grill', 'Hawaiian', 'Healthy', 'Healthy Food', 'Ice', 'Ice Cream', 'Indian', 'Indonesian', 'International', 'Iranian', 'Irish', 'Italian', 'Jamaican', 'Japanese', 'Jewish', 'Juices', 'Kazakh', 'Kebab', 'Kiwi', 'Korean', 'Kyrgyz', 'Latin', 'Latin American', 'Lebanese', 'Lithuanian', 'Malaysian', 'Mauritian', 'Mediterranean', 'Mexican', 'Middle', 'Middle Eastern', 'Modern', 'Modern European', 'Mongolian', 'Moroccan', 'Mughlai', 'Nepalese', 'Nigerian', 'North', 'North Indian', 'Not Available', 'Others', 'Pakistani', 'Pan', 'Pan Asian', 'Persian', 'Peruvian', 'Pizza', 'Polish', 'Portuguese', 'Raclette', 'Ramen', 'Romanian', 'Russian', 'Sandwich', 'Scandinavian', 'Scottish', 'Seafood', 'Sichuan', 'Sicilian', 'Singaporean', 'Somali', 'South', 'South African', 'South Indian', 'Southern', 'Spanish', 'Sri Lankan', 'Steakhouse', 'Street', 'Street Food', 'Sum', 'Sushi', 'Swedish', 'Syrian', 'Taiwanese', 'Tapas', 'Tea', 'Teriyaki', 'Tex-Mex', 'Thai', 'Tibetan', 'Turkish', 'Ukrainian', 'Vegetarian', 'Venezualan', 'Vietnamese', 'Zambian']

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
  localStorage.setItem 'filters', JSON.stringify(App.s.filters)



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
