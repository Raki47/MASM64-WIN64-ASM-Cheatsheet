; ****************************************************
; * MAIN.ASM                                         *
; ****************************************************
; * Here Is where the magic happens, window is       *
; * Initialised and ASCII cheatsheet table is drawn. *
; ****************************************************
; * V0.1                                             *
; * Created from  20/08/26 - 21/08/26, Just a basic  *
; * window and ACII table, maybe future OpenGL       *
; * intergration will come. codebase cleanup soon    *
; ****************************************************


option casemap:none

EXTERN GetModuleHandleA:PROC
EXTERN LoadIconA:PROC
EXTERN LoadImageA:PROC
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
EXTERN SendMessageA:PROC

; ****************************************************
; *             Drawing text on window               *
; ****************************************************
EXTERN TextOutA:PROC
EXTERN CreateFontA:PROC
EXTERN SelectObject:PROC
EXTERN DeleteObject:PROC
EXTERN SetTextColor:PROC
EXTERN SetBkColor:PROC
EXTERN BeginPaint:PROC
EXTERN EndPaint:PROC
EXTERN DrawTextA:PROC
; ****************************************************
EXTERN SetScrollInfo:PROC
EXTERN GetClientRect:PROC

EXTERN InvalidateRect:PROC
EXTERN SetScrollInfo:PROC
EXTERN GetClientRect:PROC
EXTERN GetScrollInfo:PROC

EXTERN GetClassLongPtrA:PROC

; ****************************************************
; * GL.ASM
; ****************************************************
; * EXTERN OpenGL functions needed In the space below
; ****************************************************

; EXTERN glad_glClearColor:QWORD
; EXTERN glad_glClear:QWORD

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

includelib kernel32.lib
includelib user32.lib

.data

ClassName       db   "MASM64Window",0
WindowTitle     db   "MASM64 Register Cheatsheet",0

WS_OVERLAPPEDWINDOW EQU 00CF0000h
WS_VSCROLL          EQU 00200000h
WM_PAINT        EQU 000Fh
WM_DESTROY      EQU 0002h
WM_VSCROLL      EQU 0114h
WM_MOUSEWHEEL   EQU 020Ah
WM_SIZE         EQU 0005h

SB_VERT         EQU 1

SB_LINEUP      EQU 0
SB_LINEDOWN    EQU 1
SB_PAGEUP      EQU 2
SB_PAGEDOWN    EQU 3
SB_THUMBPOSITION EQU 4
SB_THUMBTRACK  EQU 5
SB_TOP          EQU 6
SB_BOTTOM       EQU 7

SIF_RANGE      EQU 1
SIF_PAGE       EQU 2
SIF_POS        EQU 4
SIF_ALL        EQU 17h

TRUE           EQU 1

CONTENT_HEIGHT EQU 2000

IDI_MAINICON    EQU  101
hMainIcon       dq   0

wc              db   80 dup(0)
msg             db   48 dup(0)

; ********************************************************
; *                    Scrolling                         *
; ********************************************************

ps          db 72 dup(0)

ScrollInfo  db 28 dup(0)

ScrollPos   dd 0
ScrollMax   dd 1400
ScrollPage  dd 600

; Original table rectangle
TableRect   dd 20, 20, 780, 2000

; Rectangle actually passed to DrawTextA
DrawRect    dd 20, 20, 780, 2000

; Temporary storage for WndProc
PaintHwnd   dq 0
PaintHDC   dq 0

; ****************************************************
; *                                                  *
; *                  T  A  B  L  E                   *
; *                                                  *
; ****************************************************

; SB_VERT             EQU 1
SIF_RANGE           EQU 1
SIF_PAGE            EQU 2
SIF_POS             EQU 4
SIF_ALL             EQU 17h

