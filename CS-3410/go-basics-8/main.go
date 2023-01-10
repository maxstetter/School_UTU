package spiralmatrix

func SpiralMatrix(size int) [][]int {
	result := [][]int{}
	for r := 0; r < size; r++ {
		result = append(result, make([]int, size))
	}
	row, col := 0, 0
	drow, dcolumn := 0, 1
	for i := 1; i <= size*size; i++ {
		result[row][col] = i
		if row+drow < 0 || size <= row+drow || col+dcolumn < 0 || size <= col+dcolumn || result[row+drow][col+dcolumn] != 0 {
			drow, dcolumn = dcolumn, -drow
		}
		row, col = row+drow, col+dcolumn
	}
	return result
}
