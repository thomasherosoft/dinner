App.c.search =
  controller: ->
    # name = location = ''
    #
    # perform = ->
    #   loc = if location == 'My Location' then [App.myPosition.lat, App.myPosition.lng].join(',') else location
    #   queue = []
    #   load
    #     search_name: name
    #     search_location: loc
    # debounced = App.x.debounce 250, perform
    #
    # clear_name: (e) ->
    #   e.target.parentNode.querySelector('input').value = ''
    #   name = ''
    #   perform()
    #
    # clear_location: (e) ->
    #   e.target.parentNode.querySelector('input').value = ''
    #   location = ''
    #   perform()
    #
    # search_name: (val) ->
    #   if val || val == ''
    #     name = val
    #     debounced()
    #   name
    #
    # search_location: (val) ->
    #   if val || val == ''
    #     location = val
    #     debounced()
    #   location
    #
    # useMyPosition: (e) ->
    #   if App.myPosition
    #     App.centerMap App.myPosition
    #     e.target.parentNode.querySelector('input')
    #       .value = location = 'My Location'
    #     perform()

    input = m.prop ''
    suggestions = []
    loading = false

    loadSuggestions = (e) ->
      console.debug 'autocomplete', e.target.value
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

    suggestions: -> suggestions
    choose: (x, e) -> input(x.title)
    input: input
    loading: -> loading
    loadSuggestions: App.x.debounce(200, loadSuggestions)
    search: ->
      console.debug 'searching for', input()



  view: (ctrl) ->
    state = []
    state.push 'with-suggestions' if ctrl.suggestions().length
    state.push 'in-progress' if ctrl.loading()
    [
      m '.search-wrap', [
        m 'input.search',
          className: state.join(' ')
          onchange: m.withAttr('value', ctrl.input)
          onkeyup: ctrl.loadSuggestions
        m 'i.fa.fa-search'
        m 'i.fa.fa-spin.fa-spinner'

        m 'ul.suggestions', [
          ctrl.suggestions().map (x) ->
            m 'li', onclick: ctrl.choose.bind(null, x), [x.name, x.address].join(', ')
        ]
      ]

      m 'button.search', onclick: ctrl.search, 'Search'
    ]


    # m 'form.form-inline', onsubmit: ((e) -> e.preventDefault()), [
    #   m '.search-group', [
    #     m 'i.fa.fa-search'
    #     m 'input.form-control',
    #       onkeyup: m.withAttr('value', ctrl.search_name)
    #       placeholder: 'Search Restaurant Name or Cuisine'
    #     m 'i.fa.fa-times',
    #       className: (if ctrl.search_name() then '' else 'transparent')
    #       onclick: ctrl.clear_name
    #   ]
    #
    #   m '.search-group', [
    #     m 'i.fa.fa-location-arrow.location', onclick: ctrl.useMyPosition
    #     m 'input.form-control.location',
    #       onkeyup: m.withAttr('value', ctrl.search_location)
    #       placeholder: 'Location'
    #     m 'i.fa.fa-times',
    #       className: (if ctrl.search_location() then '' else 'transparent')
    #       onclick: ctrl.clear_location
    #   ]
    # ]