TABLE_TEXT db "===============================================================", 13, 10
           db "|                 General Purpose Registers                   |", 13, 10
           db "===============================================================", 13, 10
           db "| 64-bit Registers |", 13, 10
           db "====================", 13, 10
           db " ", 13, 10
           db "==============================", 13, 10
           db "| RAX | Accumulator register |", 13, 10
           db "===============================================================", 13, 10
           db "| Used for arithmetic operations and as a return register.     |", 13, 10
           db "===============================================================", 13, 10
           db " ", 13, 10
           db "=======================", 13, 10
           db "| RBX | Base register |", 13, 10
           db "===============================================================", 13, 10
           db "| Used for base addressing.                                   |", 13, 10
           db "===============================================================", 13, 10
           db " ", 13, 10
           db "=======================", 13, 10
           db "| RCX | Counter register |", 13, 10
           db "===============================================================", 13, 10
           db "| Used for loop counters and as the first argument in         |", 13, 10
           db "| function calls.                                             |", 13, 10
           db "===============================================================", 13, 10
           db " ", 13, 10
           db "======================", 13, 10
           db "| RDX | Data register |", 13, 10
           db "===============================================================", 13, 10
           db "| Used for I/O operations and as the second argument in       |", 13, 10
           db "| function calls.                                             |", 13, 10
           db "===============================================================", 13, 10
           db " ", 13, 10
           db "======================", 13, 10
           db "| RSI | Source Index |", 13, 10
           db "===============================================================", 13, 10
           db "| Typically used for string and array memory operations.      |", 13, 10
           db "===============================================================", 13, 10
           db " ", 13, 10
           db "===========================", 13, 10
           db "| RDI | Destination Index |", 13, 10
           db "===============================================================", 13, 10
           db "| Also used for string and array operations. RSI and RDI      |", 13, 10
           db "| are often used as source and destination pointers.          |", 13, 10
           db "===============================================================", 13, 10
           db " ", 13, 10
           db "=======================", 13, 10
           db "| RSP | Stack Pointer |", 13, 10
           db "===============================================================", 13, 10
           db "| Points to the top of the stack.                             |", 13, 10
           db "===============================================================", 13, 10
           db " ", 13, 10
           db "======================", 13, 10
           db "| RBP | Base Pointer |", 13, 10
           db "===============================================================", 13, 10
           db "| Often omitted by modern compilers, freeing it to be used    |", 13, 10
           db "| as a general purpose register.                              |", 13, 10
           db "===============================================================", 13, 10
           db " ", 13, 10
           db "=============================", 13, 10
           db "| RIP | Instruction Pointer |", 13, 10
           db "===============================================================", 13, 10
           db "| Points to the next instruction to be executed.              |", 13, 10
           db "| (64-bit exclusive register)                                 |", 13, 10
           db "===============================================================", 13, 10
           db " ", 13, 10
           db "===============================", 13, 10
           db "| R8-R15 | Extended Registers |", 13, 10
           db "===============================================================", 13, 10
           db "| Additional general purpose registers for extended operations|", 13, 10
           db "| and function arguments.                                     |", 13, 10
           db "===============================================================", 13, 10
           db 0



.code

WndProc PROC
    ; RCX = hWnd
    ; RDX = uMsg
    ; R8  = wParam
    ; R9  = lParam

    mov PaintHwnd, rcx

    cmp edx, 0Fh                 ; WM_PAINT
    je  Paint

    cmp edx, 115h                 ; WM_VSCROLL
    je  VScroll

    cmp edx, WM_MOUSEWHEEL
    je  MouseWheel

    cmp edx, 2                   ; WM_DESTROY
    je  Destroy

    sub rsp, 28h
    call DefWindowProcA
    add rsp, 28h
    ret


