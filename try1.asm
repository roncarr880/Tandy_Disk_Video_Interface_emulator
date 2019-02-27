   ; offset to move code up without disturbing the relative addresses
   ; remove offset and use labels to relocate functions or remove functions
   ; offset as zero should assemble same as original image 


   .define offset $100

   .org $d200 +offset
 
D200    MVI   A,0C3h
    STA   $EEC2          ;2   JMP D83F
    STA   $EEB6          ;2   JMP D7DD
    LXI   H,D7DD
    SHLD  $EEB7
    LXI   H,D83F
    SHLD  $EEC3
    LXI   B,D22E       ; table pointer
    LXI   D,$F507       ; destination + offset
                           ; loop start
D21A    LDAX  B            ; get offset
    INX   B
    MOV   L,A          ; 
    INR   A
    JZ    D28C         ; exit if offset was FF
    MVI   H,00h
    DAD   D            ; calculate destination address
    LDAX  B
    INX   B
    MOV   M,A          ; store 1st
    INX   H
    LDAX  B
    INX   B
    MOV   M,A          ; store 2nd
    JMP   D21A

D22E                   ; table
    .db $48
    .dw D757    ;$d757 +offset 
    .db $44
    .dw D74D    ;$d74d +offset
    .db $08
    .dw D48E   ;  $d48e +offset
    .db $0c
    .dw D790    ;$d790 +offset
    .db $04
    .dw D86B    ;$d86b +offset
    .db $0a
    .dw D6F1    ;$d6f1 +offset
    .db $40
    .dw  D443  ;$d443 +offset
    .db $42
    .dw D767    ;$d767 +offset
    .db $10
    .dw D3F0   ;$d3f0 +offset
    .db $0e
    .dw $dc51 +offset
    .db $14
    .dw D3F4   ;$d3f4 +offset
    .db $16
    .dw D3E8   ;$d3e8 +offset
    .db $1e
    .dw D3E3   ;$d3e3 +offset
    .db $20
    .dw D3DF   ;$d3df +offset
    .db $22
    .dw D3EC   ;$d3ec +offset
    .db $30
    .dw  D3CC  ; $d3cc +offset
    .db $56
    .dw D3F8   ;$d3f8 +offset
    .db $5c
    .dw D3FC   ;$d3fc +offset
    .db $5e
    .dw D401   ;$d401 +offset
    .db $58
    .dw D406   ;$d406 +offset
    .db $5a
    .dw D40A   ;$d40a +offset
    .db $26
    .dw $de76 +offset
    .db $24
    .dw D40E   ;$d40e +offset
    .db $62
    .dw $e68e +offset
    .db $60
    .dw $e63f +offset
    .db $54
    .dw $e582 +offset
    .db $52
    .dw $e5a8 +offset
    .db $28
    .dw D412   ;$d412 +offset
    .db $00
    .dw  D399    ; $d399 +offset
    .db $02
    .dw  D3C5    ; $d3c5 +offset
    .db $36
    .dw D422    ;$d422 +offset
    .db $ff

D28C
    MVI   C,1Bh
    CALL  $D73F +offset
    MVI   C,63h
    CALL  $D73F +offset
    MVI   A,0FFh
    STA   $FEB1
    MVI   A,01h
    LXI   H,D2A3   ; try as a label
    SHLD  $EEB4

D2A3    CALL  $9BE1          ; final maxram address
    LXI   H,D887             ; FAT pointers stored there
    SHLD  $F738
    LXI   H,0000h
    MVI   A,0FFh
    SHLD  $E846  +offset      ;FAT stored here for drive 0:
    STA   $E848  +offset
    SHLD  $E849  +offset
    SHLD  $E89B  +offset      ;FAT for drive 1:
    STA   $E89D  +offset
    SHLD  $E89E  +offset     ; 1554 from old himem
    LXI   H,$504D
    SHLD  $EEAE       ; 61102 just below old himem 61104
    JMP   $9AE8

D2CC    PUSH  B
    CALL  D2D2    ; label
    POP   B
    RET

D2D2    MOV   H,A          ;g
    MVI   A,03h
    STA   $FEAF          ;2
    MVI   A,02h
    MOV   L,A          ;o
    JNC   D2E0
    DCR   A
    DCR   L
