/************
 * Tandy DVI.   The disk video interface for the Tandy M100, M102, and M200 laptops.
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
 *   
 *   Have decided to keep a fake FAT and fake Directory for the 180k simulated drive.  The files will
 *   be stored on the SD card as files instead of inserting them in the disk image.
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
#define DIR_SIZE  768    // 3 sectors can hold 48 files at 16 bytes per entry
                         // max possible for 180k drive is 80 files which is the number of clusters
                         // but we only have 8k of ram to play with on the Arduino Mega so keeping
                         // this small.  Directory sectors are 1 to 15 which is more entries than 
                         // the FAT can support

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
unsigned char my_dir[DIR_SIZE];          // 3 sectors, 48 files
unsigned char my_dir_backup[DIR_SIZE];   // needed for kill and rename functions
unsigned char my_fat[80];    // one copy enough? for sectors 16,17,18.  80 clusters.
                             // double subscript these for drive 1 if end up with enough ram
                             
// globals for writing to fake filesystem
unsigned char wcount,wdisk,wtrack,wsector,wdestination;
int wbytecount;
// destination of the write
#define NONE 0
#define FAT  1
#define DIRECTORY 2
#define FILE 3

// some events are difficult to detect as only the directory and fat are written
// kill a file( directory write + 6 fat writes ) or rename a file( a directory write only )
unsigned char ren_kill_flag;
unsigned long ren_kill_time;

// space to store directory names
char dir_names[10][9];    // arbitrary 10 names at 8 characters long for now
                          // M200 has 6 character filenames, so I think this will be ok
char directory_path[30];                          
                                                          
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

   Serial.println();
   Serial.println(F("Starting.."));

   directory_search();    // dealing with the fake directory here
   change_directory(5);
   
}


void directory_search(){   // fill out the dir_names array
SdFile root;
SdFile file;
char filename[30];
int i = 0;

  
   root.open("/M200ROOT",O_RDONLY); 
   while (file.openNext(&root, O_RDONLY)){
     if( file.isDir() ){
         file.getName(filename,29);
         filename[8] = 0;          // make sure it fits
         strcpy(dir_names[i++],filename);        
     }
     file.close();
     if( i >= 10 ) break;          // no more unless the names size is increased
   }
   root.close(); 
}

void list_folders(){   // send a list of our dir_names array back to the M200
int i;                 // formatted for printing with tabs and carriage returns

   puts_Aport("   ");
   for( i = 0; i < 10; ++i ){
      if(dir_names[i][0] == 0 ) break;
      if( write_Aport(i+'0') ) return;     // abort on function 4
      puts_Aport(" - ");
      puts_Aport(dir_names[i]);
      if( i & 1 ) puts_Aport("\r\n   ");
      else write_Aport('\t');
   }
   write_Aport(EOF);
}

void puts_Aport(char *str){
char c;

   while( c = *str++ ) if( write_Aport(c) ) return;;
}

void change_directory(char num){   // change default path on SD card
                                  // this is accessed by adding disk commands 8 and 9
char filename[30];

   if( num >= 10 ) num = 0;
   if( dir_names[0][0] == 0 ) error("No directories found");
   if( dir_names[num][0] == 0 ) num = 0;
   strcpy(filename,"/M200ROOT/");
   strcat(filename,dir_names[num]);
   strcpy(directory_path,filename);   // not sure how to access the default path, so save in a string
   sd.chdir(filename);

   mk_fake_fs2();
  
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
      // case 0xc: ctrl_break();      break;  this doesn't seem to happen but was in the documentation
       default:  unknown_dispatch(function); break; 
    }      
  }

  // special detect for rename and kill functions. The filename needs to be found.
  if( ren_kill_flag ){
     if( (millis() - ren_kill_time)  > 1000 ){        // allow time for a disk file write
        if( ren_kill_flag == 1 ) rename_file();       // whereupon it will not be a rename or kill
        else if( ren_kill_flag == 7 ) delete_file();  // event
        else if( ren_kill_flag == 4 ) Serial.println(F("Seqential File Open"));
        else Serial.println(F("Unknown File Event"));
        ren_kill_flag = 0;
     }
  }

}

void rename_file(){    // search for a rename event by comparing the old and new copies of the directory
int i;
char new_name[30];
char old_name[30];

    for(i = 0;  i < DIR_SIZE; i += 16 ){
      if( my_dir[i] == 0 ) continue;
      if( my_dir[i+10] == 0xff ) continue;
      make_filename(i,new_name);
      make_filename2(i,old_name);
      if( strcmp(new_name,old_name) == 0 ) continue;

      sd.rename(old_name,new_name);
      Serial.print(F("Rename "));  Serial.print(old_name);
      Serial.print(F(" to " ));   Serial.println(new_name);
    }
}


void delete_file(){  // a deleted file has its name zero'd in the directory and the head cluster
int i;               // in place.  Search is for zero'd name in new, and intact file name in old directory
char filename[30];
 
  // what file was deleted ?
  filename[0] = '?'; filename[1] = 0;

  for( i = 0; i < DIR_SIZE; i += 16 ){   // search the directory and backup for changes
      if( my_dir[i] == 0 && my_dir_backup[i] != 0 ) break;
  }

  if( i < DIR_SIZE ){             // the file is not deleted but moved to a backup folder( 3 copies ).
      make_filename2(i,filename);
      backup(filename);
  }
  
  Serial.print(F("File Deleted")); Serial.write(' '); Serial.println(filename);

}

void backup( char filename[] ){    // keeps 3 copies of files in backup folders on delete
char longpath[40];
char longpath2[40];

      strcpy(longpath,"/backup3/");
      strcat(longpath,filename);
      if( sd.exists(longpath) ) sd.remove(longpath);
      strcpy(longpath2,"/backup2/");
      strcat(longpath2,filename);
      sd.rename(longpath2,longpath);
      strcpy(longpath,"/backup1/");
      strcat(longpath,filename);
      sd.rename(longpath,longpath2);
      sd.rename(filename,longpath);      // move instead of delete
}

void function4(){   // what does function 4 do, reset all? or attention?
unsigned char c;    // seems to be sent on ram bank change and on boot

    c = read_Aport();
    Serial.print(F("Function4 "));  Serial.println(c);

    wdestination = NONE;
    file.close();
}

void disk_data(){    // the actual write of the data to SD or our fake file system
unsigned char c;
  
    c = read_Aport();
    switch(wdestination){
      case NONE:     break;    // bit bucket
      case FILE:   write_file(c);   break;
      case FAT:    write_fat(c);    break;
      case DIRECTORY: write_directory(c);  break;
    }
    
}    

void crt_read(){    // this seems to be for support of LCOPY aka Print Screen command
unsigned char c;    // and something else that currently remains a mystery

    c = read_Aport();
    Serial.print(F("CRT Read ")); Serial.println(c,HEX);
    switch(c){
       case 'K':   write_Aport(0);   break;    // 4B, LCOPY command
       case 'k':   write_Aport(1);  puts_Aport("ok");  break;  // 6B, mystery command
           // M200 reads and saves 2* the returned value, memory set aside is 322 bytes
           // if we can short circuit this, we can reclaim the otherwise unused 320 bytes
       default:    write_Aport(0);   break;
    }

}

void crt_write(){   // pass characters to a terminal program
unsigned char c;

   c = read_Aport();
   // every character sent has control characters probably for positioning
   // put them in the bit bucket for now as they mess up the diagnostic messages
  // Serial.write(c); 
}

void disk_command(){       // the disk commands have been extended with commands 8 and 9 which
unsigned char command;     // are unknown to the Tandy disk software, but are used to read the
                           // directories and to change to a directory via a BASIC program.

   command = read_Aport(); 

   Serial.print(F("Disk Command ")); Serial.print(command);

   switch(command){
       case 0:              // not sure what this command is, recal?
         write_Aport(128);  // this response seems to work, hangs on return of many other values
       break;
       case 1:  disk_img_write(); break;
       case 2:  disk_img_read();  break;
       case 8:  change_directory(read_Aport()); break;
       case 9:  list_folders();     break;
   }

   Serial.println();

}


void unknown_dispatch(unsigned char function){
unsigned char c;
static unsigned long last_time;
  
  Serial.print(F("Unknown Dispatch Function ")); Serial.print(function );
  c = read_Aport();
  Serial.print(F(" Port A "));  Serial.print(c ); Serial.write(' ');
  if( isalnum(c)) Serial.write(c);
  Serial.println();

  // are these happening really really fast
  if( (millis() - last_time) < 30 ){    // the M200 probably powered off
      digitalWrite(A8,HIGH);      // reset the 82C55, all pins inputs
      delay(1000);                // wait a long time
      digitalWrite(A8,LOW);
  }
  
  last_time = millis();
}

unsigned char read_Aport(){        // 82C55 port A handshake mode
unsigned char c;

  while( digitalRead(OBFA) ){           // wait for data 
     if( (PINB >> 4) == 4 ) break;      // look for reset on the b port
  }
  digitalWrite(ACKA,LOW);
  c = PINA;
  digitalWrite(ACKA,HIGH);

  return c;
}

unsigned char write_Aport( unsigned char c ){

  while( digitalRead(IBFA) ){              // wait for Tandy M200 to read the old data
     if( (PINB >> 4) == 4 ) return 128;  // break;  // look for reset on the B port.
  }
  if( (PINB >> 4) == 4 ) return 128;     // abort write even if ready
  PORTA = c;
  DDRA = 0xff;                // outputs 
  digitalWrite(STBA,LOW);
  digitalWrite(STBA,HIGH);
  DDRA = 0x00;                // leave the A port defaulted to inputs
  return 0;
}

void disk_img_write(){    // the destination of the upcoming disk writes is determined.
unsigned char c;
unsigned long offset;
char filename[15];
static char oldfilename[15];
static unsigned long oldoffset;
int i;

   offset = 0;
   wcount = read_Aport();
   wdisk = read_Aport();
   wtrack = read_Aport();
   wsector = read_Aport();

   Serial.print(F(" Count "));  Serial.print(wcount);
   Serial.print(F(" Disk "));   Serial.print(wdisk);
   Serial.print(F(" Track "));  Serial.print(wtrack);
   Serial.print(F(" Sector ")); Serial.print(wsector);

   write_Aport(0);

   wbytecount = 0;
   // find the write destination
   if( wtrack == 20 && wsector <= 3 ){
      wdestination = DIRECTORY;
      ren_kill_flag = 1;         // flag a directory write
      backup_directory();        // save current before writing
      ren_kill_time = millis();
   }
   if( wtrack == 20 && wsector >= 16 ){
      wdestination = FAT;
      if( ren_kill_flag ) ++ren_kill_flag;    // count fat writes
   }
   if( wtrack > 2 && wtrack != 20 ){
      wdestination = FILE;
      ren_kill_flag = 0;    // it is something other than rename or kill command
   }

   if( wdestination == FILE ){
      i = find_dir_entry(wdisk,wtrack,wsector,&offset);
      
      if( i == -1 ){            // shouldn't happen unless fat is not up to date
                                           // this happens when
                                           // writing sequential text and
         strcpy(filename,oldfilename);     // when the file needs more than 1 cluster.
                                           // the FAT is updated after the data write.
                                           // use the previous filename, can't determine via stale FAT
         offset = oldoffset + 9 * 256;     // add one cluster size to the offset
         if( wsector == 18 || wsector == 9) oldoffset += 9 * 256;      
      }
      else{
        make_filename(i,filename);
        strcpy(oldfilename,filename);
        oldoffset = offset;               // the offset is mostly used for the log messages
      }                                   // except when zero a new file is created
      
      offset += 256UL * (unsigned long)((wsector-1) % 9);
      Serial.write(' ');  Serial.print(filename);
      Serial.write(' ');  Serial.print(offset);
     // open file here. on create,  check if exists and move old to backup versions
      if( offset == 0 && sd.exists(filename) ) backup(filename); 
      int flags = O_WRONLY;
      if( offset == 0 ) flags |= O_CREAT;
      else flags |= O_AT_END;                 // O_AT_END removes need for a seekSet
      if( file.open(filename,flags ) == 0 ){
          Serial.print(F(" Open for write failed"));
          wdestination = NONE;
      }
   }
}


void write_directory( unsigned char c ){   // updating the fake directory
int index;

    index = 256*(wsector-1);
    index += wbytecount;
    ++wbytecount;

    if( index < DIR_SIZE ) my_dir[index] = c;
     
    if( wbytecount >= 256*(int)wcount ) wdestination = NONE;   // done
    
}

void backup_directory(){   // make a copy as the filenames are zero'd out on delete
int i;                     // otherwise will not know what file was deleted

     for( i = 0; i < DIR_SIZE; ++i ) my_dir_backup[i] = my_dir[i];
}

void write_fat( unsigned char c ){   // update the fake FAT, discard writes beyond 80( # of clusters )

    if( wbytecount < 80 ) my_fat[wbytecount] = c;
    ++wbytecount;

    if( wbytecount >= 256*(int)wcount ) wdestination = NONE;

}

void write_file( unsigned char c ){   // write to the open file

   file.write(c);
   ++wbytecount;
   if( wbytecount >= 256*(int)wcount ){
      wdestination = NONE;
      file.close();
   }
}


void disk_img_read(){        // read the disk image, fake directory, fake FAT or open a file.
unsigned long file_offset;   // and send the data out to the M200
int stat,x;
unsigned char c, count, disk, track, sector;
SdFile file;

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
       read_fat(count);
       return;
   }

   if( track > 2 && track != 20 ){
       read_file(count,disk,track,sector);
       return;
   }

   // else we read system tracks 0,1,2 or parts of track 20 that are not faked
   // mostly just during boot will we be here,
   // also the system reads T20 S15 which is all zero's for some reason

   if(file.open("/M200ROOT/DSK0.IMG",O_RDONLY) == 0 ) error("File open failed");

   // Simulating a 180k floppy, 40 tracks, 18 sectors per track, tracks numbered 0 to 39,
   // sectors numbered 1 to 18,  sectors are 256 bytes long, a cluster is 9 sectors.
   file_offset = 256UL * 18UL * (unsigned long)track;
   file_offset += 256UL * (unsigned long)(sector-1);
   if( file.seekSet(file_offset) == 0 ) error("Seek failed");

   /*  read the number of sectors requested, send status before each 256 bytes */
   while( count-- ){
      write_Aport(0);      // error status sent here, just faking it for now
      for( x = 0; x < 256; ++x ){
          c = stat = file.read();
          //if( stat == -1 ) error("End of file\n");
          if( write_Aport(c) ) break;    // quit if function4 was sent by M200
      } 
   }

   file.close();
      
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
      write_Aport(0);       // add checking if y + 256 is off the end of the array and return error?
      for( x = 0; x < 256; ++x ){
        if( write_Aport(my_dir[y++]) ) break; 
      }
   }   
}