Paint:

    ; --------------------------------------------------------
    ; BeginPaint
    ; --------------------------------------------------------

    mov PaintHwnd, rcx

    sub rsp, 28h

    mov rcx, PaintHwnd
    lea rdx, ps

    call BeginPaint

    add rsp, 28h

    mov PaintHDC, rax


    ; --------------------------------------------------------
    ; Build DrawRect
    ;
    ; X coordinates stay fixed.
    ; Y coordinates move upward by ScrollPos.
    ; --------------------------------------------------------

    mov eax, ScrollPos

    ; LEFT = 20
    mov dword ptr [DrawRect+0], 20

    ; TOP = 20 - ScrollPos
    mov ecx, 20
    sub ecx, eax
    mov dword ptr [DrawRect+4], ecx

    ; RIGHT = 780
    mov dword ptr [DrawRect+8], 780

    ; BOTTOM = CONTENT_HEIGHT - ScrollPos
    mov ecx, CONTENT_HEIGHT
    sub ecx, eax
    mov dword ptr [DrawRect+12], ecx


    ; --------------------------------------------------------
    ; DrawTextA
    ; --------------------------------------------------------

    sub rsp, 28h

    mov rcx, PaintHDC
    lea rdx, TABLE_TEXT

    mov r8d, -1

    lea r9, DrawRect

    mov dword ptr [rsp+20h], 0

    call DrawTextA

    add rsp, 28h


    ; --------------------------------------------------------
    ; EndPaint
    ; --------------------------------------------------------

    sub rsp, 28h

    mov rcx, PaintHwnd
    lea rdx, ps

    call EndPaint

    add rsp, 28h

    xor eax, eax
    ret


VScroll:

    ; --------------------------------------------------------
    ; LOWORD(wParam) = scroll command
    ; HIWORD(wParam) = track position
    ; --------------------------------------------------------

    mov eax, r8d
    and eax, 0FFFFh

    cmp eax, SB_LINEUP
    je  ScrollUp

    cmp eax, SB_LINEDOWN
    je  ScrollDown

    cmp eax, SB_PAGEUP
    je  ScrollPageUp

    cmp eax, SB_PAGEDOWN
    je  ScrollPageDown

    cmp eax, SB_THUMBPOSITION
    je  ScrollThumb

    cmp eax, SB_THUMBTRACK
    je  ScrollThumb

    cmp eax, SB_TOP
    je  ScrollTop

    cmp eax, SB_BOTTOM
    je  ScrollBottom

    jmp ScrollDone


ScrollUp:

    sub ScrollPos, 20
    jmp ClampScroll


ScrollDown:

    add ScrollPos, 20
    jmp ClampScroll


ScrollPageUp:

    mov eax, ScrollPage
    sub ScrollPos, eax
    jmp ClampScroll


ScrollPageDown:

    mov eax, ScrollPage
    add ScrollPos, eax
    jmp ClampScroll


ScrollThumb:

    ; HIWORD(wParam) = thumb position

    mov eax, r8d
    shr eax, 16

    mov ScrollPos, eax

    jmp ClampScroll


ScrollTop:

    mov ScrollPos, 0
    jmp ClampScroll


ScrollBottom:

    mov eax, ScrollMax
    mov ScrollPos, eax

    jmp ClampScroll


ClampScroll:

    ; --------------------------------------------------------
    ; Minimum = 0
    ; --------------------------------------------------------

    cmp ScrollPos, 0
    jge CheckScrollMaximum

    mov ScrollPos, 0


CheckScrollMaximum:

    ; --------------------------------------------------------
    ; Maximum = ScrollMax
    ; --------------------------------------------------------

    mov eax, ScrollMax

    cmp ScrollPos, eax
    jle UpdateScrollBar

    mov ScrollPos, eax


UpdateScrollBar:

    ; --------------------------------------------------------
    ; Update scrollbar position
    ; --------------------------------------------------------

    mov dword ptr [ScrollInfo+0], 28
    mov dword ptr [ScrollInfo+4], SIF_ALL

    mov dword ptr [ScrollInfo+8], 0

    mov eax, ScrollMax
    add eax, ScrollPage
    mov dword ptr [ScrollInfo+12], eax

    mov eax, ScrollPage
    mov dword ptr [ScrollInfo+16], eax

    mov eax, ScrollPos
    mov dword ptr [ScrollInfo+20], eax

    mov dword ptr [ScrollInfo+24], 0


    sub rsp, 28h

    mov rcx, PaintHwnd
    mov edx, SB_VERT
    lea r8, ScrollInfo
    mov r9d, TRUE

    call SetScrollInfo

    add rsp, 28h


    ; --------------------------------------------------------
    ; Repaint
    ; --------------------------------------------------------

    sub rsp, 28h

    mov rcx, PaintHwnd
    xor edx, edx
    mov r8d, TRUE

    call InvalidateRect

    add rsp, 28h


