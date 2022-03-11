%include "config.s"
%include "macros.mac"

section .text
global _start


;------------------------------------------------
%defstr		ARGSTR	dxobcs%
%strlen		ARGLEN	ARGSTR
;------------------------------------------------

_start:		_mrpush '1', '2', '3'
		push Msg

		mov rdi, test
		call printf
		_mrpop rcx, rcx, rcx

		mov rax, 0x01
		mov rdi, 1
		mov rsi, buffer
		mov edx, BUFFSIZE
		syscall
fin:
		mov rax, 0x3c
		xor rdi, rdi
		syscall

section		.data
test:		db "%s_%c_%c_%c_%%", 0xa
Msg:		db "%sO%o%.fgf", 0x0a
MsgLen		equ $ - Msg

section		.text

;------------------------------------------------
; printf
;------------------------------------------------
; Entry: rdi - string addr
;	  other args via stack
; Note_: rsi - curr adr in buffer
;
;------------------------------------------------
; TODO buffer(write on overflow) or on newline

printf:		push rbp
		mov rbp, rsp

		mov rsi, buffer
		
.print_loop:	cmp byte [rdi], 0xa		; \0
		je .print_end
		cmp byte [rdi], '%'		; arg flag
		jne .save
		
		inc rdi
		mov byte bl, [rdi]		; TODO
		call ident_arg
		inc rdi

		jmp .print_loop

.save:		mov byte al, [rdi]		; TODO movsb?
		mov byte [rsi], al
		inc rsi
		inc rdi

		jmp .print_loop

.print_end:	pop rbp
		ret
;------------------------------------------------


;------------------------------------------------
; Entry: bl  - char
; 	 rsi - current free addr in buffer
; Destr: rax, rcx, rdx
;	 rsi(changed to next free adr in buff)
;------------------------------------------------
ident_arg:	mov rcx, ARGLEN - 1

.ident_loop:	cmp byte bl, args[rcx]
		je .switch
		loop .ident_loop

		; default: dont do anything

		ret

.switch		add rbp, 0x8

		mov rcx, qword jmp_table[0 + rcx * 8]
		jmp rcx

.case_d:	mov rax, 1
		ret

.case_x:	mov rax, 2
		ret

.case_o:	mov rax, 3
		ret

.case_b:	mov rax, 4
		ret
; OK
.case_c:	mov byte al, [rbp + 8]
		mov byte [rsi], al
		inc rsi
		ret
; OK
.case_s:	mov rdx, [rbp + 8]

.s_loop:	mov byte al, [rdx]
		cmp al, 0xa

		je .s_loop_end
		
		mov byte [rsi], al
		inc rsi
		inc rdx
		jmp .s_loop

.s_loop_end:	ret
; OK
.case_per:	mov byte [rsi], bl
		inc rsi
		ret
;------------------------------------------------

;------------------------------------------------
section		.data
;jmp_table:	dq ident_arg.case_d, ident_arg.case_x,\
;		   ident_arg.case_o, ident_arg.case_b,\
;		   ident_arg.case_c, ident_arg.case_s,\
;		   ident_arg.case_per

jmp_table:	_jmptbl_addr d, x, o, b, c, s, per
args:		db ARGSTR, 0xa
buffer:		resb BUFFSIZE
;------------------------------------------------
