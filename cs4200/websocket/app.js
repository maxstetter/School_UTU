console.log('hi')

var socket = new WebSocket('ws://wsecho.herokuapp.com/')

var button = document.querySelector("button");
button.onclick = function () {
	socket.send("yeah boi");
};

socket.onmessage = function (event) {
	var newDiv = document.createElement("div");
	newDiv.innerHTML = event.data;
	document.body.appendChild(newDiv);
};
