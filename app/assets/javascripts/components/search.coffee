input = m.prop ''
suggestions = null
loading = false
active = false

loadSuggestions = (e) ->
  return if e.defaultPrevented
  m.startComputation()
  loading = true
  m.endComputation()
  App.x
    .get
      background: true
      data: {q: e.target.value}
      url: '/restaurants/autocomplete'
    .then (x) ->
      m.startComputation()
      suggestions = x
      loading = false
      m.endComputation()
      # console.timeEnd('load suggestion')
    , ->
      m.startComputation()
      loading = false
      m.endComputation()
debouncedLoad = App.x.debounce 150, loadSuggestions


App.c.search =
  controller: ->
    self =
      activate: (e) ->
        document.body.scrollTop = e.target.parentNode.parentNode.offsetTop - 4 if e
        active = true
      deactivate: -> active = false
      choose: (value, type, e) ->
        input value
        document.querySelector('input.search').value = value
        suggestions = null
        self.search(type)
      input: input
      search: (type) ->
        self.deactivate()
        App.s.query = input()
        App.s.type = type if type && !type.type
        setTimeout -> pubsub.publish 'search'
      selected: -> selected

      navigate: (e) ->
        if e.keyCode == 13
          self.search()
          return
        else if e.keyCode == 27
          return self.deactivate()
        suggestions = null unless e.target.value
        self.activate()
        debouncedLoad(e)
        # console.time('load suggestion')


  view: (ctrl) ->
    state = []
    state.push 'with-suggestions' if suggestions
    state.push 'in-progress' if loading
    state.push 'active' if active
    m '#search', className: (if m.route() == '/' then '' else 'hidden'), [
      m '.search-wrap', [
        m 'input.search',
          autocorrect: off
          className: state.join(' ')
          onchange: m.withAttr('value', ctrl.input)
          onfocus: ctrl.activate
          onkeyup: ctrl.navigate
          placeholder: 'Search..'
          spellcheck: off
        m 'i.fa.fa-search'
        m 'i.fa.fa-spin.fa-spinner'

        m 'ul.suggestions', [
          m 'li.muted', 'Search for restaurant by name, address, location, cuisine ...'

          m 'li.location.with-icon',
            onmousedown: ctrl.choose.bind(null, 'Current Location', 'location')
            [
              m 'i.fa.fa-location-arrow'
              'Use Current Location'
            ]

          (if suggestions && Object.keys(suggestions).length then results(ctrl) else samples(ctrl))
        ]
      ]

      m 'button.search',
        onclick: ctrl.search
        'Find Restaurants'
    ]


samples = (ctrl) ->
  [
    m 'li.head', 'Samples'
    ['Mayfair', 'Notting Hill'].map (x) ->
      m 'li.with-icon', onmousedown: ctrl.choose.bind(null, x, 'cities'), [
        m 'i.fa.fa-map'
        x
      ]

    [
      ['Gymkhana', 'Albemarle Street']
      ['Locanda Locatelli', 'Seymour Street']
    ].map (x) ->
      m 'li.with-icon', onmousedown: ctrl.choose.bind(null, x[0], 'names'), [
        m 'i.fa.fa-cutlery'
        x.join(', ')
      ]
  ]

suggestionKeys =
  names:
    name: 'Restaurant'
    icon: 'fa-cutlery'
  addresses:
    name: 'Address'
    icon: 'fa-map-o'
  cities:
    name: 'City'
    icon: 'fa-map-o'
  cuisines:
    name: 'Cuisine'
    icon: 'fa-asterisk'

results = (ctrl) ->
  Object.keys(suggestionKeys).map (key) ->
    if Array.isArray(suggestions[key]) && suggestions[key].length
      [
        m 'li.head', suggestionKeys[key].name
        suggestions[key].map (x) ->
          m 'li.with-icon', onmousedown: ctrl.choose.bind(null, x.replace(/<[^>]+>/g, ''), key), [
            m 'i.fa', className: suggestionKeys[key].icon
            m.trust(x)
          ]
      ]
