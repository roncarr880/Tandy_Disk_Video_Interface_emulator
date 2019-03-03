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
    LXI   D,$F507       ; destination + table relative addresses
                           ; loop start
D21A    LDAX  B            ; get table relative address
    INX   B                ; 
    MOV   L,A          ; 
    INR   A
    JZ    D28C         ; exit if was FF
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

D22E                   ; table of relative destination and data word to write
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
    .dw D443  ;$d443 +offset
    .db $42
    .dw D767    ;$d767 +offset
    .db $10
    .dw D3F0   ;$d3f0 +offset
    .db $0e
    .dw DC51   ;$dc51 +offset
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
    .dw D3CC  ; $d3cc +offset
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
    .dw DE76   ;$de76 +offset
    .db $24
    .dw D40E   ;$d40e +offset
    .db $62
    .dw E68E   ;$e68e +offset
    .db $60
    .dw E63F   ;$e63f +offset
    .db $54
    .dw E582   ;$e582 +offset
    .db $52
    .dw E5A8   ;$e5a8 +offset
    .db $28
    .dw D412   ;$d412 +offset
    .db $00
    .dw D399    ; $d399 +offset
    .db $02
    .dw D3C5    ; $d3c5 +offset
    .db $36
    .dw D422    ;$d422 +offset
    .db $ff

D28C
    MVI   C,1Bh
    CALL  D73F   ;$D73F +offset
    MVI   C,63h
    CALL  D73F   ;$D73F +offset
    MVI   A,0FFh
    STA   $FEB1
    MVI   A,01h
    LXI   H,D2A3
    SHLD  $EEB4

D2A3    CALL  $9BE1          ; final maxram address, previous code run one time only
    LXI   H,D887             ; FAT pointers stored there
    SHLD  $F738
    LXI   H,0000h
    MVI   A,0FFh
    SHLD  E846   ;$E846  +offset      ;FAT stored here for drive 0:
    STA   E848   ;$E848  +offset
    SHLD  E849   ;$E849  +offset
    SHLD  E89B   ;$E89B  +offset      ;FAT for drive 1:
    STA   E89D   ;$E89D  +offset
    SHLD  E89E   ;$E89E  +offset     ; 1554 from old himem
    LXI   H,$504D
    SHLD  $EEAE       ; 61102 just below old himem 61104
    JMP   $9AE8

D2CC    PUSH  B
    CALL  D2D2
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
D2E4    SHLD  E844   ;$E844  +offset
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
    LDA   E844     ;$E844  +offset
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
    JMP   E613+1   ;$E614 +offset

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
    JNZ   D760    ;$D760 +offset
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
    JMP   DC08    ;$DC08 +offset
D3E3    RNC   
    POP   PSW
    JMP   DC92     ;$DC92 +offset
D3E8    POP   H
    JMP   DD65     ;$DD65 +offset
D3EC    POP   D
    JMP   E156     ;$E156 +offset
D3F0    POP   D
    JMP   E191     ;$E191 +offset
D3F4    POP   B
    JMP   E5E3     ;$E5E3 +offset
D3F8    POP   B
    JMP   E00F     ;$E00F +offset
D3FC    INX   SP          ;3
    INX   SP          ;3
    JMP   DDEB     ;$DDEB +offset
D401    POP   B
    PUSH  H
    JMP   DC60     ;$DC60 +offset
D406    POP   B
    JMP   E1D6     ;$E1D6 +offset
D40A    POP   B
    JMP   E218     ;$E218 +offset
D40E    POP   B
    JMP   DE00     ;$DE00 +offset
D412    POP   PSW
    LDA   $F73C
    PUSH  PSW
    CALL  $5B40
    JNC   E5C2     ;$E5C2 +offset
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
    CALL  D881     ;$D881 +offset
    JNZ   $1604
    LXI   H,0010h
    DAD   SP
    INX   H
    MOV   A,M
    STA   $EF05
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
    CALL  D73F    ;$D73F +offset
    POP   B
    CALL  D73F    ;$D73F +offset
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
    CALL  D881      ;$D881  +offset
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
    CALL  D881      ;$D881  +offset
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
    CNZ   D6A7     ;$D6A7  +offset
    JMP   D679     ;$D679  +offset

D4E7    LDA   $EF05
    ANA   A
    JZ    D542
    LDA   $EF09
    CPI   50h
    JNZ   D51D
    LXI   H,0010h
    DAD   SP          ;9
    LXI   D,$7DD5
    CALL  D881      ;$D881  +offset
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
    CALL  D6A7     ;$D6A7  +offset
    POP   B
    DCR   C
    JNZ   D510
    JMP   D679     ;$D679  +offset

D51D    LDA   $EF05
    ANA   A
    JZ    D542
    LXI   H,0014h
    DAD   SP
    LXI   D,$2579
    CALL  D881     ;$D881  +offset
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
    CALL  D881     ;$D881  +offset
    JNZ   D557
    MVI   A,01h
    STA   D8AF     ;$D8AF  +offset
    JMP   D679     ;$D679  +offset


D557    LDA   D8AF   ;$D8AF  +offset
    ANA   A
    JZ    D58B
    LXI   H,0012h
    DAD   SP
    LXI   D,$053C
    CALL  D881     ;$D881  +offset
    JNZ   D58B
    XRA   A
    STA   D8AF     ;$D8AF  +offset
    LXI   H,D88B   ;$D88B +offset
D572    MOV   A,M
    INX   H
    ANA   A
    JZ    D679     ;$D679 +offset
    PUSH  H
    MOV   C,A
    LDA   $EF05
    ANA   A
    MOV   A,C
    PUSH  PSW
    CZ    $503C
    POP   PSW
    CNZ   D6A7     ;$D6A7  +offset
    POP   H
    JMP   D572

D58B    LDA   $EF05
    ANA   A
    JZ    D679    ;$D679 +offset
    LDA   $EF13
    ANA   A
    JP    D679    ;$D679  +offset
    POP   PSW
    PUSH  PSW
    CPI   66h     ; 'f'
    JZ    D675    ;$D675  +offset
    CPI   65h     ; 'e'
    JZ    D674    ;$D674  +offset
    CPI   52h     ; 'R'
    LXI   H,D952   ;$D952  +offset
    JZ    D5E3
    CPI   53h     ; 'S'
    JZ    D5BF
    CPI   72h     ; 'r'
    LXI   H,D8B1
    JZ    D5E3
    CPI   73h     ; 's'
    JNZ   D679    ;$D679  +offset
