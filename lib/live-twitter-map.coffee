fs = require 'fs'
sys = require 'sys'
path = require 'path'
http = require 'http'
express = require 'express'
io = require 'socket.io'
twitter = require 'ntwitter'

exports.TwitterMap = class TwitterMap
  constructor: (port) ->
    @created_web_server port
    
    # NUMBER OF CONNECTED CLIENTS
    @clients = 0
    # NUMBER OF TWEETS PROCESSED
    @count = 0
    # TIME IN SECONDS SINCE THE SERVER STARTED
    @time = 0
    # BACKLOG OF TWEETS TO SEND TO THE CLIENTS
    @backlog = []

  created_web_server: (port) =>
    pubDir = path.resolve __dirname + '/public'
    # setting up express server
    app = express()
    app.configure ->
      app.use express.static pubDir
    # setting up client web page
    app.get '/', (req,res) ->
      res.sendfile path.join pubDir, "client.html"
    # establishing the server
    server = http.createServer(app).listen port

    # attaching socket.io to the server
    @socket = io.listen server
    @socket.set 'log level', 1
    @socket.on 'connection', (socket) =>
      console.log 'New Connection'
      @clients++
      @checkStream()

      socket.on 'disconnect', =>
        console.log 'Disconnect'
        @clients--
        @checkStream()

  checkStream: =>
    if @clients > 0 && !@stream?
      @startStream()
    else if @clients <= 0 && @stream
      @stopStream()

  startStream: =>
    # CREATING THE TWITTER STREAMING CONNECTION
    console.log 'Start Streaming'
    @api = new twitter
      consumer_key: process.env.TWITTER_KEY
      consumer_secret: process.env.TWITTER_SECRET
      access_token_key: process.env.TWITTER_TOKEN
      access_token_secret: process.env.TWITTER_TOKEN_SECRET
    @api.verifyCredentials (err,data) ->
      throw err if err?
      console.log "Authenticated with Twitter"
    @api.stream 'statuses/filter', locations: [-180, -90, 180, 90], (stream) =>
      @stream = stream
      console.log(stream)
      stream.on 'error' , (err) =>
        throw err
      stream.on 'data', (tweet) =>
        console.log (tweet)
        if tweet.coordinates?
          @backlog.push
            lat:   tweet.coordinates.coordinates[1]
            lon:   tweet.coordinates.coordinates[0]
            text:  tweet.text
            user:  tweet.user.screen_name
            image: tweet.user.profile_image_url
            country: tweet.user.location
          sys.puts "#{++@count} @#{tweet.user.screen_name}: #{tweet.text}"
      stream.on 'end',(resp) =>
        sys.puts "END :#{resp.statusCode}"
        if resp.statusCode == 200
          @checkStream()
        else
          setTimeout (=> @checkStream()), 5 * 60 * 1000

  stopStream: =>
    if @stream?
      console.log "STOPPING STREAM"
      @stream.destroy()
      @stream = null

  run: =>
    # starting the timer
    setInterval (=> @time++),1000
    # start reading from the Streaming API
    @checkStream()
    # send new tweets to the client every 1/4 secind
    setInterval @broadcast_tweets ,250

  # send the tweets backlog to client & reset it
  broadcast_tweets: =>
    return unless @clients > 0
    backlog = unescape(encodeURIComponent(JSON.stringify(@backlog)))
    @socket.sockets.emit 'tweets',backlog
    @backlog = []



