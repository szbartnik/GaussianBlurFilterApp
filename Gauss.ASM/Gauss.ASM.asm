.686 
.387
.model flat, stdcall 
option casemap :none
.xmm

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib

.data

rowPadded  dd ?
gaussHalf  dd ?
gaussMask  dd 25 dup(0)

.code

PARAMS STRUCT
	maskSize      DWORD  ?
	imgOffset     DWORD  ?
	blurLvl       DWORD  ?
	imgWidth      DWORD  ?
	imgHeight     DWORD  ?
	imgPartId     DWORD  ?
	imgPartsCount DWORD  ?
	imgPtr        BYTE PTR  ?
PARAMS ENDS

; Computes specified pascal triangle row (max 24)
ComputePascalRow proc x:DWORD
	local counter:DWORD

	; Setting iterator to the initial value
	mov     counter, 1

	; Setting the first element
	mov     gaussMask, 1

	jmp @startOfFirstLoop
	@firstGaussIteration:
	; Checking iterate conditions
	mov     eax, counter
	inc     eax
	mov     counter, eax
	mov     eax, x

	;;;;;;;;;;;;;;;;;;
	;;; First loop ;;;
	@startOfFirstLoop:
	cdq
	sub     eax, edx
	sar     eax, 1
	cmp     counter, eax
	jg      @startOfSecondLoop

	; n - i + 1
	mov     eax, x
	sub     eax, counter
	inc     eax

	; row[i - 1] * (n - i + 1)
	mov     ecx, counter
	imul    eax, gaussMask [ecx*4-4]

	; row[i - 1] * (n - i + 1) / i
	cdq
	idiv    counter

	; row[i] = row[i - 1] * (n - i + 1) / i;
	mov     gaussMask [ecx*4], eax

	jmp @firstGaussIteration

	;;;;;;;;;;;;;;;;;;;
	;;; Second loop ;;;
	@secondGaussIteration:

	mov     eax, counter
	inc     eax
	mov     counter, eax

	@startOfSecondLoop:
	mov     eax, x
	cmp     counter, eax
	jge     @endOfSecondGaussIteration

	; row[i] = row[n - i];
	sub     eax, counter ; n-i
	dec     eax
	mov     ecx, gaussMask [eax*4]
	mov     eax, counter
	mov     gaussMask [eax*4], ecx

	jmp @secondGaussIteration

	@endOfSecondGaussIteration:
	ret

ComputePascalRow endp

Malloc proc nSize:dword
	
	add nSize, 4
	invoke GlobalAlloc, GPTR, nSize
	ret

Malloc endp

GlSize proc pointer:dword
	
	invoke GlobalSize, pointer
	ret

GlSize endp

;;;;;;;;;;;;
;;; Main ;;;
ComputeGaussBlur proc args:PARAMS

	; Compute rowPadded
	mov     eax, args.imgWidth
	imul    eax, 3
	add     eax, 3
	and     eax, 0FFFFFFFCh
	mov     rowPadded, eax

	; Compute half of gauss mask
	mov     eax, args.maskSize
	cdq
	sub     eax, edx
	sar     eax, 1
	mov     gaussHalf, eax

	; Compute Pascal row
	invoke  ComputePascalRow, args.maskSize



ret

ComputeGaussBlur endp 

end 