D5BF    PUSH  H   ; 's' or 'S' with H as D8B1 or D952.  What is this?
    CALL  D6A7    ;$D6A7  +offset
    MVI   D,6Bh
    CALL  D7D4    ;$D7D4  +offset
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
    JMP   D666   ;$D666  +offset

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
D666    POP   PSW
    POP   PSW
    JMP   $1604

D66B    MVI   A,1Bh
D66D    PUSH  B
    CALL  D6A7
    POP   B
    MOV   A,C          ;y
    RET 

D674    ORI   0AFh
D675    STA   D8B0
D679    POP   PSW
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
    CALL  D73F    ;$D73F  +offset
    MVI   C,51h
    CALL  D73F    ;$D73F  +offset
D69E    POP   PSW
    RET 


D6A0    NOP
D6A1    MVI   M,0FFh
    LXI   H,$1604
    XTHL  
D6A7    CALL  D727   ;$D727  +offset
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

D887    .DW   E848    ;$E848 +offset   ; Fat addresses again
D889    .DW   E89D    ;$E89D +offset   ; need to point to the storage area where
                              ; they are located

D88B    .DB "[DISK-VIDEO code installed]",0dh,0ah,0

D8A9    .DW 0000h
D8AB    .DW 0000h
D8AD    .DW 0000h

D8AF    .DB   0
D8B0    .DB   0
D8B1    .DS   161

D952    .DS   161

       ;  D8B3 to D9F2 seems to never be overwritten
       ;  code that uses this space is never used?
       ;  D8B1 to D952 is another 160
       ;  half the M200 screen size but split in two?

       ; .ORG   $D9F3 + offset

D9F3    LHLD  $F73D
    MOV   B,M          ;F
    INX   H
    INX   H
    MOV   A,M
    ORA   A
    JZ    E5FB+1    ;$E5FC  +offset
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
    CALL  DB72    ;$DB72  +offset
    POP   B
    MOV   M,C          ;q
DA41    MVI   B,09h
DA43    JC    $0106   ; da44 is a jump target in middle of instruction
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
    JC    E2FC    ;$E2FC +offset
    MOV   M,A          ;w
    RET 


DA5E    LHLD  $F73F
    INX   H
    MOV   A,M
    CALL  DB56    ;$DB56  +offset
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
DA87    CALL  E379    ;$E379  +offset
    JNZ   DA8E
    INR   E
DA8E    INR   D
    MOV   A,D          ;z
    SUI   13h
    JNZ   DA87
    ORA   E
    JZ    E5F0     ;$E5F0  +offset
    MVI   A,03h
    SUB   E
    CNZ   E336     ;$E336  +offset
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
    CALL  E537     ;$E537  +offset
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
    CALL  DC2E    ;$DC2E  +offset
    RZ    
    DCX   H
    DCX   H
    MOV   A,M
    ORA   A
    JZ    DAEB
    CALL  E308    ;$E308  +offset
    JC    E5F0    ;$E5F0  +offset
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
    CP    DC2E    ;$DC2E  +offset
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
DB39    JMP   E18D    ;$E18D +offset

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
    JZ    E5F0      ;$E5F0  +offset
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
DB75    INX   H
    MOV   A,M
    CALL  DB56
    MVI   C,00h
DB7C    MOV   L,A          ;o
    MOV   B,A          ;G
    MVI   H,00h
    DAD   D
    INR   C
    JZ    E5F0     ;$E5F0  +offset
    MOV   A,M
    CPI   0C0h
    JC    DB7C
    CPI   0CAh
    JNC   E5F0     ;$E5F0  +offset
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
DBA6    CALL  E3A3     ;$E3A3  +offset
    MVI   E,10h
DBAB    MOV   A,M
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

DBD8    POP   H
    LXI   D,0010h
    DAD   D
    POP   D
    DCR   E
    JNZ   DBAB
    INR   D
    MOV   A,D          ;z
    CPI   0Fh
    JNZ   DBA6
DBE9    LDA   $F743
    ORA   A
    JZ    DC01
    LHLD  $F741
    LDA   $F744
    CMP   D
    JZ    DBFF
    ADI   80h
    STA   $F744          ;2
DBFF    ORA   A
    RET 


DC01    MOV   A,E
    ADI   80h
    STA   $F743          ;2
    RET 
DC08    CALL  DC2E
    POP   H
    MOV   A,M
    ORA   A
    RET 
DC0F    PUSH  H
    XRA   A
    STA   $FEB0          ;2
    CALL  $8FD5
    CALL  $8FF3
    POP   H
    JNC   DC1F
    XRA   A
DC1F    STA   $F734          ;2
    ANA   A
    JNZ   DC31
    JMP   E5F2+1    ;$E5F3  +offset


DC29    SUI   01h
    JC    E5F2+1    ;$E5F3  +offset
DC2E    MVI   H,00h
    MOV   L,A          ;o
DC31    LDA   $F734
    ORA   A
    JZ    DC0F
    DCR   A
    CMP   L
    JC    E5F2+1    ;$E5F3  +offset
    MOV   A,L
    STA   $F73C          ;2
    DAD   H
    XCHG  
    LHLD  $F738
    DAD   D
    MOV   A,M
    INX   H
    MOV   H,M          ;f
    MOV   L,A          ;o
    MOV   A,M
    SHLD  $F73D
    INR   A
    RET 

DC51    RC    
    XCHG  
    LHLD  $F73D
    MOV   A,M
    INR   A
    XCHG  
    MOV   A,M
    RNZ   
    MVI   M,00h          ;6
    JMP   E60A+1   ;$E60B  +offset

DC60    CALL  DC2E
    CALL  DBA0
    JZ    E5F8+1    ;$E5F9  +offset
    CALL  DC7E
    CALL  DBA0
    JNZ   E604+1   ;$E605  +offset
    CALL  DC81
    LDA   $F744
    MOV   D,A          ;W
    CALL  E3B7    ;$E3B7  +offset
    POP   H
    RET
 
DC7E    LXI   H,$F746
DC81    LXI   D,$F74F
DC84    MVI   B,09h
DC86    MOV   C,M          ;N
    LDAX  D
    MOV   M,A          ;w
    MOV   A,C          ;y
    STAX  D
    INX   D
    INX   H
    DCR   B
    JNZ   DC86
    RET

