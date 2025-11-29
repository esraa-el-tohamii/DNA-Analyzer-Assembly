org 100h

; --------------------------------------------------------------
; DATA SECTION
; --------------------------------------------------------------

dna1        db 200 dup("$")
dna2        db 200 dup("$")
pat         db 50 dup("$")
mrna        db 300 dup("$")
protein     db 300 dup("$")
revcomp     db 200 dup("$")

msgEnter1   db "Enter DNA sequence: $"
msgEnterPat db 0Dh,0Ah,"Enter pattern: $"
msgEnter2   db 0Dh,0Ah,"Enter 2nd DNA for similarity: $"

msgCounts   db 0Dh,0Ah,"--- Analysis Result ---$"
msgA        db 0Dh,0Ah,"Count A = $"
msgT        db 0Dh,0Ah,"Count T = $"
msgC        db 0Dh,0Ah,"Count C = $"
msgG        db 0Dh,0Ah,"Count G = $"

msgGC       db 0Dh,0Ah,"GC% = $"
msgRC       db 0Dh,0Ah,"Reverse Complement: $"
msgFound    db 0Dh,0Ah,"Pattern found at: $"
msgNotFound db 0Dh,0Ah,"Pattern not found$"

msgWin      db 0Dh,0Ah,"Best GC-window start = $"
msgWinGC    db "GC-Count= $"

msgMRNA     db 13,10,"mRNA: $"
msgProt     db 0Dh,0Ah,"Protein: $"

msgSim      db 0Dh,0Ah,"Similarity (%) = $"
msgNL       db 0Dh,0Ah,"$"

countA      dw 0
countT      dw 0
countC      dw 0
countG      dw 0

win_pos     dw 0
win_gc      dw 0

similarityV dw 0



; --------------------------------------------------------------
; PROCEDURES
; --------------------------------------------------------------

print_str proc
    mov ah, 09h
    int 21h
    ret
print_str endp


print_char proc
    mov ah, 02h
    int 21h
    ret
print_char endp


print_num proc
    push ax
    push bx
    push cx
    push dx

    xor cx, cx
    mov bx, 10

cvt_loop:
    xor dx, dx
    div bx
    push dx
    inc cx

    cmp ax, 0
    jne cvt_loop

prn_loop:
    pop dx
    add dl,'0'

    mov ah,02h
    int 21h

    loop prn_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_num endp

; ==============================================================  
;                      MAIN PROGRAM START  
; ==============================================================  

start:

; --------------------------------------------------------------  
; INPUT DNA #1  
; --------------------------------------------------------------  

    mov dx, offset msgEnter1
    call print_str

    mov dx, offset dna1
    mov ah, 0Ah
    int 21h

    mov si, offset dna1 + 2
    mov cl, [dna1 + 1]
    xor ch, ch


; --------------------------------------------------------------  
; COUNT A / T / C / G  
; --------------------------------------------------------------  

    mov countA, 0
    mov countT, 0
    mov countC, 0
    mov countG, 0

count_loop:

    mov al, [si]

    cmp al, 'A'
    je cntA

    cmp al, 'T'
    je cntT

    cmp al, 'C'
    je cntC

    cmp al, 'G'
    je cntG

    jmp cnt_skip


cntA:
    inc countA
    jmp cnt_skip

cntT:
    inc countT
    jmp cnt_skip

cntC:
    inc countC
    jmp cnt_skip

cntG:
    inc countG
    jmp cnt_skip


cnt_skip:
    inc si
    loop count_loop



; --------------------------------------------------------------  
; PRINT COUNTS  
; --------------------------------------------------------------  

    mov dx, offset msgCounts
    call print_str

    mov dx, offset msgA
    call print_str
    mov ax, countA
    call print_num

    mov dx, offset msgT
    call print_str
    mov ax, countT
    call print_num

    mov dx, offset msgC
    call print_str
    mov ax, countC
    call print_num

    mov dx, offset msgG
    call print_str
    mov ax, countG
    call print_num



