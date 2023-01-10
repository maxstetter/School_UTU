for(y = 0; y < 9; y = y + 1)
{
    for(x = 0; x < 9; x = x + 1)
    {
        int index, elt;

        index = (y*9) + x;
        
        elt = board[index];

        if(elt & 0x8000 != 0):
            board[index] = #0b1000001111111110
    }
}
///////////////////

        mov     x1, #0 //index
        mov     x2, #0 //elt
        mov     x3, #0b1000001111111110 //special value

        
1:
        cmp     x1, #81
        b.gt    3f


        ldrh    w2, [x0, x1, lsl#1]; //elt = board[index] 

        and     x4, x2, #0x8000 //elt & 0x8000

        cbnz     x4, 2f // if x6 != 0

        add     x1, x1, #1

        goto 1b
2:
        strh    x3, [x0, x1, lsl#1]; //board[index] = #0b1000001111111110

        add     x1, x1, #1

        goto 1b
        
3:
        ret     

///////////////////

mov     x1, #0 //group
mov     x2, #0 //index
mov     x3, #0 //set
mov     x4, #0 //tempindex
mov     x5, #0 //elt

ldrb    w4, [x1, x2]
ldrh    w5, [x0, x4, lsl#1];

//////////////////////////////   calc_pencil_gets_used   /////////////////////////////////////////////////

    used = 0
    for (i = 0; i < 9; i++)
        index = group[i]
        elt = board[index]
        if (elt & 0x8000 == 0)
            used = used | 1<<elt
    return used

////////////////////////////
calc_pencil_get_used:
        mov     x2, #0 //index
        mov     x3, #0 //used
        mov     x4, #0 //tempindex
        mov     x5, #0 //elt
        mov     x6, #0 //i
        mov     x8, #1 // 1

1:

        ldrb    w4, [x1, x2] //load into tempindex
        ldrh    w5, [x0, x4, lsl#1] //load into elt

        tst     x5, #0x8000
        b.ne 2f

        lsl     x7, x8, x5 //used = used | 1<<elt
        orr     x3, x3, x7

2:

        add     x2, x2, #1

3:
        cmp     x2, #9
        b.lt    1b
        mov     x0, x3
        ret;
////////////////////// calc pencil clear used: ////////////////////////

calc_pencil_clear_used:
        mov     x3, #0 //index
        mov     x4, #0 //tempindex
        mov     x5, #0 //elt

1:

        ldrb    w4, [x1, x3] //load into tempindex
        ldrh    w5, [x0, x4, lsl#1] //load into elt

        tst     x5, #0x8000
        b.eq 2f
        
        bic     x5, x5, x2
2:
        strh    w5, [x0, x4, lsl#1]
        add     x3, x3, #1

3:
        cmp     x3, #9
        b.lt    1b
        ret
;
////////////////////////////// calc_pencil ////////////////////////////

calc_pencil:

        //x0 is board
        //x1 is group
        mov     x11, #0 //index
        stp     x29, x30, [sp, #-16]!
        mov     x29, sp
        sub     sp, sp, #32
        str     x19, [x29, #-32]
        str     x20, [x29, #-24]
        str     x21, [x29, #-16]
        str     x22, [x29, #-8]
        mov     x20, x0
        mov     x19, x1
        
1:
        mov     x0, x20 
        bl reset_pencils
        b 3f
2:
        mov     x1, x19
        add     x1, x1, x11
        mov     x0, x20
        bl      calc_pencil_get_used
        mov     x21, x0
        mov     x0, x20
        mov     x1, x19
        mov     x2, x21
        add     x1, x1, x11
        bl      calc_pencil_clear_used
        mov     x20, x0
        add     x11, x11, #9
3:
        cmp     x11, #243
        b.lt    2b

4:
        ldr     x19, [x29, #-32]
        ldr     x20, [x29, #-24]
        ldr     x21, [x29, #-16]
        ldr     x22, [x29, #-8]
        add     sp, sp, #32
        ldp     x29, x30, [sp], 16
        ret



