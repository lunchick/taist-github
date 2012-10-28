express = require 'express'
pg = require('pg')

conString = process.env.DATABASE_URL || "postgres://esewdxcylckkdx:k0EenLTX2J1SNEzFSu4N8FY6OS@ec2-107-22-165-35.compute-1.amazonaws.com:5432/d438m8fsbapo0j"
console.log conString
client = new pg.Client conString
app = express.createServer express.logger()

app.get '/', (request, response) ->
	client.connect()
	console.log "bla"
	client.query "SELECT NOW() as when", (err, result) ->
		console.log "bla"
		console.log "Row count: %d", result.rows.length
		console.log "Current year: %d", result.rows[0].when.getYear()
	response.send 'Hello World!'

port = process.env.PORT || 4000;

app.listen port, () ->
	console.log "Listening on " + port
