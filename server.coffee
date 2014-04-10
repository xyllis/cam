#ここから
Paparazzo = require './paparazzo'
http = require 'http'
url = require 'url'

camdata =
    "daika"  : 
        "host" : "daika.dyndns.tv"
        "port" : 8080
        "user" : "g4s1"
        "pass" : "g4s1"
        "listen_port" : 42431
        "log_level" : 0
    "kind"   : 
        "host" : "kind.dyndns.tv"
        "port" : 8080
        "user" : "g4s1"
        "pass" : "g4s1"
        "listen_port" : 42432
        "log_level" : 0
    "aoyama" : 
        "host" : "87aoyama.dyndns.tv"
        "port" : 8080
        "user" : "g4s1"
        "pass" : "g4s1"
        "listen_port" : 42433
        "log_level" : 0
    "orienttravel" : 
        "host" : "orienttravel.dyndns.tv"
        "port" : 8080
        "user" : "g4s1"
        "pass" : "g4s1"
        "listen_port" : 42434
        "log_level" : 0
    "kobo" : 
        "host" : "kose.dyndns.tv"
        "port" : 8080
        "user" : "g4s1"
        "pass" : "g4s1"
        "listen_port" : 42435
        "log_level" : 0

setup = (name, param) ->
    paparazzo = new Paparazzo
        host: param.host
        port: param.port
        path: "/videostream.cgi?resolution=8&rate=12&user=#{param.user}&pwd=#{param.pass}"

    updatedImage = ''

    paparazzo.on "update", (image) =>
        updatedImage = image
        #console.log "Downloaded #{image.length} bytes of #{name}"
        
    paparazzo.on 'error', (error) =>
        #console.log "Error: #{error.message}"
        
    paparazzo.start()

    server = http.createServer (req, res) ->
        data = ''
        path = url.parse(req.url).pathname
            
        if path == '/camera' and updatedImage?
            data = updatedImage
            #console.log "Will serve image of #{data.length} bytes of #{name}"

        res.writeHead 200,
            'Content-Type': 'image/jpeg'
            'Content-Length': data.length

        res.write data, 'binary'
        res.end()

    io = require('socket.io').listen(server, {'log level': param.log_level})
    server.listen(param.listen_port, 'www.garden4s.com')

    count = 0
    brit = 3
    cont = 3
    
    http.get(
        {
            host: param.host,
            port: param.port,
            path: '/get_camera_params.cgi?user=' + param.user + '&pwd=' +param.pass
        },
        (res) ->
            content = '';
            res.on 'readable', () ->
                content += res.read();
            .on 'end', () ->
                contents = content.replace(/var\s/g, '').replace(/;/g, '')
                eval(contents)
                brit = Math.floor((brightness+1)/50) + 1
                cont = contrast + 1
    ).on 'error', (e) ->
        console.log e

    io.sockets.on 'connection', (socket) =>
        count++
        io.sockets.emit('user connected', count)
        socket.emit('init control', [brit, cont])
        #console.log "#{name}#{count}"

        socket.on 'disconnect', () =>
            count--
            #console.log "#{name}#{count}"
            io.sockets.emit('user disconnected', count)
        
        socket.on 'send mes', (mes) =>
            io.sockets.emit('send mes', mes)

        socket.on 'change brightness', (num) =>
            socket.broadcast.emit('change brightness', num)
            brit = num

        socket.on 'change contrast', (num) =>
            socket.broadcast.emit('change contrast', num)
            cont = num

for name, param of camdata
    setup(name, param)
