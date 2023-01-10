import time
from machine import Pin, SPI
from nrf24l01 import NRF24L01

pins = {"spi": 0, "miso": 4, "mosi": 7, "sck": 6, "csn": 5, "ce": 12}

tx_address = b"\xbb\xf0\xf0\xf0\xf0"
rx_address = b"\xaa\xf0\xf0\xf0\xf0"

csn = Pin(pins["csn"], mode=Pin.OUT, value=1)
ce  = Pin(pins["ce"],  mode=Pin.OUT, value=0)
nrf = NRF24L01(SPI(pins["spi"]), csn, ce, payload_size=32)

nrf.open_tx_pipe(tx_address)
nrf.open_rx_pipe(1, rx_address)
nrf.start_listening()

print("nRF24L01 receiver; waiting for the first message...")

while True:
    if nrf.any():
        while nrf.any():
            message = nrf.recv().decode("utf-8")
            print("received:", message)
            time.sleep_ms(15)

        time.sleep_ms(500)
        nrf.stop_listening()

        try:
            reply = message.upper()
            print("sending reply:", reply)
            nrf.send(reply.encode("utf-8"))
        except OSError:
            pass
        nrf.start_listening()
