# Tandy_Disk_Video_Interface_emulator
Using an Arduino Mega to emulate the Disk Video Interface for a Tandy M200 laptop.

Dasm.ino - reads an image file on the SD card and outputs 8085 assembly. Disassembler.  Not part of the main project.\
DVI.DAT  - A floppy disk image file for the M100 or M200 laptops.\
Tandy_DVI.ino - The main program that emulates the DVI.\
CPM.BA - Lines in the 200-299 range show how to use the enhanced DVI commands to change directories.\
NEW_BOOT, NEW_DVI - Recovering 1900 bytes of wasted space in the shipped version of the DVI code.  The video part of the DVI is not used.

Status:  Very usable now.
