def read_board(input, board):
    for i = 0; i < 81; i++
        ch = input[i]

        // was the input too short?
        if ch == 0:
            return 1

        // was it an unfilled square?
        else if ch == '.':
            board[i] = 0x8000

        // was it a filled square?
        else if ch >= '1' and ch <= '9':
            board[i] = ch - '0'

        // anything else is invalid
        else:
            return 2

    // was the input too long?
    ch = input[i]
    if ch != 0:
        return 3

    // success
    return 0

//////////////////////////////////////////////////////
1:
    while i < 81, loop
        ch = input[i]

        if  ch == 0:
            return 1

        else if ch == '.':
            board[i] - 0x8000
            i++
            goto 1b:
        
        else if ch >= '1' and ch <= '9':
            board[i] = ch - '0'
            i++
            goto 1b:

        else:
            return 2
    ch = input[i]
    if ch != 0:
        return 3
    
    return 0

/////////////////////////////////////////////////////
1:
ldrh ch [x0, i, lsl#1 ]
    while i < 81, loop
        ch = input[i]

        cmp ch, 0   //if  ch == 0:
        b.eq 2f     //branch to 2f

        b 3f    //else branch to 3
2:
mov x0, #1 //return 1
return x0
3:
        cmp ch, '.' //else if
        b.ne 4f //if ch != '.'

        strh 0x8000 [x1, i, lsl #1]    //board[i] - 0x8000
        add i, i, #1    //i++
            goto 1b:
4:
        cmp ch, #'1' //else if compare ch to 1
        b.lt 5f //if ch < 1 go to 5f
        cmp ch, #'9' //else if compare ch to 9
        b.gt 5f //if ch > 9 go to 5f
        sub ch, ch, #'0' // ch - '0'
        strh ch [x1, i, lsl #1]    //board[i] = ch
        add i, i, #1 //i++
        goto 1b
5:
mov x0, #2
return x0

    ch = input[i]
    if ch != 0:
        return 3
    
    return 0


//////////////////////////////////////////////////////////////////////
1:
ldrh ch [x0, i, lsl#1 ]    //ch = input[i]
    cmp i, 81 
    b.lt 3f //while i < 81, loop
    b 6f //else go to 6f
2:
mov x0, #1 //return 1
return x0
3:
        cmp ch, #0   //if  ch == 0:
        b.eq 2b     //branch to 2b

        cmp ch, '.' //else if
        b.ne 4f //if ch != '.'

        strh 0x8000 [x1, i, lsl #1]    //board[i] - 0x8000
        add i, i, #1    //i++
            goto 1b:
4:
        cmp ch, #'1' //else if compare ch to 1
        b.lt 5f //if ch < 1 go to 5f
        cmp ch, #'9' //else if compare ch to 9
        b.gt 5f //if ch > 9 go to 5f

        sub ch, ch, #'0' // ch - '0'
        strh ch [x1, i, lsl #1]    //board[i] = ch
        add i, i, #1 //i++
        goto 1b
5:
mov x0, #2
return x0

6:
    cmp ch, #'0' 
    b.ne 7f    //if ch != 0 go to 7f
    
    mov x0, #0 //x0 = 0
    return 0
7:
mov x0, #3
return x0

/////////////////////////////////////////////////////////////////////////////

mov x2, #0 //i = 0
mov x3, #0 //ch = 0
mov x4, 0x8000 // x4 = 0x8000

1:
ldrh w3 [x0, x2, lsl#1 ]    //ch = input[i]
    cmp x2, #81 
    b.lt 3f //while i < 81, loop
    b 6f //else go to 6f
2:
mov x0, #1 //return 1
return x0
3:
        cmp x3, #0   //if  ch == 0:
        b.eq 2b     //branch to 2b

        cmp x3, '.' //else if
        b.ne 4f //if ch != '.'

        strh w4 [x1, x2, lsl #1]    //board[i] - 0x8000
        add x2, x2, #1    //i++
            goto 1b:
4:
        cmp x3, #'1' //else if compare ch to 1
        b.lt 5f //if ch < 1 go to 5f
        cmp x3, #'9' //else if compare ch to 9
        b.gt 5f //if ch > 9 go to 5f

        sub x3, x3, #'0' // ch - '0'
        strh w3 [x1, x2, lsl #1]    //board[i] = ch
        add x2, x2, #1 //i++
        goto 1b
5:
mov x0, #2
return x0

6:
    cmp x3, #'0' 
    b.ne 7f    //if ch != 0 go to 7f
    
    mov x0, #0 //x0 = 0
    return 0
7:
mov x0, #3
return x0

//////////////////////////////////////////////////////////////////////

read_board:

        mov x2, #0      // i = 0
        mov x3, #0      // ch = 0
        mov x4, 0x8000  // x4 = 0x8000

1:
        ldrh w3 [x0, x2, lsl #1]       // load input[i] into ch
        cmp x2, #81     //compare i to 81
        b.lt 3f         //if i < 81, branch to 3f
        b 6f            //else go to 6f 
2:
        mov x0, #1
        ret
3:
        cmp x3, #'0' //compare ch to '0'
        b.eq 2b         //if ch == '0' branch to 2b

        cmp x3, #'.' //compare ch to '.'
        b.ne 4f         //if ch != '.' go to 4f

        strh w4 [x1, x2, lsl #1] // board[i] = 0x8000
        add x2, x2, #1          //i++
        b 1b            //branch to 1b

4:
        cmp x3, #'1' //compare ch to '1'
        b.lt 5f         //if ch < 1 branch to 5f
        cmp x3, #'9' //compare ch to '9'
        b.gt 5f         //if ch > 9 branch to 5f

        sub x3, x3, #'0' //ch - '0'
        strh w3 [x1, x2, lsl #1] //board[i] = ch
        add x2, x2, #1  //i++
        b 1b            //branch to 1b
5:
        mov x0, #2 //x0 = 2
        ret
6:
        cmp x3, #'0'    //compare ch to '0'
        b.ne 7f         //if ch != 0 branch to 7f

        mov x0, #0      //x0 = 0
        ret
7:
        mov x0, #3      //x0 = 3
        ret


//////////////////////////////////////////////////////////////////////

read_board:

        mov x2, #0      // i = 0
        mov x3, #0      // ch = 0
        mov x4, #0x8000  // x4 = 0x8000

1:
        ldrb w3 [x0, x2]       // load input[i] into ch
        cmp x3, #'0' //compare ch to '0'
        b.ne 2f         //if ch != '0' branch to 2f
        
        mov x0, #1
        ret
2:
        cmp x3, #'.' //compare ch to '.'
        b.ne 3f         //if ch != '.' go to 3f

        strh w4 [x1, x2, lsl #1] // board[i] = 0x8000
        add x2, x2, #1          //i++
        b 6f            //branch to 6f

4:
        cmp x3, #'1' //compare ch to '1'
        b.lt 5f         //if ch < 1 branch to 5f
        cmp x3, #'9' //compare ch to '9'
        b.gt 5f         //if ch > 9 branch to 5f

        sub x3, x3, #'0' //ch - '0'
        strh w3 [x1, x2, lsl #1] //board[i] = ch
        add x2, x2, #1  //i++
        b 6f            //branch to 6f
5:
        mov x0, #2 //x0 = 2
        ret
6:
        add x2, x2, #1  //i++
        cmp x2, #81     //compare i to 81
        b.lt 1b         //if i < 81, branch to 1b

        ldrb w3 [x0, x2]       // load input[i] into ch
        cmp x3, #'0'    //compare ch to '0'
        b.eq 7f         //if ch == 0 branch to 7f

        mov x0, #0      //x0 = 0
        ret
7:
        mov x0, #3      //x0 = 3
        ret
