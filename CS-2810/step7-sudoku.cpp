
bool changed = false; //local scratch register
int was_changed = 0; // global callee saved register

1b:

for( index = 0; index < 81; index++)
{
    count = 0
    n = 0
    elt = board[index]
    if elt & 0x8000 == 0:
        solved square so continue //breaks loop, goes to index++
    for i from 1 to 9: //inclusive
        if (elt & (1<<i)) != 0:
            count += 1
            n = i
    if count == 1:
        board[index] = n //set board position to n
        changed = true;
}

if( changed == true )
{
    calc_pencil();
    changed = false;
    was_changed = 1;
    //run loop again (goto 1b)
}
else
{
    return was_changed
}



// board will be in stack


////////////////////////////////////////////////////////////////////////////////////////////////////////
promote_pencil_singletons:

        mov     x3, #1  //1
        mov     x5, #1 //i
        //x6 = elt[board]
        mov     x7, #0  //count
        mov     x9, #0  //n     
        mov     x10, #0 //changed local scratch
        mov     x11, #0 //index


        stp     x29, x30, [sp, #-16]
        mov     x29, sp
        sub     sp, sp, #32
        str     x19, [x29, #-32]
        str     x20, [x29, #-24]
        str     x21, [x29, #-16]
        str     x22, [x29, #-8]

        mov     x20, x0 //board
        mov     x19, x1 //table
        mov     x21, #0 //was_changed global

1:
        cmp     x11, #81
        b.ge    3f

        mov     x5, #1 //i = 1  
        mov     x7, #0 //count = 0
        mov     x9, #0 //n = 0
        //might have to use x0 instead of x20
        ldrh    w6, [x20, x11, lsl#1] //elt = board[index]
        tst     x6, #0x8000
        b.ne    2f


        add     x11, x11, #1 //index++
        b       1b

2:
        //cmp   x5, #1
        //b.lt  4f
        cmp     x5, #9
        b.gt    4f

        //need to increment i
        //if (elt & 1<<i)) == 0
        lsl     x4, x3, x5
        tst     x4, x6
        b.eq    6f
        mov     x9, x5
6:
        add     x7, x7, #1
        add     x5, x5, #1 //i++
        b       2b
7:
        add     x11, x11, #1 //index ++ 
        b       1b
4:
        cmp     x7, #1  //if (count != 1)
        b.ne    7b
        strh    w9, [x20, x11, lsl#1] //board[index] = n
        mov     x10, #1 //changed = true        
        add     x11, x11, #1 //index ++ 
        b       1b
3:
        cmp     x10, #1 //if changed != true
        b.ne    5f
        mov     x0, x20 //x0 = board
        mov     x1, x19 //x1 = table
        bl      calc_pencil
        mov     x10, #0 //changed = false
        mov     x21, #1 //was_changed = true
        mov     x11, #0 //index = 0
        b       1b
5:
        mov     x0, x21 //x0 = was_changed

        ldr     x19, [x29, #-32]
        ldr     x20, [x29, #-24]
        ldr     x21, [x29, #-16]
        ldr     x22, [x29, #-8]
        add     sp, sp, #32
        ldp     x29, x30, [sp], 16

        ret
