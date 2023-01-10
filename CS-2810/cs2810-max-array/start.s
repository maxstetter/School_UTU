                .global _start
                .equ    sys_exit, 93

                .text
_start:
                // test the function with the array below
                // change these lines to test with other values
                adr     x0, test_array
                mov     x1, #test_len
                bl      array_max

                // call the exit system call, using the return
                // value of array_max (in x0) as the exit status code
                // use "make run" to run this code and it will
                // report the exit status code as an error number
                mov     x8, #sys_exit
                svc     #0

                .data
                // using .8byte, each element will be a 64-bit value
test_array:     .8byte  -2, 13, 16, -24, 5, 7, 11, 10, 6, 13
                // this computes the number of elements
                // . represents the current memory address, so by
                // computing (. - test_array) we get the number of bytes
                // used in test_array. Dividing by 8 gives the number
                // of elements
                .equ    test_len, (. - test_array)/8