DC92    PUSH  D
    PUSH  H
    MOV   A,D          ;z
    CALL  DC2E
    POP   H
    POP   D
    JNZ   DCA1
    MOV   A,D          ;z
    CALL  DB32
DCA1    MOV   M,E          ;s
    INX   H
    MVI   M,0FFh          ;6
    INX   H
    INX   H
    INX   H
    MOV   M,D          ;r
    POP   PSW
    CALL  $5B7E
    MOV   A,M
    MVI   M,00h          ;6
    STA   $F745          ;2
    PUSH  PSW
    CALL  DBA0
    JZ    DCCC
    POP   PSW
    MOV   B,A          ;G
    ANI   86h
    JZ    E604+1 ;$E605  +offset
    MOV   A,B          ;x
    STC          ;7
    CALL  DD64       ;$DD64  +offset
DCC6    CALL  DF93   ;$DF93  +offset
    JMP   DD2C       ;$DD2C  +offset

DCCC    PUSH  H
    LXI   D,0009h
    DAD   D
    MOV   A,M
    INX   H
    MOV   E,M
    LHLD  $F73F
    INX   H
    MOV   M,E          ;s
    INX   H
    INX   H
    INX   H
    INX   H
    INX   H
    INX   H
    ANI   0F1h
    MOV   M,A          ;w
    POP   H
    POP   PSW
    CPI   08h
    JZ    DD14
    MOV   B,A          ;G
    ANI   05h
    JNZ   DD2C
    PUSH  B
    PUSH  H
    CALL  DD64    ;$DD64  +offset
    CALL  DF51    ;$DF51  +offset
    JC    E601+1
    CALL  DA5E
    LHLD  $F73F
    INX   H
    MVI   M,0FFh          ;6
    POP   H
    POP   PSW
    ANI   82h
    JNZ   DCC6
    MOV   M,A          ;w
    LDA   $F744
    MOV   D,A          ;W
    CALL  E3B7     ;$E3B7  +offset
    POP   H
    RET

DD14    CALL  DB72
    LHLD  $F73F
    INX   H
    INX   H
    MOV   M,B          ;p
    INX   H
    ORA   A
    JZ    DD27
    DCR   A
    MOV   M,A          ;w
    JMP   DD36

DD27    LHLD  $F73F
    MVI   M,02h          ;6
DD2C    LHLD  $F73F
    INX   H
    MOV   A,M
    INX   H
    MOV   M,A          ;w
    INX   H
    MVI   M,00h          ;6
DD36    INX   H
    INX   H
    XRA   A
    MOV   M,A          ;w
    INX   H
    MOV   M,A          ;w
    INX   H
    MOV   A,M
    ORI   02h
    MOV   M,A          ;w
    CALL  $5DB6
    DCX   H
    MOV   M,A          ;w
    LHLD  $F73F
    LDA   $F745
    CPI   08h
    JNZ   DD53
    MVI   A,02h
DD53    MOV   M,A          ;w
    JNZ   DD62
    INX   H
    INX   H
    INX   H
    INX   H
    INX   H
    INX   H
    INX   H
    MOV   A,M
    ORI   20h
    MOV   M,A          ;w
DD62    POP   H
DD63    RET 
DD64    RET

DD65    CALL  E2E8    ;$E2E8  +offset
    JZ    DD7A
    LHLD  $F73F
    LXI   D,0006h
    DAD   D
    MOV   A,M
    ORA   A
    JZ    DDA3
    CALL  E471       ;$E471  +offset
DD7A    CALL  $5DB6
    POP   H
    PUSH  H
    LXI   D,0007h
    DAD   D
    MOV   M,A          ;w
    MOV   H,A          ;g
    MOV   L,A          ;o
    SHLD  $F73F
    POP   H
    ADD   M
    MVI   M,00h          ;6
    JZ    DD9E
    INX   H
    INX   H
    INX   H
    INX   H
    MOV   A,M
    CALL  DAFB
    LHLD  $F73D
    INX   H
    MOV   A,M
    ORA   A
DD9E    POP   H
    RZ    
    JMP   E2FC    ;$E2FC  +offset


DDA3    LHLD  $F73D
    INX   H
    INR   M          ;4
    XCHG  
    LHLD  $F73F
    LXI   B,0002h
    DAD   B
    MOV   L,M          ;n
    MVI   H,00h
    INX   D
    INX   D
    DAD   D
    DCR   M          ;5
    MOV   A,M
    CPI   0C0h
    JNZ   DD7A
    LHLD  $F73F
    INX   H
    MOV   A,M
DDC2    MVI   H,00h
    MOV   L,A          ;o
    DAD   D
    MOV   C,A          ;O
    MOV   A,M
    CPI   0C0h
    JNC   DD7A
    MOV   B,A          ;G
    MOV   L,A          ;o
    MVI   H,00h
    DAD   D
    MOV   A,M
    CPI   0C0h
    MOV   A,B          ;x
    JC    DDC2
    XCHG  
    MVI   B,00h
    DAD   B
    MVI   M,0C9h          ;6
    XCHG  
    MVI   M,0FFh          ;6
    LHLD  $F73D
    INX   H
    INX   H
    INR   M          ;4
    JMP   DD7A

DDEB    MOV   A,D          ;z
    CPI   09h
    JNC   E5FE+1    ;$E5FF  +offset
    MVI   E,10h
    PUSH  PSW
    XRA   A
    CALL  $5BD1
    XRA   A
    CALL  $5BF7
    POP   PSW
    JMP   DAFB

DE00    PUSH  H
    CALL  $061B
    INX   H
    SHLD  E842    ;$E842  +offset
    LHLD  $EF67
    PUSH  H
DE0C    CALL  E51E  ;$E51E  +offset
    CALL  E52B      ;$E52B  +offset
    INR   C
    POP   D
    LHLD  E842      ;$E842  +offset
    MOV   A,L
    SUB   E
    MOV   L,A          ;o
    MOV   A,H
    SBB   D
    INR   L
    DCR   L
    JZ    DE26
    JP    DE25
    INR   A
DE25    INR   A
DE26    CPI   09h
    JC    DE2D
    MVI   A,09h
DE2D    ORA   A
    STC          ;7
    XCHG  
    CNZ   E517   ;$E517  +offset
    ORA   A
    PUSH  PSW
    MOV   B,A          ;G
    MVI   C,00h
    DAD   B
    XCHG  
    LHLD  E842    ;$E842  +offset
    RST   3
    JZ    DE52
    JC    DE52
    POP   PSW
    PUSH  D
    CALL  D9F3
    LHLD  $F73F
    INX   H
    INX   H
    MOV   M,C          ;q
    JMP   DE0C

