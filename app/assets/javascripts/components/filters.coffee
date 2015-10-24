filterNames =
  michelin: 'M'
  zagat: 'Z'
  timeout: 'T'
  foodtruck: 'F'
  faisal: 'E'
  deliveroo: 'D'

shortFilterNames =
  michelin: 'M'
  zagat: 'Z'
  timeout: 'T'
  foodtruck: 'F'
  faisal: 'E'
  deliveroo: 'D'

App.c.filters =
  controller: ->
    filter: (name) ->
      queue = []
      load filter: name

    luck: (e) ->
      spinner = e.target.children[0]
      spinner.classList.remove('hidden')
      queue = []
      load(luck: true).then ->
        spinner.classList.add('hidden')

    showTip: (e) ->
      # $(e.target).tooltip('show')

    hideTip: (e) ->
      # $(e.target).tooltip('hide')

  view: (ctrl) ->
    [
      m 'h3', 'Explore London', [
        m 'small.lucky',
          onclick: ctrl.luck
          "I'm feeling lucky"
          [ m 'i.fa.fa-spin.fa-spinner.hidden' ]
      ]
      m 'ul.filters-icons', [
        Object.keys(filterNames).map (name) ->
          m 'li', className: (if App.s.filter == name then 'active' else ''), [
            m 'a',
              href: 'javascript:;'
              onclick: ctrl.filter.bind(null, name)
              onmouseover: ctrl.showTip
              onmouseout: ctrl.hideTip
              title: filterNames[name]
              shortFilterNames[name]
              # replace line above with
              #   m 'img', className: 'some-class', src: '/path/to/image.png'
              # and remove onmouse* handlers above which changes innerText
          ]
      ]
    ]
