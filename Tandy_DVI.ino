/************
 * Tandy DVI
 *   Mega 2560, proto board with 82C55 interface, and a SD card board.  The circuit is loosely
 *   based upon the schematic in the DVI service manual. 
 *   
 *   To make the program easier to understand( or more confusing depending upon your point of view ),
 *     the A port of the 82C55 is wired to the A port of the Mega, the 4 used bits of the B port
 *     of the 82C55 are wired to the B port of the Mega although they are shifted into the upper 
 *     nibble,  and the handshake lines on the C port of the 82C55 are wired to the corresponding
 *     bits on the C port of the Mega.
 *   
 *   From reading club100, the way to unload the DVI code from the M200 is to 
 *      poke 61110,201 : poke 61122,201 : call 39703 : clear 100, maxram
 *   But this seems to disable any attempt to reload it.  A call to IOINIT is used to enable it again.
 *   call 33820 while in the bank in question.  
 */

#define OBFA 30     // port C handshake names
#define ACKA 31
#define IBFA 32
#define STBA 33

/*  Tandy Basic disk error codes. Basic may trap most of these itsself */
#define IE 50     // Internal error
#define BN 51     // Bad file Number
#define FF 52     // File not Found
#define AO 53     // Already Open
#define EF 54     // Read Past End of File
#define NM 55     // Bad File Name
#define DS 56     // Direct Statement, binary data in an ascii file
#define FL 57     // Too many Files
#define CF 58     // File not Open
#define AT 59     // Bad Allocation Table
#define DN 60     // Bad Drive Number
#define TS 61     // Bad Track or Sector
#define FE 62     // File Exists ( rename error )
#define DF 63     // Disk Full

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
   Serial.begin(38400);

   /* reset the 82C55 */
   pinMode(A8,OUTPUT);
   digitalWrite(A8,HIGH);

   /* Port A, bidirectional port of the 82C55 */
   pinMode(22,INPUT_PULLUP);   // maintain a default mode of input for this bus
   pinMode(23,INPUT_PULLUP);
   pinMode(24,INPUT_PULLUP);
   pinMode(25,INPUT_PULLUP);
   pinMode(26,INPUT_PULLUP);
   pinMode(27,INPUT_PULLUP);
   pinMode(28,INPUT_PULLUP);
   pinMode(29,INPUT_PULLUP);

   /* Port B, the command port on upper nibble */
   pinMode(10,INPUT_PULLUP);
   pinMode(11,INPUT_PULLUP);
   pinMode(12,INPUT_PULLUP);
   pinMode(13,INPUT_PULLUP);

   /* Port C, the 82C55 handshake lines */
   pinMode(5,OUTPUT);      // C0, interface enable bit, wired to a pin instead of just soft ground  
   digitalWrite(5,HIGH);   // high, not yet ready
   
   pinMode(30,INPUT_PULLUP);  // OBFA, low when data is available on A port
   pinMode(32,INPUT_PULLUP);  // IBFA, Buffer full, wait for low before writing new data
   pinMode(31,OUTPUT);        // ACKA, Low to ACK data and read it on the A port
   digitalWrite(31,HIGH);
   pinMode(33,OUTPUT);        // STBA, Write low to latch output data
   digitalWrite(33,HIGH);
   // C3 INTRA unused, C1,C2 are wired to ground via resistor

   digitalWrite(A8,LOW);  // release reset pin on 82C55
   digitalWrite(5,LOW);   // ready, Tandy reads 000 on the C2,C1,C0 bits to detect
                          // the presence of the DVI on the expansion bus
   
   if (!sd.begin(chipSelect, SD_SCK_MHZ(8))) {
      sd.initErrorHalt();
   }

   sd.chdir("M200ROOT");
   Serial.println(F("Starting.."));
}

void loop() {
unsigned char function;

  if( digitalRead(OBFA) == LOW ){      // something was sent to the A port
    function = PINB >> 4;             // B port will tell us what to do with it
    switch(function){                 // command dispatch
       case 0:   crt_write();       break;
       case 1:   crt_read();        break;
       case 2:   disk_data();       break;
       case 3:   disk_command();    break;
       case 4:   function4();       break;
       case 0xc: ctrl_break();      break;
       default:  unknown_dispatch(function); break; 
    }      
  }

}

