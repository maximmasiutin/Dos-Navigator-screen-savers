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
                .286
                org     100h
                locals  @@
                jumps

Start:          call    InitChanges
                mov     ax,0B800h
                mov     dx,es:[463h]
                cmp     dx,3D4h
                je      @@Color
                mov     ah,0B0h
@@Color:        mov     VRAMseg,ax
                mov     ax,es:[044Ah]
                mov     ScreenWidth,ax
                mov     ax,es:[044Ch]
                shr     ax,1
                mov     ScreenSize,ax
                mov     al,es:[0484h]
                inc     al
                mov     ah,0
                mov     ScreenHeight,ax

                add     dl,6
                mov     bx,dx
                push    cs
                pop     es
                mov     di,offset EGApalette
                mov     si,di
                cld
                mov     cx,16
                push    cx
@@GetEGApal:    mov     dx,bx
                in      al,dx                   ; Drop flip-flop trigger
                mov     dx,3C0h
                mov     al,16
                sub     al,cl
                out     dx,al
                inc     dx
                insb
                dec     dx
                loop    @@GetEGApal
                xchg    dx,bx
                in      al,dx
                xchg    dx,bx
                mov     al,20h
                out     dx,al
                mov     dl,0C7h
                mov     di,offset VGApalette
                push    di
                mov     cx,16
@@ReadRGB:      lodsb
                out     dx,al
                inc     dx
                inc     dx
                insb
                insb
                insb
                dec     dx
                dec     dx
                loop    @@ReadRGB
                pop     si
                mov     al,0
                call    FadeOut
                mov     cx,ScreenSize
                push    cx
                mov     ds,VRAMseg
                xor     si,si
                mov     di,offset ScreenBuffer
                rep     movsw
                push    ds
                pop     es
                pop     cx
                xor     si,si
                xor     di,di
@@TranfColors:  inc     si
                inc     di
                lodsb
                mov     ah,al
                shr     ah,4
                and     al,0Fh
                mov     bx,offset ColorXLAT
                xlat    cs:[bx]
                xchg    ah,al
                xlat    cs:[bx]
                shl     al,4
                or      al,ah
                stosb
                loop    @@TranfColors
                push    cs
                pop     ds

                mov     si,offset LighterPal
                call    SetLighterPal

                mov     dx,41h
                mov     bx,ScreenWidth
                sub     bx,8
                call    FitToAH
                shl     bx,1
                mov     StepX,bx
                and     ax,0FFFEh
                mov     LighterX,ax
                mov     dx,40h
                mov     bx,ScreenHeight
                sub     bx,4
                call    FitToAH
                mov     StepY,bx
                mov     LighterY,ax

@@MoveLighter:  call    DisplayLighter
                call    Pause
                call    CheckChanges
                jc      @@End
                call    HideLighter

                mov     ax,LighterX
                mov     bx,ScreenWidth
                sub     bx,7
                and     bx,0FFFEh
                cmp     ax,bx
                jb      @@HOK1
                mov     StepX,-2
@@HOK1:         or      ax,ax
                jg      @@HOK2
                mov     StepX,2
@@HOK2:         add     ax,StepX
                mov     LighterX,ax

                mov     ax,LighterY
                mov     bx,ScreenHeight
                sub     bx,4
                cmp     ax,bx
                jb      @@VOK1
                mov     StepY,-1
@@VOK1:         or      ax,ax
                jg      @@VOK2
                mov     StepY,1
@@VOK2:         add     ax,StepY
                mov     LighterY,ax

                jmp     @@MoveLighter

@@End:          mov     ax,0C0Bh
                int     21h                     ; Clear keyboard
                call    HideLighter
                mov     si,offset GrayPalette+9
                call    SetLighterPal
                mov     cx,ScreenSize
                mov     es,VRAMseg
                mov     si,offset ScreenBuffer
                xor     di,di
                rep     movsw
                push    cs
                pop     es

                mov     al,1
                call    FadeOut
                int     20h

SetLighterPal   proc    near
                mov     cx,4
                mov     bx,offset EGApalette+9
                mov     dx,3C8h
@@SetPal:       mov     al,[bx]
                inc     bx
                out     dx,al
                inc     dx
                outsb
                outsb
                outsb
                dec     dx
                loop    @@SetPal
                ret
                endp

FitToAH         proc    near
                in      al,dx
                mov     ah,al
                in      al,dx
                and     ax,03FFh
