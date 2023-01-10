Write an ARM64 function to find the largest element in an array.

Your function should implement this interface:

    int array_max(int *array, int count)

(all `int` values mean 64-bit integers)

`array` is the address of an array of 64-bit integers, and
`count` is the number of entries in the array (so the total memory
used by the array is `8 × count`).

You may assume that the array contains at least one element. Hint: 
start by assuming the first element is the largest, then scan the
rest of the array looking for anything bigger.

Note that this is a leaf function so there is no need to set up a
stack frame. You can do everything using scratch registers.

Write your code in the file `array_max.s`.