; --------------------------------------------------------------  
; COMPUTE GC%  
; --------------------------------------------------------------  

    mov ax, countC
    add ax, countG

    mov bl, [dna1 + 1]
    cmp bl, 0
    je noGC

    xor bh, bh
    mov cx, bx

    xor dx, dx
    mul word ptr 100
    div cx

noGC:

    mov dx, offset msgGC
    call print_str
    call print_num
; --------------------------------------------------------------  
; REVERSE COMPLEMENT  
; --------------------------------------------------------------  

    mov si, offset dna1 + 2
    mov cl, [dna1 + 1]
    xor ch, ch

    mov di, offset revcomp
    add di, cx
    dec di

rev_loop:

    mov al, [si]

    cmp al, 'A'
    je rcT

    cmp al, 'T'
    je rcA

    cmp al, 'C'
    je rcG

    cmp al, 'G'
    je rcC

    jmp rc_end


rcT:
    mov [di], 'T'
    jmp rc_next

rcA:
    mov [di], 'A'
    jmp rc_next

rcG:
    mov [di], 'G'
    jmp rc_next

rcC:
    mov [di], 'C'


rc_next:
rc_end:

    inc si
    dec di
    loop rev_loop


    mov dx, offset msgRC
    call print_str

    mov dx, offset revcomp
    call print_str



; --------------------------------------------------------------  
; PATTERN SEARCH  
; --------------------------------------------------------------  

    mov dx, offset msgEnterPat
    call print_str

    mov dx, offset pat
    mov ah, 0Ah
    int 21h

    mov bl, [pat + 1]
    xor bh, bh
    cmp bx, 0
    je no_pattern_to_search

    mov dx, offset msgFound
    call print_str

    mov si, offset dna1 + 2
    mov di, offset pat + 2

    mov cl, [dna1 + 1]
    xor ch, ch

    mov bh, 1       ; position counter



pat_outer:

    cmp cx, bx
    jb finished_pat

    push cx
    push si
    push di

    mov al, bl
    mov ah, 0


pat_inner:

    mov dl, [si]
    cmp dl, [di]
    jne pat_no

    inc si
    inc di
    dec ax
    jnz pat_inner


    mov ax, bx
    call print_num

    mov dl, ' '
    call print_char


pat_no:

    pop di
    pop si
    pop cx

    inc si
    inc bh
    dec cx
    jmp pat_outer



finished_pat:

    mov dx, offset msgNL
    call print_str
    jmp after_pat



no_pattern_to_search:

    mov dx, offset msgNotFound
    call print_str



after_pat:
; --------------------------------------------------------------  
; GC WINDOW (SIZE 10)  
; --------------------------------------------------------------  

    mov win_gc, 0
    mov win_pos, 0

    mov cl, [dna1 + 1]
    xor ch, ch

    cmp cx, 10
    jb skip_gw

    sub cx, 9

    mov si, offset dna1 + 2
    mov dx, 1


gw_loop:

    push cx
    push si

    mov ax, 0
    mov di, si
    mov cl, 10


gw_count:

    mov al, [di]

    cmp al, 'C'
    je gw_add

    cmp al, 'G'
    jne gw_skip


gw_add:
    inc ax


gw_skip:
    inc di
    loop gw_count


    cmp ax, win_gc
    jbe gw_continue

    mov win_gc, ax
    mov win_pos, dx


gw_continue:

    pop si
    inc si

    inc dx

    pop cx
    loop gw_loop



skip_gw:

    mov dx, offset msgWin
    call print_str

    mov ax, win_pos
    call print_num

    mov dx, offset msgWinGC
    call print_str

    mov ax, win_gc
    call print_num




; --------------------------------------------------------------  
; TRANSCRIPTION (T ? U)  
; --------------------------------------------------------------  

    mov si, offset dna1 + 2
    mov di, offset mrna

    mov cl, [dna1 + 1]
    xor ch, ch


