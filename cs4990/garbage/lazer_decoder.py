from machine import Pin
import time

phone = Pin(3, Pin.IN, Pin.PULL_UP)


BUMP_VALUE = 0.005
PHONE_NUMBER = []

uptime = 0
count = 0

def printSensorValue():
    print("sensor.value(): ", phone.value())

def printPhoneNumber():
    global PHONE_NUMBER
    number = "number: "
    for i in range(len(PHONE_NUMBER)):
        gotnumber = str(PHONE_NUMBER[i])
        if gotnumber == "10":
            gotnumber = "0"
        number = number + gotnumber
    print(number)

def waitForSignal(timeout):
    now = time.ticks_ms()
    while time.ticks_ms() - now < timeout:
        time.sleep(BUMP_VALUE)
        if phone.value() == 0:
            print("signal start")
            uptime = time.ticks_ms() - now
            while phone.value() == 0:
                pass
            time.sleep(BUMP_VALUE)
            return uptime
    #printPhoneNumber()
    return -1


def evaluateTime(uptime):
    global count, PHONE_NUMBER
    if uptime == -1:
        if count > 0:
            PHONE_NUMBER.append(count)
            count = 0
        print("-1 phone number: ", PHONE_NUMBER)
        PHONE_NUMBER = []
    elif uptime < 500 or count == 0:
        print("uptime: ", uptime)
        count += 1
        print("count: ", count)
        #PHONE_NUMBER.append(count)
        print("PHONE_NUMBER: ", PHONE_NUMBER)
    else:
        PHONE_NUMBER.append(count)
        count = 1
        print(PHONE_NUMBER)


def init():
    global count, PHONE_NUMBER
    print("initialized")
    count = 0
    PHONE_NUMBER = []
    

def loop():
    global count, PHONE_NUMBER
    now = time.ticks_ms()
    uptime = waitForSignal(5000)
    if uptime == -1:
        if count > 0:
            PHONE_NUMBER.append(count)
            count = 0
        printPhoneNumber()
        PHONE_NUMBER = []
    elif uptime < 70 or count == 0:
        #print("uptime: ", uptime)
        count += 1
        print("count: ", count)
        #PHONE_NUMBER.append(count)
        #print("PHONE_NUMBER: ", PHONE_NUMBER)
    else:
        PHONE_NUMBER.append(count)
        count = 1
    print("number: ", PHONE_NUMBER)

if __name__ == '__main__':
    init()
    while True:
        #printSensorValue()
        #print("begin loop")
        loop()