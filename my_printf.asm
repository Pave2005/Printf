section     .data

MainBuffer  db 2048 DUP(0)

JmpTable:   times '%' -  0      dq  EndOfFunc
                                dq  PercSpec            ; спецификатор '%'.

            times 'b' - '%' - 1 dq  EndOfFunc           ; случаи от '$' до 'a'.
                                dq  BinSpec             ; спецификатор 'b' - двоичное число.
                                dq  CharSpec            ; спецификатор 'c'.
                                dq  DecSpec             ; спецификатор 'd'.

            times 'o' - 'd' - 1 dq  EndOfFunc
                                dq  OctSpec             ; спецификатор 'o' - восьмериченое число.

            times 's' - 'o' - 1 dq  EndOfFunc
                                dq  StrSpec             ; cпецификатор 's' - распечатка строки.

            times 'x' - 's' - 1 dq  EndOfFunc
                                dq  HexSpec             ; спецификатор 'x' - шестнадцатиричное число.

            times 255 - 'x' - 1 dq  EndOfFunc           ; не спецификаторы.


RegTable:                       dq  FirstArg
                                dq  SecondArg
                                dq  ThirdArg
                                dq  FourthArg
                                dq  FifthArg


section .text

MainBuffSize     equ     2048
MainBuffEndAddr  equ     MainBuffer + MainBuffSize - 1
MaxItoaSize      equ     64

StackProloge     equ     16

;-------------------------------------------------------------------------------
%macro  .ExchangeSyms 0

        mov al, byte [rdi]
        mov byte [rbx], al

%endm
;-------------------------------------------------------------------------------
%macro  .FlushBuff 2

        cmp rbx, MainBuffEndAddr - %1
        jb %2

        call PrintStr
%2:
%endm
;-------------------------------------------------------------------------------
%macro  .2PowSpecs 1

        xor rax, rax
        call TakeArg
        mov r12, rcx

        mov rcx, %1

        call Itoa2Pow

        mov rcx, r12
        jmp EndOfFunc

%endm
;-------------------------------------------------------------------------------
%macro  .WriteSymAndRenewNum 1

        mov byte [rbx], r11b
        inc rbx

        shr rax, cl

        cmp rax, 0
        jne %1

%endm
;-------------------------------------------------------------------------------
%macro  .Next 1

        inc rdi
        inc rbx

        .FlushBuff 0, %1
        jmp TakeSyms

%endm
;-------------------------------------------------------------------------------
global MyPrintf
;===============================================================================
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;первые 6 аргументов функции хранятся в регистрах RDI, RSI, RDX, RCX, R8, R9.
;RDI - начало форматной строки.
;:==============================================================================
MyPrintf:   xor r15, r15                                ; счетчик аргуентов.

            lea rbx, MainBuffer                         ; положили в RBX адрес первого элемента буфера.
            xor r14, r14

TakeSyms:   cmp byte [rdi], 0                           ; \0 - конец строки.
            je PrintStr

            cmp byte [rdi], '%'
            je HandleSpec

Copy:       .ExchangeSyms                               ; если не % то кладем в буфер символ из форматной строки и
                                                        ; и проверяем новый символ.
            .Next CheckBuffEnd

HandleSpec: inc rdi                                     ; индекс символа со спецификатором

            xor rax, rax
            mov al, byte [rdi]                          ; al - символ спецификатора.

            mov rax, qword [8 * rax + JmpTable]         ; переходим к значениям из jump таблицы.
            jmp rax                                     ; в ax - метка на фукцию определенную спецификатором.
;===============================================================================
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:==============================================================================
PrintStr:   mov r10, rdx                                ; сохраняем значение rdx
            mov r13, rsi                                ; сохраняем значение rsi
            mov r12, rdi                                ; сохраняем значение rdi
            mov r14, rax

            xor rax, rax
            xor rsi, rsi
            xor rdx, rdx

            lea rsi, MainBuffer                         ; адрес начала буфера.
            sub rbx, rsi                                ; rbx - место конечного символа.
            mov rdx, rbx                                ; для запуска системного вызова кладем в rdx - число символов,
                                                        ; которые нужно распечатать.
            add rdx, 1

            mov rbx, rcx                                ; сохраняем значение rcx

            mov rdi, 1
            mov rax, 1                                  ; параметры для запуска функции.
            syscall

            mov rdi, r12
            mov rsi, r13
            mov rdx, r10
            mov rcx, rbx
            mov rax, r14

            xor rbx, rbx

            lea rbx, MainBuffer                         ; вернули rbx на начало буфера.

            xor r10, r10
            xor r12, r12
            xor r13, r13
            xor r14, r14

            ret
