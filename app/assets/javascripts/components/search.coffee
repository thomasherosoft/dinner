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
      activate: -> active = true
      deactivate: -> active = false
      choose: (value, e) ->
        input value
        e.target.parentNode.parentNode.querySelector('input').value = value
        suggestions = null
        self.search()
      input: input
      search: (mylocation=false) ->
        self.deactivate()
        App.s.query = input()
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
    [
      m '.search-wrap', [
        m 'input.search',
          className: state.join(' ')
          onchange: m.withAttr('value', ctrl.input)
          onfocus: ctrl.activate
          onkeyup: ctrl.navigate
        m 'i.fa.fa-search'
        m 'i.fa.fa-spin.fa-spinner'

        m 'ul.suggestions', [
          m 'li.muted', 'Search for restaurant by name, address, location, cuisine ...'

          m 'li.location.with-icon',
            onmousedown: ctrl.choose.bind(null, 'Current Location')
            [
              m 'i.fa.fa-location-arrow'
              'Use Current Location'
            ]

          (if suggestions && Object.keys(suggestions).length then results(ctrl) else samples(ctrl))
        ]
      ]

      m 'button.search',
        onclick: ctrl.search
        'Search'
    ]


samples = (ctrl) ->
  [
    m 'li.head', 'Samples'
    ['Mayfair', 'Fitzrovia', 'Marylebone', 'Notting Hill'].map (x) ->
      m 'li.with-icon', onmousedown: ctrl.choose.bind(null, x), [
        m 'i.fa.fa-map'
        x
      ]

    [
      'Gymkhana, Albemarle Street'
      'Asakusa, Eversholt Street'
      'Dishroom, Boundary Street'
      'Locanda Locatelli, Seymour Street'
    ].map (x) ->
      m 'li.with-icon', onmousedown: ctrl.choose.bind(null, x), [
        m 'i.fa.fa-cutlery'
        x
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
          m 'li.with-icon', onmousedown: ctrl.choose.bind(null, x.replace(/<[^>]+>/g, '')), [
            m 'i.fa', className: suggestionKeys[key].icon
            m.trust(x)
          ]
      ]
