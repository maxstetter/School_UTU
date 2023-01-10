package phonenumber

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
)

type phoneNumber struct {
	area       string
	exchange   string
	subscriber string
}

func wholeNumber(number phoneNumber) string {
	answer := number.area + number.exchange + number.subscriber
	fmt.Println("wholNumber: ", answer)
	return answer
}

func Number(phoneNumber string) (string, error) {
	//var err error
	phoneNumber = strings.Replace(phoneNumber, "+", "", -1)
	phoneNumber = strings.Replace(phoneNumber, "-", "", -1)
	phoneNumber = strings.Replace(phoneNumber, ".", "", -1)
	phoneNumber = strings.Replace(phoneNumber, "(", "", -1)
	phoneNumber = strings.Replace(phoneNumber, ")", "", -1)
	phoneNumber = strings.ReplaceAll(phoneNumber, " ", "")
	_, err := strconv.Atoi(phoneNumber)
	if err != nil {
		err = errors.New("invalid characters")
	}

	fmt.Println("PHONE TEST: ", phoneNumber)
	if len(phoneNumber) > 10 && string(phoneNumber[0]) == "1" {
		phoneNumber = phoneNumber[1:]
	}
	if len(phoneNumber) > 10 && string(phoneNumber[0]) != "1" {
		err = errors.New("Too many numbers.")
	}
	if len(phoneNumber) < 10 {
		err = errors.New("Not enough numbers.")
	}

	area := string(phoneNumber[:3])
	exchange := string(phoneNumber[3:6])
	subscriber := string(phoneNumber[6:])
	fmt.Println("area: :", area)
	fmt.Println("exchange: :", exchange)
	fmt.Println("subscriber: :", subscriber)

	if string(area[0]) == "1" || string(exchange[0]) == "1" || string(area[0]) == "0" || string(exchange[0]) == "0" {
		err = errors.New("invalid first digit.")
	}
	return phoneNumber, err
}

func AreaCode(phoneNumber string) (string, error) {
	phoneNumber, err := Number(phoneNumber)
	area := string(phoneNumber[:3])
	if err != nil {
		err = errors.New("Number(phoneNumber) failed.")
	}
	return area, err
}

func Format(phoneNumber string) (string, error) {
	phoneNumber, err := Number(phoneNumber)
	if err != nil {
		err = errors.New("Number(phoneNumber) failed.")
	}
	area := string(phoneNumber[:3])
	exchange := string(phoneNumber[3:6])
	subscriber := string(phoneNumber[6:])
	formatted := fmt.Sprintf("(%s) %s-%s", area, exchange, subscriber)
	return formatted, err
}
