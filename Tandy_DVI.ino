/************
 * Tandy DVI
 *   Mega 2560, proto board with 82C55 interface, and a SD card board.
 *   
 *   1st test, just want the Tandy M200 to boot the disk img
 */

#define OBFA 30
#define ACKA 31
#define IBFA 32
#define STBA 33

#include <SPI.h>
#include "SdFat.h"
#include "sdios.h"
const uint8_t chipSelect = 4;

SdFat sd;
SdFile file;

ArduinoOutStream cout(Serial);

char cinBuf[40];   // Buffer for Serial input.
ArduinoInStream cin(Serial, cinBuf, sizeof(cinBuf));  // Create a serial input stream.

#define error(msg) sd.errorHalt(F(msg))  // Error messages stored in flash.

void setup() {
   Serial.begin(9600);

   /* Port A, bidirectional port of the 82C55 */
   pinMode(22,INPUT);   // set to input for starters
   pinMode(23,INPUT);
   pinMode(24,INPUT);
   pinMode(25,INPUT);
   pinMode(26,INPUT);
   pinMode(27,INPUT);
   pinMode(28,INPUT);
   pinMode(29,INPUT);

   /* Port B, the command port on upper nibble */
   pinMode(10,INPUT);
   pinMode(11,INPUT);
   pinMode(12,INPUT);
   pinMode(13,INPUT);

   /* Port C, the handshake lines */
   digitalWrite(5,HIGH);   // C0 - not ready yet
   pinMode(5,OUTPUT);     // interface enable bit
   pinMode(30,INPUT);     // OBFA, low when data is available on A port
   digitalWrite(31,HIGH); 
   pinMode(31,OUTPUT);    // ACKA, Low to ACK data and read it on the A port
   pinMode(32,INPUT);     // IBFA, Buffer full, wait for low before writing new data
   digitalWrite(33,HIGH);
   pinMode(33,OUTPUT);    // STBA, Write low to latch output data
   // C3 intra unused, C1,C2 are wired to ground via resistor

   if (!sd.begin(chipSelect, SD_SCK_MHZ(8))) {
      sd.initErrorHalt();
   }

   sd.chdir("M200ROOT");
   digitalWrite(5,LOW);   // ready, Tandy reads 000 on the C0,C1,C2 bits
   // !!! maybe should wire reset on this side and release it here

}

void loop() {
unsigned char command;

  if( digitalRead(OBFA) == 0 ){      // something was sent to the A port
    command = PINB >> 4;             // B port will tell us what to do with it
    switch(command){                 // command dispatch
       case 0:   break;              // CRT data write
       case 1:   break;              // CRT data read
       case 2:   disk_data();       break;  // should be a file open for write ?
       case 3:   disk_command();    break;
       case 0xc: ctrl_break();      break;
       default:  unknown_dispatch(command); break;    // close all and abort ? 
    }      
  }
  delay(1);
}

void ctrl_break(){   // control break was pressed ?
  
}

void disk_data(){
}

void disk_command(){
unsigned char count;
unsigned char disk;
unsigned char track;
unsigned char sector;
unsigned char command;

   command = read_Aport();   //!!!  will all need to be changed when we have more commands ?
                             // !!! need to do this 1st read here
   count = read_Aport();     // !!!  and maybe move all this down to disk image read when we learn
   disk = read_Aport();      // !!!  what the other commands look like
   track = read_Aport();     // !!!  are the commands always 5 bytes long?
   sector = read_Aport();

   Serial.print(F("Disk Command ")); Serial.print(command,HEX);  Serial.write(' ');
   Serial.print(F("Count "));  Serial.print(count,HEX);    Serial.write(' ');
   Serial.print(F("Disk "));   Serial.print(disk,HEX);  Serial.write(' ');
   Serial.print(F("Track "));  Serial.print(track,HEX); Serial.write(' ');
   Serial.print(F("Sector ")); Serial.println(sector,HEX);

   if( command == 2 ) disk_img_read(count,disk,track,sector);  // only command we know of at this point
   
}

void unknown_dispatch(unsigned char command){
unsigned char c;
  
  Serial.print(F("Unknown Command Dispatch(port B) "));  Serial.print(command,HEX);
  c = read_Aport();
  Serial.print(F("Port A "));  Serial.print(c,HEX); Serial.write(' ');
  if( isalnum(c)) Serial.write(c);
  Serial.println();
}

unsigned char read_Aport(){
unsigned char c;

  while( digitalRead(OBFA) );   // wait for data !!! need to time this out
  digitalWrite(ACKA,LOW);
  c = PINA;
  digitalWrite(ACKA,HIGH);

  return c;
}

void write_Aport( unsigned char c ){

  while( digitalRead(IBFA) );    // wait for Tandy M200 to read the old data  !!! will want to time this out
  PORTA = c;
  DDRA = 0xff;   // outputs
  digitalWrite(STBA,LOW);
  digitalWrite(STBA,HIGH);
  DDRA = 0x00;   // inputs
}

void disk_img_read( unsigned char count, unsigned char disk, unsigned char track,unsigned char sector){
unsigned long file_offset;
int stat,x;
unsigned char c;

   // set default directory  here or address root with /M200ROOT/ ?
   if(file.open("DSK0.IMG",O_RDONLY) == 0 ) error("File open failed");

   // 180k floppy, 40 tracks, 18 sectors per track, tracks numbered 0 to 39, sectors numbered 1 to 18
   // sectors are 256 bytes long
   file_offset = 256UL * 18UL * (unsigned long)track;
   file_offset += 256UL * (unsigned long)(sector-1);
   if( file.seekSet(file_offset) == 0 ) error("Seek failed");

   /*  read the number of sectors requested, send status after each 256 bytes */
   while( count-- ){
      for( x = 0; x < 256; ++x ){
          c = stat = file.read();
          //if( stat == -1 ) error("End of file\n");
          write_Aport(c);
      }
      write_Aport(0);   // !!! eventually this will be errors like eof, file not found, etc 
   } 
}