@@FIT1:         cmp     ax,bx
                jb      @@OK1
                sub     ax,bx
                jmp     @@FIT1
@@OK1:          shr     bx,1
                cmp     ax,bx
                mov     bx,-1
                ja      @@OK3
                neg     bx
@@OK3:          ret
                endp

SetVGApalette   proc    near
                mov     ah,16
                mov     bx,offset EGApalette
                mov     dx,CRTstatus
@@W4R1:         in      al,dx
                test    al,8
                jne     @@W4R1
@@W4R2:         in      al,dx
                test    al,8
                je      @@W4R2
@@SetRGB:       mov     al,[bx]
                inc     bx
                mov     dl,0C8h
                out     dx,al
                inc     dx
                mov     cl,3
                rep     outsb
                dec     ah
                jne     @@SetRGB
                ret
                endp

FadeOut         proc    near
                mov     @@FadeIn,al
                mov     bp,63
@@SetPal:       mov     si,offset VGAPalette
                mov     di,offset WorkPalette
                mov     cx,16*3
                mov     bx,bp
                cmp     @@FadeIn,0
                je      @@FadeOut
                mov     bx,64
                sub     bx,bp
@@FadeOut:      lodsb
                mov     bh,[si+16*3-1]
                sub     al,bh
                imul    bl
                sar     ax,6
                add     al,bh
                stosb
                loop    @@FadeOut
                mov     si,offset WorkPalette
                call    SetVGApalette
                dec     bp
                jge     @@SetPal
                ret
@@FadeIn        db      ?
                endp

DisplayLighter  proc    near
                mov     ax,LighterY
                mov     bp,ScreenWidth
                shl     bp,1
                mul     bp
                sub     bp,7*2
                mov     bx,LighterX
                shl     bx,1
                add     ax,bx
                inc     ax
                mov     di,ax
                mov     si,offset Lighter
                mov     bl,4 ; H
@@0:            mov     cx,7 ; W
@@1:            lodsb
                mov     ah,es:[di]
                or      al,al
                je      @@SkipIt
                and     ah,0F0h
@@SkipIt:       or      al,ah
                stosb
                inc     di
                loop    @@1
                add     di,bp
                dec     bl
                jne     @@0
                ret
                endp

HideLighter     proc    near
                mov     ax,LighterY
                mov     bp,ScreenWidth
                shl     bp,1
                mul     bp
                sub     bp,7*2
                mov     bx,LighterX
                shl     bx,1
                add     ax,bx
                inc     ax
                mov     di,ax
                mov     si,ax
                add     si,offset ScreenBuffer
                mov     dl,4 ; H
@@0:            mov     cx,7 ; W
@@1:            lodsb
                inc     si
                mov     ah,al
                shr     ah,4
                and     al,0Fh
                mov     bx,offset ColorXLAT
                xlat    cs:[bx]
                xchg    ah,al
                xlat    cs:[bx]
                shl     al,4
                or      al,ah
                stosb
                inc     di
                loop    @@1
                add     di,bp
                add     si,bp
                dec     dl
                jne     @@0
                ret
                endp

include mTask.inc
include az_ss.inc

VRAMseg         dw      ?
ScreenWidth     dw      ?
ScreenHeight    dw      ?
ScreenSize      dw      ?
LighterX        dw      ?
LighterY        dw      ?
StepX           dw      ?
StepY           dw      ?
EGApalette      db      16 dup (?)
WorkPalette     db      16*3 dup (?)
VGApalette      db      16*3 dup (?)
GrayPalette     db      00,00,00
                db      00,01,02
                db      00,02,04
                db      00,03,06
                db      00,04,08
                db      00,05,10
                db      00,06,12
                db      00,07,14
                db      00,02,04
                db      00,03,06
                db      00,04,08
                db      00,05,10
                db      00,06,12
                db      00,07,14
                db      00,08,16
                db      00,09,18
LighterPal      db      20,20,20
                db      25,25,25
                db      30,30,30
                db      35,35,35
Lighter         db      00,09,10,11,10,09,00 ; ±±±±±
                db      09,10,11,12,11,10,09 ;±±±±±±±
                db      09,10,11,12,11,10,09 ;±±±±±±±
                db      00,09,10,11,10,09,00 ; ±±±±±
ColorXLAT       db      0,1,2,3,4,5,6,7,2,3,4,5,6,7,14,15

ScreenBuffer    db      132*60 dup (?)

                end     Start