mrna_loop:

    mov al, [si]

    cmp al, 'T'
    jne tr_cpy

    mov al, 'U'


tr_cpy:

    mov [di], al

    inc si
    inc di

    loop mrna_loop


    mov byte ptr [di], '$'


    mov dx, offset msgMRNA
    call print_str

    mov dx, offset mrna
    call print_str




; --------------------------------------------------------------  
; TRANSLATION (CODON TABLE)  
; --------------------------------------------------------------  

    mov si, offset mrna
    mov di, offset protein

    mov cl, [dna1 + 1]
    xor ch, ch


translate_loop:

    cmp cx, 3
    jb translation_end


    mov al, [si]
    mov ah, [si + 1]
    mov dl, [si + 2]



; ------------------- START CODON TABLE -----------------------  


    cmp al, 'U'
    jne C1

    cmp ah, 'U'
    jne C1

    cmp dl, 'U'
    je mkF

    cmp dl, 'C'
    je mkF



C1:

    cmp al, 'U'
    jne C2

    cmp ah, 'U'
    jne C2

    cmp dl, 'A'
    je mkL

    cmp dl, 'G'
    je mkL



C2:

    cmp al, 'U'
    jne C3

    cmp ah, 'C'
    jne C3

    jmp mkS



C3:

    cmp al, 'U'
    jne C4

    cmp ah, 'A'
    jne C4

    cmp dl, 'U'
    je mkY

    cmp dl, 'C'
    je mkY



C4:

    cmp al, 'U'
    jne C5

    cmp ah, 'A'
    jne C5

    cmp dl, 'A'
    je mkStop

    cmp dl, 'G'
    je mkStop



C5:

    cmp al, 'U'
    jne C6

    cmp ah, 'G'
    jne C6

    cmp dl, 'U'
    je mkC

    cmp dl, 'C'
    je mkC



C6:

    cmp al, 'U'
    jne C7

    cmp ah, 'G'
    jne C7

    cmp dl, 'A'
    je mkStop



C7:

    cmp al, 'U'
    jne C8

    cmp ah, 'G'
    jne C8

    cmp dl, 'G'
    je mkW



C8:

    cmp al, 'C'
    jne C9

    jmp mkL



C9:

    cmp al, 'C'
    jne C10

    cmp ah, 'C'
    jne C10

    jmp mkP



C10:

    cmp al, 'C'
    jne C11

    cmp ah, 'A'
    jne C11

    cmp dl, 'U'
    je mkH

    cmp dl, 'C'
    je mkH



C11:

    cmp al, 'C'
    jne C12

    cmp ah, 'A'
    jne C12

    cmp dl, 'A'
    je mkQ

    cmp dl, 'G'
    je mkQ



C12:

    cmp al, 'C'
    jne C13

    cmp ah, 'G'
    jne C13

    jmp mkR



C13:

    cmp al, 'A'
    jne C14

    cmp ah, 'U'
    jne C14

    cmp dl, 'U'
    je mkI

    cmp dl, 'C'
    je mkI

    cmp dl, 'A'
    je mkI



C14:

    cmp al, 'A'
    jne C15

    cmp ah, 'U'
    jne C15

    cmp dl, 'G'
    je mkM



C15:

    cmp al, 'A'
    jne C16

    cmp ah, 'C'
    jne C16

    jmp mkT



C16:

    cmp al, 'A'
    jne C17

    cmp ah, 'A'
    jne C17

    cmp dl, 'U'
    je mkN

    cmp dl, 'C'
    je mkN



C17:

    cmp al, 'A'
    jne C18

    cmp ah, 'A'
    jne C18

    cmp dl, 'A'
    je mkK

    cmp dl, 'G'
    je mkK



C18:

    cmp al, 'A'
    jne C19

    cmp ah, 'G'
    jne C19

    cmp dl, 'U'
    je mkS

    cmp dl, 'C'
    je mkS



