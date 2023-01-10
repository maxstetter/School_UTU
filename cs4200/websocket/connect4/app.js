// server: connect4ws.herokuapp.com

var app = new Vue({
  el: '#game',
  data: {
    board: [
      [1, 0, 0, 0, 0, 0],
      [1, 2, 0, 0, 0, 0],
      [1, 2, 1, 0, 0, 0],
      [1, 2, 1, 2, 0, 0],
      [1, 2, 1, 0, 0, 0],
      [1, 2, 0, 0, 0, 0],
      [1, 0, 0, 0, 0, 0]
    ]
  },
  methods: {
	  connectSocket: function () {
		this.socket = new WebSocket("wss://connect4ws.herokuapp.com");
		//on message send data.
		this.socket.onmessage = (event) => {
			console.log("socket.onmessage worked.");
			var message = JSON.parse(event.data);
			this.board = message.board;
		};
	},
    play: function (position) {
      console.log('column', position, 'clicked');
	    var message = {action: 'play', position: position};
	    this.socket.send(JSON.stringify(message));
    }
  },
  created: function () {
    console.log('ready');
  	this.connectSocket();
  }
});
