package romannumerals

import (
	"errors"
)

func ToRomanNumeral(input int) (string, error) {
	var roman = ""
	if input <= 0 || input > 3000 {
		return roman, errors.New("Too Large or Small")
	}
	for input > 0 {
		if input-1000 >= 0 {
			input -= 1000
			roman += "M"
			continue
		} else if input-900 >= 0 {
			input -= 900
			roman += "CM"
			continue
		} else if input-500 >= 0 {
			input -= 500
			roman += "D"
			continue
		} else if input-400 >= 0 {
			input -= 400
			roman += "CD"
			continue
		} else if input-100 >= 0 {
			input -= 100
			roman += "C"
			continue
		} else if input-90 >= 0 {
			input -= 90
			roman += "XC"
			continue
		} else if input-50 >= 0 {
			input -= 50
			roman += "L"
			continue
		} else if input-40 >= 0 {
			input -= 40
			roman += "XL"
			continue
		} else if input-10 >= 0 {
			input -= 10
			roman += "X"
			continue
		} else if input-9 >= 0 {
			input -= 9
			roman += "IX"
			continue
		} else if input-5 >= 0 {
			input -= 5
			roman += "V"
			continue
		} else if input-4 >= 0 {
			input -= 4
			roman += "IV"
			continue
		} else {
			input -= 1
			roman += "I"
			continue
		}
	}
	//roman = strings.TrimSuffix(roman, "IIII")
	//roman = strings.Replace(roman, "IIII", "IV" ,1)
	//roman = strings.Replace(roman, "VIV", "IX" ,1)
	//roman = strings.Replace(roman, "XXXX", "XL" ,1)
	//roman = strings.Replace(roman, "CCCC", "CD" ,1)
	return roman, nil
}