C19:

    cmp al, 'A'
    jne C20

    cmp ah, 'G'
    jne C20

    cmp dl, 'A'
    je mkR

    cmp dl, 'G'
    je mkR



C20:

    cmp al, 'G'
    jne C21

    cmp ah, 'U'
    je mkV

    cmp ah, 'C'
    je mkV

    cmp ah, 'A'
    je mkV

    cmp ah, 'G'
    je mkV



C21:

    cmp al, 'G'
    jne C22

    cmp ah, 'C'
    jne C22

    jmp mkA



C22:

    cmp al, 'G'
    jne C23

    cmp ah, 'A'
    jne C23

    cmp dl, 'U'
    je mkD

    cmp dl, 'C'
    je mkD



C23:

    cmp al, 'G'
    jne C24

    cmp ah, 'A'
    jne C24

    cmp dl, 'A'
    je mkE

    cmp dl, 'G'
    je mkE



C24:

    cmp al, 'G'
    jne unknown

    cmp ah, 'G'
    jne unknown

    jmp mkG



unknown:

    mov byte ptr [di], 'X'
    jmp codone



; ---------------- AMINO ACID WRITERS -----------------  

mkF:    mov [di], 'F'   ; Phenylalanine
        jmp codone

mkL:    mov [di], 'L'
        jmp codone

mkS:    mov [di], 'S'
        jmp codone

mkY:    mov [di], 'Y'
        jmp codone

mkC:    mov [di], 'C'
        jmp codone

mkStop: mov [di], '*'
        jmp codone

mkW:    mov [di], 'W'
        jmp codone

mkP:    mov [di], 'P'
        jmp codone

mkH:    mov [di], 'H'
        jmp codone

mkQ:    mov [di], 'Q'
        jmp codone

mkR:    mov [di], 'R'
        jmp codone

mkI:    mov [di], 'I'
        jmp codone

mkM:    mov [di], 'M'
        jmp codone

mkT:    mov [di], 'T'
        jmp codone

mkN:    mov [di], 'N'
        jmp codone

mkK:    mov [di], 'K'
        jmp codone

mkV:    mov [di], 'V'
        jmp codone

mkA:    mov [di], 'A'
        jmp codone

mkD:    mov [di], 'D'
        jmp codone

mkE:    mov [di], 'E'
        jmp codone

mkG:    mov [di], 'G'
        jmp codone



codone:

    add si, 3
    inc di
    sub cx, 3

    jmp translate_loop



translation_end:

    mov dx, offset msgProt
    call print_str

    mov dx, offset protein
    call print_str
; --------------------------------------------------------------  
; SIMILARITY CHECK  
; --------------------------------------------------------------  

    mov dx, offset msgEnter2
    call print_str

    mov dx, offset dna2
    mov ah, 0Ah
    int 21h


    ; determine shorter length

    mov cl, [dna1 + 1]
    xor ch, ch

    mov bl, [dna2 + 1]
    xor bh, bh

    cmp bx, cx
    jb len_ok

    mov cx, bx


len_ok:

    mov similarityV, 0

    mov si, offset dna1 + 2
    mov di, offset dna2 + 2



sim_loop:

    cmp cx, 0
    je sim_calc

    mov al, [si]

    cmp al, [di]
    jne sim_skip

    inc similarityV


sim_skip:

    inc si
    inc di

    dec cx
    jmp sim_loop



; --------------------------------------------------------------  
; CALCULATE SIMILARITY (%)  
; --------------------------------------------------------------  

sim_calc:

    mov ax, similarityV

    mov bl, [dna2 + 1]
    xor bh, bh
    mov cx, bx

    cmp cx, 0
    je sim_done


    xor dx, dx        ; clear high word before mul

    mul word ptr 100  ; DX:AX = matches * 100
    div cx            ; AX = percentage



sim_done:

    mov dx, offset msgSim
    call print_str

    call print_num

    mov dx, offset msgNL
    call print_str


    ; End program cleanly  
    mov ax, 4C00h
    int 21h