D2E0    JNZ   D2E4
    INR   L
D2E4    SHLD  $E844  +offset
    CALL  D35C
    MOV   A,H
    CALL  D35C
    LDA   $F73C
    CALL  D35C
    MOV   A,B          ;x
    CALL  D35C
    MOV   A,C          ;y
    CALL  D35C
    MVI   B,00h
    LDA   $E844  +offset
    DCR   A
    DCR   A
    JZ    D338
    JP    D34B
    MVI   A,02h
    STA   $FEAF          ;2
D30E    LDAX  D
    CALL  D35C
    INX   D
    DCR   B
    JNZ   D30E
    DCR   H
    JNZ   D30E
D31B    CALL  D389
    ANA   A
    RZ    
    PUSH  PSW
    CALL  D32C
    POP   PSW
    CPI   02h
    STC          ;7
    RNZ   
    JMP   $E614 +offset

D32C    CALL  $8FE6
    IN    80h
    RET 

D332    CALL  D32C
    JMP   $15AC

D338    CALL  D31B
    RC    
D33C    CALL  D389
    STAX  D
    INX   D
    DCR   B
    JNZ   D33C
    DCR   H
    JNZ   D338
    ANA   A
    RET 


D34B    CALL  D31B
    RC    
D34F    CALL  D389
    DCR   B
    JNZ   D34F
    DCR   H
    JNZ   D34B
    ANA   A
    RET 

D35C    PUSH  PSW
D35D    CALL  $8B69
    JC    D372
    IN    82h
    RLC
    JNC   D35D
    LDA   $FEAF
    OUT   81h
    POP   PSW
    OUT   80h
    RET 

D372    LDA   $FEAF
    ANA   A
    JNZ   D332
    LDA   $EF05
    ANA   A
    JZ    D332
    CALL  $8FD0
    JNZ   $D760 +offset
    JMP   D35D

D389    CALL  $8B69
    JC    D332
    IN    82h
    ANI   20h
    JZ    D389
    IN    80h
    RET 

D399    POP   B     ; vector table
    CALL  $0902
    DCX   H
    RST   2
    PUSH  H
    LHLD  $EEB4
    MOV   B,H          ;D
    MOV   C,L          ;M
    LHLD  $F61A
    JZ    $4E5C
    POP   H
    RST   1
    INR   L
    PUSH  D
    CALL  $12C3
    DCX   H
    RST   2
    JNZ   $0471
    XTHL  
    XCHG  
    MOV   A,H
    ANA   A
    JP    $0906
    PUSH  D
    LXI   D,D2A3+1   ;D2A4 in middle of an instruction
    JMP   $4E48

D3C5    POP   B    ; vector table
    LXI   H,D2A3
    JMP   $2893

D3CC    CALL  $5B3C    ; vector table
    RZ    
    SUI   30h
    RC    
    MOV   C,A          ;O
    CALL  $5B3C
    SUI   3Ah
    RNZ   
    INX   SP          ;3
    INX   SP          ;3
    INR   A
    MOV   A,C          ;y
    RET 

D3DF    POP   H
    JMP   $DC08 +offset
D3E3    RNC   
    POP   PSW
    JMP   $DC92 +offset
D3E8    POP   H
    JMP   $DD65 +offset
D3EC    POP   D
    JMP   $E156 +offset
D3F0    POP   D
    JMP   $E191 +offset
D3F4    POP   B
    JMP   $E5E3 +offset
D3F8    POP   B
    JMP   $E00F +offset
D3FC    INX   SP          ;3
    INX   SP          ;3
    JMP   $DDEB +offset
D401    POP   B
    PUSH  H
    JMP   $DC60 +offset
D406    POP   B
    JMP   $E1D6 +offset
D40A    POP   B
    JMP   $E218 +offset
D40E    POP   B
    JMP   $DE00 +offset
D412    POP   PSW
    LDA   $F73C
    PUSH  PSW
    CALL  $5B40
    JNC   $E5C2 +offset
    INX   SP          ;3
    INX   SP          ;3
    JMP   $1A00

D422    PUSH  H
    PUSH  D
    PUSH  B
    PUSH  PSW
    LXI   H,000Ch
    DAD   SP          ;9
    LXI   D,$1DA0
    CALL  $D881 +offset
    JNZ   $1604
    LXI   H,0010h
    DAD   SP
    INX   H
    MOV   A,M
    STA   $EF05 +offset