DE52    LHLD  $F73F
    INX   H
    INX   H
    MOV   E,M
    MVI   D,00h
    CALL  DB56
    DAD   D
    POP   PSW
    ADD   M
    MOV   M,A          ;w
    CALL  DA43+1    ; call into middle of an instruction
DE64    POP   H
    XRA   A
    CALL  $5BF7
    JMP   $052D

DE6C    RST   3
    RZ    
    MOV   A,M
    INX   H
    CALL  $5D10
    JMP   DE6C

DE76    INX   SP          ;3
    INX   SP          ;3
    POP   PSW
    JZ    E616+1   ;$E617  +offset
    CALL  $2C1C
    CALL  $5CE1
    XRA   A
    CALL  $5B43
    MVI   M,80h          ;6
    SHLD  $F73F
    CALL  DB72
    MOV   B,A          ;G
    PUSH  B
    LXI   H,DF42   ;$DF42  +offset
    SHLD  $EF34
    LHLD  $EF67
    PUSH  H
DE9A    SHLD  E83F   ;$E83F  +offset
    CALL  E51E       ;$E51E  +offset
    CALL  DB56
    MOV   L,B          ;h
    MVI   H,00h
    DAD   D
    MOV   A,M
    CPI   0C0h
    JNC   DED0
    POP   H
    PUSH  H
    PUSH  PSW
    LXI   D,0900h
    CALL  DF1E      ;$DF1E  +offset
    POP   PSW
    LHLD  $F73F
    INX   H
    INX   H
    MOV   M,A          ;w
    CALL  E52B    ;$E52B  +offset
    INR   C
    POP   H
    MVI   A,09h
    ORA   A
    CALL  E517     ;$E517  +offset
    LXI   D,0900h
    DAD   D
    PUSH  H
    JMP   DE9A

DED0    POP   H
    POP   B
    MOV   A,B          ;x
    PUSH  PSW
    MOV   D,A          ;W
    MVI   E,00h
    PUSH  H
    SHLD  E83F      ;$E83F  +offset
    CALL  DF1E
    CALL  E51E    ;$E51E  +offset
    CALL  E52B    ;$E52B  +offset
    INR   C
    POP   H
    POP   PSW
    ORA   A
    CNZ   E517    ;$E517  +offset
    CALL  $061B
    INX   H
    XCHG  
    LHLD  $F661
    XCHG  
    MOV   A,E
    SUB   L
    MOV   C,A          ;O
    MOV   A,D          ;z
    SBB   H
    MOV   B,A          ;G
    CALL  $82DA
    LHLD  $F661
    DAD   B
    SHLD  $F661
    LXI   H,0000h
    SHLD  $EF34
    CALL  $4C43
    XRA   A
    STA   $F75A          ;2
    CALL  $5BF7
    LDA   $F745
    ORA   A
    JNZ   $082F
    JMP   $052D


DF1E    PUSH  B
    MOV   C,E          ;K
    MOV   B,D          ;B
    LHLD  E83F      ;$E83F  +offset
    CALL  $82A8
    JC    DF33
    LHLD  $F661
    DAD   B
    SHLD  $F661
    POP   B
    RET 


DF33    CALL  $2C1C
    XRA   A
    STA   $F75A          ;2
    MOV   L,A          ;o
    MOV   H,A          ;g
    SHLD  $EF34
    JMP   E619+1    ;$E61A  +offset
DF42    CALL  $2C1C
    XRA   A
    STA   $F75A          ;2
    MOV   L,A          ;o
    MOV   H,A          ;g
    SHLD  $EF34
    JMP   E613+1    ;$E614  +offset

DF51    LHLD  $F73F
    INX   H
    MOV   B,M          ;F
    INX   H
    INX   H
    INX   H
    MOV   C,M          ;N
    PUSH  H
    LHLD  $F736
    LDA   $F735
    INR   A
    PUSH  PSW
DF63    POP   PSW
DF64    DCR   A
    JM    DF90
    PUSH  PSW
    MOV   E,M
    INX   H
    MOV   D,M          ;V
    INX   H
    LDAX  D
    ORA   A
    JZ    DF63
    INX   D
    LDAX  D
    CMP   B
    JNZ   DF63
    INX   D
    INX   D
    INX   D
    LDAX  D
    CMP   C
    JNZ   DF63
    POP   PSW
    XTHL  
    PUSH  PSW
    RST   3
    JNZ   DF8C
    POP   PSW
    XTHL  
    JMP   DF64

DF8C    POP   PSW
    POP   H
    STC          ;7
    RET 

DF90    POP   H
    ORA   A
    RET
 
DF93    PUSH  PSW
    LDA   $F743
    ORA   A
    JP    DFC9
    CPI   81h
    MOV   A,D          ;z
    STA   $F744          ;2
    JM    E5FB+1     ;$E5FC  +offset
    JNZ   DFBD
    CPI   0Eh
    JZ    DFC5
    PUSH  H
    LHLD  $F73A
    MOV   A,M
    PUSH  PSW
    MVI   M,0FFh          ;6
    INR   D
    CALL  E3B7    ;$E3B7  +offset
    POP   PSW
    MOV   M,A          ;w
    JMP   DFC4

DFBD    PUSH  H
    LXI   B,0010h
    DAD   B
    MVI   M,0FFh          ;6
DFC4    POP   H
DFC5    MOV   A,E
    STA   $F743          ;2
DFC9    LDA   $F744
    ADI   80h
    MOV   D,A          ;W
    PUSH  H
    CC    E3A3     ;$E3A3  +offset
    CALL  D9F3
    LXI   D,$F746
    POP   H
    CALL  DC84
    POP   PSW
    ANI   80h
    XCHG  
    LHLD  $F73D
    DCX   H
    ORA   M
    LXI   H,E841    ;$E841  +offset
    MOV   C,A          ;O
    MOV   A,M
    MVI   M,00h          ;6
    ANI   01h
    ORA   C
    STAX  D
    LHLD  $F73F
    INX   H
    PUSH  H
    INX   H
    INX   H
    INX   H
    INX   H
    INX   H
    INX   H
    MOV   M,A          ;w
    POP   H
    MOV   A,M
    INX   D
    STAX  D
    LDA   $F744
    ANI   7Fh
    MOV   D,A          ;W
    JMP   E3B7    ;$E3B7  +offset

