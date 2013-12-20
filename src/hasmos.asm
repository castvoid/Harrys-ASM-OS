; ----------------------------------------------------------------------
; Harry's ASM OS
; 
; Based on code from OSDev
; ----------------------------------------------------------------------

; todo:
; - faster draw command
; - draw a smiley ( :D )
; - move into protected mode

; --------------------------------------------
;  Boot program code begins here
; --------------------------------------------
; boot code begins at 0x003E
begin:
; ---- setup
        mov     ax, cs                  ; Get the current segment
        mov     ds, ax                  ; The data is in this segment
        cli                             ; disable interrupts while changing stack
        mov     ss, ax                  ; We'll use this segment for the stack too
        mov     sp, 0xfffe              ; Start the stack at the top of the segment
        sti                             ; Reenable interrupts
        call    clearScreen
        call    intro_text

cmdprompt:
        mov     si, str_prompt              ; display the str_prompt
        call    print_string

        mov     di, buffer              ; set up the buffer for the input line
        call    get_string              ; gets the line that the user enters

        mov     si, buffer              ; lets get the buffer back
        cmp     byte [si], 0            ; if the string is only null (i.e. is empty) go back to the beginning
        je      cmdprompt


        mov     si, buffer              ; put the buffer in si
        mov     di, str_ls_cmd              ; put the string for the command into di
        call    strcmp                  ; compare them
        jc      .ls_cmd                 ; if they are the same, run the command

        mov     si,buffer               ; for quick testing w/o writing all the necessary stuff
        mov     di, str_temp_cmd
        call    strcmp
        jc      .temp_cmd

        mov     si, buffer              ; smile command
        mov     di, str_smile_cmd
        call    strcmp
        jc      .smile_cmd

        mov     si, buffer              
        mov     di, str_setbg_cmd
        call    strcmp
        jc      .setbg_cmd

        mov     si, buffer
        mov     di, str_reboot_cmd
        call    strcmp
        jc      .reboot_cmd

        mov     si, buffer   
        mov     di, str_clear_cmd
        call    strcmp          
        jc      begin                   ; since it clears the screen, just go to the beginning setup, since that does it.

        mov     si, buffer
        mov     di, str_draw_cmd
        call    strcmp
        jc      draw_cmd

        mov     si, buffer
        mov     di, str_listgames_cmd
        call    strcmp
        jc      .listgames_cmd

        mov     si, invalidcommand      ; if it doesn't match any command, it must be invalid
        mov     bx, 0x04                ; red text
        call    print_color_string
        mov     si,buffer
        call    print_color_string
        mov     si,newline
        call    print_color_string
        jmp     cmdprompt              ; go back again, ready for another command.
; --------------------------------------------
.ls_cmd
        mov     si, str_msg_ls
        call    print_string
        jmp     cmdprompt
; --------------------------------------------
.temp_cmd
        mov     al,0
        mov     ax,0
        div     al

        jmp     cmdprompt
; --------------------------------------------
.smile_cmd
        mov     si, str_msg_smile
        call    print_string
        jmp     cmdprompt
; --------------------------------------------
.setbg_cmd
        mov     ah, 0                   ; read char vector
        int     0x16                    ; wait for a keypress giving AL
        call    charToHex
        mov     ah,0x0B
        mov     bh,0x00
        mov     bl,al
        int     0x10
        jmp     cmdprompt
; --------------------------------------------
.reboot_cmd
        call    display_confirmation
        int     0x19                    ;Try to reboot. 90% of the time, it works every time
; --------------------------------------------
.listgames_cmd
        mov     si,str_games_list
        call    print_string
        jmp     cmdprompt
; --------------------------------------------
; External commands
; --------------------------------------------
draw_cmd
        xor     cx,cx                   ; x pos
        xor     dx,dx                   ; y pos
        xor     al,al                   ; colour
        mov     ah, 0x0C                ; draw pixel function
        mov     bh, 0                   ; on page 0
.rec_draw:   
        inc     al                      ; increase the colour
        cmp     cx, 640
        jge     .incY                   ; if we're at the end of the screen width, go to next line
        cmp     dx, 350 
        jge     cmdprompt                ; if we're at the end of the screen height, return to the str_prompt
        int     0x10                    ; draw it
        inc     cx                      ; increment x
        jmp     .rec_draw
 .incY
        inc     dx                      ; increment y
        xor     cx,cx                   ; reset x
        jmp     .rec_draw
; --------------------------------------------
; data for the OS
; --------------------------------------------
str_intro1          db 'Welcome to ',0
str_intro2          db "Harry's ASM OS", 13,10, 0
     
str_prompt          db '>',0
str_temp_cmd        db 'temp',0
str_clear_cmd       db 'clear',0
str_smile_cmd       db 'smile',0
str_ls_cmd          db 'ls',0
str_draw_cmd        db 'draw',0
str_reboot_cmd      db 'reboot',0
str_setbg_cmd       db 'setbg',0 
str_listgames_cmd   db 'list games',0

str_msg_smile       db 15,2,' Have a nice day! ',1,14,13,10,0
str_msg_ls          db 'what',39,'s a filesystem?',13,10,0
str_msg_confirm     db 'Are you sure you wish to proceed? (Y/N)',13,10,0
str_msg_proceeding  db 'Proceeding...',13,10,0
str_msg_aborted     db 'Aborted.',13,10,0

