package hamming

import (
	"errors"
)

func Distance(a, b string) (int, error) {
	hamming := 0
	var err error
	if len(a) != len(b) {
		err = errors.New("Invalid Entries.")
		return 0, err
	} else {
		for i := 0; i < len(a); i++ {
			if a[i] != b[i] {
				hamming += 1
			}
		}
	}
	return hamming, err
}
