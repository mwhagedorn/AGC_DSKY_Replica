Forked from https://github.com/r1cebank/AGC_DSKY_Replica to add my own changes and mods.

<p align="center">
<b>Apollo DSKY replica files, instructions, upgrades and all information I figure out  </b><br>
<br><br>
<br>🐦 <a href="https://twitter.com/mkmeorg">Twitter</a>
| 📺 <a href="https://www.youtube.com/mkmeorg">YouTube</a>
| 🌍 <a href="http://www.mkme.org">mkme.org</a><br>
<br>
Support this project and become a patron on <a href="https://www.patreon.com/EricWilliam">Patreon</a>.<br>
Chat: <a href="https://discord.gg/j9S4Fgv">Discord</a></b>!
</p>

## AGC_DSKY_Replica

Forked From; https://github.com/r1cebank/AGC_DSKY_Replica

Mechanically accurate Apollo DSKY replica.

This project is based off the 3D models I re-created from the original MIT Instrumentation Labs drawings (those models can be found on [VirtualAGC's GitHub](https://github.com/virtualagc/virtualagc/tree/mechanical/3D-models)). 
In order to 3D print them, I slightly modified them (widened some holes for brass inserts, keyboard, etc).

A Raspberry Pi running VirtualAGC is doing the grunt work, the display is a simple LCD and the status lights are LEDs. 


More on the [Hackaday.io project page](https://hackaday.io/project/174524).

Will add laser cut keys as well as changes to the Arduino code and display usage.  
 
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

## Assembly

- Print all parts 

## Programming Arduinos

- Program the Arduino NANO with included sketch
- Program Pro-Micro with included sketch

## Programming Pi

Install Raspbian image
Enable SSH, VNC and Serial 
in terminal
sudo apt-get update
sudo apt-get upgrade 
reboot

From http://www.ibiblio.org/apollo/download.html#Raspberry_Pi_Raspbian_:
 (this was a helpful bug report https://github.com/virtualagc/virtualagc/issues/1103
FYI the Pi will be using YaAGC : https://www.ibiblio.org/apollo/yaAGC.html?msclkid=bfcc1461aef711ecba1be6cac11bfc4d

sudo apt-get install wx3.0-headers 
sudo apt-get install liballegro4-dev 
sudo apt-get install git  (already installed) 
sudo apt-get install libwxgtk3
sudo apt-get install libncurses5-dev 
sudo apt-get install libsdl-dev

git clone --depth 1 https://github.com/virtualagc/virtualagc

cd virtualagc
make clean install

sudo apt-get install python2
pip install serial

/usr/lib/python2.7


Put the python file in it : 
cd /home/pi/virtualagc/piPeripheral/

Still cant run shell from desktop this fixed:
https://stackoverflow.com/questions/14219092/bash-script-and-bin-bashm-bad-interpreter-no-such-file-or-directory


Now python says serial failed:
pip install serial

sudo su
sudo apt-get remove python3






## Documentation

All AGC docs: https://www.ibiblio.org/apollo/links2.html

Ultimate AGC Talk Video: https://www.youtube.com/watch?v=xx7Lfh5SKUQ

Interesting AGC Talk https://www.youtube.com/watch?v=nDZKzGYVFEk 

Eldon Hall Talk Pt1 https://www.youtube.com/watch?v=PbX8OtPe3eY 



------------------------------------------------------------------------------------------------


Forked From; https://github.com/r1cebank/AGC_DSKY_Replica

Mechanically accurate Apollo DSKY replica.

This project is based off the 3D models I re-created from the original MIT Instrumentation Labs drawings (those models can be found on [VirtualAGC's GitHub](https://github.com/virtualagc/virtualagc/tree/mechanical/3D-models)). 
In order to 3D print them, I slightly modified them (widened some holes for brass inserts, keyboard, etc).

A Raspberry Pi running VirtualAGC is doing the grunt work, the display is a simple LCD and the status lights are LEDs. 


More on the [Hackaday.io project page](https://hackaday.io/project/174524).