;:==============================================================================
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:==============================================================================
PercSpec:   xor rax, rax

            .ExchangeSyms                               ; переложили символ в буфер.

            inc rbx

            jmp EndOfFunc
;-------------------------------------------------------------------------------
CharSpec:   xor rax, rax
            call TakeArg                                ; вызываем функцию.

            mov byte [rbx], al                          ; положили символ в буффер.

            inc rbx

            jmp EndOfFunc
;-------------------------------------------------------------------------------
StrSpec:    xor rax, rax
            call TakeArg

            mov r12, rsi                                ; хранит старое значение rsi.
            mov rsi, rax

MoveStr:    .FlushBuff 0, CheckBuffSizeInRemoving       ; проверяет хватает ли места в буфере.
            cmp byte [rsi], 0
            je EndMove

            mov al, byte [rsi]                          ; переложили символ из строки в буфер.
            mov byte [rbx], al

            inc rbx
            inc rsi

            jmp MoveStr

            mov rsi, r12                                ; вернули в rsi старое значение.

EndMove:    jmp EndOfFunc
;-------------------------------------------------------------------------------
DecSpec:    xor rax, rax
            call TakeArg

            cmp eax, 0
            jge ModOfInt

            sub rax, 1

            xor rax, -1                                 ; получили число по модулю.

            mov byte [rbx], '-'
            inc rbx

ModOfInt:   call Itoa10

            jmp EndOfFunc
;-------------------------------------------------------------------------------
BinSpec:    .2PowSpecs 1
;-------------------------------------------------------------------------------
OctSpec:    .2PowSpecs 3
;-------------------------------------------------------------------------------
HexSpec:    .2PowSpecs 4
;-------------------------------------------------------------------------------
EndOfFunc:  xor rax, rax
            inc rdi
            jmp TakeSyms
;===============================================================================
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;===============================================================================
Itoa10:     .FlushBuff MaxItoaSize, CheckBuffSizeIn10

            mov r12, rsi
            mov r13, rdx

            xor rdx, rdx
            mov rsi, rbx                                ; запоминает начальную позицию числа в буффере.
            xor r10, r10

            mov r10b, 10

GetNumStr:  div r10d                                    ; поделили на 10 число из регистра rax.

            add dl, '0'

            mov byte [rbx], dl
            inc rbx

            xor rdx, rdx
            cmp eax, 0
            jne GetNumStr

            call ReverseStr

            mov rsi, r12
            mov rdx, r13

            ret
;===============================================================================
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;===============================================================================
Itoa2Pow:       .FlushBuff MaxItoaSize, CheckBuffSizeIn2

                mov r13, rsi


                mov rsi, rbx

                mov r10, 1
                shl r10, cl
                sub r10, 1

                cmp cl, 4
                jae ConvToHexNum

ConvToNum:      mov r11, rax
                and r11, r10

                add r11b, '0'                           ; либо '0', либо '1'.

                .WriteSymAndRenewNum ConvToNum

                jmp Finish

ConvToHexNum:   mov r11, rax
                and r11, r10

                cmp r11b, 9
                jbe DecNum

                sub r11b, 10
                add r11b, 'A'

                jmp WriteSym

DecNum:         add r11b, '0'

WriteSym:       .WriteSymAndRenewNum ConvToHexNum

Finish:         call ReverseStr

                mov rsi, r13

                ret
;===============================================================================
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;===============================================================================
ReverseStr: mov r11, rbx                                ; запомнили rbx.
            mov r14, rdx

            dec rbx

RevNumStr:  cmp rbx, rsi
            jbe Skip

            mov dl, [rbx]
            mov dh, [rsi]

            mov [rbx], dh
            mov [rsi], dl

            inc rsi
            dec rbx

            jmp RevNumStr

Skip:       mov rdx, r14
            mov rbx, r11
            ret
;===============================================================================
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;===============================================================================
TakeArg:    cmp r15, 4
            ja UseStack

            mov rax, qword [8 * r15 + RegTable]
            jmp rax

FirstArg:   mov rax, rsi                                ; в rsi лежит первый аргумент.
            jmp End

SecondArg:  mov rax, rdx
            jmp End

ThirdArg:   mov rax, rcx
            jmp End

FourthArg:  mov rax, r8
            jmp End

FifthArg:   mov rax, r9
            jmp End

UseStack:   mov rax, r15

            sub rax, 4 + 1                              ; Get from the stack the correct value

            mov rax, [rsp + StackProloge + rax * 8]

End:        add r15, 1
            ret
;===============================================================================
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;===============================================================================
