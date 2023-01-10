from machine import Pin, Timer
import time

lazer = Pin(2,Pin.OUT)

#timer.init(freq=2.5, mode=Timer.PERIODIC, callback=blink)

# x = 0.05
# y = 0.15
# z = 0.05

# GLOBALS
NUMBERS = []
MESSAGE = "4087526560"
BOOLMESSAGE = True


def loop():
    global BOOLMESSAGE
    x = 0.05
    y = 0.15
    z = 0.05
    for num in NUMBERS:
        time.sleep(y)
        for _ in range(num):
            time.sleep(x)
            lazer.value(1)
            time.sleep(x)
            lazer.value(0)
        print("Num: ", num)
    time.sleep(z)
    BOOLMESSAGE = False
    
def init():
    global NUMBERS, MESSAGE
    for i in MESSAGE:
        if i == "0":
            NUMBERS.append(int(10))
        else:
            NUMBERS.append(int(i))


def blinkLazer():
    time.sleep(0.5)
    lazer.value(1)
    time.sleep(0.5)
    lazer.value(0)
    
if __name__ == '__main__':
    init()
    while BOOLMESSAGE:
        loop()