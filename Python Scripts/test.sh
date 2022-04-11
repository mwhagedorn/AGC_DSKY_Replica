#!/bin/bash
echo "Enabling numlock"
setleds=+num
# Turn Numlock on for the TTYs:
for tty in /dev/tty[1-6]; do
    /usr/bin/setleds -D +num < "$tty";
done
echo "Starting VirtualAGC"
screen -dm bash -c "cd /home/pi/virtualagc/yaAGC/; ./yaAGC --port=19697 --core=../Colossus249/Colossus249.bin"
echo "Starting DSKY"
cd /home/pi/virtualagc/piPeripheral/
python3 ericDSKY.py
