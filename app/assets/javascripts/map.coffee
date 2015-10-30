map = infoWindow = staticInfoWindow = places = distance = geocoder = myPosition = null
uberCircle = null
uberRadius = 3*1609.34

addLeftButtons = ->
  ctrl = document.createElement 'div'
  ctrl.className = 'gm-controls'

  icon = document.createElement 'i'
  icon.className = 'fa fa-plus'
  ctrl.appendChild icon
  icon.addEventListener 'click', ->
    map.setZoom map.getZoom()+1
  map.controls[google.maps.ControlPosition.LEFT_CENTER].push ctrl

  ctrl = document.createElement 'div'
  ctrl.className = 'gm-controls'

  icon = document.createElement 'i'
  icon.className = 'fa fa-minus'
  ctrl.appendChild icon
  icon.addEventListener 'click', ->
    map.setZoom map.getZoom()-1
  map.controls[google.maps.ControlPosition.LEFT_CENTER].push ctrl

  ctrl = document.createElement 'div'
  ctrl.className = 'gm-controls'

  icon = document.createElement 'i'
  icon.className = 'fa fa-location-arrow'
  ctrl.appendChild icon

  icon.addEventListener 'click', ->
    map.setCenter myPosition if myPosition

  map.controls[google.maps.ControlPosition.LEFT_CENTER].push ctrl


addUberMarker = ->
  btn = document.createElement 'div'
  btn.style.backgroundColor = '#fff'
  btn.style.border = '2px solid #fff'
  btn.style.borderRadius = '2px'
  btn.style.boxShadow = '0 0 3px rgba(0,0,0,.3)'
  btn.style.padding = '5px'
  btn.style.marginTop = '10px'
  btn.style.textAlign = 'center'
  btn.innerText = 'Purple Circle = £12 on Uber'

  map.controls[google.maps.ControlPosition.TOP_LEFT].push btn


top.initMap = ->
  deferred = m.deferred()
  map = new google.maps.Map document.getElementById('map'),
    center:
      lat: 51.5084509
      lng: -0.1433683
    disableDefaultUI: true
    zoom: 12

  addLeftButtons()

  map.addListener 'idle', ->
    deferred.resolve()

  infoWindow = new google.maps.InfoWindow map: map, disableAutoPan: true
  staticInfoWindow = new google.maps.InfoWindow map: map, zIndex: 1
  staticInfoWindow.close()
  places = new google.maps.places.PlacesService map
  distance = new google.maps.DistanceMatrixService
  geocoder = new google.maps.Geocoder

  if navigator.geolocation
    navigator.geolocation.getCurrentPosition (pos) ->
      App.myPosition = myPosition =
        # lat: pos.coords.latitude
        # lng: pos.coords.longitude
        # lat: 51.512545 # testing purposes
        # lng: -0.12033  # testing purposes

      App.s.location = [myPosition.lat, myPosition.lng].join(',')

      infoWindow.close()

      App.getAddressByCoord(myPosition).then (x) ->
        myPosition.address = x

      uberCircle = App.drawCircle
        fillOpacity: 0
        radius: uberRadius
        strokeColor: '#800080'
        strokeOpacity: 0.9
        strokeWeight: 3
      addUberMarker()

      App.drawCircle
        fillColor: 'blue'
        fillOpacity: 0.9
        radius: 25
        strokeColor: 'blue'
        strokeOpacity: 0.9
        strokeWeight: 3
    , ->
      App.myPosition = myPosition = 0
      infoWindow.setContent 'Error: The Geolocation service failed.'
  else
    App.myPosition = myPosition = 0
    infoWindow.setContent "Error: Your browser doesn't support geolocation."

  deferred.promise


App.drawCircle = (args) ->
  return unless args.center || myPosition
  new google.maps.Circle App.x.extend(args, map: map, center: myPosition)


App.newMarker = (args) ->
  opts = App.x.extend args, map: map
  new google.maps.Marker(opts)

App.getPlace = (id) ->
  deferred = m.deferred()

  places.getDetails placeId: id, (data, status) ->
    if status == google.maps.places.PlacesServiceStatus.OK
      geometry = data.geometry.location
      deferred.resolve
        address: data.vicinity || data.formatted_address
        latitude: geometry.lat()
        longitude: geometry.lng()
        name: data.name
        phone: data.formatted_phone_number
        photo: data.photos?[0]?.getUrl(maxWidth: 800)
        rating: Math.floor(100 * (data.rating || 0) / 5.0)
        reviews: data.reviews
    else
      deferred.reject(status)

  deferred.promise


App.distance = (to) ->
  deferred = m.deferred()

  if myPosition
    distance.getDistanceMatrix
      origins: [myPosition],
      destinations: [to]
      travelMode: google.maps.TravelMode.TRANSIT
    , (result, status) ->
      dist = result.rows[0]
      if dist && dist.elements[0]
        dist = dist.elements[0]
        miles = dist.distance?.value / 1609.34
        deferred.resolve(miles)
      else
        deferred.reject(status)
  else
    setTimeout ->
      deferred.reject myPosition == 0
    , 100

  deferred.promise


App.getAddressByCoord = (pos) ->
  deferred = m.deferred()
  geocoder.geocode location: pos, (data, status) ->
    if status == google.maps.GeocoderStatus.OK
      data.some (x) ->
        if x.formatted_address
          deferred.resolve(x.formatted_address)
        else
          false
    else
      deferred.reject(status)

  deferred.promise


App.showInfo = (html, marker, permanent=false) ->
  w = if permanent then staticInfoWindow else infoWindow
  w.setContent(html)
  w.open(map, marker)

App.closeInfo = (permanent=false) ->
  w = if permanent then staticInfoWindow else infoWindow
  w.close()

App.centerMap = (position) -> map.setCenter position

App.showMe = -> map.setCenter myPosition if myPosition

App.adjustUberCircle = (inside, radiusPoint) ->
  if radiusPoint
    p1 = new google.maps.LatLng myPosition.lat, myPosition.lng
    p2 = new google.maps.LatLng radiusPoint.lat, radiusPoint.lng
    meters = google.maps.geometry.spherical.computeDistanceBetween(p1, p2)
    uberRadius = if inside
                   Math.max uberRadius, meters
                 else
                   Math.min uberRadius, meters
    uberCircle.setRadius uberRadius
  else
    uberRadius


fitQueue = []
fitMapTo = ->
  coords = fitQueue.pop()
  fitQueue.splice(0, fitQueue.length)

  bounds = new google.maps.LatLngBounds
  coords.forEach (c) -> bounds.extend(c)

  google.maps.event.addListenerOnce map, 'bounds_changed', ->
    map.setZoom(15) if map.getZoom() > 15

  map.fitBounds bounds
debouncedFitMapTo = App.x.debounce 500, fitMapTo

App.fitMapTo = (coords) ->
  fitQueue.push coords
  debouncedFitMapTo()