void read_fat(unsigned char count){
int x;  

  while( count-- ){
      write_Aport(0);    // status
      for( x = 0; x < 80; ++x ) if(write_Aport(my_fat[x]) ) break;
      for( x = 80; x < 256; ++x ) if( write_Aport(0xff)) break;     // pad out to a full sector
  }
  
}

void read_file(unsigned char count, unsigned char disk, unsigned char track, unsigned char sector){
int x,i;
char filename[15];
unsigned char c;
unsigned long offset;
int stat;


   // do a reverse lookup of the directory entry using the cluster number
   offset = 0;
   i = find_dir_entry( disk, track, sector, &offset );
   
   if( i == -1 ){                      // unused disk area was requested
       while( count-- ){               // send all 0xff's, ignore if a count more than 1
          write_Aport(0);              // actually moves into a used area of the disk
          for( x = 0; x < 256; ++x ) if(write_Aport(0xff)) break;   
       }
       return;
   }

   make_filename(i,filename);
   
   offset += 256UL * (unsigned long)((sector-1) % 9);

   Serial.write(' '); Serial.print(filename);
   Serial.write(' '); Serial.print(offset);
   
   if(file.open(filename,O_RDONLY) == 0 ){
      write_Aport(FF);            // file not found
      return;
   }
   if( file.seekSet(offset) == 0 ) error("\nSeek failed");

   /*  read the number of sectors requested, send status before each 256 bytes */
   while( count-- ){
      write_Aport(0);      // success status hardcoded
      for( x = 0; x < 256; ++x ){
          c = stat = file.read();
          if( stat == -1 ) c = EOF;   // end of file, start filling with EOF
          if( write_Aport(c) ) break;
      } 
   }
   file.close();
}