void function4(){   // what does function 4 do, reset all? or attention?
unsigned char c;    // seems to be sent on ram bank change and on boot

    c = read_Aport();
    Serial.print(F("Function4 "));  Serial.println(c);
}
void ctrl_break(){   // control break was pressed ?

    read_Aport();   // discard
}

void disk_data(){
  
    read_Aport();   // throw it away for now
}

void crt_read(){    // not sure we can support this unless we keep fake video memory
                    // how many bytes is the M200 expecting?
    read_Aport();
    write_Aport(IE);  // return Internal Error and see what happens
}

void crt_write(){   // pass characters to a terminal program
unsigned char c;

   c = read_Aport();
  // if( isalnum(c) ) Serial.write(c); // or bit bucket, the control characters mess up the diag
                                     // messages
}

void disk_command(){
unsigned char command;

   command = read_Aport(); 

   Serial.print(F("Disk Command ")); Serial.print(command);

   switch(command){
       case 0:              // not sure what this command is, recal?
         delay(3);          // delay probably not needed
         // mk_floppy_img();  // maybe
         write_Aport(128);  // this response seems to work after a cold boot
       break;
       case 1:                    break;
       case 2:  disk_img_read();  break;
   }

   Serial.println();

}


void unknown_dispatch(unsigned char function){
unsigned char c;
  
  Serial.print(F("Unknown Dispatch Function ")); Serial.print(function );
  c = read_Aport();
  Serial.print(F(" Port A "));  Serial.print(c ); Serial.write(' ');
  if( isalnum(c)) Serial.write(c);
  Serial.println();
}

unsigned char read_Aport(){
unsigned char c;

  while( digitalRead(OBFA) ){                // wait for data 
     if( (PINB >> 4) == 4 ) break;      // look for reset on the b port
  }
  digitalWrite(ACKA,LOW);
  c = PINA;
  digitalWrite(ACKA,HIGH);

  return c;
}

void write_Aport( unsigned char c ){

  while( digitalRead(IBFA) ){              // wait for Tandy M200 to read the old data
     if( (PINB >> 4) == 4 ) return;  // break;  // look for reset on the B port.
  }
  PORTA = c;
  DDRA = 0xff;                // outputs 
  digitalWrite(STBA,LOW);
  digitalWrite(STBA,HIGH);
  DDRA = 0x00;                // leave the A port defaulted to inputs
}

void disk_img_read(){
unsigned long file_offset;
int stat,x;
unsigned char c, count, disk, track, sector;

   count = read_Aport();
   disk = read_Aport();
   track = read_Aport();
   sector = read_Aport();

   Serial.print(F(" Count "));  Serial.print(count);
   Serial.print(F(" Disk "));   Serial.print(disk);
   Serial.print(F(" Track "));  Serial.print(track);
   Serial.print(F(" Sector ")); Serial.print(sector);


   // !!! set default directory here or address root with /M200ROOT/ ?
   if(file.open("DSK0.IMG",O_RDONLY) == 0 ) error("File open failed");
   // or open DSK1.IMG for disk 1

   // Simulating a 180k floppy, 40 tracks, 18 sectors per track, tracks numbered 0 to 39,
   // sectors numbered 1 to 18,  sectors are 256 bytes long, a cluster is 9 sectors.
   file_offset = 256UL * 18UL * (unsigned long)track;
   file_offset += 256UL * (unsigned long)(sector-1);
   if( file.seekSet(file_offset) == 0 ) error("Seek failed");

   /*  read the number of sectors requested, send status before each 256 bytes */
   while( count-- ){
      write_Aport(0);      // !!! error status sent here, just faking it for now
      for( x = 0; x < 256; ++x ){
          c = stat = file.read();
          //if( stat == -1 ) error("End of file\n");
          write_Aport(c);
      } 
   }

   file.close();  // !!! should file be a local object instead of global?
      
}

