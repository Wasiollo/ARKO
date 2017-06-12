section	.text
global  func

;rdi	= src
;rsi	= dst
;rdx	= width
;rcx	= height
;r8		= masksize

func:

	push	r12						;
	push	r13						;
	push	r14						; save registers that C program can use
	push	r15						;
	
	push	rbp
	mov		rbp,	rsp
	
	push	rdi						; src -> stack
	push	rsi						; dst -> stack
	push	rdx						; width -> stack
	push	rcx						; height -> stack
	push	r8						; masksize -> stack
	
	mov		r11,	rdi				; 	
	mov		rdi,	rsi				; changing src and dst becouse of
	mov		rsi,	r11				; troubles with names source, destiny
	
	imul	r10,	rdx,	3		; r10 = 3*width

	imul	rax,	r8,		3		; 3*masksize
	mov		r14,	rax				; r14 = 3*masksize
	
	push	r14						; triple mask size -> stack
	
	mov		rax,	r8				; masksize to rax
	shr		rax,	1				; shift to have half

	push	rax						; half of mask size

	imul	rax,	rdx,	24		;
	add		rax,	31				; some math from net
	shr		rax,	5				;
	shl		rax,	2				; rax = row size

	push	rax						; row size

	mov		r9,		rax				; rowsize
	sub		r9,		r10				; rowsize - 3*widh = padding overflow

	push	r9						; padding overflow -> stack

	mov		r9,		rax				; row size
	imul	r9,		r8				; multiple by mask size
	add		r9,		rsi				; adding to begin of file, so its n lines above the 
									; begining
	sub		r9,		[rsp]			; sub [rsp] = pad ovfl

	mov		r12,	[rsp+16]		; half of masksize
	imul	r12,	6				; multiplaying by 3*2 to have (masksize-1)*3 colors
	add		r12,	r9				; adding to counted r9
	push	r12						; last in row set

	sub		r9,		r10				; sub 3*width
	add		r9,		r14				; add 3*masksize
	mov		r13, 	r9				; last in mask

	mov		r10,	r8				; masksize
	dec		r10						; masksize-1
	imul	r10,	rax				; (masksize-1)*rowsize
	sub		r9,		r10				; counted r9 - counted r10
	mov		r11, 	r9				; last analyzed

	
	mov		r12, rsi				; first analyzed

	push	rsi						; location in first row

	mov		rbx,	[rsp + 32]		; [rsp + 32]=1/2 masksize
	inc		rbx						; (1/2 mask +1
	imul	rbx,	rax				; rbx = (1/2 mask+1)*rowsize
	imul	r9,		[rsp + 32],	3 	; r9 = (1/2 mask)*3 	
	sub		rbx,	r9				; rbx - r9
	sub		rbx,	[rsp + 16]		; rbx - padding
	add		rbx,	rsi				; add begining

	push	rbx						; right border


	imul	rax,	[rsp + 40]		;1/2mask * rowsize
	add		rax,	rsi				;add begining
					
	mov		r15,	rax				;middle row in set

					
	mov		r9,		rsi				;first row in set

	
	push	0x000000				;min BGR - B=0 G=0 R=0

	mov		rcx,	rdx

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;[rsp + 96]		= [src]													;;
;;[rsp + 88]		= [dst]													;;
;;[rsp + 80]		= [width]												;;
;;[rsp + 72]		= [height]												;;
;;[rsp + 64]		= [masksize]											;;
;;[rsp + 56]		= [mask size] * 3 										;;
;;[rsp + 48]		= [mask size] / 2										;;
;;[rsp + 40]		= [row size]											;;
;;[rsp + 32]		= [padding overflow]									;;
;;[rsp + 24]		= [pointer to last in row set]							;;
;;[rsp + 16]		= [pointer to location in first row from the set]		;;
;;[rsp + 8]			= [pointer to right border]								;;
;;[rsp + 2]			= [max R]												;;
;;[rsp + 1]			= [max G]												;;
;;[rsp + 0]			= [max B]												;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;   REGISTERS  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;r15			= [pointer to middle row from set]							;;
;r14 			= [mask size] * 3											;;
;r13 			= [pointer to last in mask]									;;
;r12			= [pointer to first analyzed]								;;
;r11			= [pointer to last analyzed]								;;
;r9				= [pointer to first row from set]							;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin:

	mov		rbx,	[rsp + 48]		; copy [mask size]/2 from stack
	mov		rsi,	r15				; copy [pointer to middle row from set] from stack
	

cBlue:

	lodsb

	cmp		al,		[rsp]			; compare max blue with blue in this pixel
	jbe		cGreen					; if not greater jumpt to green checking

	mov		[rsp],		al			; set this value as max of blue

cGreen:
	lodsb

	cmp		al,		[rsp + 1]
	jbe		cRed					;everything the same as in Blue

	mov		[rsp + 1],	al

cRed:
	lodsb

	cmp		al,		[rsp + 2]		;everything the same as in Blue
	jbe		nextPix

	mov		[rsp + 2],	al

nextPix:
	cmp		rsi,	r11				;compare current pixel and last analyzed	
	jl		cBlue					; if less than check next pixel

	cmp		rsi, 	r13				; compare current pixel and last in mask
	je		nextMask				; if equal nextMask

	mov		rax,		[rsp + 40]	; moving row size to rax

	add		r12,		rax			; adding to first anlyzed row size

	add		r11,		rax			;adding to last analyzed row

	mov		rsi, 		r12			; moving to rsi first analyzed
	
	jmp		cBlue					; jumping to checking

nextMask:

	mov		al,			[rsp]		; moving to al max B
	stosb							; saving al to rdi

	mov		al,			[rsp + 1]	; moving to al max G
	stosb							; saving al to rdi

	mov		al,			[rsp + 2]	; moving to al max R
	stosb							; saving al to rdi

	mov		qword [rsp], 0x000000	;minimal value setting

	mov		rax,		[rsp + 24]	; pointer to last in row set

	cmp		r13, 		rax			; last in mask compare with rowsize
	je		nextRow					; if equal next row

	add		qword [rsp + 16],	3	; adding 3 to both rsp+16 and r13 becouse of next mask
									; which is in the next pixel - 3 colors
	add		qword r13, 	3			; - || - --- - -

	mov		rax,		[rsp + 16]	; moving rsp+16 to rax

	mov		r12,		rax			; moving rax to first analyzed
	mov		rsi,		rax			; moving rax to actually analyzed
	
	add		rax,	r14				; adding masksize*3 to rax 

	mov		r11,	rax				; moving rax to last analyzed

	jmp		cBlue					; jump to checking Blue

nextRow:

	mov		rsi,	[rsp + 8]		; rsi is in the beginining of new line - right border

	add		rdi,	[rsp + 32]		; adding padding to rdi
	
	dec		qword [rsp + 72]		; decrementing height
	jz		end						; if counter of height is zero then end

	mov		rax,		[rsp + 40]	; moving rowsize to rax
	add		r9,	rax					; adding rowsize to r9 - first row from set
	add		r15,	 rax			; adding rowsize to r15
	add		[rsp + 8],	rax			; adding rowsize to rightborder
	add		[rsp + 24],	rax			; adding rowsize to last in row

	mov		rax,		r9			; rax = first row from set
	mov		[rsp + 16],	rax			

	mov 	r12,		rax			; first analyzed = first row from set
	mov		rsi,		rax			; rsi = -||-

	add		rax,	r14				; adding masksize *3 to rax

	mov		r11, rax				; moving to pointer to last analyzed rax

	mov		rbx,		[rsp + 64]	; masksize
	dec		rbx						; masksize - 1
	imul	rbx,		[rsp + 40]	; rbx = rbx * rowsize
	add		rax,		rbx			; add rbx to rax


	mov		r13, rax				; moving rax to last in mask
	jmp		begin					; jump to begin

end:
	add		rsp,	104				; returning stack to begining
	pop		rbp

	pop		r15
	pop		r14		 				; restore registers that C program can use
	pop		r13
	pop		r12


	mov		rax,	0

	ret