D43C    POP   PSW
    POP   B
    POP   D
D43F    POP   H
    POP   H
    POP   H
    RET 

D443    POP   D
    CALL  $1158
    PUSH  H
    MVI   C,63h
    CPI   28h
    JZ    D455
    INR   C
    CPI   50h
    JNZ   $0906
D455    STA   $EF12
    LXI   H,0101h
    SHLD  $EF0F
    LDA   $EF05
    ANA   A
    JZ    D46E
    LDA   $EF12
    STA   $EF09
    SHLD  $EF06
D46E    PUSH  B
    MVI   C,1Bh
    CALL  $D73F +offset
    POP   B
    CALL  $D73F +offset
    LDA   $EF0A
    LXI   H,$EF05
    ANA   M
    CNZ   $4FC7
    POP   H
    RET 

D484    .DB   "ATDNTSFEDF"

D48E    PUSH  PSW
    CPI   3Fh
    JNZ   D4BF
    LXI   H,0010h
    DAD   SP          ;9
    MOV   B,H          ;D
    MOV   C,L          ;M
    LXI   D,0515h
    CALL  $D881  +offset
    JNZ   D4BF
    LDA   $EF5D
    SUI   3Bh
    CPI   05h
    JNC   D4BF
    MOV   E,A
    MVI   D,00h
    LXI   H,D484
    DAD   D
    DAD   D
    DCX   B
    DCX   B
    DCX   B
    DCX   B
    DCX   B
    MOV   A,H
    STAX  B
    DCX   B
    MOV   A,L
    STAX  B
D4BF    LXI   H,0010h
    DAD   SP          ;9
    LXI   D,$7AE6
    CALL  $D881  +offset
    JNZ   D4E7
    LDA   $EF07
    CPI   17h
    JNZ   D4E7
    POP   PSW
    PUSH  PSW
    MOV   B,A          ;G
    LDA   $EF05
    ANA   A
    MOV   A,B          ;x
    PUSH  PSW
    CZ    $503C
    POP   PSW
    CNZ   $D6A7  +offset
    JMP   $D679  +offset

D4E7    LDA   $EF05
    ANA   A
    JZ    D542
    LDA   $EF09
    CPI   50h
    JNZ   D51D
    LXI   H,0010h
    DAD   SP          ;9
    LXI   D,$7DD5
    CALL  $D881  +offset
    JNZ   D51D
    LDA   $EF10
    CPI   07h
    JNZ   D51D
    POP   PSW
    PUSH  PSW
    MOV   B,A          ;G
    MVI   C,28h
D510    MOV   A,B          ;x d510
    PUSH  B
    CALL  $D6A7  +offset
    POP   B
    DCR   C
    JNZ   D510
    JMP   $D679  +offset

D51D    LDA   $EF05
    ANA   A
    JZ    D542
    LXI   H,0014h
    DAD   SP
    LXI   D,$2579
    CALL  $D881  +offset
    JNZ   D542
    CALL  $8FD0
    JZ    D542
    XRA   A
    CALL  $2922
    MVI   A,28h
    STA   $EF09
    POP   PSW
    RET 


D542    LXI   H,0014h
    DAD   SP
    LXI   D,$8395
    CALL  $D881  +offset
    JNZ   D557
    MVI   A,01h
    STA   $D8AF  +offset
    JMP   $D679  +offset


D557    LDA   $D8AF  +offset
    ANA   A
    JZ    D58B
    LXI   H,0012h
    DAD   SP
    LXI   D,$053C
    CALL  $D881  +offset
    JNZ   D58B
    XRA   A
    STA   $D8AF  +offset
    LXI   H,$D88B +offset
D572    MOV   A,M
    INX   H
    ANA   A
    JZ    $D679 +offset
    PUSH  H
    MOV   C,A
    LDA   $EF05
    ANA   A
    MOV   A,C
    PUSH  PSW
    CZ    $503C
    POP   PSW
    CNZ   $D6A7  +offset
    POP   H
    JMP   D572

