#!/usr/bin/env python3
"""Send a display command to the DSKY Arduino Nano over serial.

Usage examples:

  # Set program, verb, noun and all three data rows
  python3 send_dsky.py --verb 37 --noun 00 --prog 06 --r1 +12345 --r2 -00042 --r3 +00000

  # Turn on LEDs only
  python3 send_dsky.py --uplink --gimbal

  # Print packet bytes without opening serial port
  python3 send_dsky.py --verb 37 --noun 00 --dry-run

  # Override port or baud rate
  python3 send_dsky.py --port /dev/ttyAMA0 --baud 9600 --prog 01

Finding the serial device after plugging in the Nano:
  ls /dev/ttyUSB* /dev/ttyACM*   # CH340 clones -> ttyUSB0, genuine Nano -> ttyACM0
  dmesg | tail -20                # shows assigned device name and confirmation
"""

import argparse
import sys
import serial


def _format_register(value):
    """Format a register value as 6-char string: sign + 5 digits."""
    if value is None:
        return '      '
    value = value.strip()
    if len(value) == 6 and value[0] in ('+', '-', ' '):
        return value
    try:
        n = int(value)
        return f"{'-' if n < 0 else '+'}{abs(n):05d}"
    except ValueError:
        return value[:6].ljust(6)


def build_packet(args):
    # 39-byte packet: 38 data bytes + newline
    # [0-9]   LED statuses: UPLINK, NO ATT, STANDBY, KEY REL, OPR ERR, TEMP, GIMBAL, PROG, RESTART, TRACKER
    # [10-12] ignored placeholders
    # [13]    COMP ACTY
    # [14-15] PROG, [16-17] VERB, [18-19] NOUN
    # [20-25] R1, [26-31] R2, [32-37] R3
    # [38]    newline
    buf = bytearray(39)

    leds = [args.uplink, args.no_att, args.standby, args.key_rel,
            args.opr_err, args.temp, args.gimbal, args.prog_led,
            args.restart, args.tracker]
    for i, flag in enumerate(leds):
        buf[i] = ord('1') if flag else ord('0')

    buf[10] = buf[11] = buf[12] = ord('3')  # ignored by Arduino

    buf[13] = ord('1') if args.comp_acty else ord('0')

    def two_digits(val):
        return val.zfill(2)[:2] if val else '  '

    prog = two_digits(args.prog)
    buf[14], buf[15] = ord(prog[0]), ord(prog[1])

    verb = two_digits(args.verb)
    buf[16], buf[17] = ord(verb[0]), ord(verb[1])

    noun = two_digits(args.noun)
    buf[18], buf[19] = ord(noun[0]), ord(noun[1])

    for base, val in [(20, args.r1), (26, args.r2), (32, args.r3)]:
        reg = _format_register(val)
        for i, c in enumerate(reg):
            buf[base + i] = ord(c)

    buf[38] = ord('\n')
    return bytes(buf)


def main():
    parser = argparse.ArgumentParser(description='Send a display command to the DSKY Nano')
    parser.add_argument('--port', default='/dev/ttyUSB0')
    parser.add_argument('--baud', type=int, default=9600)

    parser.add_argument('--prog', help='Program number, e.g. 06')
    parser.add_argument('--verb', help='Verb number, e.g. 37')
    parser.add_argument('--noun', help='Noun number, e.g. 00')

    parser.add_argument('--r1', help='Row 1 value, e.g. +00000 or -12345')
    parser.add_argument('--r2', help='Row 2 value')
    parser.add_argument('--r3', help='Row 3 value')

    parser.add_argument('--uplink',   action='store_true')
    parser.add_argument('--no-att',   action='store_true', dest='no_att')
    parser.add_argument('--standby',  action='store_true')
    parser.add_argument('--key-rel',  action='store_true', dest='key_rel')
    parser.add_argument('--opr-err',  action='store_true', dest='opr_err')
    parser.add_argument('--temp',     action='store_true')
    parser.add_argument('--gimbal',   action='store_true')
    parser.add_argument('--prog-led', action='store_true', dest='prog_led')
    parser.add_argument('--restart',  action='store_true')
    parser.add_argument('--tracker',  action='store_true')
    parser.add_argument('--comp-acty', action='store_true', dest='comp_acty')

    parser.add_argument('--dry-run', action='store_true', help='Print packet without sending')

    args = parser.parse_args()
    packet = build_packet(args)

    if args.dry_run:
        print(f'Packet ({len(packet)} bytes): {packet!r}')
        return

    try:
        with serial.Serial(args.port, baudrate=args.baud, timeout=1) as ser:
            ser.write(packet)
            print(f'Sent {len(packet)} bytes to {args.port}')
    except serial.SerialException as e:
        print(f'Error: {e}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
