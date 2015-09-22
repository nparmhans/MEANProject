$ ->
  window.MarkerImage = google.maps.MarkerImage
  window.Marker      = google.maps.Marker
  window.Point       = google.maps.Point
  window.LatLng      = google.maps.LatLng
  window.Size        = google.maps.Size
  window.InfoWindow  = google.maps.InfoWindow

  # LiveMap is our Model
  class LiveMap
    constructor: (@auto_show_chance, @view) ->
      @counter = 0
      @setup_socket()

    setup_socket: ->
      socket = io.connect()
      socket.on 'tweets', (tweets) =>
        data = JSON.parse(decodeURIComponent(escape(tweets)))
        
        # Iterate over the array of tweets stored 
        for tweet in data
          auto_show = @random_percent() < @auto_show_chance
          lat       = tweet.lat
          lng       = tweet.lon
          user      = tweet.user
          text      = tweet.text
          @view.add_marker lat, lng, user, text, auto_show, 10000
          @counter++
        # Update the views counter 
        @view.update_counter(@counter)
      socket.on 'disconnect', =>
        @view.disconnected()

    random_percent: ->
      Math.floor Math.random() * 100 + 1

  # LiveMapView is our view
  class LiveMapView
    constructor: (start_location, zoom_level) ->
      options =
        zoom:      zoom_level
        center:    start_location
        mapTypeId: google.maps.MapTypeId.HYBRID
      @map        = new google.maps.Map(document.getElementById('map_canvas'), options)
      @counter    = $ "#counter"
      @title      = $ "#title"
      @infowindow = false # whether or not an InfoWindow is "auto-showing" right now

    update_counter: (count) ->
      @counter.text count

    disconnected: ->
      @title.html "DISCONNECTED<br />Please refresh the page."
      @title.css  "color", "#ff0000"

    marker_for: (lat, lng, user) ->
      marker       = new Marker
        position: new LatLng(lat, lng)
        map:      @map
        title:    user
      marker

    info_window_for: (user, tweet) ->
      infowindow = new InfoWindow
        content: "<div class='info'>" +
          "<a href='http://twitter.com/#{user}' target='_blank'>@#{user}</a>: #{tweet}" +
          "</div>"
        disableAutoPan: true
        maxWidth: 350
      infowindow

    add_marker: (lat, lng, user, tweet, autoshow, timeout = null) ->
      marker     = @marker_for lat, lng, user,
      infowindow = @info_window_for  user, tweet
      if timeout?
        marker.timeout = setTimeout (=> @remove_marker(marker)), timeout

      # Show the InfoWindow when the marker is clicked
      google.maps.event.addListener marker, 'click', =>
        infowindow.open @map, marker
        if marker.timeout?
          # Reset the timeout for the marker 
          clearTimeout marker.timeout
          marker.timeout = setTimeout (=> @remove_marker(marker)), timeout

      if autoshow == true && @infowindow == false
        setTimeout (=> infowindow.open @map, marker), 1000
        marker.auto_infowindow = infowindow
        @infowindow = true

    remove_marker: (marker) ->
      marker.setMap null
      @infowindow = false if marker.auto_infowindow

  # Create a new map with a 1% auto-show chance
  window.view = new LiveMapView new LatLng(15, -15), 3
  window.Map  = new LiveMap 15, view





