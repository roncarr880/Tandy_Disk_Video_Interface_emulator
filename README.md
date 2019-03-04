# Tandy_Disk_Video_Interface_emulator
Using an Arduino Mega to emulate the Disk Video Interface for a Tandy M200 laptop.

Dasm.ino - reads an image file on the SD card and outputs 8085 assembly. Disassembler.  Not part of the main project.\
DVI.DAT  - A floppy disk image file for the M100 or M200 laptops.\
Tandy_DVI.ino - The main program that emulates the DVI.\
CPM.BA - Lines in the 200-299 range show how to use the enhanced DVI commands to change directories.\
try1.asm -  An attempt to relocate the DVI image in M200 memory.  There appears to be about 1700 bytes of wasted space in the as shipped version of the M200 code.   Work in progress, successfully moved the code up 256 bytes.\
TRY2.ASM - Changed all addressing to symbolic(unless above HIMEM) and relocated up saving 1648 bytes.  Working ok so far.

Status:  Very usable now.
