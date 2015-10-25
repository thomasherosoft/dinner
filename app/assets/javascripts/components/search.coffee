input = m.prop ''
selected = null
suggestions = []
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
      suggestions = x.slice()
      loading = false
      m.endComputation()
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
      suggestions: -> suggestions
      choose: (x, e) ->
        input x.name
        e.target.parentNode.parentNode.querySelector('input').value = x.name
        suggestions = []
        selected = null
        self.search()
      input: input
      loading: -> loading
      search: (mylocation=false) ->
        self.deactivate()
        args = if mylocation
                 location: [App.myPosition?.lat, App.myPosition?.lng].join(',') if mylocation
               else
                 q: input()
        setTimeout -> pubsub.publish 'search-for', args
      selected: -> selected

      navigate: (e) ->
        if e.keyCode == 13
          if use = suggestions.filter((x) -> x.id == selected)[0]
            self.choose(use, e)
          else
            self.search()
          return
        else if e.keyCode == 27
          return self.deactivate()
        else if e.keyCode == 38 || e.keyCode == 40
          if suggestions.length
            e.preventDefault()
            found = suggestions.some (x, i) ->
              if x.id == selected
                selected = suggestions[if e.keyCode == 38 then i-1 else i+1]?.id
              else
                false
            selected = false unless found
            unless selected
              x = if e.keyCode == 38 then suggestions.length-1 else 0
              selected = suggestions[x].id
          else
            selected = null
        self.activate()
        debouncedLoad(e)


  view: (ctrl) ->
    state = []
    state.push 'with-suggestions' if ctrl.suggestions().length
    state.push 'in-progress' if ctrl.loading()
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
            onmousedown: ctrl.search.bind(null, 'my location')
            [
              m 'i.fa.fa-location-arrow'
              'Use Current Location'
            ]

          (if suggestions.length then results(ctrl) else samples(ctrl))
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
      m 'li.with-icon', onmousedown: ctrl.choose.bind(null, name: x), [
        m 'i.fa.fa-map'
        x
      ]

    [
      'Gymkhana, Albemarle Street'
      'Asakusa, Eversholt Street'
      'Dishroom, Boundary Street'
      'Locanda Locatelli, Seymour Street'
    ].map (x) ->
      m 'li.with-icon', onmousedown: ctrl.choose.bind(null, name: x), [
        m 'i.fa.fa-cutlery'
        x
      ]
  ]


results = (ctrl) ->
  areas = []
  cuisines = []
  suggestions.forEach (s) ->
    areas.push s.area if areas.indexOf(s.area) < 0
    s.cuisines.forEach (c) ->
      cuisines.push c if cuisines.indexOf(c) < 0

  areas.splice 3, 4
  cuisines.splice 3, 4
  suggestions.splice 3, 4

  [
    m 'li.head', 'Restaurants'
    suggestions.map (x) ->
      m 'li.with-icon',
        className: (if x.id == ctrl.selected() then 'selected' else '')
        onmousedown: ctrl.choose.bind(null, x)
        [
          m 'i.fa.fa-cutlery'
          [x.name, x.address].join(', ')
        ]

    m 'li.head', 'City'
    areas.map (x) ->
      m 'li.with-icon', onmousedown: ctrl.choose.bind(null, name: x), [
        m 'i.fa.fa-map-o'
        x
      ]

    m 'li.head', 'Cuisines'
    cuisines.map (x) ->
      m 'li.with-icon', onmousedown: ctrl.choose.bind(null, name: x), [
        m 'i.fa.fa-asterisk'
        x
      ]
  ]
