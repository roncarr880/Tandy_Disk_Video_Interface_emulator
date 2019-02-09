# Tandy_Disk_Video_Interface_emulator
Using an Arduino Mega to emulate the Disk Video Interface for a Tandy M200 laptop.


Dasm.ino - reads an image file on the SD card and outputs 8085 assembly. Disassembler.  Not part of the main project.\
DVI.DAT  - A disk image file for the M100 or M200 laptops.\
Tandy_DVI.ino - The main program that emulates the DVI.

Status:  It boots and reads files from the image.  The command level is lower level than I had hoped.\
  It reads and writes sectors, updates the directory track and FAT. So it limits itself to 180k of the 8 gig\
  flash card.
