;**********************
; Multitaskers support
;**********************
mtNothing       equ     0
mtDesqView      equ     1
mtWindows       equ     2
mtOS2           equ     3

DetectMultiTask proc    near
                mov     ax,1022h
                xor     bx,bx
                int     15h
                test    bx,bx
                jz      @@noDesqView
                mov     mTaskSystem,mtDesqView
                mov     mTaskVersion,bx
                jmp     @@locEx
@@noDesqView:   mov     ax,1600h
                int     2Fh
                mov     bx,0200h
                cmp     al,1
                je      @@setWin
                cmp     al,0FFh
                je      @@setWin
                mov     ax,160Ah
                xor     bx,bx
                int     2Fh
                test    bx,bx
                jz      @@noWindows
@@setWin:       mov     mTaskSystem,mtWindows
                mov     mTaskVersion,bx
                jmp     @@locEx
@@noWindows:    clc
                mov     ax,3306h
                int     21h             ;Get true version
                jc      @@DRDOS
@@noDRDOS:      cmp     al,0FFh
                je      @@locEx
                cmp     bh,100
                jae     @@locEx
                cmp     bl,10
                jb      @@checkHLT
                mov     al,bl
                mov     ah,0
                mov     bl,10
                div     bl
                mov     ah,bh
                xchg    al,ah
@@setOS2:       mov     mTaskSystem,mtOS2
                mov     mTaskVersion,ax
                jmp     @@locEx
@@checkHLT:     xor     dx,dx
                mov     ax,1
                hlt
                db      035h,0CAh,0EBh,001h,0C0h
                cmp     ax,1
                ja      @@locEx
                mov     ax,0201h                ; Suppose it`s version 2.1
                jmp     @@setOS2
@@DRDOS:        cmp     ax,1
                jne     @@noDRDOS
@@locEx:        ret
DetectMultiTask endp

GiveUpTimeSlice proc    near
                mov     al,mTaskSystem
                cmp     al,mtDesqView
                jne     @@noDesqView
                mov     ax,1000h
                int     15h
                clc
                ret
@@noDesqView:   cmp     al,mtOS2
                jne     @@noOS2
                xor     dx,dx
                mov     ax,1            ; Release proc for 1 msec
                hlt
                db      035h,0CAh
                clc
                ret
@@noOS2:        cmp     al,mtWindows
                jne     @@locEx
                mov     ax,1680h
                int     2Fh
                clc
                ret
@@locEx:        stc
                ret
                endp

mTaskSystem     db      0
mTaskVersion    dw      0
