# Tandy_Disk_Video_Interface_emulator
Using an Arduino Mega to emulate the Disk Video Interface for a Tandy M200 laptop.


Dasm.ino - reads an image file on the SD card and outputs 8085 assembly. Disassembler.  Not part of the main project.\
DVI.DAT  - A disk image file for the M100 or M200 laptops.\
Tandy_DVI.ino - The main program that emulates the DVI.

Status:  It boots and reads sectors from the image.  It reads and writes files to/from the SD card.\
Files can be deleted( copies are saved ).

Need:  Need a chdir command and remove the hardcoding of the directory path.  There is an issue with large sequential files\
that cross a cluster boundary.  The FAT is not updated before the data tracks are written.  It may remain with a temporary fix.\
The better solution I think would be to write orphan cluster files and concatenate files after the FAT is updated.