E00A    MVI   A,01h
    STA   $EF60          ;2
E00F    MVI   E,01h
    JZ    E01D
    CALL  $1158
    DCX   H
    RST   2
    JNZ   $0471
    INR   E
E01D    MOV   A,E
    PUSH  H
    DCR   E
    PUSH  D
    CALL  DC29
    POP   D
    MOV   A,E
    JNZ   E031
    CALL  DB32
    PUSH  H
    CALL  DAEB
    POP   H
E031    LHLD  E777    ;$E777  +offset
    MOV   C,H          ;L
    MOV   B,L          ;E
    LHLD  $F73A
    XRA   A
    INR   A
    CALL  E537       ;$E537  +offset
    JC    E613+1     ;$E614  +offset
    LDA   E777+2       ;$E779  +offset
    MOV   E,A
    MVI   D,00h
    DAD   D
    PUSH  H
    DCX   H
    RST   2
    JNC   E062
    RST   2
    JNC   E062
    RST   2
    CPI   2Eh
    JNZ   E062
    LXI   H,E76B    ;$E76B  +offset
    CALL  $3517
    POP   H
    JMP   E066

E062    POP   H
    LXI   H,E75F    ;$E75F  +offset
E066    CALL  $3517
    MVI   D,01h
E06B    CALL  E3A3  ;$E3A3 +offset
    PUSH  D
    MVI   B,10h
E071    MOV   A,M
    INR   A
    JZ    E0F0
    DCR   A
    JZ    E0D0
    CALL  E086
    CALL  E0B2
    CALL  E0C4
    JMP   E0D4

E086    MVI   D,09h
E088    MOV   A,M
    INX   H
    RST   4
    DCR   D
    RZ    
    MOV   A,D          ;z
    CPI   03h
    JNZ   E088
    PUSH  H
    INX   H
    INX   H
    INX   H
    MOV   A,M
    ANI   81h
    JZ    E0A9
    ANI   80h
    JNZ   E0A7
    ADI   0Ah
    JMP   E0A9

E0A7    ADI   0Eh
E0A9    ADI   20h
    ANI   7Fh
    RST   4
    POP   H
    JMP   E088

E0B2    PUSH  H
    PUSH  B
    MVI   A,20h
    RST   4
    CALL  DB75
    MOV   L,C          ;i
    MVI   H,00h
    INR   L
    CALL  $470B
    POP   B
    POP   H
    RET 

E0C4    CALL  E13F
    ANI   0Fh
    RZ    
    MVI   A,20h
    RST   4
    JMP   E0C4

E0D0    LXI   D,0009h
    DAD   D
E0D4    LXI   D,0007h
    DAD   D
    PUSH  H
    LXI   H,0000h
    CALL  $143E
    POP   H
    CALL  E131
    DCR   B
    JNZ   E071
    POP   D
    INR   D
    MOV   A,D          ;z
    CPI   0Fh
    JC    E06B
    PUSH  D
E0F0    POP   D
    CALL  $5A77
    LHLD  $F73D
    INX   H
    INX   H
    MOV   L,M          ;n
    MVI   H,00h
    MOV   C,L          ;M
    MOV   B,H          ;D
    DAD   H
    DAD   H
    DAD   H
    DAD   B
    PUSH  H
    MOV   A,H
    ANA   A
    RAR
    MOV   H,A          ;g
    MOV   A,L
    RAR
    MOV   L,A          ;o
    MOV   A,H
    ANA   A
    RAR
    MOV   H,A          ;g
    MOV   A,L
    RAR
    MOV   L,A          ;o
    CALL  $470B
    POP   H
    MOV   A,L
    ANI   03h
    MOV   L,A          ;o
    MVI   H,00h
    DAD   H
    DAD   H
    LXI   B,E746-4    ;$E742  +offset
    DAD   B
    CNZ   $3517
    LXI   H,E752    ;$E752 +offset
    CALL  $3517
    CALL  $5A8A
    POP   H
    JMP   $0C64

E131    CALL  E14B
    MOV   C,A          ;O
    CALL  E13F
    ADI   0Fh
    CMP   C
    JNC   $5A8A
    RET 

E13F    LDA   $EF60
    ORA   A
    LDA   $F073
    RZ    
    LDA   $EF5F
    RET
 
E14B    LDA   $EF60
    ORA   A
    LDA   $EF09
    RZ    
    MVI   A,0FFh
    RET
 
E156    LXI   D,0007h
    DAD   D
    MOV   A,M
    ANI   02h
    DCX   H
    DCX   H
    PUSH  H
    CNZ   E440    ;$E440  +offset
    POP   H
    INX   H
    MOV   E,M
    INX   H
    MOV   A,M
    ORI   08h
    MOV   M,A          ;w
    INX   H
    MOV   A,E
    POP   PSW
    PUSH  H
    PUSH  PSW
    SUI   0Dh
    JZ    E17A
    INR   M          ;4
    CPI   13h
    SBB   A
    ADD   M
E17A    MOV   M,A          ;w
    INX   H
    MVI   D,00h
    XCHG  
    DAD   D
    POP   PSW
    MOV   M,A          ;w
    POP   H
    PUSH  PSW
    DCX   H
    DCX   H
    INR   M          ;4
    MOV   A,M
    ORA   A
    CZ    E3BD   ;$E3BD  +offset
    POP   PSW
E18D    POP   B
    POP   D
    POP   H
    RET
 
E191    LXI   D,0007h
    DAD   D
    MOV   A,M
    ANI   02h
    DCX   H
    PUSH  H
    SUI   01h
    CMC
    CC    E440     ;$E440  +offset
    POP   H
    JC    E1B8
    DCX   H
    MOV   A,M
    INX   H
    MOV   E,M
    INR   M          ;4
    CMP   M
    INX   H
    JNZ   E1B2
    MOV   A,M
    ORI   02h
    MOV   M,A          ;w
E1B2    INX   H
    INX   H
    MVI   D,00h
    DAD   D
    MOV   A,M
E1B8    POP   D
    POP   H
    POP   B
    RET
 
E1BC    PUSH  H
    PUSH  D
    PUSH  B
    PUSH  PSW
    SHLD  $F73F
    MOV   A,H
    ORA   L
    JZ    E1D1
    LXI   D,0004h
    DAD   D
    MOV   A,M
    ORA   A
    CP    DC2E
E1D1    POP   PSW
    POP   B
    POP   D
    POP   H
    RET 