void make_filename(int i, char buf[] ){
int j,x;
   
   // make a proper filename 6 by 3, filenames are stored with space padding and 3 character
   // extension by its position in the 9 character field
   j = 0;
   for( x = 0; x < 6; ++x ){     // pick up the filename ignoring spaces
      if( my_dir[i] != ' ' ) buf[j++] = my_dir[i];
      ++i;       
   }
   buf[j++] = '.';          // get the extension ignoring spaces
   for( x = 0; x < 3; ++x ){
      if( my_dir[i] != ' ' ) buf[j++] = my_dir[i];
      ++i;
   }
   // remove the . if no extension
   if( buf[j-1] == '.' ) buf[j-1] = 0;
   buf[j] = 0;
 
}

void make_filename2(int i, char buf[] ){   // look for filenames in the backup directory
int j,x;                                   // replicated code from make_filename()
   
   // make a proper filename 6 by 3, filenames are stored with space padding and 3 character
   // extension by its position in the 9 character field
   j = 0;
   for( x = 0; x < 6; ++x ){     // pick up the filename ignoring spaces
      if( my_dir_backup[i] != ' ' ) buf[j++] = my_dir_backup[i];
      ++i;       
   }
   buf[j++] = '.';          // get the extension ignoring spaces
   for( x = 0; x < 3; ++x ){
      if( my_dir_backup[i] != ' ' ) buf[j++] = my_dir_backup[i];
      ++i;
   }
   // fix up if no extension
   if( buf[j-1] == '.' ) buf[j-1] = 0;
   buf[j] = 0;
 
}


