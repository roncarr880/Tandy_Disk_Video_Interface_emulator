   ; offset to move code up without disturbing the relative addresses
   ; remove offset and use labels to relocate functions or remove functions
   ; offset as zero should assemble same as original image 


   .define offset $100

   .org $d200 +offset
 
D200    MVI   A,0C3h
    STA   $EEC2          ;2   JMP D83F
    STA   $EEB6          ;2   JMP D7DD
    LXI   H,$D7DD +offset
    SHLD  $EEB7
    LXI   H,$D83F +offset
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
    .dw $d757 +offset  ; or these could be labels without an offset
    .db $44
    .dw $d74d +offset
    .db $08
    .dw D48E   ;  $d48e +offset
    .db $0c
    .dw $d790 +offset
    .db $04
    .dw $d86b +offset
    .db $0a
    .dw $d6f1 +offset
    .db $40
    .dw  D443  ;$d443 +offset
    .db $42
    .dw $d767 +offset
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
    LXI   H,$D887 +offset
    SHLD  $F738
    LXI   H,0000h
    MVI   A,0FFh
    SHLD  $E846  +offset      ;0000ff00000000ff0000 in memory, what for?
    STA   $E848  +offset        ;2
    SHLD  $E849  +offset
    SHLD  $E89B  +offset
    STA   $E89D  +offset        ;2
    SHLD  $E89E  +offset     ; 1554 from old himem
    LXI   H,$504D
    SHLD  $EEAE       ; 61102 just below old himem
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

D58B



    .end