E1D6    RST   2      ; one of the vectors is e1d6
    RST   1
E1D8    .db  28h          ; strange, undefined instruction
    CALL  E288
    PUSH  PSW
    RST   1
    DAD   H
    POP   PSW
    PUSH  H
    MOV   L,A          ;o
    LDA   $F73C
    PUSH  PSW
    MOV   A,L
    CALL  DC29
    MVI   A,80h
    PUSH  B
    CALL  $34C3
    XCHG  
    POP   B
    PUSH  H
    LHLD  $F73A
    MVI   A,01h
    ORA   A
    CALL  E517     ;$E517  +offset
    POP   D
    LHLD  $F73A
    LDA   E2B7
    ANA   A
    JZ    E20B
    LXI   B,0080h
    DAD   B
E20B    XCHG  
    MVI   C,80h
    CALL  E27D
    POP   PSW
E212    CALL  DC2E
    JMP   $34F3

E218    CALL  E288
    PUSH  PSW
    RST   1
    INR   L
    PUSH  B
    CALL  $0DD6
    PUSH  H
    CALL  $367C
    XTHL  
    DCX   H
    RST   2
    JNZ   $0471
    POP   D
    POP   B
    XTHL  
    PUSH  H
    PUSH  B
    XCHG  
    MOV   C,M          ;N
    INX   H
    MOV   E,M
    INX   H
    MOV   D,M          ;V
    MOV   A,C          ;y
    CPI   81h
    JNC   E616+1    ;$E617  +offset
    POP   H
    POP   PSW
    PUSH  PSW
    PUSH  H
    PUSH  B
    PUSH  D
    MOV   C,L          ;M
    CALL  DC29
    LHLD  $F73A
    XRA   A
    INR   A
    CALL  E517    ;$E517  +offset
    POP   D
    LHLD  $F73A
    CALL  E268
    POP   B
    ORA   C
    CNZ   E27D
    POP   B
    POP   PSW
    STC          ;7
    MVI   A,01h
    LHLD  $F73A
    CALL  E517    ;$E517  +offset
    POP   H
    RET 

E268    LXI   B,0080h
    LDA   E2B7
    ANA   A
    JZ    E274
    DAD   B
    XRA   A
E274    PUSH  H
E275    MOV   M,A          ;w
    INX   H
    DCR   C
    JNZ   E275
    POP   H
    RET
 
E27D    PUSH  H
E27E    LDAX  D
    MOV   M,A          ;w
    INX   H
    INX   D
    DCR   C
    JNZ   E27E
    POP   H
    RET
 
E288    CALL  $1158
    INR   A
    PUSH  PSW
    RST   1
    INR   L
    CALL  $1158
    CPI   28h
    JNC   E5F5+1     ;$E5F6  +offset
    PUSH  PSW
    RST   1
    INR   L
    CALL  $1158
    DCR   A
    CPI   12h
    JNC   E5F5+1     ;$E5F6  +offset
    INR   A
    PUSH  PSW
    RST   1
    INR   L
    CALL  $1158
    CPI   02h
    JNC   E616+1    ;$E617  +offset
    STA   E2B7
    POP   PSW
    POP   B
    MOV   C,A          ;O
    POP   PSW
    RET 

E2B7    .db   0

E2B8    MVI   B,0FFh
    LHLD  $F73F
    XCHG  
    LXI   H,0007h
    DAD   D
    MOV   A,M
    ANI   01h
    MVI   A,00h
    JNZ   E2DB
    LXI   H,0108h
    DAD   D
E2CE    MOV   A,M
    ORA   A
    JZ    E2DD
    CPI   1Ah
    MOV   A,B          ;x
    RZ    
    ORA   A
    INR   A
    INX   H
    RNZ   
E2DB    STC          ;7
    RET
 
E2DD    MOV   A,B          ;x
    SUI   01h
    MOV   B,A          ;G
    DCX   H
    JNC   E2CE
    INX   H
    XRA   A
    RET
 
E2E8    PUSH  D
    LHLD  $F73F
    LXI   D,0007h
    DAD   D
    MOV   A,M
    ANI   08h
    POP   D
    RET 

E2F5    LHLD  $F73D
    INX   H
    MOV   A,M
    ORA   A
    RZ    
E2FC    PUSH  B
    PUSH  D
    PUSH  H
    PUSH  PSW
    CALL  E308
    POP   PSW
    POP   H
    POP   D
    POP   B
    RET
 
E308    LXI   B,0010h
E30B    PUSH  B
    CALL  DB56
    XCHG  
    MVI   B,14h
    MVI   A,01h
    STC          ;7
    CALL  E554   ;$E554  +offset
    POP   B
    JNC   E31D
    INR   B
E31D    INR   C
    MOV   A,C          ;y
    CPI   13h
    JC    E30B
    DCX   H
    DCX   H
    XRA   A
    MOV   M,A          ;w
    ORA   B
    RZ    
    CPI   03h
    CMC
    JNC   E336
    DCX   H
    DCX   H
    DCX   H
    MVI   M,00h          ;6
    RET 

E336    ADI   30h
    LHLD  $F73F
    PUSH  H
    LXI   H,0000h
    SHLD  $F73F
    RST   4
    CPI   31h
    LXI   H,E712    ;$E712  +offset 
    JZ    E34E
    LXI   H,E71B    ;$E71B  +offset
E34E    PUSH  PSW
    CALL  $3517
    LXI   H,E736    ;$E736  +offset
    CALL  $3517
    POP   PSW
    LXI   H,E718     ;$E718  +offset
    JZ    E362
    LXI   H,E723     ;$E723  +offset
E362    CALL  $3517
    LXI   H,E727     ;$E727  +offset
    CALL  $3517
    LDA   $F73C
    ADI   30h
    RST   4
    CALL  $5A8A
    POP   H
    SHLD  $F73F
    RET
 
E379    PUSH  D
    MVI   B,14h
    MOV   C,D          ;J
    CALL  DB56
    XCHG  
    MOV   A,E
    ORA   A
    JZ    E388
    MVI   A,0FFh
E388    INR   A
    CALL  E38F
    SBB   A
    POP   D
    RET 

E38F    MVI   A,01h
    LHLD  $F73A
    CALL  E537    ;$E537  +offset
    RC    
    CALL  DB56
    LHLD  $F73A
    MVI   B,50h
    JMP   DC86

E3A3    MVI   A,01h
    ORA   A
