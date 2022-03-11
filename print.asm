%include "config.s"
%include "macros.mac"

section .text
global _start


;------------------------------------------------
%defstr		ARGSTR	dxobcs%
%strlen		ARGLEN	ARGSTR
;------------------------------------------------

_start:		mov rax, 0x14
		call dectoi
		mov qword [Msg], rdi

		_mpush '&', '1', '2', '9', Msg, test	; TODO cdecl

		call printf

		_mrpop rcx, rcx, rcx, rcx, rcx, rcx

fin:
		mov rax, 0x3c
		xor rdi, rdi
		syscall

section		.data
test:		db "%s%%%c%c%c", 0xa, "gg", 0xa, 0x0
Msg:		db "(.Y.)", 0x0a, 0x0
MsgLen		equ $ - Msg

section		.text

;------------------------------------------------
; printf
;------------------------------------------------
; Entry: rsi - string addr
;	  other args via stack
; Note_: rsi - curr adr in buffer
;
;------------------------------------------------
; TODO buffer(write on overflow) or on newline

printf:		push rbp
		mov rbp, rsp

		mov rsi, [rbp + 16]
		mov rdi, buffer
		
.print_loop:	cmp byte [rsi], 0x0		; \0
		je .print_end
		cmp byte [rsi], '%'		; arg flag
		jne .save
		
		inc rsi
		mov byte bl, [rsi]		; TODO
		call ident_arg
		inc rsi

		jmp .print_loop

.save:		mov byte al, [rsi]		; TODO movsb?
		call buff_ins	
		inc rsi

		jmp .print_loop

.print_end:	pop rbp
		ret
;------------------------------------------------


;------------------------------------------------
; Entry: bl  - char
; 	 rdi - current free addr in buffer
; Destr: rax, rcx, rdx, rdi
; Exit:  rax - free adr in buff, _note: rax = rdi
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

.case_d:	mov rax, [rbp + 16]
		call dectoi

		mov qword [atoi_num_buff], rax
		mov rcx, atoi_num_buff
		jmp .s_loop
		
		jmp .return

.case_x:	mov rax, 2
		jmp .return

.case_o:	mov rax, 3
		jmp .return

.case_b:	mov rax, 4
		jmp .return
; OK
.case_c:	mov byte al, [rbp + 16]
		call buff_ins
		jmp .return

; OK
.case_s:	mov rcx, [rbp + 16]

.s_loop:	mov byte al, [rcx]
		cmp al, 0x0

		je .return
		
		call buff_ins

		inc rcx
		jmp .s_loop
	
; OK
.case_per:	sub rbp, 0x8
		mov al, bl
		call buff_ins

.return:	mov rax, rdi
		ret
;------------------------------------------------

;------------------------------------------------
; Entry: rdi - current free position in buffer
; 	 al  - char to write in buffer
;
; Writes symbol to buffer. If buffer if full or
; newline character detected, buffer will be written
; to console via syscall(1). After writing buffer will
; be cleared
; Exit:	 rax - free pos in buffer(rdi = rax)
;------------------------------------------------
buff_ins:	mov [rdi], al
		inc rdi

		cmp rdi, buffer +  BUFFSIZE - 1	; last always \0
		ja .call_write

		cmp al, 0xa			; if \n
		je .call_write
		
		ret

.call_write:	mov rdx, rdi
		sub rdx, buffer
		call write_buff
		mov rdi, buffer			; now buffer is free
		mov rax, rdi			; TODO
		
		ret
;------------------------------------------------

;------------------------------------------------
; write_buff
;------------------------------------------------
; Entry: edx - buffer size
;_Note:	 rsi = addres of buffer
; Destr: rax
;------------------------------------------------
write_buff:	_mpush rdi, rsi, rcx		; TODO ?
		
		mov rax, 0x01
		mov rdi, 1
		mov rsi, buffer

		syscall

		_mrpop rdi, rsi, rcx

		ret

;------------------------------------------------




;------------------------------------------------
; dectoa
;------------------------------------------------
; Entry: 	rax - number to transform
; algorithm taken from stackexchange.com/questions/142842/integer-to-ascii-algorithm-x86-assembly
;------------------------------------------------
dectoi:		_mpush rbx, rdx, rdi
		mov ebx, 0xCCCCCCCD		; magic number
		xor rdi, rdi

.loop:		mov ecx, eax			

		mul ebx                         ; divide by 10	
		shr edx, 3

		mov eax, edx 	

		lea edx, [edx*4 + edx]          ; multiply by 10
		lea edx, [edx * 2 - '0']	; and prep for sub	
		sub ecx, edx

    		shl rdi, 8                      ; make room for byte
		add rdi, rcx

		cmp rax, 0
		jnz .loop

		mov rax, rdi

		_mrpop rbx, rdx, rdi
		ret



;------------------------------------------------
section		.data
jmp_table:	_jmptbl_addr d, x, o, b, c, s, per
atoi_chars:	db "0123456789ABCDEF"
atoi_num_buff:	resb 64
args:		db ARGSTR, 0xa
buffer:		resb BUFFSIZE
;------------------------------------------------



