import serial

# MSB of address routes the command to different systems the lower 3 bytes are the address in that system
# Addresses 0 to 7 channels
# Address 8 general register
# Address 9 SPI communication byte0:SPI address byte1:spi select
# Address > 9 AXI streams for filter configuration and coefficient reload.

# TODO implement AXI interfaces to filters


# MSB
# |         |    1    |    3    |
#      | channel |
channel_reg_map = {


}

class Registers:

    def __init__(self, port):
        self.port = port

    def _write_channel(self, value, address):
        pass

