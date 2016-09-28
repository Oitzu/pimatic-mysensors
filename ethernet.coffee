events = require 'events'
net = require 'net'
Promise = require 'bluebird'

class EthernetDriver extends events.EventEmitter
  
  constructor: (protocolOptions)->
    @port = protocolOptions.port
    @host = protocolOptions.host
    
  connect: (timeout) ->
    
    # Create connection
    @connection = net.createConnection @port, @host
   
    console.log "CONNECTING"
 
    # cleanup
    @ready = no

     # reject promise on close
    @connection.on 'close', () =>
      console.log "CLOSE"
      @emit('reconnect')
    
    # setup data listener
    @connection.on 'data', (data) => 
      # Sanitize data
      data = data.toString()
      line = data.replace(/(\r\n|\n|\r)/gm,"")
      @emit('line', line)
    
    # reject promise on error
    @connection.on 'error', (error) =>
      console.log "ERROR"
    
    #resolve promise on connect
    @connection.on 'connect', () =>
      @ready = yes
      @emit 'ready'
      return
      
    return new Promise( (resolve, reject) =>
      @once("ready", resolve)
      @once("error", reject)
    )

  disconnect: -> 
    @connection.end()
    return Promise.resolve()

  write: (data) -> 
    if not @connection.write(data, 'utf-8', () =>
      @emit "done"
    )
      @emit "error"

    return new Promise( (resolve, reject) =>
      @once("done", resolve)
      @once("error", reject)
    )

module.exports = EthernetDriver
