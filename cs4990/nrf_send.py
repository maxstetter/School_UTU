import time
from machine import Pin, SPI
from nrf24l01 import NRF24L01

pins = {"spi": 0, "miso": 4, "mosi": 7, "sck": 6, "csn": 5, "ce": 12}

tx_address = b"\xaa\xf0\xf0\xf0\xf0"
rx_address = b"\xbb\xf0\xf0\xf0\xf0"

print("NRF24L01 transmitter")

csn = Pin(pins["csn"], mode=Pin.OUT, value=1)
ce  = Pin(pins["ce"],  mode=Pin.OUT, value=0)
nrf = NRF24L01(SPI(pins["spi"]), csn, ce, payload_size=32)

nrf.open_tx_pipe(tx_address)
nrf.open_rx_pipe(1, rx_address)
nrf.start_listening()

counter = 0
while True:
    nrf.stop_listening()
    
    counter += 1
    message = "hello " + str(counter)
    print("sending:", message)
    
    try:
        nrf.send(message.encode("utf-8"))
    except OSError:
        pass

    nrf.start_listening()

    t = time.ticks_ms()
    timeout = False
    while not nrf.any() and not timeout:
        if time.ticks_ms() - t > 1000:
            timeout = True

    if timeout:
        print("no response received.")
    else:
        response = nrf.recv().decode("utf-8")
        print ("received response:", response)

    time.sleep_ms(1000)