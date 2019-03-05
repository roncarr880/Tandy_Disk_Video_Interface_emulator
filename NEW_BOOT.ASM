     ; Second boot loader M200  running at D100

     .ORG   0D100h

    LXI   SP,0D980h
    LXI   H,0000
    PUSH  H
    MVI   A,03h
    STA   $FEAF          ;3 == disk function
    LXI   H,D135
    MVI   B,05h        ; send 5 byte command
D111    MOV   A,M      ; send the disk read command
    CALL  $9031
    INX   H
    DCR   B
    JNZ   D111
    LXI   H,0D980h      ; load and run address of the new image
    MVI   C,15h         ; reading 21 sectors
D11F    CALL  $904E     ; read status, expect 0
    ORA   A
    STC
    RNZ   
D125    CALL  904E      ; read a sector
    MOV   M,A
    INX   H
    DCR   B
    JNZ   D125
    DCR   C             ; repeat for all the sectors
    JNZ   D11F
    JMP   0D980h        ; run the code just loaded

D135    .DB   02h    ; read disk command
        .DB   15h    ; count 21 sectors 
        .DB   00h    ; disk 1
        .DB   01h    ; track 1
        .DB   0Fh    ; start sector 15

    .ORG   0D1FFh    ; make this 1 sector long, pad with zero
D1FF    .DB 0

    .END
  