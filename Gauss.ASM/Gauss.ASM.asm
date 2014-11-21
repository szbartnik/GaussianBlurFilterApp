.686 
.387
.model flat, stdcall 
option casemap :none
.xmm

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\macros\macros.asm
includelib \masm32\lib\kernel32.lib

.data

rowPadded  dd ?
gaussHalf  dd ?
gaussSum   dd ?
gaussMask  dd 25 dup(0)
tempImg    dd ?

two       dq 2
three     dq 3

.code

PARAMS STRUCT
	maskSize      DWORD  ?
	imgOffset     DWORD  ?
	blurLvl       DWORD  ?
	imgWidth      DWORD  ?
	imgHeight     DWORD  ?
	imgPartId     DWORD  ?
	imgPartsCount DWORD  ?
	imgPtr        DWORD  ?
PARAMS ENDS

ComputeGaussMaskSum proc maskSize:DWORD

	LOCAL counter:DWORD

	xor         eax, eax
	mov         gaussSum, eax  
	mov         counter, eax  
	jmp         @loopInit

	@loopBegin:
	mov         eax, counter 
	inc         eax
	mov         counter, eax  

	@loopInit:
	mov         eax, counter  
	cmp         eax, maskSize
	jge         @loopEnd 
	mov         eax, counter  
	mov         edx, gaussSum 
	add         edx, gaussMask [eax*4]  
	mov         gaussSum, edx  
	jmp         @loopBegin

	@loopEnd:
	ret

ComputeGaussMaskSum endp

FirstIteration proc args:PARAMS
	
	LOCAL imgOffset    : DWORD
	LOCAL offset1      : DWORD
	LOCAL offset2      : DWORD

	LOCAL currPosition : DWORD
	LOCAL maxY         : DWORD
	LOCAL currY        : DWORD
	LOCAL x            : DWORD
	LOCAL y            : DWORD
	LOCAL k            : DWORD
	
	; Compute maxY
	mov     eax, args.imgHeight
	sub     eax, args.maskSize
	inc     eax
	mov     maxY, eax
	
	; Compute imgOffset
	mov     eax, args.imgPtr
	add     eax, args.imgOffset
	mov     imgOffset, eax

	xor     eax, eax
	mov     currPosition, eax ; Initialize currPosition
	mov     y, eax            ; Initialize y loop iterator variable

	@yLoopStart:
		; Check y iterate conditions
		cmp     eax, args.imgHeight
		jge     @yLoopEnd

		; ########## Actions of y loop begins ##########
		; Compute currY
		sub     eax, gaussHalf
		mov     currY, eax
		
		; Compute offset1
		imul    eax, rowPadded
		add     eax, imgOffset
		mov     offset1, eax

		mov     eax, currY

		.if eax >= 0 && eax < maxY
			@x1LoopInitialization:
				xor     eax, eax
				mov     x, eax

			@x1LoopStart:
				; Check x iterate conditions
				cmp     eax, args.imgWidth
				jge     @x1LoopEnd

				; ########## Actions of x loop begins ##########
			
				; Compute offset2
				imul    eax, 3
				add     eax, offset1
				mov     offset2, eax

				; Zero xmm registers
				movsd xmm0, [three]
				movsd xmm1, [two]

				subsd xmm0, xmm1

				movsd three, xmm0
				
				; ########## Actions of x loop ends #########
				; Increment x counter
				mov     eax, x
				inc     eax
				mov     x, eax
				jmp     @x1LoopStart

			@x1LoopEnd:
		.else
			@x2LoopInitialization:
				; Compute offset2
				mov     eax, gaussHalf
				imul    eax, rowPadded
				add     eax, offset1
				mov     offset2, eax
				
				xor     eax, eax
				mov     x, eax

			@x2LoopStart:
				; Check x iterate conditions
				cmp     eax, args.imgWidth
				jge     @x2LoopEnd

				; ########## Actions of x loop begins ##########
				
				; ########## Actions of x loop ends #########
				; Increment x counter
				mov     eax, x
				inc     eax
				mov     x, eax
				jmp     @x2LoopStart

			@x2LoopEnd:
		.endif
	
		; ########## Actions of y loop ends ##########
		; Increment y counter
		mov     eax, y
		inc     eax
		mov     y, eax
		jmp     @yLoopStart

	@yLoopEnd:
		ret

FirstIteration endp

SecondIteration proc args:PARAMS

	ret

SecondIteration endp

; Computes specified pascal triangle row (max 24)
ComputePascalRow proc maskSize:DWORD

	LOCAL counter:DWORD

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
		mov     eax, maskSize

		;;;;;;;;;;;;;;;;;;
		;;; First loop ;;;
	@startOfFirstLoop:
		cdq
		sub     eax, edx
		sar     eax, 1
		cmp     counter, eax
		jg      @startOfSecondLoop

		; n - i + 1
		mov     eax, maskSize
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
		mov     eax, maskSize
		cmp     counter, eax
		jg      @endOfSecondGaussIteration

		; row[i] = row[n - i];
		sub     eax, counter ; n-i
		mov     ecx, gaussMask [eax*4]
		mov     eax, counter
		mov     gaussMask [eax*4], ecx

		jmp @secondGaussIteration

	@endOfSecondGaussIteration:
		ret

ComputePascalRow endp

;;;;;;;;;;;;
;;; Main ;;;
ComputeGaussBlur proc args:PARAMS

	; Compute rowPadded
	mov     eax, args.imgWidth
	imul    eax, 3
	add     eax, 3
	and     eax, 0FFFFFFFCh
	mov     rowPadded, eax

	; Allocate memory for temporary image array
	mov     ebx, args.imgHeight
	imul    ebx, eax
	mov     tempImg, alloc(ebx)

	; Compute half of gauss mask
	mov     eax, args.maskSize
	cdq
	sub     eax, edx
	sar     eax, 1
	mov     gaussHalf, eax

	; Compute Pascal row
	mov     eax, args.maskSize
	dec     eax
	invoke  ComputePascalRow, eax

	; Compute Gauss mask sum
	invoke ComputeGaussMaskSum, args.maskSize

	invoke FirstIteration, args
	invoke SecondIteration, args

	; Free the memory 
	free(tempImg)

	ret

ComputeGaussBlur endp 

end 