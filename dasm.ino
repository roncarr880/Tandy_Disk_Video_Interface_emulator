// 8085 disassembler based upon a Basic program
#include <SPI.h>
#include "SdFat.h"
#include "sdios.h"
const uint8_t chipSelect = 4;

unsigned int x,y;
unsigned char c;

/* test data
unsigned char data[] = {
  58,1,0,254,171,202,71,224,49,0,227,33,0,0,229,62,
  3,50,250,255,33,61,224,6,5,126,205,222,118,35,5,194,
  25,224,33,0,227,14,18,205,251,118,183,55,192,205,251,118,
  119,35,5,194,45,224,13,194,39,224,195,0,227,2,18,0
};
*/

SdFat sd;
SdFile file;
// Create a Serial output stream.
ArduinoOutStream cout(Serial);

// Buffer for Serial input.
char cinBuf[40];

// Create a serial input stream.
ArduinoInStream cin(Serial, cinBuf, sizeof(cinBuf));
// Error messages stored in flash.
#define error(msg) sd.errorHalt(F(msg))

void setup() {
  Serial.begin(9600);
  
  // Wait for USB Serial 
  while (!Serial) {
    SysCall::yield();
  }
  delay(1000);

  cout << F("Type any character to start\n");
  // Wait for input line and discard.
  cin.readline();
  cout << endl;
  
  // Initialize at the highest speed supported by the board that is
  // not over 50 MHz. Try a lower speed if SPI errors occur.
  if (!sd.begin(chipSelect, SD_SCK_MHZ(8))) {
    sd.initErrorHalt();
  }

  sd.ls(LS_SIZE);

  cout << F("\nEnter the filename\n");
  cin.readline();
  cout << cinBuf;
  cinBuf[strlen(cinBuf)-1] = 0;
  if(file.open(cinBuf,O_RDONLY) == 0 ) error("File open failed");

  cout << F("\nEnter the starting address(hex)\n");
  cin.readline();
  x = strtol(cinBuf,0,16);

  cout << F("Enter the ending address(hex)\n");
  cin.readline();
  y = strtol(cinBuf,0,16);
  
  if( file.seekSet(x) == 0 ) error("Seek failed");
  
}


void loop() {
int s;

   if( x > y ){  //done
    file.close();
    while(1);
    delay(60000);
    x = 0;   //start again
   }
   c = s = file.read();
   if( s == -1 ) error("End of file\n");
   
   prnt(x,4);   Serial.print("    ");
   
   switch((c & 192)/64){
    case 0:  group1(c);  break;
    case 1:  group2(c);  break;
    case 2:  group3(c);  break;
    case 3:  group4(c);  break;
   }

   if( isalnum(c)){ Serial.print("          ;");  Serial.write(c); }
   Serial.println();

   ++x;
   
}

void unknown(){
  Serial.print("???");
}

void group1(unsigned char op){    //50
unsigned char a,d,b;
const char g7_15[][4] = {
  "RLC","RRC","RAL","RAR","DDA","CMA","STC","CMC"
};

   a = (op&15);
   d = (op&48)/16;
   b = (op&56)/8;

   switch(a){
      case 0:
         switch(d){
          case 0: Serial.print("NOP"); break;
          case 1: unknown(); break;
          case 2: Serial.print("RIM"); break;
          case 3: Serial.print("SIM"); break;
         }
      break;
      case 1:
         Serial.print("LXI   ");   reg_pair(c,d);
         Serial.write(',');   address();         
      break;
      case 2:
         if( d < 2 ){ Serial.print("STAX  ");  reg_pair(c,d); }
         else if( d == 2 ){ Serial.print("SHLD  ");  address(); }
         else{ Serial.print("STA   ");  address(); }
      break;
      case 3:
         Serial.print("INX   ");  reg_pair(c,d);
      break;
      case 4:    case 12:
         Serial.print("INR   ");  reg(b);
      break;
      case 5:    case 13:
         Serial.print("DCR   ");  reg(b);
      break;
      case 6:    case 14:
         Serial.print("MVI   ");  reg(b);
         Serial.write(',');  immediate();
      break;
      case 7:    case 15:
         Serial.print(g7_15[b]);
      break;
      case 8: 
         unknown();
         //group2(op); //  mov  c,b ? no, error in BASIC program
      break;   
      case 9:
         Serial.print("DAD   ");  reg_pair(c,d);
      break;
      case 10:      
         if( d < 2 ){ Serial.print("LDAX  "); reg_pair(c,d); }
         else if( d == 2 ){ Serial.print("LHLD  "); address(); }
         else{ Serial.print("LDA   "); address(); }
      break;   
      case 11:
         Serial.print("DCX   ");   reg_pair(c,d);   
      break;
   }  
}

