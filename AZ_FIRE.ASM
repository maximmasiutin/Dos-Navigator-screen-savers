;*************************************************************************
;
;      Dos Navigator II Screen Saver source
;      (C)opyright 1995 Andy Zabolotny
;
;      This source is freeware and licenced only for non-commercial use
;
;*************************************************************************

                .model  tiny
                .code
                .386
                org     100h
                locals  @@
                jumps

WaveW           equ     320
WaveH           equ     100
WaveAddr        equ     (320-WaveW)/2

Start:          call    InitChanges
                mov     al,es:[449h]
                mov     LastMode,al
                call    InitVideo

                push    ds
                pop     es
                mov     cx,WaveW * WaveH * 2 / 4 + 1
                xor     eax,eax
                mov     di,offset WaveImage1
                rep     stosd

                mov     ax,0A000h
                mov     es,ax
@@waveLoop:     mov     si,Wave1
                add     si,WaveW - 1
                mov     di,Wave2
                inc     di
                ;mov     ebx,[si-WaveW]
                mov     ecx,[si]
                mov     edx,[si+WaveW]
                mov     bl,0
                add     si,4

                mov     bp,WaveW * (WaveH - 2)
@@waveLine:     ;mov     al,[si-WaveW]
                ;shrd    ebx,eax,8
                mov     al,[si]
                shrd    ecx,eax,8
                mov     al,[si+WaveW]
                shrd    edx,eax,8
                inc     si
                shld    eax,ecx,16
                add     al,cl
                setc    ah
                add     al,ch
                adc     ah,0
                add     al,dh
                adc     ah,0
                ror     ax,2
                test    al,al
                jz      @@put
                test    cl,1
                setnz   ah
                sub     al,ah
@@put:          mov     [di],al
                inc     di
                dec     bp
                jnz     @@waveLine

                mov     cx,WaveW
                mov     dx,randSeed
@@MakeSeed:     add     bx,05EDAh
                xor     bx,dx
                add     dx,0E34Ah
                mov     dl,bh
                add     dh,bl
                adc     dl,al
                add     bx,dx
                rol     bx,3
                mov     al,bl
                and     al,07Fh
                mov     [di],al
                inc     di
                loop    @@MakeSeed
                mov     randSeed,dx

                mov     si,Wave1
                xchg    si,Wave2
                mov     Wave1,si
                add     si,WaveW
                mov     di,WaveAddr+320
                mov     dx,WaveH-2-2
@@refresh0:     mov     cx,WaveW/4
                rep     movsd
                add     di,(320 - WaveW)
                dec     dx
                jne     @@refresh0
                call    Pause
                call    CheckChanges
                jnc     @@WaveLoop

                mov     ax,0C0Bh
                int     21h                     ; Clear keyboard
                mov     ah,0
                mov     al,LastMode
                int     10h
                int     20h

InitVideo       proc    near
                mov     ax,13h
                int     10h
                mov     dx,CRTstatus
                sub     dl,6
                mov     ax,0309h
                out     dx,ax

                mov     dx,03C8h
                mov     al,0
                out     dx,al
                inc     dx
                mov     si,offset PalData
                mov     cl,nPalColors

@@makePal:      mov     ch,32
@@makeRamp:     mov     di,3
                xor     bx,bx
@@makeRGB:      mov     al,32
                sub     al,ch
                mov     ah,[si+bx+3]
                sub     ah,[si+bx]
                imul    ah
                sar     ax,5
                add     al,[si+bx]
                out     dx,al
                inc     bx
                dec     di
                jne     @@makeRGB
                dec     ch
                jne     @@makeRamp
                add     si,6
                dec     cl
                jne     @@makePal
                ret
InitVideo       endp

include mTask.inc
include az_ss.inc

randSeed        dw      ?
LastMode        db      0
PalData         db      00,00,00, 24,00,00
                db      25,01,00, 48,32,08
                db      50,33,08, 63,63,63
nPalColors      equ     ($ - PalData)/6
Wave1           dw      offset WaveImage1       ;offset WaveImage1
Wave2           dw      offset WaveImage2       ;offset WaveImage2
WaveImage1      db      WaveW * WaveH dup (?)
WaveImage2      db      WaveW * WaveH dup (?)
                end     Start
