# Tandy_Disk_Video_Interface_emulator
Using an Arduino Mega to emulate the Disk Video Interface for a Tandy M200 laptop.

Dasm.ino - reads an image file on the SD card and outputs 8085 assembly. Disassembler.  Not part of the main project.\
DVI.DAT  - A disk image file for the M100 or M200 laptops.\
Tandy_DVI.ino - The main program that emulates the DVI.

Status:  It boots and reads sectors from the image.  It reads and writes files to/from the SD card.\
Files can be deleted or renamed.  Sequential data files can be read and written.

Todo:  Need a chdir command and remove the hardcoding of the directory path.
