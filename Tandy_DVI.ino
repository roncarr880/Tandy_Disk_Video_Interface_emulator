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

#define EOF 26

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

// Faking the image FAT and DIRECTORY, track 20.  Storing files as files and not in the image.
// only tracks 0,1,2 and parts of 20 will come from the image. T20 S15 seems special and all zero's.
unsigned char my_dir[768];  // 3 sectors, 48 files, others will be from the image, max 80 filenames/clusters
unsigned char my_fat[80];    // one copy enough? fpr sectors 16,17,18.  80 clusters.

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

   sd.chdir("M200ROOT/SCRTCH");
   Serial.println(F("Starting.."));

   // for now, do this once here.  make a fake filesystem
   mk_fake_fs();
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
       case 1:                    break;  // this will be a write to disk
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

   // will the data be from the img or from the faked file system
   if( track == 20 && sector <= 3 ){
       read_directory(count,disk,track,sector);
       return;
   }
   if( track == 20 && sector >= 16 ){
       read_fat(count,disk,track,sector);
       return;
   }

   if( track > 2 && track != 20 ){
       read_file(count,disk,track,sector);
       return;
   }

   // else we read system tracks 0,1,2 or parts of track 20 that are not faked
   // mostly just during boot will we be here, also system reads T20 S15 all zero's for some reason

   // !!! set default directory here or address root with /M200ROOT/ ?
   if(file.open("/M200ROOT/SCRTCH/DSK0.IMG",O_RDONLY) == 0 ) error("File open failed");
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

void read_directory(unsigned char count, unsigned char disk, unsigned char track, unsigned char sector ){
int x,y;
   // size 768, 3 sectors, 16 bytes per entry
   if( sector == 0 || sector > 3 ){
       write_Aport(TS);     // bad sector
       return;
   }
   y = 256 * ( sector - 1 );
   while( count-- ){
      write_Aport(0);               // add checking if y + 256 is off the end of the array and return error
      for( x = 0; x < 256; ++x ){
         write_Aport(my_dir[y++]); 
      }
   }   
}

void read_fat(unsigned char count, unsigned char disk, unsigned char track, unsigned char sector){
int x;  
  // don't really need all those parameters
  while( count-- ){
      write_Aport(0);    // status
      for( x = 0; x < 80; ++x ) write_Aport(my_fat[x]);
      for( x = 80; x < 256; ++x ) write_Aport(0xff);     // pad out to a full sector
  }
  
}

void read_file(unsigned char count, unsigned char disk, unsigned char track, unsigned char sector){
int x,i,j;
char filename[15];
// int head;
// unsigned char t
unsigned char c;
unsigned long offset;
int stat;


   // do a reverse lookup of the directory entry using the cluster number
   offset = 0;
   i = find_dir_entry( disk, track, sector, &offset );
   
   if( i == -1 ){                      // unused disk area was requested
       while( count-- ){               // send all 0xff's, ignore if count more than 1
          write_Aport(0);              // actually moves into a used area
          for( x = 0; x < 256; ++x ) write_Aport(0xff);   
       }
       return;
   }

   // make a proper filename from 6 by 3, filenames are stored with space padding and 3 character
   // extension by its position in the 9 character field
   j = 0;
   for( x = 0; x < 6; ++x ){     // pick up the filename ignoring spaces
      if( my_dir[i] != ' ' ) filename[j++] = my_dir[i];
      ++i;       
   }
   filename[j++] = '.';          // get the extension ignoring spaces
   for( x = 0; x < 3; ++x ){
      if( my_dir[i] != ' ' ) filename[j++] = my_dir[i];
      ++i;
   }
   // fix up if no extension
   if( filename[j-1] == '.' ) filename[j-1] = 0;
   filename[j] = 0;
   
 //  ++i;
 //  head = my_dir[i];

//!!! think add 256UL * (sector-1)%9; to the offset  mod 9, 0 to 8 and 9 to 17
   // this will fail if clusters are not together, there should be an easier way to do this
   // calc the file offset needed
//Serial.write(' '); Serial.print(head); Serial.write(' ');   
//   t = head/2;
//Serial.print(t);
//   offset = 256UL * 18UL * (unsigned long)(track - t);
//   if( 2*t != head ) offset -= 256UL * 9UL;   //2nd cluster in the track

   offset += 256UL * (unsigned long)((sector-1) % 9);

   Serial.write(' '); Serial.print(filename);
   Serial.write(' '); Serial.print(offset);
   
   // well I don't know if we are there but let it go
   if(file.open(filename,O_RDONLY) == 0 ) error("File open failed");
   if( file.seekSet(offset) == 0 ) error("\nSeek failed");

   /*  read the number of sectors requested, send status before each 256 bytes */
   while( count-- ){
      write_Aport(0);      // !!! error status sent here, just faking it for now
      for( x = 0; x < 256; ++x ){
          c = stat = file.read();
          if( stat == -1 ) c = EOF;   // end of file, start filling with EOF
          write_Aport(c);
      } 
   }
   file.close();
}


