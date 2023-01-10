package wordy
import (
	"strconv"
	"strings"
	"fmt"
)

func Answer(question string) (int, bool) {
	if strings.Contains(question, "What is ") == false {
		return 0, false
	}
	if strings.Contains(question, "?") == false {
		return 0, false
	}
	ans := true
	var action string
	var previous string
	previous = "asdf"
	var result int
	trimmed := strings.TrimPrefix(question, "What is")
	trimmed = strings.TrimSuffix(trimmed, "?")
	words := strings.Fields(trimmed)
	for i, word := range words {
		fmt.Println(i, " => ", word)
		num, err := strconv.Atoi(word)
		if err != nil && word != "by" && word != "cubed" {
			action = word
			if previous == "asdf"{
				previous = word
			} else{
				if previous == word{
					result = 0
					ans = false
					break
				}
			}
		} else {
			previous = word

			if result == 0 {
				result += num
				continue
			}
			if word == "by" {
				continue
			}
			if result != 0 && action != "" {
				switch action {
				case "plus":
					result += num
				case "minus":
					result -= num
				case "multiplied":
					result *= num
				case "divided":
					result /= num
				default:
					return 0, false
				}
			}
		}
	}
	if result == 0{
		ans = false
	}
	return result, ans 
}
