
<p align="center">
<b>Apollo DSKY replica files, instructions, upgrades and all information I figure out  </b><br>
<br><br>
<br>🐦 <a href="https://twitter.com/mkmeorg">Twitter</a>
| 📺 <a href="https://www.youtube.com/mkmeorg">YouTube</a>
| 🌍 <a href="http://www.mkme.org">mkme.org</a><br>
| ☕ <a href="https://ko-fi.com/mkmeorg">Buy me a coffee! </a> |<br>
<br>
Support this project and become a patron on <a href="https://www.patreon.com/EricWilliam">Patreon</a>.<br>
Chat: <a href="https://discord.gg/j9S4Fgv">Discord</a></b>!
</p>

## AGC_DSKY_Replica

Forked From; https://github.com/ManoDaSilva/AGC_DSKY_Replica to add my own changes and mods.

I Will add laser cut keys as well as changes to the Arduino code and display usage.  
 
Posting all files here so someday I can give back to the orginal project

I will doccument the whole build in a Playlist on MKME Lab channel 

Forum thread documenting this build:

http://forum.mkme.org/viewtopic.php?f=4&t=1156
 
## Parts:

Exact parts and supplies I used

|     Component    | Source  |
| ---------- |----------------|
| Raspberry Pi 4  | https://amzn.to/3dSqno6
| Nextion Enhanced 3.5 Display | https://amzn.to/3s5FimY
| Fosa 10 PCs Mechanical Keyboard Switch Blue Switch Transparent Keyswitch  | https://amzn.to/3DTQPbo
| Grey PLA  | https://amzn.to/3GJDGna
| Black PLA | https://amzn.to/3J2qGKm
| M33mm x 40 cap screws | https://ebay.us/bAamab
| M3x16 countersunk (front plate holddown) | https://amzn.to/3urwtVX
| M3 Brass Inserts (most of DSKY) | https://amzn.to/3owhshP
|M3x5mm(L)-5.4mm(OD) brass inserts (some holes are big| https://amzn.to/35Yzz9P
| 90 degree USBC Cable | https://amzn.to/3otdNkN
| 90 degree Micro HDMI | https://amzn.to/3sq0qDf
| DSKY LED PCB KIT | TBD 


## Full video here:

TBD http://youtube.com/mkmeorg

All initial videos are included in the forum thread above- they are VLOGs of the build steps and show a lot of how to make it 

## Assembly

- Print all parts and assemble.  No way I'm typing this up :)

## Programming Arduinos

- Program the Arduino NANO with included sketch (Mine is updated/altered)

- Program Pro-Micro with included sketch (original didnt work- mine is fixed)

## Programming Pi

Here is my discussion with Ron Burkey to make this all work.  There were NUMEROUS fixes needed. Thanks Ron!  https://github.com/virtualagc/virtualagc/discussions/1170

Install Raspbian image

Enable SSH, VNC and Serial in sudo raspi-config 

``` 
sudo apt-get update

sudo apt-get upgrade 

sudo reboot

sudo apt-get install wx3.0-headers
 
sudo apt-get install liballegro4-dev 

sudo apt-get install libx11-dev

sudo apt-get install git  (already installed) 

sudo apt-get install libwxgtk3.0

sudo apt-get install libncurses5-dev 

sudo apt-get install libsdl-dev

sudo apt-get install screen

pip install pyserial

``` 

--fix-missing on anny errors you get (I had several)

``` 
git clone --depth 1 https://github.com/virtualagc/virtualagc

cd virtualagc

make clean install
``` 

Install provided test.sh on the Desktop run by bash ./test.sh

Current contents are: 

``` 
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

```

This will be reference in automatic startup below- edit this file to change what Apollo code we want to run! 

Install provided ericDSKY.py in /home/pi/virtualagc/piPeripheral/


### Raspberry Pi Safe Shutdown Button

Source:  https://magpi.raspberrypi.com/articles/off-switch-raspberry-pi

This code creates a button on GPIO 21, waits for it to be pressed, then executes the system command to power down the Raspberry Pi. GPIO 21 is nice because it’s on pin 40 of the 40-pin header and sits right next to a ground connection on pin 39. This combination makes it difficult for an off-switch to be plugged in incorrectly.

Copy shutdown.py and shutdown.sh to Desktop

By doing it this way we will have terminal windows open for both the sim and for the shutdown script- Handy for debugging and monitoring! 

You wat this script first in autostart or input will go to wrong terminal window

```
Make out shell script on Desktop exectable 

chmod 755 shutdown.sh

sudo nano /etc/xdg/lxsession/LXDE-pi/autostart

Add this line: 

@lxterminal -e /home/pi/Desktop/shutdown.sh


```


New way Eric trying so it doesnt get stucK when running the agc and another terminal for shutdown 

https://www.itechfy.com/tech/auto-run-python-program-on-raspberry-pi-startup/

sudo nano /etc/rc.local

add this line to run the python file 

sudo python /home/pi/Desktop/shutdown.py &

Rmoved the .sh from autostart- this method will be way better anyhow as it doesnt take another .sh file to run it 




shutdown.py contents:

```
#!/usr/bin/env python3

from gpiozero import Button

from signal import pause

import os, sys



offGPIO = int(sys.argv[1]) if len(sys.argv) >= 2 else 21

holdTime = int(sys.argv[2]) if len(sys.argv) >= 3 else 6



# the function called to shut down the RPI

def shutdown():

    os.system("sudo poweroff")



btn = Button(offGPIO, hold_time=holdTime)

btn.when_held = shutdown

pause()    # handle the button presses in the background

```

shutdown.sh contents:
```
#!/bin/bash
echo "Starting Safe SHutdown"
cd /home/pi/Desktop/
python3 shutdown.py



```



### Start The AGC automatically at boot

https://forums.raspberrypi.com/viewtopic.php?t=263191,

```
Make out shell script on Desktop exectable 

chmod 755 test.sh

sudo nano /etc/xdg/lxsession/LXDE-pi/autostart

Add this line: 

@lxterminal -e /home/pi/Desktop/test.sh


sudo reboot
```


### Probably not needed anymore:

sudo apt-get install python2


## Documentation

The Raspberry Pi will be using YaAGC : https://www.ibiblio.org/apollo/yaAGC.html?msclkid=bfcc1461aef711ecba1be6cac11bfc4d

All AGC docs: https://www.ibiblio.org/apollo/links2.html

DSKY explanation and instructions http://www.ibiblio.org/apollo/yaDSKY.html 

Ultimate AGC Talk Video: https://www.youtube.com/watch?v=xx7Lfh5SKUQ

Interesting AGC Talk https://www.youtube.com/watch?v=nDZKzGYVFEk 

Eldon Hall Talk Pt1 https://www.youtube.com/watch?v=PbX8OtPe3eY 

Good explanation of the AGC https://www.youtube.com/watch?v=J-5aT2zSfSA

Great overview of Apollo computers https://www.youtube.com/watch?v=YGymMMQbPbo

enable numloc https://raspberrypi.stackexchange.com/questions/38794/enable-num-lock-at-boot-raspberry-pi?msclkid=c9a10f2ab21d11eca47d554a07129494

From http://www.ibiblio.org/apollo/download.html#Raspberry_Pi_Raspbian_:
 
this was a helpful bug report https://github.com/virtualagc/virtualagc/issues/1103


## Original info 

Forked From; https://github.com/ManoDaSilva/AGC_DSKY_Replica

Mechanically accurate Apollo DSKY replica.

This project is based off the 3D models I re-created from the original MIT Instrumentation Labs drawings (those models can be found on [VirtualAGC's GitHub](https://github.com/virtualagc/virtualagc/tree/mechanical/3D-models)). 
In order to 3D print them, I slightly modified them (widened some holes for brass inserts, keyboard, etc).

A Raspberry Pi running VirtualAGC is doing the grunt work, the display is a simple LCD and the status lights are LEDs. 


More on the [Hackaday.io project page](https://hackaday.io/project/174524).

