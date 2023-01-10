import random

def IsPrimeMiller(x):
    for i in range(20):
        b = random.randrange(2, x)
        if MillerTest(x, b) == False:
            return False
    return True

def MillerTest(x, b):
    t = x-1
    s = 0
    while t % 2 == 0:
        t = t//2
        s += 1
    if pow(b, t, x) == 1:
        return True
    for i in range(s):
        if pow(b, t, x) == x-1:
            return True
        t *= 2
    return False


def main():
    getter = int(input("choose number: "))
    print(IsPrimeMiller(getter))
    
main()