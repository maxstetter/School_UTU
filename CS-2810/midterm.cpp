stoi(char *string):
    int n = 0;
    int i = 0;
1:
    string c = *string[i]
    if *string[0] == '-':
        goto 4f
4:
        if int(c) >= 0 and int(c) <=9: //if the character is between 0 and 9
            if i < size of the string //if i is less than the size
                n = n * 10 + ( c - '0' ); //n = number                    
                i++ //index increase by one
                goto 4b //start loop over
            else:
                goto 3f
        else:
            goto 3f

    else:
        goto 5f
5:
        if int(c) >= 0 and int(c) <=9: //if the character is between 0 and 9
            if i < size of the string //if i is less than the size
                n = n * 10 + ( c - '0' ); //n = number
                i++ //index increase by one
                goto 5b //start loop over
            else:
                goto 2f
        else:
            goto 2f
3:
    n = 0 - n
    return n
2:
    return n