// reverse lookup of a filename from the cluster information, calculated offset into the file.
int find_dir_entry( unsigned char disk, unsigned char track, unsigned char sector, unsigned long *off ){
int cluster;
int i;
int chain;
int found;

    cluster = 2 * track;
    if( sector > 9 ) cluster += 1;

    if( my_fat[cluster] > 0xf0 ) return -1;  // unused cluster
    
    // need to follow all the cluster chains until we find the one we want
    // start with the head cluster for each file in the directory
    found = 0;
    for( i = 0; i < DIR_SIZE; i += 16 ){
      
        if( my_dir[i] == 0 || my_dir[i] == 0xff ) continue;   // deleted or unused 

        *off = 0;
        chain = my_dir[i + 10];     // the head cluster number in the directory entry
        
        while( chain < 0xc0 ){      // final cluster is 0xc0 + last sector #( 1 to 9 )
          if( chain == cluster ){
            found = 1;
            break;
          }
          chain = my_fat[chain];    // follow the clusters
          *off += 9*256;            // add 9 sectors to the file offset
        }
                
        if(found) break;            // found with this directory entry
    }
    if( i < DIR_SIZE ) return i;
    else return -1;
}


void mk_fake_fs2(){    // make a fake filesystem 180k floppy
int i,j;

SdFile root;
SdFile file;
char filename[30];
unsigned long file_size;
int type;
int entry,head,sectors;

   Serial.println();
   // format.  fill the arrays with ff
   for( i = 0; i < 80; ++i ) my_fat[i] = 0xff;
   for( i = 0; i < DIR_SIZE; ++i ) my_dir[i] = 0xff;

   // set the system area's in the fat
   for( i = 0; i < 6; ++i ) my_fat[i] = 0xfe;   // boot tracks 0,1,2
   my_fat[40] = 0xfe;  my_fat[41] = 0xfe;       // directory track 20 uses 2 clusters

   root.open(directory_path,O_RDONLY);      // open directory
   root.rewind();
   
   entry = 0; head = 6;                         // fake dir entry, starting head cluster of free space
   while(file.openNext(&root,O_RDONLY)){        // open each file in directory
       file.getName(filename,29);
       file_size = file.fileSize();            // reported filesize sometimes more than actual?
                                               // doesn't seem to cause any problems except used fake space
       type = 0;                               // text file as default type
       for( i = 0; i < 40; ++i){               // test for binary data in the file
          j = file.read();
          if( j == -1 ) break;                 // end of file
          if( j >= 128 ) type = 1;             // binary data in file, set as a machine code file
       }

       // fill in the directory entry, 6 by 3 filenames
       for( i = 0; i < 9; ++i ) my_dir[entry+i] = ' ';   // pad with spaces
       for( i = 0; i < 6; ++i ){                         // get filename 6 characters max
           if( filename[i] == 0 ) break;
           if( filename[i] == '.' ) break;
           my_dir[entry+i] = filename[i];
       }
       // now get the extension if any
       if( filename[i] == '.' ){
           ++i; j = 6;                        // position of the extension
           while( j < 9 ){
              if( filename[i] == 0) break;
              my_dir[entry+j] = filename[i++];
              ++j;
           }  
       }

       if( type == 1 && my_dir[entry+6] == 'B' ) type = 0x80;   // good chance it is a basic token file
       my_dir[entry+9] = type;                                  // .BA or .BAS although those extensions
                                                                // are not required

       my_dir[entry+10] = head;                              // pointer to head cluster
       Serial.print(F("Cluster "));  Serial.print(head);  Serial.write(' ');       
       sectors = file_size / 256UL;
       sectors += 1;

       while( sectors > 9 ){                                 // chain the clusters
          j = head;
          my_fat[j] = head = bump_head(j);
          Serial.print(head);  Serial.write(' ');
          sectors -= 9;
       }

       my_fat[head] = 0xc0 + sectors;                        // chain terminator
       head = bump_head(head);                               // next free cluster
       
       Serial.print(filename);  Serial.write(' '); Serial.println(file_size);
       // Serial.print(F("   Slack "));  Serial.println( (9 - sectors) * 256 );
       file.close();

       entry += 16;                        // next directory entry
       if( entry >= DIR_SIZE ) break;      // out of space in directory, 3 sectors at this point
   }
   root.close();
  
}


