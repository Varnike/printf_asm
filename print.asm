%include "config.s"
%include "macros.mac"

section .text
global _start


;------------------------------------------------
%defstr		ARGSTR	dxobcs%
%strlen		ARGLEN	ARGSTR
;------------------------------------------------

		global Print

section		.text

Print:		pop r11				; save ret addr to r15
		_mpush r9, r8, rcx, rdx, rsi, rdi

		call __printf

		_mrpop r9, r8, rcx, rdx, rsi, rdi

		push r11			; restore ret addr
		ret
;------------------------------------------------



;------------------------------------------------
; printf
;------------------------------------------------
; Entry: rsi - string addr
;	  other args via stack
; Note_: rsi - curr adr in buffer
;
;------------------------------------------------

__printf:	push rbp
		mov rbp, rsp

		_mpush rbx, r12, r13, r14, r15

		mov rsi, [rbp + 16]
		mov rdi, buffer
		
.print_loop:	cmp byte [rsi], 0x0		; \0
		je .print_end
		cmp byte [rsi], '%'		; arg flag
		jne .save
		
		inc rsi
		mov byte bl, [rsi]
		call ident_arg
		inc rsi

		jmp .print_loop

.save:		mov byte al, [rsi]
		call buff_ins	
		inc rsi

		jmp .print_loop

.print_end:	_mrpop rbx, r12, r13, r14, r15

		pop rbp
		ret
;------------------------------------------------

%macro		_two_sys_write 3
		_mpush %1, %2, %3
		mov rcx, [rbp + 16]
		push rcx

		call atoi

		_mrpop r8, r8, r8, r8

		mov rcx, atoi_num_buff
		
		call str_write

		jmp .return
%endmacro

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
		
		cmp byte bl, args[rcx]
		je .switch

		; default: dont do anything

		ret

.switch		add rbp, 0x8

		mov rcx, qword jmp_table[0 + rcx * 8]
		jmp rcx

.case_d:	mov rax, [rbp + 16]
		call dectoi

		mov qword [atoi_num_buff], rax
		mov byte atoi_num_buff[8], 0x0
		mov rcx, atoi_num_buff

		call str_write
		jmp .return

.case_x:	_two_sys_write atoi_num_buff, 8, 0x10

.case_o:	_two_sys_write atoi_num_buff, 11, 0x8

.case_b:	_two_sys_write atoi_num_buff, 32, 0x2
; OK
.case_c:	mov byte al, [rbp + 16]
		call buff_ins
		jmp .return

; OK
.case_s:	mov rcx, [rbp + 16]

		call str_write
		jmp .return
; OK
.case_per:	sub rbp, 0x8
		mov al, bl
		call buff_ins

.return:	mov rax, rdi
		ret
;------------------------------------------------



;------------------------------------------------
; str_write
;------------------------------------------------
; Entry: rcx - address of null-terminated string
;------------------------------------------------
str_write:	mov byte al, [rcx]
		cmp al, 0x0

		je .return
		
		call buff_ins

		inc rcx
		jmp str_write

.return:	ret
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
		mov rax, rdi
		
		ret
;------------------------------------------------

;------------------------------------------------
; write_buff
;------------------------------------------------
; Entry: edx - buffer size
;_Note:	 rsi = addres of buffer
; Destr: rax
;------------------------------------------------
write_buff:	_mpush rdi, rsi, rcx
		
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


;------------------------------------------------
; atoi
;------------------------------------------------
; Entry:	%1 - number to transorm
;		%2 - bit depth of system(2\8\16)
;		%3 - number of chars to write, also 0x0
;		     will be added
;		%4 - array to write
;------------------------------------------------
atoi:		push rbp
		mov rbp, rsp

		_mpush rdi, rsi, rax, rcx

		mov r8,  [rbp + 16]		; num
		mov r10, [rbp + 24]		; bit mask
		mov rcx, [rbp + 32]		; number of chars
		mov rdi, [rbp + 40]		; array addr

		add rdi, rcx			; end of str
		mov byte [rdi], 0x0		; and 0x0 to end
		dec rdi

		dec r10				; set bit mask

		mov r9, r8

.convert:	and r9, r10
		
		mov al, atoi_chars[r9]
		mov byte [rdi], al
		dec rdi

		mov r9, r8
		
		cmp r10, 0x7
		ja .hex
		jb .bin

		shr r9, 3
		jmp .cont
			
.hex:		shr r9, 4
		jmp .cont

.bin:		shr r9, 1

.cont:		mov r8, r9
		loop .convert
		
.loop_end:	_mrpop rdi, rsi, rax, rcx

		pop rbp
		ret
;------------------------------------------------


;------------------------------------------------
section		.data
jmp_table:	_jmptbl_addr d, x, o, b, c, s, per
atoi_chars:	db "0123456789ABCDEF"
atoi_num_buff:	db 65 dup('*')
args:		db ARGSTR, 0xa
buffer:		resb BUFFSIZE
;------------------------------------------------
