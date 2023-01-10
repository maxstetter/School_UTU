const WebSocket = require('ws');

const wss = new WebSocket.Server({server: server});

var player1 = null;
var player2 = null;

wss.on('connection', function connection(ws) {
	if (player1 == null){
		player1 = ws;
	} else if (player2 == null){
		player2 = ws;
	} else {
		
	}
});