E3A6    PUSH  D
    LHLD  $F73A
    PUSH  H
    MOV   C,D          ;J
    MVI   B,14h
    CALL  E554      ;$E554  +offset
    JC    E613+1    ;$E614  +offset
    POP   H
    POP   D
    RET 

E3B7    MVI   A,01h
    STC          ;7
    JMP   E3A6

E3BD    CALL  E482    ;$E482  +offset
E3C0    CALL  E49D    ;$E49D  +offset
    JNC   E3D8
    CALL  $5DB6
    MVI   M,1Ah          ;6
    DCX   H
    DCX   H
    MOV   A,M
    ORI   08h
    MOV   M,A          ;w
    XRA   A
    DCX   H
    MOV   M,A          ;w
    DCX   H
    MVI   M,00h          ;6
    RET 


E3D8    PUSH  PSW
    CALL  E509
    LHLD  $F73F
    CALL  DB5E
    MVI   C,0FFh
    JNC   E41F
    CALL  E2B8
    MOV   B,A          ;G
    JC    E3F5
    ORA   A
    JNZ   E3F5
    MVI   B,00h
    STC          ;7
E3F5    SBB   A
    MOV   C,A          ;O
    POP   PSW
    JC    E402
    MOV   A,C          ;y
    INR   A
    JZ    E402
    MVI   M,1Ah          ;6
E402    LHLD  $F73F
    INX   H
    INX   H
    INX   H
    INX   H
    INX   H
    INX   H
    INX   H
    MOV   A,M
    ANI   20h
    JZ    E422
    MOV   A,M
    ANI   0DFh
    MOV   M,A          ;w
    MOV   A,B          ;x
    ORA   A
    PUSH  PSW
    JNZ   E424
    CALL  E3C0
E41F    POP   PSW
    MVI   B,00h
E422    PUSH  PSW
    XRA   A
E424    LHLD  $F73F
    LXI   D,0007h
    DAD   D
    PUSH  PSW
    MOV   A,M
    ANI   0FDh
    MOV   M,A          ;w
    POP   PSW
    DCX   H
    MOV   M,A          ;w
    DCX   H
    MOV   M,B          ;p
    POP   PSW
    RNC   
    INR   C
    JZ    E43E
    INR   B
    DCR   B
    RZ    
E43E    ORA   A
    RET 

E440    PUSH  PSW
    CALL  E2E8
    CNZ   E471
    POP   PSW
    PUSH  PSW
    CALL  E49F
    JC    E460
    POP   PSW
    PUSH  PSW
    STC          ;7
    CALL  E3D8
    JC    E460
    POP   PSW
    INX   H
    INX   H
    INX   H
    INX   H
    MOV   A,M
    ORA   A
    RET 

E460    POP   PSW
    RC    
    INX   H
    INX   H
    INX   H
    MVI   M,00h          ;6
    INX   H
    MVI   M,00h          ;6
    INX   H
    MOV   A,M
    ANI   0FDh
    MOV   M,A          ;w
    STC          ;7
    RET 

E471    LHLD  $F73F
    CALL  DB5E
    JNC   E482
    CALL  E2B8
    JC    E482
    MVI   M,1Ah          ;6
E482    CALL  E51E
    MOV   A,M
    ANI   0F7h
    MOV   M,A          ;w
    CALL  E52B
    CALL  E495
    MVI   A,01h
    STC          ;7
    JMP   E517

E495    LHLD  $F73F
    LXI   D,0009h
    DAD   D
    RET 

E49D    ORI   37h
E49F    LHLD  $F73F
    PUSH  H
    PUSH  PSW
    CALL  DB5E
    JNC   E4AF
    POP   PSW
    JC    $4592
    PUSH  PSW
E4AF    POP   H
    XTHL  
    INX   H
    INX   H
    MOV   B,M          ;F
    INX   H
    MOV   C,M          ;N
    INR   C
    MOV   A,C          ;y
    CPI   0Ah
    CMC
    JNC   E4DE
    PUSH  H
    CALL  DB56
    MOV   L,B          ;h
    XRA   A
    MOV   H,A          ;g
    DAD   D
    MVI   C,01h
    MOV   B,M          ;F
    POP   H
    MVI   A,0BFh
    CMP   B
    JNC   E503
    POP   PSW
    PUSH  PSW
    CMC
    JNC   E503
    PUSH  H
    CALL  D9F3
    POP   H
    MOV   B,C          ;A
    MVI   C,01h
E4DE    POP   PSW
    PUSH  PSW
    CMC
    JNC   E503
    PUSH  B
    PUSH  H
    CALL  DB56
    MOV   L,B          ;h
    MVI   H,00h
    DAD   D
    MVI   A,0C0h
    ADD   C
    MOV   E,A
    MOV   A,M
    CMP   E
    JNC   E501
    CPI   0C0h
    CMC
    JNC   E501
    INR   M          ;4
    CALL  DA43+1     ; in middle of instruction
    STC          ;7
E501    POP   H
    POP   B
E503    XTHL  
    POP   H
    MOV   M,C          ;q
    DCX   H
    MOV   M,B          ;p
    RET 


E509    CALL  E51E
    MOV   A,M
    ANI   0F3h
    MOV   M,A          ;w
    CALL  E52B
    INX   H
    INX   H
    XRA   A
    INR   A
E517    CALL  E554
    RNC   
    JMP   E613+1

E51E    LHLD  $F73F
    INX   H
    INX   H
    MOV   B,M          ;F
    INX   H
    MOV   C,M          ;N
    INX   H
    INX   H
    INX   H
    INX   H
    RET 

E52B    MOV   A,B          ;x
    ORA   A
    RAR
    MOV   B,A          ;G
    MOV   A,C          ;y
    JNC   E535
    ADI   09h
E535    MOV   C,A          ;O
    RET 

E537    XCHG  
    PUSH  PSW
    LHLD  $F73D
    INR   M          ;4
    JZ    E542
    MOV   M,B          ;p
    INR   M          ;4
E542    DCR   M          ;5
    POP   PSW
    PUSH  D
    PUSH  PSW
    CALL  D2CC
    JC    E550
    POP   PSW
    POP   H
    ORA   A
    RET 

E550    POP   PSW
    POP   H
    STC          ;7
    RET 

E554    PUSH  PSW
    PUSH  H
    LHLD  $F73D
    MOV   A,M
    INR   A
    JZ    E56C
    MVI   D,14h
    MOV   A,D          ;z
    SUB   B
    JZ    E56C
    MOV   E,A
    MOV   A,D          ;z
    SUB   M
    XRA   E
    CM    E2F5
