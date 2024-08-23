BITS 32

section .data
    introduceMess db "Please introduce a binary number (e.g. 01001): "
    introduceLen equ $ - introduceMess
    overflowMess db "Overflow error occurs! Stop any processes!", 10
    overflowLen equ $ - overflowMess
    number db 5 dup(0)
    NbLen equ $ - number 
    ;ActualNbLength db 1 dup(0)

    ConvOptions db "Options:",10,"1. Octal",10, "2. Decimal", 10, "3. Hexa", 10
    ConvOptLen equ $ - ConvOptions
    typeConversion db "Please enter the conversion option: "
    typeConvLen equ $ - typeConversion 

    outNb db 15 dup(0)
    outLen equ $ - outNb

section .text
    global _start

_overflow_check:
    mov eax, 4
    mov ebx, 1
    mov ecx, overflowMess
    mov edx, overflowLen
    int 0x80
    jmp _end
_read: 
    push ebp
    mov ebp, esp

    ;print the introduce message
    mov eax, 4
    mov ebx, 1
    mov ecx, introduceMess
    mov edx, introduceLen
    int 0x80

    ; introduce the number (sys_write) in terminal
    ; initiate and push canary value
    rdrand esi
    push esi
    sub esp, NbLen
    mov eax, 3
    mov ebx, 0
    mov ecx, esp
    mov edx, NbLen
    int 0x80
    ; verify overflow case 
    mov eax, [ebp-4]
    cmp eax, esi
    jne _overflow_check

    ; determine the string length
    mov ecx, 0
    _for2:
        inc ecx
        movzx eax, byte [esp+ecx]
        cmp eax, 48
        je _for2
        cmp eax, 49
        je _for2

    ; copy the input to number string
    ; in ebx will be the length of the string

 ;_error:
    ;mov edi, ActualNbLength                             ; because by declaring a length of a string with EQU, we cannot actually 
                                                        ; reinitialize this memory address with another variable !!!
    mov esi, number 
    mov ebx, ecx
    _for:
        mov eax, [esp]      ; extract the value from esp
        mov [esi], eax      ; and assign it to the address from esi
        inc esp
        inc esi
        loop _for
    ; for debug verifying
    mov esi, number 

    mov esp, ebp
    pop ebp
    ret

_conv_type:
    push ebp
    mov ebp, esp

    ; option menu
_option_menu:
    mov eax, 4
    mov ebx, 1
    mov ecx, ConvOptions
    mov edx, ConvOptLen
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, typeConversion
    mov edx, typeConvLen
    int 0x80

_read1:
    rdrand esi
    push esi
    dec esp

    mov eax, 3
    mov ebx, 0
    mov ecx, esp
    mov edx, 1
    int 0x80

    mov eax, [ebp-4]
    cmp esi, eax
    jne _overflow_check

    ; extragerea unei valori din esp se realizeaza cu un cast de tip byte
    movzx eax, byte [esp] 
    sub eax, 48
    mov esp, ebp
    pop ebp
    ret

_decimal:
    push ebp
    mov ebp, esp
    ; the value will be stored in edx reg and converted later to string
    mov edx, 0
    mov esi, number 
    mov ecx, [ebp+8]        ; extract the string length from the main program
    dec ecx
    ;sub esp, NbLen
    _for1:
        ;movzx eax, byte [esi]
        mov al, [esi]
        inc esi
        sub eax, 48
        cmp eax, 0
        je _zero
        mov ebx, ecx 
        mov eax, 1
    _loop_shift:
        shl eax, 1
        loop _loop_shift
        add edx, eax
        mov ecx, ebx
    _zero:
        loop _for1
        
        mov al, [esi]
        sub eax, 48
        cmp eax, 0
        je _final_dec
        inc edx         ; if the LSB is 1
    _final_dec:
        mov esp, ebp
        pop ebp
        ret

_hexa:
    mov eax, edx
    mov esi, outNb
    mov ecx, 0
    _extract2:
        mov ebx, 16
        mov edx, 0
        div ebx
        cmp edx, 10
        je val_A
        cmp edx, 11
        je val_B
        cmp edx, 12
        je val_C 
        cmp edx, 13
        je val_D
        cmp edx, 14
        je val_E
        cmp edx, 15
        je val_F
        add edx, 48
        mov [esi], edx
        jmp _continue

    val_A:
        mov ebx, 65
        mov [esi], ebx
        jmp _continue
    val_B:
        mov ebx, 66
        mov [esi], ebx
        jmp _continue
    val_C:
        mov ebx, 67
        mov [esi], ebx
        jmp _continue
    val_D: 
        mov ebx, 68
        mov [esi], ebx
        jmp _continue
    val_E:
        mov ebx, 69
        mov [esi], ebx
        jmp _continue
    val_F:
        mov ebx, 70
        mov [esi], ebx
        jmp _continue
    _continue: 
        inc esi
        inc ecx
        cmp eax, 0
        jne _extract2 
    mov ebx, ecx 
    jmp _add_rest
_octal:
    ; in edx we have the number 
    ; divide number by 8 and put rest on stack
    mov eax, edx 
    mov ecx, 0
    mov ebx, 8 
    _convert_to_octal:
    mov edx, 0
    div ebx
    push edx 
    inc ecx 
    cmp eax, 0
    jne _convert_to_octal
    
    ; extract rest from stack 
    mov eax, 0
    mov ebx, 10
    _extract3:
    mov edx, 0
    mul ebx 
    pop edx 
    add eax, edx 
    loop _extract3 
    mov edx, eax    ; store the number in edx for conversion
    jmp _NbToString
_start:
    ; after this call the input will be stored in number var from data section
    call _read
    push ebx        ; push the string length to stack
    
    ; Number is now in EDX
    call _decimal   ; convert the number to decimal in all cases
    push edx      
    call _conv_type
    pop edx
    ; after this call the type of conversion will be stored in EAX reg
    ; convert the number to the specified call
    cmp eax, 1
    je _octal
    cmp eax, 2
    je _NbToString     ; string length used here
    cmp eax, 3
    je _hexa

    
_NbToString:
    mov esi, outNb  
    mov eax, edx      ; number we want to print 
    mov ebx, 0        ; total length of the string nb
    mov edx, 0 
_for3:                  ; retain the string length
    push ebx
    mov ebx, 10
    div ebx
    pop ebx
    inc ebx
    mov ecx, eax
    add dl, 0x30
    mov [esi], dl
    inc esi
    xor edx, edx
    cmp ecx, 0
    jne _for3
_add_rest:
    mov dl, 0x0         ; add terminator
    mov [esi], dl

    mov ecx, 0          ; inferior limit
    mov edx, ebx        ; superior limit
    push ebx            ; retain the string length in stack
    mov esi, outNb     
_reverse_string:
    dec edx
    mov al, [esi+edx]
    mov bl, [esi+ecx]
    mov [esi+ecx], al
    mov [esi+edx], bl
    inc ecx
    cmp ecx, edx
    jl _reverse_string
print:
    mov eax, 4
    mov ebx, 1
    mov ecx, outNb  
    pop edx             ; extract string length
    int 0x80

_end:
    mov eax, 1
    xor ebx, ebx
    int 0x80