int find_dir_entry( unsigned char disk, unsigned char track, unsigned char sector, unsigned long *off ){
int cluster;
int i;
int chain;
int found;

    cluster = 2 * track;
    if( sector > 9 ) cluster += 1;

    if( my_fat[cluster] > 0xf0 ) return -1;  // unused 
    
    // need to follow all the cluster chains until we find the one we want
    found = 0;
    for( i = 0; i < 48; i += 16 ){
        *off = 0;
        chain = my_dir[i + 10];     // the head cluster number in the directory entry
        
        while( chain < 0xc0 ){      // final cluster is 0xc0 + last sector #( 1 to 9 )
          if( chain == cluster ){
            found = 1;
            break;
          }
          chain = my_fat[chain];
          *off += 9*256;            // add 9 sectors to the file offset
        }
                
        if(found) break;  
    }
    if( i < 48 ) return i;
    else return -1;
}



void mk_fake_fs(){
int i;

   // format.  fill the arrays with ff
   for( i = 0; i < 80; ++i ) my_fat[i] = 0xff;
   for( i = 0; i < 768; ++i ) my_dir[i] = 0xff;

   // set the system area's in the fat
   for( i = 0; i < 6; ++i ) my_fat[i] = 0xfe;   // boot tracks 0,1,2
   my_fat[40] = 0xfe;  my_fat[41] = 0xfe;       // directory track 20 clusters
   
   // just setting up 3 known files for testing, this code will be changed 
   // dasm 13 sectors,  nemon 4 sectors, xpand 3 sectors

   my_dir[0] = 'D';
   my_dir[1] = 'A';
   my_dir[2] = 'S';
   my_dir[3] = 'M';
   my_dir[4] = ' ';
   my_dir[5] = ' ';
   my_dir[6] = 'B';
   my_dir[7] = 'A';
   my_dir[8] = ' ';
   my_dir[9] = 0;     // 0 is text file.  1 is CO and 0x80 is a basic token file
   my_dir[10] = 12;   // head cluster, fake track 6
   // rest are unused
   my_fat[12] = 13;   // chain of cluster numbers in fat
   my_fat[13] = 0xc0 + 4;
   
   my_dir[16] = 'N';
   my_dir[17] = 'E';
   my_dir[18] = 'M';
   my_dir[19] = 'O';
   my_dir[20] = 'N';
   my_dir[21] = ' ';
   my_dir[22] = 'B';
   my_dir[23] = 'A';
   my_dir[24] = ' ';
   my_dir[25] = 0;
   my_dir[26] = 18;   // track 9
   my_fat[18] = 0xc0 + 4;

   my_dir[32] = 'X';
   my_dir[33] = 'P';
   my_dir[34] = 'A';
   my_dir[35] = 'N';
   my_dir[36] = 'D';
   my_dir[37] = ' ';
   my_dir[38] = 'B';
   my_dir[39] = 'A';
   my_dir[40] = ' ';
   my_dir[41] = 0;
   my_dir[42] = 21;  // track 10 2nd cluster 
   my_fat[21] = 0xc0 + 3;
     
}

