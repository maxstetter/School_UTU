package diamond

import (
	"bytes"
	"errors"
)

func Gen(char byte) (string, error) {
	if char < 'A' || char > 'Z' {
		return "", errors.New("invalid letter.")
	}
	x := int(char - 'A')
	rows := make([][]byte, 2*x+1)
	for i, j := x, 0; i >= 0; i, j = i-1, j+1 {
		line := bytes.Repeat([]byte{' '}, 2*x+2)
		line[2*x+1] = '\n'
		b := 'A' + byte(j)
		line[i], line[2*x-i] = b, b
		rows[j], rows[2*x-j] = line, line
	}
	return string(bytes.Join(rows, nil)), nil
}