D58B    LDA   $EF05
    ANA   A
    JZ    $D679 +offset
    LDA   $EF13
    ANA   A
    JP    $D679  +offset
    POP   PSW
    PUSH  PSW
    CPI   66h
    JZ    $D675  +offset
    CPI   65h
    JZ    $D674  +offset
    CPI   52h
    LXI   H,$D952  +offset
    JZ    D5E3
    CPI   53h
    JZ    D5BF
    CPI   72h
    LXI   H,D8B1
    JZ    D5E3
    CPI   73h
    JNZ   $D679  +offset
D5BF    PUSH  H
    CALL  $D6A7  +offset
    MVI   D,6Bh
    CALL  $D7D4  +offset
    CALL  D389
    POP   H
    MOV   B,A
    MVI   C,02h
    MOV   M,A
    INX   H
    MOV   D,B
D5D2    CALL  D389
    MOV   M,A 
    INX   H
    DCR   B
    JNZ   D5D2
    MOV   B,D
    DCR   C
    JNZ   D5D2
    JMP   $D666  +offset

D5E3    PUSH  H
    CALL  D6A7
    POP   H
    PUSH  H
    MOV   A,M
    ORA   A
    JZ    D665
    LHLD  $EF06
    MVI   B,01h
    MOV   C,L          ;M
    CALL  D66B
    MVI   A,59h
    CALL  D66D
    MOV   A,C          ;y
    ADI   1Fh
    CALL  D66D
    MOV   A,B          ;x
    ADI   1Fh
    CALL  D66D
    POP   H
    MOV   B,M          ;F
    INX   H
    PUSH  H
    MVI   D,00h
    MOV   E,B          ;X
    DAD   D
    XCHG  
    POP   H
D612    LDAX  D
    PUSH  B
    PUSH  D
    PUSH  H
    MOV   C,A          ;O
    PUSH  B
    CALL  D66B
    ANI   02h
    MVI   A,70h
    JNZ   D623
    INR   A
D623    CALL  D6A7
    POP   B
    CALL  D66B
    ANI   01h
    MVI   A,65h
    JZ    D632
    INR   A
D632    CALL  D6A7
    POP   H
    PUSH  H
    MOV   A,M
    CALL  D6A7
    POP   H
    POP   D
    POP   B
    INX   H
    INX   D
    DCR   B
    JNZ   D612
    LDA   $EF15
    ANA   A
    MVI   C,70h
    JNZ   D64E
    INR   C
D64E    CALL  D66B
    CALL  D6A7
    LDA   D8B0
    ANA   A
    MVI   C,65h
    JNZ   D65E
    INR   C
D65E    CALL  D66B
    CALL  D6A7
    PUSH  H
D665    POP   H
    POP   PSW
    POP   PSW
    JMP   $1604

D66B    MVI   A,1Bh
D66D    PUSH  B
    CALL  D6A7
    POP   B
    MOV   A,C          ;y
    RET 

D674    ORI   0AFh
    STA   D8B0
    POP   PSW
    MOV   C,A          ;O
    LDA   $EF05
    ORA   A
    MOV   A,C          ;y
    LXI   H,D6A0   ; strange code here
    JNZ   D6A1     ; jump to 2nd part of lxi
    MOV   A,M
    MVI   M,00h          ;6
    ANA   A
    MOV   A,C          ;y
    RZ    
    PUSH  PSW
    LDA   $FEB0
    INR   A
    JNZ   D69E
    MVI   C,1Bh
    CALL  $D73F  +offset
    MVI   C,51h
    CALL  $D73F  +offset
D69E    POP   PSW
    RET 


D6A0    NOP
D6A1    MVI   M,0FFh
    LXI   H,$1604
    XTHL  
D6A7    CALL  $D727  +offset
    MOV   C,A
    MVI   A,01h
    STA   $F4F5
    LDA   $EF05
    ANA   A
    JZ    D6C1
    CALL  $5062
    LHLD  $EF06
    SHLD  $EF0F
    RET 

D6C1    LDA   $EF0A
    PUSH  PSW
    XRA   A
    STA   $EF0A          ;2
    LHLD  $EF06
    PUSH  H
    LHLD  $EF0F
    SHLD  $EF06
    LHLD  $EF11
    SHLD  $EF08
    CALL  $5062
    LHLD  $EF06
    SHLD  $EF0F
    LXI   H,2810h
    SHLD  $EF08
    POP   H
    SHLD  $EF06
    POP   PSW
    STA   $EF0A          ;2
    RET

