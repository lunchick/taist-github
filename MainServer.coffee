express = require 'express'
pg = require('pg')

conString = process.env.DATABASE_URL || "postgres://postgres:letunov1988@localhost:5432/postgres"
client = new pg.Client conString
app = express.createServer()
app.use express.bodyParser()
client.connect()

app.get '/issue', (request, response) ->
	repos = request.query["repos"]
	issueId = request.query["issue"]
	query = client.query "SELECT commentid, timespent FROM timetrack WHERE repos = $1 and issueid = $2", [repos, issueId]
	comments = []
	query.on 'row', (result) ->
		comments.push result
	query.on 'end', () ->
		response.header 'Access-Control-Allow-Origin','*'
		response.header 'Access-Control-Allow-Headers','X-Requested-With'
		response.send { "comments" : comments}

app.get '/report', (request, response) ->
	repos = request.query["repos"]
	timePeriod = request.query["timePeriod"]
	endDate = new Date()
	startDate = new Date()
	if timePeriod is 'week'
		startDate.setDate startDate.getDate()-7
	else
		startDate.setDate startDate.getDate()-30

	query = client.query "SELECT reporter, timespent FROM timetrack WHERE repos = $1 and date between $2 and $3", [repos, startDate, endDate]
	report = []
	query.on 'row', (result) ->
		report.push result
	query.on 'end', () ->
		result = processResult report
		response.header 'Access-Control-Allow-Origin','*'
		response.header 'Access-Control-Allow-Headers','X-Requested-With'
		response.send result

app.post '/addComment', (request, response) ->
	client.query "INSERT INTO timetrack(repos, issueid, commentid, date, timespent, reporter) values($1, $2, $3, $4, $5, $6)",
		[request.body.repos, request.body.issueId, request.body.commentId, request.body.date, request.body.timeSpent,request.body.reporter]
	response.header 'Access-Control-Allow-Origin','*'
	response.header 'Access-Control-Allow-Headers','X-Requested-With'
	response.send "OK"

app.post '/editComment', (request, response) ->
	client.query "UPDATE timetrack SET timespent=$1 WHERE repos = $2 and issueid = $3 and commentid = $4",
		[request.body.timeSpent, request.body.repos, request.body.issueId, request.body.commentId]
	response.header 'Access-Control-Allow-Origin','*'
	response.header 'Access-Control-Allow-Headers','X-Requested-With'
	response.send "OK"

app.post '/changePluginStatus', (request, response) ->
	repos = request.body.repos
	enable = request.body.enable
	query = client.query "SELECT enable FROM plugin_status WHERE repos = $1", [repos]
	isCreated = false;
	query.on 'row', (result) ->
		isCreated = true
		if result.enable isnt enable
			client.query "UPDATE plugin_status SET enable=$1 WHERE repos = $2", [enable, repos]
	query.on 'end', () ->
		if isCreated is false
			client.query "INSERT INTO plugin_status(repos, enable) values($1, $2)",	[repos, enable]
	response.header 'Access-Control-Allow-Origin','*'
	response.header 'Access-Control-Allow-Headers','X-Requested-With'
	response.send "OK"

app.get '/pluginStatus', (request, response) ->
	repos = request.query["repos"]
	enable = request.query["enable"]
	result = false;
	query = client.query "SELECT enable FROM plugin_status WHERE repos = $1", [repos]
	query.on 'row', (row) ->
		result = row.enable;
	query.on 'end', () ->
		response.header 'Access-Control-Allow-Origin','*'
		response.header 'Access-Control-Allow-Headers','X-Requested-With'
		response.send { status: result }

port = process.env.PORT || 4000

app.listen port, () ->
	console.log "Listening on " + port

processResult = (report) ->
	result = {}
	total = 0;
	for entry in report
		reporter = entry.reporter
		time = entry.timespent
		total += convertStringToTime time
		if (result[reporter])
			result[reporter] = result[reporter] + convertStringToTime time
		else
			result[reporter] = convertStringToTime time
	reporters = Object.keys result
	reportersList = []
	for item in reporters
		reportersList.push {"reporter" : item, "timeSpent" : convertTimeToString result[item]}

	{'reporters' : reportersList , "total" : convertTimeToString total}

convertStringToTime = (timeString) ->
	array = timeString.split ':'
	parseInt(array[0]) * 60 + parseInt(array[1])

convertTimeToString = (time) ->
	"" +  Math.floor(time/60) + ":" + if time%60 > 9 then time%60 else "0" + time%60