extern not
extern getchar
extern ord
extern size
extern print
extern chr
extern exit
extern concat
extern flush
extern substring
extern init_array
extern alloc_record
extern str_cmp

global tigermain

section .text
tigermain:
push rbp
mov rbp, rsp
sub rsp, 40
push rbx
push r12
push r13
push r14
mov r10, rdi
L44:
mov qword [rbp-8], 8
lea r12, [rbp-16]
mov r10, rbp
add r10, -8
mov r10, qword [r10]
mov rdi, r10
mov r10, 0
mov rsi, r10
mov r10, 1
mov rdx, r10
call init_array
mov r10, rax
L1_ret:
mov qword [r12], r10
lea r12, [rbp-24]
mov r10, rbp
add r10, -8
mov r10, qword [r10]
mov rdi, r10
mov r10, 0
mov rsi, r10
mov r10, 1
mov rdx, r10
call init_array
mov r10, rax
L2_ret:
mov qword [r12], r10
lea r12, [rbp-32]
mov r10, qword [rbp-8]
add r10, qword [rbp-8]
sub r10, 1
mov rdi, r10
mov r10, 0
mov rsi, r10
mov r10, 1
mov rdx, r10
call init_array
mov r10, rax
L3_ret:
mov qword [r12], r10
lea r12, [rbp-40]
mov r10, qword [rbp-8]
add r10, qword [rbp-8]
sub r10, 1
mov rdi, r10
mov r10, 0
mov rsi, r10
mov r10, 1
mov rdx, r10
call init_array
mov r10, rax
L4_ret:
mov qword [r12], r10
push rbp
mov r10, 0
mov rdi, r10
call L6_try
mov r10, rax
L42_ret:
mov rax, r10
jmp L43
L43:
pop r14
pop r13
pop r12
pop rbx
leave
ret 0

L6_try:
push rbp
mov rbp, rsp
sub rsp, 8
push rbx
push r12
mov rbx, rdi
L46:
mov r10, rbp
add r10, 16
mov r10, qword [r10]
cmp rbx, qword [r10-8]
je L39
L40:
mov r12, 0
mov r10, rbp
add r10, 16
mov r10, qword [r10]
mov r10, qword [r10-8]
sub r10, 1
mov qword [rbp-8], r10
L37:
cmp r12, qword [rbp-8]
jle L38
L23:
mov r10, 0
L41:
mov rax, r10
jmp L45
L39:
mov r10, rbp
add r10, 16
mov r10, qword [r10]
push r10
call L5_printboard
mov r10, rax
L22_ret:
jmp L41
L38:
mov r10, r12
add r10, 1
mov r11, qword [rbp+16]
add r11, -16
mov r11, qword [r11]
cmp qword [r11+r10*8], 0
je L26
L27:
mov r10, 0
L28:
cmp r10, 0
jne L31
L32:
mov r10, 0
L33:
cmp r10, 0
jne L35
L36:
lea r12, [r12+1]
jmp L37
L26:
mov r11, 1
mov r10, r12
add r10, rbx
add r10, 1
mov r8, qword [rbp+16]
add r8, -32
mov r8, qword [r8]
cmp qword [r8+r10*8], 0
je L24
L25:
mov r11, 0
L24:
mov r10, r11
jmp L28
L31:
mov r11, 1
mov r10, r12
add r10, 7
sub r10, rbx
add r10, 1
mov r8, qword [rbp+16]
add r8, -40
mov r8, qword [r8]
cmp qword [r8+r10*8], 0
je L29
L30:
mov r11, 0
L29:
mov r10, r11
jmp L33
L35:
mov r10, r12
add r10, 1
mov r11, qword [rbp+16]
add r11, -16
mov r11, qword [r11]
mov qword [r11+r10*8], 1
mov r10, r12
add r10, rbx
add r10, 1
mov r11, qword [rbp+16]
add r11, -32
mov r11, qword [r11]
mov qword [r11+r10*8], 1
mov r10, r12
add r10, 7
sub r10, rbx
add r10, 1
mov r11, qword [rbp+16]
add r11, -40
mov r11, qword [r11]
mov qword [r11+r10*8], 1
mov r10, rbx
add r10, 1
mov r11, qword [rbp+16]
add r11, -24
mov r11, qword [r11]
mov qword [r11+r10*8], r12
mov r10, rbp
add r10, 16
mov r10, qword [r10]
push r10
mov r10, rbx
add r10, 1
mov rdi, r10
call L6_try
mov r10, rax
L34_ret:
mov r10, r12
add r10, 1
mov r11, qword [rbp+16]
add r11, -16
mov r11, qword [r11]
mov qword [r11+r10*8], 0
mov r10, r12
add r10, rbx
add r10, 1
mov r11, qword [rbp+16]
add r11, -32
mov r11, qword [r11]
mov qword [r11+r10*8], 0
mov r10, r12
add r10, 7
sub r10, rbx
add r10, 1
mov r11, qword [rbp+16]
add r11, -40
mov r11, qword [r11]
mov qword [r11+r10*8], 0
jmp L36
L45:
pop r12
pop rbx
leave
ret 8

L5_printboard:
push rbp
mov rbp, rsp
sub rsp, 16
push rbx
push r12
L48:
mov r12, 0
mov r10, rbp
add r10, 16
mov r10, qword [r10]
mov r10, qword [r10-8]
sub r10, 1
mov qword [rbp-8], r10
L19:
cmp r12, qword [rbp-8]
jle L20
L7:
mov r10, L17
mov rdi, r10
call print
mov r10, rax
L21_ret:
mov rax, r10
jmp L47
L20:
mov rbx, 0
mov r10, rbp
add r10, 16
mov r10, qword [r10]
mov r10, qword [r10-8]
sub r10, 1
mov qword [rbp-16], r10
L15:
cmp rbx, qword [rbp-16]
jle L16
L8:
mov r10, L17
mov rdi, r10
call print
mov r10, rax
L18_ret:
lea r12, [r12+1]
jmp L19
L16:
mov r10, r12
add r10, 1
mov r11, qword [rbp+16]
add r11, -24
mov r11, qword [r11]
cmp qword [r11+r10*8], rbx
je L11
L12:
mov r10, L10
L13:
mov rdi, r10
call print
mov r10, rax
L14_ret:
lea rbx, [rbx+1]
jmp L15
L11:
mov r10, L9
jmp L13
L47:
pop r12
pop rbx
leave
ret 8

section .rodata
L9: db " O", 0
L10: db " .", 0
L17: db 0xA, 0