D6F1    LDA   $EF05
    ANA   A
    RZ    
    POP   H
    LDA   $EF0A
    PUSH  PSW
    XRA   A
    STA   $EF0A          ;2
    LHLD  $EF06
    PUSH  H
    LHLD  $EF0D
    SHLD  $EF06
    LXI   H,2810h
    SHLD  $EF08
    CALL  $5062
    LHLD  $EF06
    SHLD  $EF0D
    LHLD  $EF11
    SHLD  $EF08
    POP   H
    SHLD  $EF06
    POP   PSW
    STA   $EF0A          ;2
    RET 

D727    PUSH  H
    PUSH  D
    PUSH  B
    PUSH  PSW
    MOV   C,A          ;O
    CALL  D73F
    LDA   $F222
    ANA   A
    JZ    $1604
    MOV   A,C          ;y
    CPI   58h
    CZ    $8FE6
    JMP   $1604

D73F    XRA   A
    STA   $FEAF          ;2
    CALL  $8FD0
    JNZ   D760
    MOV   A,C          ;y
    JMP   D35C

D74D    POP   PSW
    CALL  $8FD0
    JNZ   D760
    JMP   $15EF
D757    POP   H
    POP   PSW
    PUSH  PSW
    CALL  D6A7
    JMP   $1604


D760    XRA   A
    CALL  $2922
    JMP   $15AC
D767    CALL  $8D11
    MVI   A,01h
    STA   $EF05          ;2
    LHLD  $EF0F
    PUSH  H
    SHLD  $EF06
    CALL  $4F63
    CALL  $4F6D
    LHLD  $EF11
    XCHG  
    POP   H
    LDA   $EF12
    MOV   B,A          ;G
D785    SUI   0Eh
    JNC   D785
    ADI   1Ch
    CMA
    INR   A
    ADD   B
    RET 

D790    PUSH  H
    PUSH  D
    PUSH  PSW
    LXI   H,0008h
    DAD   SP          ;9
    MOV   E,M
    INX   H
    MOV   D,M          ;V
    PUSH  H
    LXI   H,$5A64
    RST   3
    POP   H
    JNZ   D7AE
    INX   H
    MOV   E,M
    INX   H
    MOV   D,M          ;V
    LXI   H,$294A
    RST   3
    JZ    D7B2
D7AE    POP   PSW
    POP   D
    POP   H
    RET


D7B2    LDA   $EF05
    ANA   A
    JZ    D7AE
    POP   H
    POP   H
    POP   H
    POP   H
    POP   H
    POP   H
    MVI   D,4Bh
    CALL  D7D4
D7C4    CALL  D389
    ANA   A
    POP   H
    RZ    
    PUSH  H
    CALL  $84C9
    JC    D332
    JMP   D7C4

D7D4    MVI   A,01h
    STA   $FEAF          ;2
    MOV   A,D          ;z
    JMP   D35C

D7DD    DI    
    CALL  D32C
D7E1    LXI   B,03E8h
D7E4    CALL  $8B69
    JC    D7E1
    DCX   B
    MOV   A,B          ;x
    ORA   C
    JNZ   D7E4
    POP   H
    PUSH  H
    LXI   D,99F7h
    RST   3
    JZ    D81F
    LDA   $EF05
    ANA   A
    RZ    
    POP   H
    LXI   D,0018h
    DAD   D
    PUSH  H
    CALL  $99FF
    LHLD  $FEAA
    PUSH  H
    LDA   $F4F6
    ANA   A
    JNZ   $99E0
    CALL  $54A7
    CALL  $8D11
    MVI   A,01h
    STA   $FEB3          ;2
    POP   H
    RET

D81F    LDA   $FEB0
    ANA   A
    RZ    
    MVI   C,63h
    LDA   $EF12
    CPI   28h
    JZ    D82F
    INR   C
D82F    PUSH  B
    MVI   C,1Bh
    CALL  D73F
    POP   B
    CALL  D73F
    MVI   C,00h
    CALL  D73F
    RET
 
D83F    PUSH  PSW
    SHLD  D8A9
    POP   H
    SHLD  D8AD
    XCHG  
    SHLD  D8AB
    LXI   H,0000h
    DAD   SP          ;9
    LXI   D,$FF80
    RST   3
    JC    D85E
    LXI   D,$FFC0
    RST   3
    JNC   D85E
    POP   H
