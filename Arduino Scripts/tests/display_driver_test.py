# This is a sample Python script.

# Press ⇧F10 to execute it or replace it with your code.
# Press Double ⇧ to search everywhere for classes, files, tool windows, actions, and settings.

import serial
from time import sleep

# this is the usb serial port the nano is listenint on
SERIAL_PORT = "/dev/tty.usbserial-230"
# Serial String with the following structure:
#   -Position 0: UPLINK
#   -Position 1: ATT
#   -Position 2: STBY
#   -Position 3: KEY
#   -Position 4: ERR
#   -Position 5: TEMP
#   -Position 6: GIMBAL
#   -Position 7: PROG
#   -Position 8: RESTART
#   -Position 9: TRACKER
#   -Position 10: ALT
#   -Position 11: VEL
#   -Position 12: PLACEHOLDER LED
#   -Position 13: COMP ACTY
#   -Position 14 and 15: PROGRAM Value
#   -Position 16 and 17: VERB Value
#   -Position 18 and 19: NOUN Value
#   -Position 20, 21, 22, 23, 24, 25: R1 Value
#   -Position 26, 27, 28, 29, 30, 31: R2 Value
#   -Position 32, 33, 34, 35, 36, 37: R3 Value


VERB1 = "8"
VERB2 = "8"
NOUN1 = "9"
NOUN2 = "9"
PROG1 = "7"
PROG2 = "7"
R1_1 = " "
R1_2 = "1"
R1_3 = "0"
R1_4 = "0"
R1_5 = "0"
R1_6 = "0"
R2_1 = " "
R2_2 = "1"
R2_3 = "2"
R2_4 = "3"
R2_5 = "0"
R2_6 = "0"
R3_1 = " "
R3_2 = "1"
R3_3 = "2"
R3_4 = "4"
R3_5 = "0"
R3_6 = "0"
oldtosend = bytearray(b'33333333333333234567+90123+12451+12888\n')

def run_display_test():
    ser = serial.Serial(SERIAL_PORT, baudrate=9600,timeout=1.5)
    sleep(3)
    ser.reset_output_buffer()
    ser.reset_input_buffer()
    write_command(ser)


def write_command(ser):
    tosend = bytearray(b'33333333333333234567+90123+12451+12888\n')
    tosend[14] = ord(PROG1)
    tosend[15] = ord(PROG2)
    tosend[16] = ord(VERB1)
    tosend[17] = ord(VERB2)
    tosend[18] = ord(NOUN1)
    tosend[19] = ord(NOUN2)
    tosend[20] = ord(R1_1)
    tosend[21] = ord(R1_2)
    tosend[22] = ord(R1_3)
    tosend[23] = ord(R1_4)
    tosend[24] = ord(R1_5)
    tosend[25] = ord(R1_6)
    tosend[26] = ord(R2_1)
    tosend[27] = ord(R2_2)
    tosend[28] = ord(R2_3)
    tosend[29] = ord(R2_4)
    tosend[30] = ord(R2_5)
    tosend[31] = ord(R2_6)
    tosend[32] = ord(R3_1)
    tosend[33] = ord(R3_2)
    tosend[34] = ord(R3_3)
    tosend[35] = ord(R3_4)
    tosend[36] = ord(R3_5)
    tosend[37] = ord(R3_6)
    print("connected to: " + ser.portstr)
    written = ser.write(bytes(tosend))
    print(bytes(tosend))
    ser.flush()
    print(written)
    print(ser.out_waiting)
    print('LAMPS UPDATED')
    count = 1

    while True:
        for line in ser.read():
            print(str(count) + str(': ') + chr(line))
            count = count + 1

    ser.close()
# Press the green button in the gutter to run the script.
if __name__ == '__main__':  run_display_test()

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