E56C    POP   H
    POP   PSW
    CALL  E537
    PUSH  PSW
    MOV   A,B          ;x
    CPI   14h
    JNZ   E580
    MOV   A,C          ;y
    CPI   10h
    PUSH  H
    CC    E2F5
    POP   H
E580    POP   PSW
    RET 

E582    POP   PSW
    LDA   $F73C
    PUSH  PSW
    CALL  $5B40
    JZ    E607+1
    JC    E5FE+1
    PUSH  H
    CALL  DB3C
    CALL  DB94
    POP   H
    INX   H
    INX   H
    INX   H
    MOV   L,M          ;n
E59C    MVI   H,00h
    DAD   D
    POP   PSW
    PUSH  H
    CALL  DC2E
    POP   H
    JMP   $4264

E5A8    POP   PSW
    LDA   $F73C
    PUSH  PSW
    CALL  $5B40
    JZ    E607+1
    JC    E5FE+1
    CALL  DB75
    PUSH  PSW
    CALL  DB94
    POP   PSW
    MOV   L,A          ;o
    JMP   E59C

E5C2    JZ    E607+1
    PUSH  H
    CALL  DB5E
    POP   H
    JNZ   E5D9
    LXI   D,0005h
    DAD   D
    MOV   A,M
    INX   H
    SUB   M
    ORA   A
    JNZ   E5D9
    STC          ;7
E5D9    SBB   A
    MOV   B,A          ;G
    POP   PSW
    CALL  DC2E
    MOV   A,B          ;x
    JMP   $415B

E5E3    LXI   B,0006h
    DAD   B
    DCR   M          ;5
    INX   H
    MOV   A,M
    ANI   0FDh
    MOV   M,A          ;w
    JMP   $5EDA

E5F0    MVI   E,3Bh
E5F2    LXI   B,$3C1E     ; code calls in here in middle of instructions
E5F5    LXI   B,$3D1E
E5F8    LXI   B,$3E1E
E5FB    LXI   B,$3F1E
E5FE    LXI   B,$371E
E601    LXI   B,$351E
E604    LXI   B,$341E
E607    LXI   B,$3A1E
E60A    LXI   B,$321E
E60D    LXI   B,$361E
E610    LXI   B,$391E
E613    LXI   B,$121E
E616    LXI   B,$051E
E619    LXI   B,$071E
    PUSH  D
    XRA   A
    STA   $F75A          ;2
    CALL  $5BF7
    LDA   $F734
    DCR   A
    JM    E637
    PUSH  PSW
    MVI   A,00h
    CALL  DAFB
    POP   PSW
    MVI   A,01h
    CNZ   DAFB
E637    POP   D
    XRA   A
    STA   E841     ;$E841 +offset          ;2
    JMP   $0488

E63F    POP   B
    CPI   09h
    JNC   E5FE+1
    PUSH  D
    CALL  $30B3
    POP   D
    LXI   H,E64D
E64D    NOP
    MVI   A,0FFh
    STA   E841     ;$E841  +offset          ;2
    INR   A
    PUSH  H
    MVI   E,02h
    CALL  $5BD1
    LHLD  $F4FB
    XCHG  
    LHLD  $F4FD
    DAD   D
    SHLD  E842     ;$E842 +offset
    XCHG  
    CALL  E686
    LHLD  E842     ;$E842  +offset
    CALL  E686
    LHLD  $F4FF
    CALL  E686
    LHLD  E842     ;$E842  +offset
    XCHG  
    LHLD  $F4FB
    CALL  DE6C
    XRA   A
    STA   E841     ;$E841  +offset          ;2
    JMP   DE64

E686    MOV   A,L
    CALL  $5D10
    MOV   A,H
    JMP   $5D10

E68E    POP   B
    CPI   09h
    JNC   E5FE+1
    MVI   A,01h
    STA   E841     ;$E841  +offset          ;2
    PUSH  H
    XRA   A
    MVI   E,01h
    CALL  $5BD1
    CALL  $5D36
    MOV   E,A
    CALL  $5D36
    MOV   D,A          ;W
    XCHG  
    SHLD  $F4FB
    XCHG  
    CALL  $5D36
    MOV   L,A          ;o
    CALL  $5D36
    MOV   H,A          ;g
    PUSH  H
    CALL  $5D36
    MOV   L,A          ;o
    CALL  $5D36
    MOV   H,A          ;g
    SHLD  $F4FF
    MOV   A,H
    ORA   L
    POP   H
    JNZ   E6CE
    POP   B
    POP   PSW
    PUSH  PSW
    PUSH  B
    JC    E5FE+1
E6CE    PUSH  H
    PUSH  D
    MOV   A,L
    SUB   E
    MOV   L,A          ;o
    MOV   A,H
    SBB   D
    MOV   H,A          ;g
    SHLD  $F4FD
    LHLD  $F73F
    PUSH  H
    LXI   H,0000h
    SHLD  $F73F
    CALL  $3296
    JC    E619+1
    POP   H
    SHLD  $F73F
    POP   D
    POP   H
E6EF    RST   3
    JZ    E6FE
    CALL  $5D36
    JC    E6FE
    STAX  D
    INX   D
    JMP   E6EF

E6FE    XRA   A
    STA   E841     ;$E841 +offset          ;2
    CALL  $5BF7
    POP   H
    POP   PSW
    RNC   
    PUSH  H
    LHLD  $F4FF
    CALL  E711
    POP   H
    RET 

E711    PCHL

E712    .DB " copy",0
E718    .DB "is",0
E71B    .DB " copies",0
E723    .DB "are",0
E727    .DB " bad on drive ",0
E736    .DB " of allocation ",0

E746    .DB ".25",0
E74A    .DB ".5",0
E74D    NOP
E74E    .DB ".75",0

E752    .DB " K AVAILABLE",0
   
E75F    .DB "NO SYSTEM",0dh,0ah,0

E76B    .DB "SYSTEM VER ",0

E777    .DB  01h,0dh,0E1h   ; LXI   B,E10D

E77A    .DS 6    ; waste space to align next at E780


E83F     .DW 0
E841     .DB 0
E842     .DW 0
E844     .DW 0
E846     .DW 0
E848     .DB 0
E849     .DW 0
E84A     .DS 80

E89B     .DW 0
E89D     .DB 0
E89E     .DW 0
E8A0     .DS 80


    .end