ScrollDone:

    xor eax, eax
    ret

MouseWheel:

    ; --------------------------------------------------------
    ; WM_MOUSEWHEEL
    ;
    ; HIWORD(wParam) = wheel delta
    ; --------------------------------------------------------

    mov eax, r8d
    sar eax, 16

    cmp eax, 0
    jg WheelUp

    jl WheelDown

    jmp ScrollDone


WheelUp:

    sub ScrollPos, 60
    jmp ClampScroll


WheelDown:

    add ScrollPos, 60
    jmp ClampScroll

Destroy:

    sub rsp, 28h

    xor ecx, ecx
    call PostQuitMessage

    add rsp, 28h

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

    ; Load embedded icon with LoadImageA
    sub rsp, 40h

    mov rcx, rbx                 ; hInstance
    mov edx, IDI_MAINICON        ; resource ID
    mov r8d, 1                   ; IMAGE_ICON
    mov r9d, 0                   ; cx = 0

    mov qword ptr [rsp+20h], 0   ; cy = 0
    mov qword ptr [rsp+28h], 40h ; LR_DEFAULTSIZE

    call LoadImageA

    add rsp, 40h


    ; RAX = HICON
    mov qword ptr [wc+32], rax    ; hIcon
    mov qword ptr [wc+72], rax    ; hIconSm

    ; Save icon handle
    mov hMainIcon, rax

    ; hIcon
    mov qword ptr [wc+32], rax

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
    mov rax, hMainIcon
    mov qword ptr [wc+72], rax

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

    mov r9d, WS_OVERLAPPEDWINDOW OR WS_VSCROLL          ; WS_OVERLAPPEDWINDOW or WS_VSCROLL

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


; --------------------------------------------------------
; Initialize vertical scrollbar
; --------------------------------------------------------

    mov dword ptr [ScrollInfo+0], 28h       ; cbSize
    mov dword ptr [ScrollInfo+4], SIF_ALL    ; fMask

    mov dword ptr [ScrollInfo+8], 0          ; nMin
    mov dword ptr [ScrollInfo+12], 1400      ; nMax

    mov dword ptr [ScrollInfo+16], 600       ; nPage
    mov dword ptr [ScrollInfo+20], 0         ; nPos
    mov dword ptr [ScrollInfo+24], 0         ; nTrackPos

    sub rsp, 28h

    mov rcx, rsi                             ; HWND
    mov edx, SB_VERT                         ; vertical scrollbar
    lea r8, ScrollInfo                       ; SCROLLINFO*
    mov r9d, 1                               ; TRUE = redraw

    call SetScrollInfo

    add rsp, 28h

    ; Reload embedded icon
    sub rsp, 40h
    mov rcx, rbx
    mov edx, 32512
    call LoadIconA
    add rsp, 40h


    ; Set large icon
    sub rsp, 40h
    mov rcx, rsi
    mov edx, 80h              ; WM_SETICON
    mov r8d, 1                ; ICON_BIG
    mov r9, rax               ; HICON
    call SendMessageA
    add rsp, 40h

    
    ; Set small title-bar icon
;    sub rsp, 40h

;    mov rcx, rsi                ; hWnd
;    mov edx, 80h                ; WM_SETICON
;    xor r8d, r8d                ; ICON_SMALL
;    mov r9, hMainIcon           ; hIcon

;    call SendMessageA

;    add rsp, 40h
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