int bump_head( int cluster ){    // find the next free cluster

   ++cluster;
   while( my_fat[cluster] != 0xff ){
      ++cluster;
      if( cluster >= 80 ) return 79;  // disk full, just overwrite the last cluster over and over  
   }
   return cluster;
}

/**************************************** abandoned code but may want to look at *****************/
#ifdef NOWAY
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

// fragments is a more correct way to fix the issue of a stale fat when a file write exceeds
// one cluster, but it is very slow( 6 seconds ) to copy one fragment to the desired file.
// the current solution of using the previous filename will only fail if one has two sequential
// files open for write and one exceeds one cluster in size.  I don't think that will
// happen very often on a computer that has 19k of ram to play with.  And the issue of lost file
// pieces is avoided when the user interrupts the program
unsigned char cluster_fragments;     // a sequential file that spans more than one cluster,
                                     // the fat is updated after the file is written
                                     // but can't determine the filename until the fat is
                                     // updated, so the data is written out to temp files and
                                     // the correct file is updated later

void fix_fragments(){
int i,j;
unsigned char chain;
unsigned char fixed;
char filename[30];

/***************** this was the detect code in file write when i == -1   */
    // a new filename is created called cluster_nn where nn is the cluster number
        cluster = wtrack * 2;
        if( wsector >= 10 ) cluster += 1;
        offset = 0;
        strcpy( filename,"cluster_" );     //7
        i = cluster / 10;    filename[8] = i + '0';  
        i = cluster % 10;    filename[9] = i + '0';
        filename[10] = 0;
        cluster_fragments = 1;                    // flag to clean up when write FAT
/****************************    */  

/************ this was in make a fake file system 2  */
       // skip any lost cluster files
       if( strstr(filename,"cluster_") ){
        file.close();
        continue;
       }
       

   // need to process the files in the correct order
   // go through directory for each entry, follow the cluster chain, check for a file
   // and append the file if found.  set cluster_fragments to zero if fixed any
    fixed = 0;
    for( i = 0; i < DIR_SIZE; i += 16 ){
      
        chain = my_dir[i + 10];     // the head cluster number in the directory entry
                     
        if( chain == 0xff ) continue;
                                    
        chain = my_fat[chain];      // the head should not be a fragment, so skip the 1st one          
        while( chain < 0xc0 ){      // final cluster is 0xc0 + last sector #( 1 to 9 )
            // make the filename and see if it exists
            strcpy(filename,"cluster_");
            j = chain/10;
            filename[8] = j + '0';
            j = chain % 10;
            filename[9] = j + '0';
            filename[10] = 0;
            if( sd.exists(filename)) copy_fragment(filename,i) , ++fixed;
            chain = my_fat[chain];
        }
                  
    }
    if( fixed ) cluster_fragments = 0;
}

void copy_fragment( char *fragment, int di ){
   // get the directory filename and copy fragment to the end of the directory file
char filename[30];
SdFile fromfile;
SdFile tofile;
unsigned char c;
int stat;

    make_filename(di,filename);
    tofile.open(filename,O_WRONLY | O_AT_END);
    fromfile.open(fragment,O_RDONLY);

    Serial.println();
    Serial.print(F(" Copy ")); Serial.print(fragment); 
    Serial.print(F(" to "));   Serial.print(filename);
    
    while(1){
       c = stat = fromfile.read();
       if( stat == -1 ) break;
       tofile.write(c);
    }

    fromfile.close();
    tofile.close();

    sd.remove(fragment);
}


#endif

