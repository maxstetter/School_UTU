package encode

import (
	"strconv"
	"strings"
	"unicode"
)

func RunLengthEncode(input string) string {
	var encoded string
	for len(input) > 0 {
		letter := input[0]
		inputlen := len(input)
		input = strings.TrimLeft(input, string(letter))
		if n := inputlen - len(input); n > 1 {
			encoded += strconv.Itoa(n)
		}
		encoded += string(letter)
	}
	return encoded
}

func RunLengthDecode(input string) string {
	var decode string
	for len(input) > 0 {
		i := strings.IndexFunc(input, func(r rune) bool {
			return !unicode.IsDigit(r)
		})
		n := 1
		if i != 0 {
			n, _ = strconv.Atoi(input[:i])
		}
		decode += strings.Repeat(string(input[i]), n)
		input = input[i+1:]
	}
	return decode
}