D85E    LHLD  D8AB
    XCHG  
    LHLD  D8AD
    PUSH  H
    LHLD  D8A9
    POP   PSW
    RET 

D86B    LXI   H,000Ah
    DAD   SP          ;9
    LXI   D,$77D5
    CALL  D881
    RNZ   
    CALL  $4F6D
    LDA   $EF05
    ANA   A
    RZ    
    JMP   $8D11

D881    MOV   A,M     
    INX   H           
    MOV   H,M          ;f
    MOV   L,A          ;o
    RST   3
    RET 

D887    .DW   $E848 +offset   ; Fat addresses again
D889    .DW   $E89D +offset   ; need to point to the storage area where
                              ; they are located

D88B    .DB "[DISK-VIDEO code installed]",0dh,0ah,0

D8A9    .DW 0000h
D8AB    .DW 0000h
D8AD    .DW 0000h

D8AF    NOP
D8B0    .DB   0
D8B1    .DW   0000h

       ;  D8B3 to D9F2 seems to be wasted space 320 bytes

      .ORG   $D9F3 + offset

D9F3    LHLD  $F73D
    MOV   B,M          ;F
    INX   H
    INX   H
    MOV   A,M
    ORA   A
    JZ    $E5FC  +offset
    INX   H
    XCHG  
    MOV   A,B          ;x
    ADD   A
    MOV   C,A          ;O
    MOV   B,A          ;G
DA04    MVI   H,00h
    MOV   L,B          ;h
    DAD   D
    MOV   A,M
    INR   A
    JZ    DA26
DA0D    MOV   A,C          ;y
    ORA   A
    JZ    DA1C
    DCR   C
    MVI   H,00h
    MOV   L,C          ;i
    DAD   D
    MOV   A,M
    INR   A
    JZ    DA27
DA1C    MOV   A,B          ;x
    CPI   4Fh
    JNC   DA0D
    INR   B
    JMP   DA04
DA26    MOV   C,B          ;H
DA27    MVI   M,0C0h          ;6
    XCHG  
    DCX   H
    DCR   M          ;5
    INX   H
    XCHG  
    LHLD  $F73F
    INX   H
    MOV   A,M
    ORA   A
    INR   A
    MOV   M,C          ;q
    JZ    DA41
    DCR   A
    MOV   M,A          ;w
    PUSH  B
    CALL  $DB72  +offset
    POP   B
    MOV   M,C          ;q
DA41    MVI   B,09h
    JC    $0106
    LHLD  $F73D
    DCX   H
    DCX   H
    MVI   M,0FFh          ;6
    INX   H
    INX   H
    INX   H
    MOV   A,M
    ORA   A
    JNZ   DA58
    MVI   A,12h
    MOV   M,A          ;w
DA58    SUB   B
    JC    $E2FC +offset
    MOV   M,A          ;w
    RET 


DA5E    LHLD  $F73F
    INX   H
    MOV   A,M
    CALL  $DB56  +offset
    MVI   B,00h
DA68    MOV   L,A          ;o
    MVI   H,00h
    DAD   D
    MOV   A,M
    INR   B
    MVI   M,0FFh          ;6
    CPI   0C0h
    JC    DA68
    DCX   D
    LDAX  D
    ADD   B
    STAX  D
    DCX   D
    STAX  D
    XCHG  
    DCX   H
    DCX   H
    DCX   H
    MVI   M,0FFh          ;6
    XCHG  
    RET

DA83    MVI   E,00h
    MVI   D,10h
DA87    CALL  $E379  +offset
    JNZ   DA8E
    INR   E
DA8E    INR   D
    MOV   A,D          ;z
    SUI   13h
    JNZ   DA87
    ORA   E
    JZ    $E5F0  +offset
    MVI   A,03h
    SUB   E
    CNZ   $E336  +offset
    LHLD  $F73D
    MVI   M,14h          ;6
    DCX   H
    DCX   H
    MVI   M,00h          ;6
    INX   H
    INX   H
    INX   H
    INX   H
    PUSH  H
    INX   H
    MVI   B,50h
    XRA   A
