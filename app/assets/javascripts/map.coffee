map = infoWindow = places = distance = myPosition = null

App.initMap = ->
  map = new google.maps.Map document.getElementById('map'),
    center:
      lat: 51.5084509
      lng: -0.1433683
    zoomControl: true
    zoomControlOptions:
      position: google.maps.ControlPosition.LEFT_CENTER
    zoom: 15

  infoWindow = new google.maps.InfoWindow map: map, disableAutoPan: true
  places = new google.maps.places.PlacesService map
  distance = new google.maps.DistanceMatrixService

  if navigator.geolocation
    navigator.geolocation.getCurrentPosition (pos) ->
      myPosition =
        lat: pos.coords.latitude
        lng: pos.coords.longitude
      infoWindow.close()

      circle = new google.maps.Circle
        center: myPosition
        fillOpacity: 0
        map: map
        radius: 3*1609
        strokeColor: '#800080'
        strokeOpacity: 0.5
        strokeWeight: 1
      circle.addListener 'mouseover', ->
        infoWindow.setPosition(myPosition)
        infoWindow.setContent('Uber £12+')
        infoWindow.open(map)
      circle.addListener 'mouseout', -> infoWindow.close()
    , -> infoWindow.setContent 'Error: The Geolocation service failed.'
  else
    infoWindow.setContent "Error: Your browser doesn't support geolocation."

  null

App.newMarker = (args) ->
  $.extend args, map: map
  new google.maps.Marker(args)

App.closeInfo = -> infoWindow.close()

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
    else
      deferred.reject(status)

  deferred.promise


App.uberCost = (to) ->
  deferred = m.deferred()

  unless myPosition
    deferred.reject "Couldn't find your geolocation"

  distance.getDistanceMatrix
    origins: [myPosition],
    destinations: [to]
    travelMode: google.maps.TravelMode.DRIVING
  , (result, status) ->
    dist = result.rows[0]
    cost = null
    if dist && dist.elements[0]
      dist = dist.elements[0]
      miles = dist.distance.value / 1609
      # if miles <= 50
      time = miles / 9 * 60
      cost = Math.round(2.5 + 1.25*miles + 0.25*time)
      cost = 5 if cost < 5
      deferred.resolve(cost)
      # else
      #   deferred.resolve(0)
    else
      deferred.reject(status)

  deferred.promise


App.showInfo = (html, marker) ->
  infoWindow.setContent(html)
  infoWindow.open(map, marker)


App.centerMap = (position) -> map.setCenter position
