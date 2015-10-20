map = infoWindow = staticInfoWindow = places = distance = myPosition = null
uberCircle = null
uberRadius = 3*1609.34

App.initMap = ->
  deferred = m.deferred()
  map = new google.maps.Map document.getElementById('map'),
    center:
      lat: 51.5084509
      lng: -0.1433683
    zoomControl: true
    zoomControlOptions:
      position: google.maps.ControlPosition.LEFT_CENTER
    zoom: 15

  map.addListener 'idle', ->
    deferred.resolve()

  infoWindow = new google.maps.InfoWindow map: map, disableAutoPan: true
  staticInfoWindow = new google.maps.InfoWindow map: map, disableAutoPan: true, zIndex: 1
  places = new google.maps.places.PlacesService map
  distance = new google.maps.DistanceMatrixService

  if navigator.geolocation
    navigator.geolocation.getCurrentPosition (pos) ->
      App.myPosition = myPosition =
        lat: pos.coords.latitude
        lng: pos.coords.longitude
      infoWindow.close()

      uberCircle = App.drawCircle
        fillOpacity: 0
        radius: uberRadius
        strokeColor: '#800080'
        strokeOpacity: 0.9
        strokeWeight: 3
      uberCircle.addListener 'mouseover', ->
        infoWindow.setPosition(myPosition)
        infoWindow.setContent """
          Purple circle = get anywhere for £12.
          <br>
          Blue circle = your Deliveroo coverage area (based on current location)
        """
        infoWindow.open(map)
      uberCircle.addListener 'mouseout', -> infoWindow.close()

      App.drawCircle
        fillColor: 'blue'
        fillOpacity: 0.9
        radius: 25
        strokeColor: 'blue'
        strokeOpacity: 0.9
        strokeWeight: 3
    , -> infoWindow.setContent 'Error: The Geolocation service failed.'
  else
    infoWindow.setContent "Error: Your browser doesn't support geolocation."

  deferred.promise


App.drawCircle = (args) ->
  new google.maps.Circle App.x.extend(args, map: map, center: myPosition)


App.newMarker = (args) ->
  $.extend args, map: map
  new google.maps.Marker(args)

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
      deferred.reject null
    , 100

  deferred.promise


App.showInfo = (html, marker, permanent=false) ->
  w = if permanent then staticInfoWindow else infoWindow
  w.setContent(html)
  w.open(map, marker)

App.closeInfo = (permanent=false) ->
  w = if permanent then staticInfoWindow else infoWindow
  w.close()

App.centerMap = (position) -> map.setCenter position

App.showMe = -> map.setCenter myPosition

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