DAB1    MOV   C,M          ;N
    INX   H
    INR   C
    JNZ   DAB8
    INR   A
DAB8    DCR   B
    JNZ   DAB1
    PUSH  PSW
    LXI   B,$140F
    LHLD  $F73A
    MVI   A,01h
    ORA   A
    CALL  $E537  +offset
    DCR   A
    JC    DACE
    MOV   A,M
DACE    LHLD  $F73D
    DCX   H
    ANI   70h
    MOV   M,A          ;w
    POP   PSW
    POP   H
    MOV   M,A          ;w
    RET 


DAD9    MOV   C,A          ;O
    CALL  $DC2E  +offset
    RZ    
    DCX   H
    DCX   H
    MOV   A,M
    ORA   A
    JZ    DAEB
    CALL  $E308  +offset
    JC    $E5F0  +offset
DAEB    LHLD  $F73D
    INX   H
    MVI   M,00h          ;6
    DCX   H
    MVI   M,0FFh          ;6
    DCX   H
    MVI   M,00h          ;6
    DCX   H
    MVI   M,00h          ;6
    RET

DAFB    PUSH  H
    PUSH  D
    PUSH  B
    MOV   B,A          ;G
    LDA   $F73C
    PUSH  PSW
    MOV   A,B          ;x
    ORA   A
    JM    DB11
    LDA   $F73C
    CALL  DB19
    CNZ   DAD9
DB11    POP   PSW
    ORA   A
    CP    $DC2E  +offset
    JMP   DB39

DB19    MOV   C,A          ;O
    LDA   $F735
    MOV   B,A          ;G
DB1E    MOV   A,B          ;x
    CALL  $5B43
    JZ    DB2C
    INX   H
    INX   H
    INX   H
    INX   H
    MOV   A,M
    CMP   C
    RZ    
DB2C    DCR   B
    JP    DB1E
    MOV   A,C          ;y
    RET
 
DB32    PUSH  H
    PUSH  D
    PUSH  B
    ORA   A
    CP    DA83
DB39    JMP   $E18D +offset

DB3C    INX   H
    MOV   A,M
    INX   H
    MOV   B,M          ;F
    CALL  DB56
    MVI   C,00h
    JMP   DB51

DB48    MOV   L,A          ;o
    MVI   H,00h
    DAD   D
    MOV   A,M
    INR   C
    JZ    $E5F0  +offset
DB51    CMP   B
    JNZ   DB48
    RET 

DB56    LHLD  $F73D
    INX   H
    INX   H
    INX   H
    XCHG  
    RET 

DB5E    INX   H
    INX   H
    MOV   E,M
    INX   H
    MOV   B,M          ;F
    CALL  DB56
    MVI   H,00h
    DAD   D
    MOV   A,M
    SUI   0C0h
    CMC
    RNC   
    CMP   B
    RNZ   
    STC          ;7
    RET 

DB72    LHLD  $F73F
    INX   H
    MOV   A,M
    CALL  DB56
    MVI   C,00h
DB7C    MOV   L,A          ;o
    MOV   B,A          ;G
    MVI   H,00h
    DAD   D
    INR   C
    JZ    $E5F0  +offset
    MOV   A,M
    CPI   0C0h
    JC    DB7C
    CPI   0CAh
    JNC   $E5F0  +offset
    DCR   C
    SUI   0C0h
    RET 

DB94    PUSH  B
    MVI   B,00h
    MOV   L,C          ;i
    MOV   H,B
    DAD   H
    DAD   H
    DAD   H
    DAD   B
    XCHG  
    POP   B
    RET

DBA0    XRA   A
    STA   $F743          ;2
    MVI   D,01h
    CALL  $E3A3  +offset
    MVI   E,10h
    MOV   A,M
    INR   A
    JZ    DBE9
    DCR   A
    JNZ   DBBC
    SHLD  $F741
    XCHG  
    SHLD  $F743
    XCHG  
DBBC    LXI   B,$F746
    PUSH  D
    PUSH  H
    MVI   E,09h
DBC3    LDAX  B
    CMP   M
    JNZ   DBD8
    INX   H
    INX   B
    DCR   E
    JNZ   DBC3
    POP   D
    POP   H
    SHLD  $F743
    XCHG  
    SHLD  $F741
    RET 

dbd8
dbe9
    .end