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

rowPadded      dd ?
rowPaddedDiff  dd ?
gaussHalf      dd ?
gaussSum       dd ?
gaussMask      dd 25 dup(0)
tempImg        dd ?

align 16
testXMM        db 16 DUP(255)

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

	LOCAL maxY         : DWORD
	LOCAL currY        : DWORD
	LOCAL x            : DWORD
	LOCAL y            : DWORD
	LOCAL k            : DWORD
	
	; Mask load
	lea     ecx, gaussMask ; ecx stores mask pointer

	; Compute maxY
	mov     eax, args.imgHeight
	sub     eax, args.maskSize
	inc     eax
	mov     maxY, eax
	
	; Compute imgOffset
	mov     ebx, args.imgPtr
	add     ebx, args.imgOffset
	mov     imgOffset, ebx

	xor     eax, eax
	mov     edi, eax          ; edi stores currPosition
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
				mov     ebx, eax ; ebx stores offset2

				; Zero results register
				psubd   XMM3, XMM3

				@kLoopInitialization:
					xor     eax, eax
					mov     k, eax

				@kLoopStart:
					; Check k iterate conditions
					cmp     eax, args.maskSize
					jge     @kLoopEnd

					; ########## Actions of k loop begins ##########

					; Offsets init part
					movd      XMM1, dword ptr [ebx]
					punpcklbw XMM1, XMM0
					punpcklwd XMM1, XMM0

					; Mask init part
					movd      XMM2, dword ptr [ecx][eax*4] ; k in eax
					shufps    XMM2, XMM2, 0h

					pmullw    XMM1, XMM2 ; Multiply

					paddw     XMM3, XMM1 ; linc +=

					add     ebx, rowPadded
				
					; ########## Actions of k loop ends #########
					; Increment k counter
					mov     eax, k
					inc     eax
					mov     k, eax
					jmp     @kLoopStart	

				@kLoopEnd:

				mov     ebx, tempImg ; ebx now stores tempImg ptr

				; save b pixel
				pextrw  eax, XMM3, 0
				cwd
				cdq
				idiv    gaussSum
				mov     byte ptr [ebx][edi], al
				inc     edi

				; save g pixel
				pextrw  eax, XMM3, 2
				cwd
				cdq
				idiv    gaussSum
				mov     byte ptr [ebx][edi], al
				inc     edi

				; save r pixel
				pextrw  eax, XMM3, 4
				cwd
				cdq
				idiv    gaussSum
				mov     byte ptr [ebx][edi], al
				inc     edi


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
				mov     ebx, eax ; ebx stores offset2
				
				xor     eax, eax
				mov     x, eax

			@x2LoopStart:
				; Check x iterate conditions
				cmp     eax, args.imgWidth
				jge     @x2LoopEnd

				; ########## Actions of x loop begins ##########

				mov     edx, tempImg

				; save b pixel
				mov     al, byte ptr [ebx]
				mov     byte ptr [edx][edi], al
				inc     edi

				; save g pixel
				mov     al, byte ptr [ebx][1]
				mov     byte ptr [edx][edi], al
				inc     edi

				; save r pixel
				mov     al, byte ptr [ebx][2]
				mov     byte ptr [edx][edi], al
				inc     edi

				add     ebx, 3

				; ########## Actions of x loop ends #########
				; Increment x counter
				mov     eax, x
				inc     eax
				mov     x, eax
				jmp     @x2LoopStart

			@x2LoopEnd:
		.endif

		add     edi, rowPaddedDiff
	
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

	LOCAL beginCopy    : DWORD
	LOCAL endCopy      : DWORD

	LOCAL imgOffset    : DWORD
	LOCAL offset1      : DWORD

	LOCAL maxX         : DWORD
	LOCAL x            : DWORD
	LOCAL y            : DWORD
	LOCAL k            : DWORD

	; Compute imgOffset
	mov     ebx, args.imgPtr
	add     ebx, args.imgOffset
	mov     imgOffset, ebx

	; Compute maxX
	mov     eax, args.imgWidth
	sub     eax, args.maskSize
	inc     eax
	mov     maxX, eax

	xor     eax, eax
	mov     beginCopy, eax    ; init beginCopy
	mov     edi, eax          ; edi stores currPosition

	mov     ecx, args.imgHeight   ; ecx stores endCopy
	mov     endCopy, ecx          ; init endCopy

	.if args.imgPartId != 0
		
		; beginCopy = gaussHalf
		mov    eax, gaussHalf
		mov    beginCopy, eax

		; imgOffset += rowPadded * gaussHalf
		imul   eax, rowPadded
		add    ebx, eax    ; ebx stores imgOffset
		mov    imgOffset, ebx

	.endif

	mov     eax, args.imgPartsCount
	dec     eax

	.if args.imgPartId != eax
		
		sub ecx, gaussHalf
		mov endCopy, ecx

	.endif

	; Mask load
	lea     ecx, gaussMask  ; ecx stores mask pointer


	@yLoopInitialization:
		mov     eax, beginCopy
		mov     y, eax
	@yLoopStart:
		; Check y iterate conditions
		cmp     eax, endCopy
		jge     @yLoopEnd

		; ########## Actions of y loop begins ##########

		; Compute offset1
		imul    eax, rowPadded ; eax = y * rowPadded
		add     eax, tempImg   ; eax = tempImg + y * rowPadded
		mov     ebx, gaussHalf ; ebx = gaussHalf
		imul    ebx, 3         ; ebx = gaussHalf * 3
		sub     eax, ebx       ; eax -= ebx
		mov     offset1, eax   ; offset1 = tempImg + rowPadded * y - gaussHalf * 3;

		@x1LoopInitialization:
				xor     eax, eax
				mov     x, eax

		@x1LoopStart:
				; Check x iterate conditions
				cmp     eax, args.imgWidth
				jge     @x1LoopEnd

				; ########## Actions of x loop begins ##########

				; Compute currX
				mov     esi, eax
				sub     esi, gaussHalf ; esi stores currX

				; Compute offset2
				imul    eax, 3
				add     eax, offset1
				mov     ebx, eax ; ebx stores offset2

				; Zero results register
				psubd   XMM3, XMM3

				.if esi >= 0 && esi < maxX
					
					@kLoopInitialization:
						xor     eax, eax
						mov     k, eax

					@kLoopStart:
						; Check k iterate conditions
						cmp     eax, args.maskSize
						jge     @kLoopEnd

						; ########## Actions of k loop begins ##########

						; Offsets init part
						movd      XMM1, dword ptr [ebx]
						punpcklbw XMM1, XMM0
						punpcklwd XMM1, XMM0

						; Mask init part
						movd      XMM2, dword ptr [ecx][eax*4] ; k in eax
						shufps    XMM2, XMM2, 0h

						pmullw    XMM1, XMM2 ; Multiply

						paddw     XMM3, XMM1 ; linc +=

						add     ebx, 3
				
						; ########## Actions of k loop ends #########
						; Increment k counter
						mov     eax, k
						inc     eax
						mov     k, eax
						jmp     @kLoopStart	

					@kLoopEnd:

					mov     esi, imgOffset ; esi now stores imgOffset

					; save b pixel
					pextrw  eax, XMM3, 0
					cwd
					cdq
					idiv    gaussSum
					mov     byte ptr [esi][edi], al
					inc     edi

					; save g pixel
					pextrw  eax, XMM3, 2
					cwd
					cdq
					idiv    gaussSum
					mov     byte ptr [esi][edi], al
					inc     edi

					; save r pixel
					pextrw  eax, XMM3, 4
					cwd
					cdq
					idiv    gaussSum
					mov     byte ptr [esi][edi], al
					inc     edi

				.else
					
					; offset2 += gaussHalf * 3
					mov     eax, gaussHalf
					imul    eax, 3
					add     ebx, eax

					mov     edx, imgOffset

					; save b pixel
					mov     al, byte ptr [ebx]
					mov     byte ptr [edx][edi], al
					inc     edi

					; save g pixel
					mov     al, byte ptr [ebx][1]
					mov     byte ptr [edx][edi], al
					inc     edi

					; save r pixel
					mov     al, byte ptr [ebx][2]
					mov     byte ptr [edx][edi], al
					inc     edi

					add     ebx, 3

				.endif

				; ########## Actions of x loop ends #########
				; Increment x counter
				mov     eax, x
				inc     eax
				mov     x, eax
				jmp     @x1LoopStart

			@x1LoopEnd:

			add     edi, rowPaddedDiff

		; ########## Actions of y loop ends ##########
		; Increment y counter
		mov     eax, y
		inc     eax
		mov     y, eax
		jmp     @yLoopStart

	@yLoopEnd:
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

	; Compute rowPaddedDiff
	mov     eax, rowPadded
	mov     ebx, args.imgWidth
	imul    ebx, 3
	sub     eax, ebx
	mov     rowPaddedDiff, eax

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