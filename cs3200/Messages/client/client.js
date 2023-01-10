var carNames = [];
var saveButton = document.querySelector("#car-button");

saveButton.onclick = function() 
{
	var newCarInput = document.querySelector("#car-box");
	//need to change create Restaurant on server to my own function.
	createCarOnServer(newCarInput.value);	
};

function createCarOnServer(carName)
{
	var data = "name=" + encodeURIComponent(carName);
	fetch("http://localhost:8080/cars",
	{ 
		//request options go here: method, header(s), body.
		method: "POST",
		body: data,
		headers: 
		{
			//headers go here
			"Content-Type": "application/x-www-form-urlencoded"
		}
		
	}).then(function(response)
	{
		//response code goes here
		//TODO: refresh the data by calling loadCarsFromServer()
		loadCarsFromServer();
	});
}

function loadCarsFromServer()
{
	fetch("http://localhost:8080/cars").then(function (response)
	{
		response.json().then(function (dataFromServer)
		{
			carNames = dataFromServer;		
			var carNameList = document.querySelector("#car-list");
			carNameList.innerHTML = "";	
				// TODO: use a loop to display all of the data into the DOM
				//PYTHON: for place in lunchPlaces.
				//forEach() executes once per item in the list.
			carNames.forEach(function (car) 
			{
				console.log("one time through the loop:", car );
				var carNameItem = document.createElement("li");
				carNameItem.innerHTML = car;
				carNameList.appendChild(carNameItem);	
			});
		});
	});
}

//when the page loads:
loadCarsFromServer();
