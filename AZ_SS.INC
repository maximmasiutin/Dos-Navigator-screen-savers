InitChanges     proc    near
                call    DetectMultiTask
                xor     bx,bx
                xor     cx,cx
                xor     dx,dx
                mov     ax,3
                int     33h
                mov     Int33_BX,bx
                mov     Int33_CX,cx
                mov     Int33_DX,dx

                xor     ax,ax
                mov     es,ax
                mov     ax,es:[417h]
                mov     LastShift,ax
                mov     ax,es:[463h]
                add     al,6
                mov     CRTstatus,ax
                ret
InitChanges     endp

CheckChanges    proc    near
                xor     bx,bx
                xor     cx,cx
                xor     dx,dx
                mov     ax,3
                int     33h
                cmp     bx,Int33_BX
                jne     @@End
                cmp     cx,Int33_CX
                jne     @@End
                cmp     dx,Int33_DX
                jne     @@End

                push    es
                xor     ax,ax
                mov     es,ax
                mov     ax,es:[417h]
                pop     es
                cmp     LastShift,ax
                jne     @@End
                mov     ah,1
                int     16h
                jnz     @@End
                clc
                ret
@@End:          stc
                ret
CheckChanges    endp

Pause           proc    near
                cmp     mTaskSystem,mtNothing
                jne     @@multiTask
                mov     cx,4
                mov     dx,CRTstatus
@@W4R1:         in      al,dx
                test    al,8
                jne     @@W4R1
@@W4R2:         in      al,dx
                test    al,8
                je      @@W4R2
                loop    @@W4R1
                jmp     @@locEx

@@multiTask:    push    es
                xor     ax,ax
                mov     es,ax
                mov     bx,es:[46Ch]
@@skipSlice:    call    GiveUpTimeSlice
                cmp     bx,es:[46Ch]
                je      @@skipSlice
                pop     es

@@locEx:        ret
Pause           endp

CRTstatus       dw      ?
LastShift       dw      ?
Int33_BX        dw      ?
Int33_CX        dw      ?
Int33_DX        dw      ?
