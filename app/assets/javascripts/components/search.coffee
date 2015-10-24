input = m.prop ''
selected = null
suggestions = []
loading = false

loadSuggestions = (e) ->
  return if e.defaultPrevented
  console.debug 'autocomplete', e.target.value, e.defaultPrevented
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
    suggestions: -> suggestions
    choose: (x, e) ->
      input x.name
      e.target.parentNode.parentNode.querySelector('input').value = x.name
      suggestions = []
    input: input
    loading: -> loading
    search: -> console.debug 'searching for', input()
    selected: -> selected

    navigate: (e) ->
      console.debug 'key', e.keyCode, selected
      if e.keyCode == 38 || e.keyCode == 40
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
      debouncedLoad(e)


  view: (ctrl) ->
    state = []
    state.push 'with-suggestions' if ctrl.suggestions().length
    state.push 'in-progress' if ctrl.loading()
    [
      m '.search-wrap', [
        m 'input.search',
          className: state.join(' ')
          onchange: m.withAttr('value', ctrl.input)
          onkeyup: ctrl.navigate
        m 'i.fa.fa-search'
        m 'i.fa.fa-spin.fa-spinner'

        m 'ul.suggestions', [
          m 'li.muted', 'Search for restaurant by name, address, location ...'

          m 'li.location', [
            m 'i.fa.fa-location-arrow'
            'Use Current Location'
          ]

          m 'li.head', className: (if suggestions.length then '' else 'hidden'), 'Restaurants'
          ctrl.suggestions().map (x) ->
            m 'li',
              className: (if x.id == ctrl.selected() then 'selected' else '')
              onclick: ctrl.choose.bind(null, x), [x.name, x.address].join(', ')
        ]
      ]

      m 'button.search',
        onclick: ctrl.search
        'Search'
    ]
