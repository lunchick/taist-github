express = require 'express'

app = express.createServer express.logger()

app.get '/', (request, response) ->
	response.send 'Hello World!'

port = process.env.PORT || 4000;

app.listen port, () ->
	console.log "Listening on " + port
