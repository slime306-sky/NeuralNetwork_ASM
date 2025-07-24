; originals
%define INPUTS       2
%define HIDDEN       2
%define OUTPUTS      1

; temporary
%assign IXH_M INPUTS * HIDDEN
%assign HXO_M HIDDEN * OUTPUTS


section .bss    
    ; Variable's that are used for storing thing like weight, bias and other values
    input         resd 8        ; XOR gate have 00 01 10 11
    target        resd 4        ; XOR gate ans  0  1  1  0
    weight_hidden resd IXH_M    ; HIDDEN * INPUT
    bias_hidden   resd HIDDEN   ; HIDDEN
    weight_output resd HXO_M    ; OUTPUTS * HIDDEN
    bias_output   resd OUTPUTS  ; OUTPUTS
    hidden_r      resd HIDDEN   ; HIDDEN
    output_r      resd 4        

    ; Temporary variables for loop counter, stroring temporary data
    s     resd 1
    i     resd 1
    j     resd 1
    tw    resd 1
    ti    resd 1
    sum   resd 1
    a     resd 1

    fd    resd 1

section .data
    filename     db "xorModel.txt", 0
    out_filename db "xorOut.txt",   0
    xor_inputs   dd 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0

    ;temp weight and bias
    d_weight_hidden dd -7.3061485, -7.3277073, -9.589272, -9.705681
    d_bias_hidden   dd 11.037739, 4.0157437
    d_weight_output dd 13.255704, -13.261149
    d_bias_output   dd -6.4398603

section .text
    global _start

_start:
    
    ; loading file xorModel.txt
    mov eax, 5
    mov ebx, filename
    xor ecx, ecx
    int 0x80
    mov [fd], eax

    mov eax, 3
    mov ebx, [fd]
    mov ecx, weight_hidden
    mov edx, 16
    int 0x80

    mov eax, 3
    mov ebx, [fd]
    mov ecx, bias_hidden
    mov edx, 8
    int 0x80
    
    mov eax, 3
    mov ebx, [fd]
    mov ecx, weight_output
    mov edx, 8
    int 0x80
    
    mov eax, 3
    mov ebx, [fd]
    mov ecx, bias_output
    mov edx, 4
    int 0x80
    
    mov eax, 6
    mov ebx, esi
    int 0x80
    
    ; This loads the weights and biases from the data section into the bss section
    ; mov eax, [d_weight_hidden]
    ; mov [weight_hidden], eax

    ; mov eax, [d_weight_hidden + 4]
    ; mov [weight_hidden + 4], eax

    ; mov eax, [d_weight_hidden + 8]
    ; mov [weight_hidden + 8], eax

    ; mov eax, [d_weight_hidden + 12]
    ; mov [weight_hidden + 12], eax

    ; mov eax, [d_bias_hidden]
    ; mov [bias_hidden], eax

    ; mov eax, [d_bias_hidden + 4]
    ; mov [bias_hidden + 4], eax

    ; mov eax, [d_weight_output]
    ; mov [weight_output], eax

    ; mov eax, [d_weight_output + 4]
    ; mov [weight_output + 4], eax

    ; mov eax, [d_bias_output]
    ; mov [bias_output], eax

    ; load inputs
    mov esi, xor_inputs
    mov edi, input
    mov ecx, 8
.copy_input:
    mov eax, [esi]
    mov [edi], eax
    add esi, 4
    add edi, 4
    dec ecx
    jnz .copy_input  
              
    call forward_propagation

    ; load result in file
    mov eax, 5
    mov ebx, out_filename
    mov ecx, 577
    mov edx, 0644
    int 0x80
    mov edi, eax

    mov eax, 4
    mov ebx, edi
    mov ecx, output_r
    mov edx, 16
    int 0x80

    mov eax, 6
    mov ebx, edi
    int 0x80
    jmp .done
.done:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; forword pass
forward_propagation:
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

    mov eax, [i]
    shl eax, 2
    mov esi, bias_hidden
    add esi, eax
    mov eax, [esi]
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
    mov edx, INPUTS     ; input column 
    call matrix_data_from_index
    mov [ti], eax

    mov esi, weight_hidden
    mov ecx, [i]
    mov ebx, [j]
    mov edx, INPUTS
    call matrix_data_from_index
    mov [tw], eax

    fld dword [ti]     ; ST(0) = ti
    fmul dword [tw]    ; ST(0) = ti * tw
    fadd dword [sum]   ; ST(0) = sum + (ti * tw)
    fstp dword [sum]   ; Store result

    mov eax, [j]
    inc eax
    mov [j], eax
    jmp .inner_loop_j_h

.done_loop_j_h:
    finit
    fld dword [sum]
    call sigmoid
    mov ebx, [i]
    fstp dword [hidden_r + ebx * 4] 
    finit

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
    mov eax, [i]
    shl eax, 2
    mov esi, bias_output
    add esi, eax
    mov eax, [esi]
    
    mov [sum], eax

    mov dword [j], 0

.inner_loop_j_o:
    mov eax, [j]
    cmp eax, HIDDEN
    jge .done_loop_j_o

    ; do stuff for j output layer
    mov eax, [j]
    shl eax, 2
    mov esi, hidden_r
    add esi, eax
    mov eax, [esi]
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
    finit
    fld dword [sum]
    call sigmoid
    mov ebx, [s]
    fstp dword [output_r + ebx * 4] 
    finit

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
    ret

; -------------------------------------
; Function : sigmoid
; Input    : st0 = x
; Return   : st0 = sigmoid(x)
; Uses     : Maths;  actual sigmoid : 1 / (1 + (e ^ -x)); we used 1 / (1 + (2 ^ -x)) 
; -------------------------------------    
sigmoid:
    ; Input:  ST0 = x
    ; Output: ST0 = sigmoid(x) = 1 / (1 + e^(-x))
    fld st0                 ; duplicate x
    frndint                 ; round to int
    fxch                    ; swap
    fsub st0, st1           ; get fractional part
    f2xm1                   ; compute 2^frac - 1
    fld1
    faddp st1, st0          ; 2^frac
    fxch
    frndint                 ; get int again
    fxch
    fscale                  ; scale by 2^int
    fstp dword [a]          ; store a = 2^x

    fld dword [a]           ; load a
    fld st0                 ; duplicate
    fld1
    faddp st1, st0          ; a + 1
    fdivp st1, st0          ; a / (a + 1)
    ret

; -----̥--------------------------------
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
