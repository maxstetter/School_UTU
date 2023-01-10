from machine import Pin, Timer
import random
import time


#GLOBALS
difficulty = 3
sequence = []
iteration = 0


#timer.init(freq=2.5, mode=Timer.PERIODIC, callback=blink)
timer = Timer()


# Collection of leds.
leds = [
    Pin(2, Pin.OUT),
    Pin(4, Pin.OUT),
    Pin(6,Pin.OUT),
    Pin(8,Pin.OUT),
    Pin(10,Pin.OUT),
]

# Collection of buttons.
buttons = [
    Pin(3, Pin.IN, Pin.PULL_UP),
    Pin(5, Pin.IN, Pin.PULL_UP),
    Pin(7,Pin.IN, Pin.PULL_UP),
    Pin(9,Pin.IN, Pin.PULL_UP),
    Pin(11,Pin.IN, Pin.PULL_UP),
]


# Populates GLOBAL sequence with specified count.
def randomize(sequence, count):
    for i in range(count):
        sequence.append(random.randrange(0,5))

# Blinks leds based on timer.
def blink(timer):
    led.toggle()

# Flash the GLOBAL sequence
def flash(sequence):
    for i in sequence:
        leds[i].value(1)
        time.sleep(0.3)
        leds[i].value(0)
        time.sleep(0.2)

# Wait for Button inputs, return index of button pushed.
def waitForButton(timeout=5000):
    now = time.ticks_ms()
    while time.ticks_ms() - now < timeout:
        for i in range(len(buttons)):
            if buttons[i].value() == 0:
                leds[i].value(1)
                while buttons[i].value == 0:
                    pass
                time.sleep(0.2)
                leds[i].value(0)
                return i
    return -1

# Flash and print game is over.
def gameOver():
    print("Game Over")
    flashAll(3, 0.2)

# Initialize GLOBAL sequence with randomize: flash sequence.
def init():
    randomize(sequence, 3)
    print(sequence)
    flashRYG()
    flash(sequence)
    #waitForButton(3600000)
    pass

# Flash all leds depending on rounds and duration.
def flashAll(rounds, duration):
    for k in range(rounds):
        #time.sleep(duration)
        leds[0].value(1)
        leds[1].value(1)
        leds[2].value(1)
        leds[3].value(1)
        leds[4].value(1)
        time.sleep(duration)
        leds[0].value(0)
        leds[1].value(0)
        leds[2].value(0)
        leds[3].value(0)
        leds[4].value(0)
        time.sleep(duration)

# Flash all individually depending on rounds and duration.
def flashLoad(rounds, duration):
    for i in range(rounds):
        for k in range(len(leds)):
            time.sleep(duration)
            leds[k].value(1)
            time.sleep(duration)
            leds[k].value(0)
    flashAll(1, 1)


# Progressivley turn LEDS on. Depending on rounds and duration.
def flashProg(rounds, duration):
    for i in range(rounds):
        for k in range(len(leds)):
            leds[k].value(1)
            time.sleep(duration)
    flashAll(1, 1)

# Flash Red Yellow Green: (Ready Set Go)
def flashRYG():
    RedYellowGreen = [2, 1, 0]
    for i in range(len(RedYellowGreen)):
        time.sleep(0.1)
        leds[RedYellowGreen[i]].value(1)
        time.sleep(1)
        leds[RedYellowGreen[i]].value(0)
    flashAll(1, 1)

# Main loop includes Simon says logic
def loop():
    global iteration
    global sequence
    global difficulty
    index = waitForButton()

    if index == sequence[iteration]:
        iteration = iteration + 1
    elif index is not sequence[iteration]:
        gameOver()
    # Proceed to new round if successful.
    if iteration == len(sequence):
        print("Next Round.")
        print("Difficulty: ", difficulty)
        sequence = []
        flashProg(1, 0.1)
        difficulty += 1
        randomize(sequence, difficulty)
        print(sequence)
        flash(sequence)
        iteration = 0


if __name__ == '__main__':
    init()
    while True:
        loop()