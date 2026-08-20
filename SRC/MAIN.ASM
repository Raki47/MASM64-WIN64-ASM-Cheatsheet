; To be continued at a later date, this will be a simple app that provides a little dictionarry for 64 bit MASM registers.
; The web page will be fancier and more detailed, this is more of a bonus project to test my skills

; ****************************************************
; * GL.ASM
; ****************************************************
; * EXTERN OpenGL functions needed In the space below
; ****************************************************

EXTERN glad_glClearColor:QWORD
EXTERN glad_glClear:QWORD

; ****************************************************
; * R47_COLOUR.ASM
; ****************************************************
; * EXTERN Colours needed In the space below
; ****************************************************

INCLUDE R47_COLOUR.INC

; EXTERN R47_ColourBlend:PROC
; EXTERN R47_ColourLerp:PROC

EXTERN CYAN:R47_COLOUR

; ****************************************************


option casemap:none

EXTERN GetModuleHandleA:PROC
EXTERN ExitProcess:PROC
EXTERN RegisterClassExA:PROC
EXTERN CreateWindowExA:PROC
EXTERN DefWindowProcA:PROC
EXTERN ShowWindow:PROC
EXTERN UpdateWindow:PROC
EXTERN GetMessageA:PROC
EXTERN TranslateMessage:PROC
EXTERN DispatchMessageA:PROC
EXTERN PostQuitMessage:PROC

includelib kernel32.lib
includelib user32.lib

.data

ClassName       db "MASM64Window",0
WindowTitle     db "MASM64 Register Cheatsheet",0

wc              db 80 dup(0)
msg             db 48 dup(0)

.code

WndProc PROC
    ; RCX = hWnd
    ; RDX = uMsg
    ; R8  = wParam
    ; R9  = lParam

    cmp edx, 2                  ; WM_DESTROY
    je  Destroy

    sub rsp, 40
    call DefWindowProcA
    add rsp, 40
    ret

Destroy:
    sub rsp, 40
    xor ecx, ecx
    call PostQuitMessage
    add rsp, 40

    xor eax, eax
    ret
WndProc ENDP


MAIN PROC

    ; GetModuleHandleA(NULL)
    sub rsp, 40
    xor ecx, ecx
    call GetModuleHandleA
    add rsp, 40

    ; Store hInstance
    mov rbx, rax

    ; WNDCLASSEXA
    ; cbSize
    mov dword ptr [wc+0], 80

    ; style = CS_HREDRAW | CS_VREDRAW
    mov dword ptr [wc+4], 3

    ; lpfnWndProc
    lea rax, WndProc
    mov qword ptr [wc+8], rax

    ; cbClsExtra
    mov dword ptr [wc+16], 0

    ; cbWndExtra
    mov dword ptr [wc+20], 0

    ; hInstance
    mov qword ptr [wc+24], rbx

    ; hIcon
    mov qword ptr [wc+32], 0

    ; hCursor
    mov qword ptr [wc+40], 0

    ; hbrBackground
    mov qword ptr [wc+48], 6

    ; lpszMenuName
    mov qword ptr [wc+56], 0

    ; lpszClassName
    lea rax, ClassName
    mov qword ptr [wc+64], rax

    ; hIconSm
    mov qword ptr [wc+72], 0

    ; RegisterClassExA(&wc)
    sub rsp, 40
    lea rcx, wc
    call RegisterClassExA
    add rsp, 40


    ; CreateWindowExA(
    ;     0,
    ;     ClassName,
    ;     WindowTitle,
    ;     WS_OVERLAPPEDWINDOW,
    ;     100, 100,
    ;     800, 600,
    ;     NULL, NULL,
    ;     hInstance,
    ;     NULL
    ; )

    ; 0x78 bytes:
    ; 32 bytes shadow space
    ; 8 stack arguments
    ; extra space for alignment

    sub rsp, 78h

    ; First four arguments
    xor ecx, ecx                ; dwExStyle = 0

    lea rdx, ClassName          ; lpClassName
    lea r8,  WindowTitle        ; lpWindowName

    mov r9d, 00CF0000h          ; WS_OVERLAPPEDWINDOW

    ; Remaining arguments
    mov dword ptr [rsp+20h], 100    ; X
    mov dword ptr [rsp+28h], 100    ; Y
    mov dword ptr [rsp+30h], 800    ; Width
    mov dword ptr [rsp+38h], 600    ; Height

    mov qword ptr [rsp+40h], 0      ; hWndParent
    mov qword ptr [rsp+48h], 0      ; hMenu
    mov qword ptr [rsp+50h], rbx    ; hInstance
    mov qword ptr [rsp+58h], 0      ; lpParam

    call CreateWindowExA

    add rsp, 78h

    ; Save HWND
    mov rsi, rax

;    movss xmm0, dword ptr [CYAN + R47_COLOUR.R]
;    movss xmm1, dword ptr [CYAN + R47_COLOUR.G]
;    movss xmm2, dword ptr [CYAN + R47_COLOUR.B]
;    movss xmm3, dword ptr [CYAN + R47_COLOUR.A]
;
;    call qword ptr [glad_glClearColor]
;
;    mov ecx, 00004000h
;    call qword ptr [glad_glClear]
;

    ; ShowWindow(hwnd, SW_SHOW)
    sub rsp, 40
    mov rcx, rsi
    mov edx, 1
    call ShowWindow
    add rsp, 40

    ; UpdateWindow(hwnd)
    sub rsp, 40
    mov rcx, rsi
    call UpdateWindow
    add rsp, 40


MessageLoop:

    ; GetMessageA(&msg, NULL, 0, 0)
    sub rsp, 40
    lea rcx, msg
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call GetMessageA
    add rsp, 40

    cmp eax, 0
    jle Exit

    ; TranslateMessage(&msg)
    sub rsp, 40
    lea rcx, msg
    call TranslateMessage
    add rsp, 40

    ; DispatchMessageA(&msg)
    sub rsp, 40
    lea rcx, msg
    call DispatchMessageA
    add rsp, 40

    jmp MessageLoop


Exit:
    sub rsp, 40
    xor ecx, ecx
    call ExitProcess

MAIN ENDP

END