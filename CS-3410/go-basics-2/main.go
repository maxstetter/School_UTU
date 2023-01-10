// Package weather provides tools to provide 
// a city with a weather forecast.
package weather

// CurrentCondition represents the current weather condition.
var CurrentCondition string
// CurrentLocation provides the current location.
var CurrentLocation string

// Forecast returns a string representing the location
// and current weather conditions.
func Forecast(city, condition string) string {
	CurrentLocation, CurrentCondition = city, condition
	return CurrentLocation + " - current weather condition: " + CurrentCondition
}