void reg_pair(unsigned char op,unsigned char reg){   //600
    if( reg == 3 && op > 128 ) Serial.print("PSW");
    else if( reg == 0 ) Serial.write('B');
    else if( reg == 1 ) Serial.write('D');
    else if( reg == 2 ) Serial.write('H');
    else Serial.print("SP");
}

void reg(unsigned char reg){   //800
const char data[] = "BCDEHLMA";

   Serial.write(data[reg]);
}
void address(){  //950
unsigned int val;

  val = file.read(); ++x;
  val = val + 256*file.read(); ++x;
  prnt(val,4);
  //Serial.write('h');
}

void immediate(){    //900
unsigned char val;
   val = file.read(); ++x;
   prnt(val,2); 
   Serial.write('h'); 
}

void group2(unsigned char op){  //100
unsigned char r;

   if( op == 118 ) Serial.print("HLT");
   else{
      Serial.print("MOV   ");
      r = (op&56)/8;  reg(r);
      Serial.write(',');
      r = op & 7;     reg(r);
   }
}

void group3(unsigned char op){  //200  
char data[][4] = {
  "ADD","ADC","SUB","SBB","ANA","XRA","ORA","CMP"  
};
unsigned char b,a;
   b = op&7;   a = (op&56)/8;
   Serial.print(data[a]);   Serial.print("   ");
   reg(b);
}

void group4(unsigned char op){   //300
unsigned char a,b;
const char data1[][5] = {"RET ","??? ","PCHL","SPHL"};
const char data3[][5] = {"JMP ","??? ","OUT ","IN  ","XTHL","XCHG","DI  ","EI  "};
const char data6[][4] = {"ADI","ACI","SUI","SBI","ANI","XRI","ORI","CPI"};

   a = op & 7;   b = (op&56)/8;
   switch(a){
      case 0: Serial.write('R');  condition(b);  break;
      case 1: 
         if( (b & 1) == 0 ){ Serial.print("POP   ");  reg_pair(op,b/2); }
         else Serial.print(data1[b/2]);
      break;
      case 2: Serial.write('J'); condition(b); address(); break;
      case 3:
         Serial.print(data3[b]); Serial.print("  ");
         if( b == 0 ) address();
         if( b == 2 || b == 3 ) immediate();
      break;
      case 4: Serial.write('C'); condition(b); address(); break;
      case 5:
         if( b == 1 ){ Serial.print("CALL  "); address(); }
         else if( (b & 1) == 0 ){ Serial.print("PUSH  ");  reg_pair(op,b/2); }
         else unknown();
      break;
      case 6:
         Serial.print(data6[b]); Serial.print("   ");  immediate();
      break;
      case 7: Serial.print("RST   "); Serial.print(b); break;
   }
  
}

void condition(unsigned char b){
char data[] = "NZZ NCC POPEP M ";
   b*= 2;
   Serial.write(data[b++]);  Serial.write(data[b]);
   Serial.write("   ");
}

void prnt(unsigned int val, char places ){
   if( places > 3 && val < 4096 ) Serial.write('0');
   if( places > 2 && val < 256 ) Serial.write('0');
   if( places > 1 && val < 16 ) Serial.write('0');
   Serial.print(val,HEX); 
}