str_games_list   db 'BLACK JACK',13,10,'CHESS',13,10,'GLOBAL THERMONUCLEAR WAR',13,10,0

buffer          times 64 db 0
invalidcommand  db 'command not found: ',0
newline         db 13,10,0
; ---------------------------------------------
; Functions
; ---------------------------------------------
clearScreen:
        mov     ah, 0x0                 ; sets the video mode - probably slower than it could be
        mov     al, 0x10                
        int     0x10           
        ret
; --------------------------------------------
intro_text:
        mov     bx, 0x0A                ; we want the colour to be intense green
                                        ; bx is 8-bit, bits 3-0 are intensity,r,g,b. 5:reverse video, 6:use as bg colour, 7:blink text
        mov     si, str_intro1           ; load address of our message into si
        call    print_color_string      ; print the message
        mov     bx, 0x0F                ; this one should be white (intense red green + blue)
        mov     si, str_intro2           ; load address of our message
        call    print_color_string      ; print the message
        ret
; --------------------------------------------
display_confirmation:         
        call    clearScreen             ; first, clear the screen
        mov     ah,0x0B                 ; set bg to red
        mov     bh,0x00
        mov     bl,0x04
        int     0x10

        mov     si,str_msg_confirm          ; print confirm message
        mov     bx,0x0F                 ; in white
        call    print_color_string
.getChar
        mov     ah, 0x10                ; get a char
        int     0x16                    
        cmp     al,'Y'                  ; if it's Y, carry on
        je      .cont
        cmp     al,'N'          
        jne     .getChar                ; if it isn't N, then it isn't Y or N, so ask again
.cont
        cmp     al,'Y'                  ; if it isn't yes, it must be no (duh)
        jne     .no

        call    clearScreen             ; clear the screen again
        call    intro_text              ; put the intro text back

        mov     si,str_msg_proceeding       ; say 'proceeding'
        call    print_string
        ret                             ; return to the previous command
.no
        call    clearScreen             ; must be able to sort this mess out!
        call    intro_text

        mov     si,str_msg_aborted          ; Say 'aborted'
        mov     bx,0x04                 ; in red
        call    print_color_string

        jmp     cmdprompt              ; go back to recieve a different command
; --------------------------------------------
print_color_string:
        lodsb       ; AL = [DS:SI]      ; grabs a byte from SI
        or      al, al                  
        jz      .return                 ; if al is zero, get out
        mov     ah, 0x0e                ; print char function
        int     0x10
        jmp     print_color_string
.return:
        ret
print_string:
        mov     bx,0x07                 ; set the colour to grey
        jmp     print_color_string      ; use the other print function
; --------------------------------------------
charToHex
        sub     al,0x30                 ; subtract, so that 0 on keyboard is 0 etc.
        cmp     al,0x9                  ; if the value is now greater than 9, it must be A-F
        jg      .isLetter
        jmp     .end
.isLetter:
        sub     al,0x7                  ; A-F requires additional subtraction of 7
        jmp     .end
.end:
        ret
; --------------------------------------------
get_string:
        xor     cl, cl                  ; set length to zero
.loop:
        mov     ah, 0
        int     0x16                    ; wait for a keypress
 
        cmp     al, 0x08                ; is the keypress backspace?
        je      .backspace              ; yes, handle it
 
        cmp     al, 0x0D                ; is the keypress enter?
        je      .done                   ; yes, we're done
 
        cmp     cl, 0x3F                ; 63 chars inputted (i.e. max length)?
        je      .loop                   ; yes, only let in backspace and enter
 
        mov     ah, 0x0E
        mov     bx, 0x07
        int     0x10                    ; print out character
 
        stosb                           ; put character in buffer
        inc     cl                      ; increment cl buffer
        jmp     .loop                   ; go back to loop
 
 .backspace:
        cmp     cl, 0                   ; beginning of string?
        je      .loop                   ; yes, ignore the key
 
        dec     di                      ; dec di
        mov     byte [di], 0            ; delete character
        dec     cl                      ; decrement counter as well, as we've removed a char
 
        mov     ah, 0x0E
        mov     al, 0x08
        int     10h                     ; draw a backspace on the screen
 
        mov     al, ' '
        int     10h                     ; blank character to cover up the last one
 
        mov     al, 0x08
        int     10h                     ; backspace again
 
        jmp     .loop                   ; go back to the main loop
 
 .done:
        mov     al, 0                   ; null terminator
        stosb
 
        mov     ah, 0x0E
        mov     al, 0x0D
        int     0x10
        mov     al, 0x0A
        int     0x10                    ; print a return/newline
 
        ret
; --------------------------------------------
strcmp:
 .loop:
        mov     al, [si]                ; grab a byte from SI
        mov     bl, [di]                ; grab a byte from DI
        cmp     al, bl                  ; are they equal?
        jne     .notequal               ; nope, we're done.
 
        cmp     al, 0                   ; are both bytes (they were equal before) null (i.e. we're at the end of the strings)?
        je      .done                   ; yes, we're done.
 
        inc     di                      ; increment DI to read the next byte
        inc     si                      ; increment SI to read the next byte
        jmp     .loop                   ; do it again
 
 .notequal:
        clc                             ; not equal, clear the carry flag
        ret
 
 .done:  
        stc                             ; equal, set the carry flag
        ret
