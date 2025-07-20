; originals
%define INPUTS       2
%define HIDDEN       2
%define OUTPUTS      1
; temporary
%define IXH_M INPUTS * HIDDEN
%define HXO_M HIDDEN * OUTPUTS


section .bss
    
    ; Variable's that are used for storing thing like weight, bias and other values
    input         resd 8        ; XOR gate have 00 01 10 11
    target        resd 4        ; XOR gate ans  0  1  1  0
    weight_hidden resd IXH_M    ; HIDDEN * INPUT
    bias_hidden   resd HIDDEN   ; HIDDEN
    weight_output resd HXO_M    ; OUTPUTS * HIDDEN
    bias_output   resd OUTPUTS  ; OUTPUTS
    hidden_r      resd HIDDEN   ; HIDDEN
    output_r      resd OUTPUTS  ; OUTPUTS

    ; Temporary variables for loop counter, stroring temporary data
    s     resd 1
    i     resd 1
    j     resd 1
    tw    resd 1
    ti    resd 1
    sum   resd 1

section .text
global _start

_start:
    ; forword pass
    mov dword [s], 0 ; s = 0

.outer_loop_s:
    mov eax, [s]
    cmp eax, 4
    jge .done

    mov dword [i], 0 ; i = 0

.inner_loop_i_h:
    mov eax, [i]
    cmp eax, HIDDEN
    jge .done_loop_i_h

    ; i loop things hidden layer
    mov esi, bias_hidden
    mov ecx, 0
    mov ebx, [i]
    mov edx, HIDDEN
    call matrix_data_from_index
    mov [sum], eax

    mov dword [j], 0 ; j = 0

.inner_loop_j_h:
    mov eax, [j]
    cmp eax, INPUTS
    jge .done_loop_j_h
    
    ; do stuff for j hidden layer
    mov esi, input
    mov ecx, [s]
    mov ebx, [j]
    mov edx, 4     ; input column 
    call matrix_data_from_index
    mov [ti], eax

    mov esi, weight_hidden
    mov ecx, [i]
    mov ebx, [j]
    mov edx, INPUTS
    call matrix_data_from_index
    mov [tw], eax

    fld dword [tw]
    fld dword [ti]
    fmul 
    fld dword [sum]
    fadd
    fstp dword [sum] 

    mov eax, [j]
    inc eax
    mov [j], eax
    jmp .inner_loop_j_h

.done_loop_j_h:
    fld dword [sum]
    call sigmoid

    mov ebx, [i]
    fstp dword [hidden_r + ebx * 4] 

    mov eax, [i]
    inc eax
    mov [i], eax
    jmp .inner_loop_i_h

.done_loop_i_h:

    mov dword [i], 0

.inner_loop_i_o:
    mov eax, [i]
    cmp eax, OUTPUTS
    jge .done_loop_i_o

    ; i loop things output layer
    mov esi, bias_output
    mov ecx, 0
    mov ebx, [i]
    mov edx, OUTPUTS
    call matrix_data_from_index
    mov [sum], eax

    mov dword [j], 0

.inner_loop_j_o:
    mov eax, [j]
    cmp eax, HIDDEN
    jge .done_loop_j_o

    ; do stuff for j output layer
    mov esi, hidden_r
    mov ecx, 0
    mov ebx, [j]
    mov edx, HIDDEN
    call matrix_data_from_index
    mov [ti], eax

    mov esi, weight_output
    mov ecx, [i]
    mov ebx, [j]
    mov edx, HIDDEN
    call matrix_data_from_index
    mov [tw], eax

    fld dword [tw]
    fld dword [ti]
    fmul 
    fld dword [sum]
    fadd
    fstp dword [sum] 

    mov eax, [j]
    inc eax
    mov [j], eax
    jmp .inner_loop_j_o


.done_loop_j_o:
    fld dword [sum]
    call sigmoid

    mov ebx, [i]
    fstp dword [output_r + ebx * 4] 

    mov eax, [i]
    inc eax
    mov [i], eax
    jmp .inner_loop_i_o


.done_loop_i_o:

    mov eax, [s]
    inc eax
    mov [s], eax
    jmp .outer_loop_s

.done:
    mov eax, 1
    xor ebx, ebx
    int 0x80


; -------------------------------------
; Function : sigmoid
; Input    : st0 = x
; Return   : st0 = sigmoid(x)
; Uses     : Maths;  actual sigmoid : 1 / (1 + (e ^ -x)); we used 1 / (1 + (2 ^ -x)) 
; -------------------------------------    
sigmoid:
    ; fraction of x
    fld     st0         ; duplicate x → ST0=x, ST1=x
    fchs                ; ST0 = -x
    fld     st0         ; duplicate -x → ST0=-x, ST1=-x, ST2=x
    frndint             ; ST0 = int(-x), ST1 = -x
    fxch                ; swap → ST0 = -x, ST1 = int(-x)
    fsub                ; ST0 = -x - int(-x) = fractional part of -x = frac(-x)

    ; 2^frac
    f2xm1               ; st0 = 2^st0 - 1 
    fld1                ; st0 = 1.0f, st1 = 2^st0 - 1
    fadd                ; st0 = 2^frac

    ; 2^int * 2^frac
    fxch                ; st0 = int, st1 = 2^frac
    fscale              ; st0 = 2^(-x) = 2^int * 2^frac
    fstp    st1         ; remove st1, st0 = 2^(-x)

    fld1                ; st0 = 1, st1 = 2^(-x)
    fadd                ; st0 = 1 + 2^(-x)

    fld1                ; st0 = 1, st1 = 1 + 2^(-x)
    fdiv                ; st0 = 1 / (1 + (2 ^ -x))

    ret


; -------------------------------------
; Function: matrix_data_from_index
; Input : 
;       esi = pointer to the matrix
;       ecx = row of index
;       ebx = col of index
;       edx = number of colums
; Return : eax = data from that index
; Uses : maths 
; address = base_address + ((row_index * num_cols) + col_index) * element_size 
; in this case element_size = 4, num_cols = cols = 3 (in .bss) 
; -------------------------------------
matrix_data_from_index:
    push ebx              ; save EBX if it's caller-saved
    mov eax, ecx          ; EAX = row
    mov edi, ebx          ; save col index in EDI
    mov ebx, edx          ; EBX = number of columns
    imul eax, ebx         ; EAX = row * num_cols
    add eax, edi          ; EAX = (row * num_cols) + col
    imul eax, 4           ; EAX = offset in bytes
    add esi, eax          ; ESI = address of desired element
    mov eax, [esi]        ; EAX = value at that address
    pop ebx               ; restore EBX
    ret
