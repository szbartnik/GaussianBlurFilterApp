.686 
.387
.model flat, stdcall 
option casemap :none
.xmm

.code

; ==============================================================
; Structure representing thread parameters structure
; used to store & pass information about thread and calculated
; bitmap settings to the ComputeGaussBlur method.
; ==============================================================
PARAMS STRUCT
    processId     DWORD  ? ; Id of the current process (for debugging)
    maskSize      DWORD  ? ; Gauss mask size (width)
    imgOffset     DWORD  ? ; Offset relative to the bitmap pixels data start (bytes)
    imgWidth      DWORD  ? ; Width of the bitmap in pixels
    imgHeight     DWORD  ? ; Height of the bitmap in pixels
    imgPartId     DWORD  ? ; Number of part of the bitmap passed to the current thread
    imgPartsCount DWORD  ? ; Total number of bitmap parts (number of threads)
    imgPtr        DWORD  ? ; Pointer to the beginning of bitmap pixels data section
    tempImgPtr    DWORD  ? ; Pointer to the beginning of the temporary bimap 
PARAMS ends

; ==================================================
; Computes gauss mask sum
; Adds every gauss mask array item together
; Result in eax
;
; ### PARAMS ###
; - maskSize (DWORD): size of passed gauss mask ptr
; - gaussMask (DWORD PTR): gauss mask pointer
; ==================================================
ComputeGaussMaskSum proc maskSize:DWORD, gaussMask: PTR DWORD

    LOCAL counter  :DWORD ; Counter of the loop iterating over gaussMask
    LOCAL gaussSum :DWORD ; Gauss sum to store output gaussMask sum

    mov     ebx, gaussMask

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
    add         edx, [ebx+eax*4]  ; Ebx stores gaussMask pointer
    mov         gaussSum, edx  
    jmp         @loopBegin

    @loopEnd:
    mov         eax, gaussSum
    ret

ComputeGaussMaskSum endp
; ¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤


; ==========================================================================
; First iteration of the gauss blur algorithm. This part iterates over
; surrounding lines vertically (averages up/down pixels of every pixel)
;
; ### PARAMS ###
; - args (PARAMS): Current thread parameters structure
; - tempImg (DWORD): Temporary bitmap array pointer used to store partial result
; - rowPadded (DWORD): The pixel array must begin at a memory address 
;                      that is a multiple of 4 bytes
; - rowPaddedDiff (DWORD): Difference between rowPadded and real row width
; - gaussHalf (DWORD): Half of gauss mask
; - gaussSum (DWORD): Gauss mask sum
; - gaussMask (DWORD): Gauss mask pointer
; ==========================================================================
FirstIteration proc args     :PARAMS,
                tempImg      :DWORD,
                rowPadded    :DWORD,
                rowPaddedDiff:DWORD,
                gaussHalf    :DWORD,
                gaussSum     :DWORD,
                gaussMask    :PTR DWORD 

    
    LOCAL imgOffset    : DWORD          ; Stores current thread bitmap part offset
    LOCAL offset1      : DWORD          ; Stores offset to the current line of source bitmap 

    LOCAL maxY         : DWORD          ; Stores maximum y position that can be averaged (height - gaussWidth + 1)
    LOCAL currY        : DWORD          ; Stores current y position reduced by half of gauss mask
    LOCAL x            : DWORD          ; Current bitmap pixel X position
    LOCAL y            : DWORD          ; Current bitmap pixel Y position
    LOCAL k            : DWORD          ; Current gauss mask position
    
    ; Mask load
    mov     eax, gaussMask
    mov     ecx, eax          ; Ecx stores mask pointer

    ; Compute maxY
    mov     eax, args.imgHeight
    sub     eax, args.maskSize
    inc     eax
    mov     maxY, eax
    
    ; Compute imgOffset
    mov     esi, args.imgPtr
    add     esi, args.imgOffset
    mov     imgOffset, esi

    xor     eax, eax
    mov     edi, eax          ; Edi stores currPosition
    mov     y, eax            ; Initialize y loop iterator variable

    @yLoopStart:
        ; Check y iterate conditions
        cmp     eax, args.imgHeight
        jge     @yLoopEnd

        ; ########## Actions of y loop begin ##########
        ; Compute currY
        sub     eax, gaussHalf
        mov     currY, eax
        
        ; Compute offset1
        imul    eax, rowPadded
        add     eax, imgOffset
        mov     offset1, eax

        mov     eax, currY

        ; --------------------------------------------------------- 
        ; If |current line - gaussHalf| is in bounds of data array
        ; (edges of the bitmap)
        ; ---------------------------------------------------------
        .if eax > 0 && eax < maxY
            @x1LoopInitialization:
                xor     eax, eax
                mov     x, eax

            @x1LoopStart:
                ; Check x iterate conditions
                cmp     eax, args.imgWidth
                jge     @x1LoopEnd

                ; ########## Actions of x loop begin ##########
            
                ; Compute offset2
                imul    eax, 3
                add     eax, offset1
                mov     esi, eax ; Esi stores offset2

                ; Zero results register
                psubd   XMM3, XMM3
                
                @kLoopInitialization:
                    xor     eax, eax
                    mov     k, eax

                @kLoopStart:
                    ; Check k iterate conditions
                    cmp     eax, args.maskSize
                    jge     @kLoopEnd

                    ; ########## Actions of k loop begin ##########

                    ; Offsets init part
                    movd      XMM1, dword ptr [esi]        ; Move 4 bytes (3 used) to the XMM1
                    punpcklbw XMM1, XMM0                   ; XMM1: ...00 rr gg bb         -> ...0000 00rr 00gg 00bb 
                    punpcklwd XMM1, XMM0                   ; XMM1: ...0000 00rr 00gg 00bb -> 00000000 000000rr 000000gg 000000bb

                    ; Mask init part
                    movd      XMM2, dword ptr [ecx][eax*4] ; Move mask for the current pixel to XMM2
                    shufps    XMM2, XMM2, 0h               ; Broadcast least significant element to all elements 

                    pmullw    XMM1, XMM2                   ; Multiply offset2[0,1,2] * mask[k]
                    paddw     XMM3, XMM1                   ; Linc[b,g,r] += offset2[0,1,2] * mask[k]

                    add     esi, rowPadded
                
                    ; ########## Actions of k loop end #########
                    ; Increment k counter
                    mov     eax, k
                    inc     eax
                    mov     k, eax
                    jmp     @kLoopStart	

                @kLoopEnd:

                mov     esi, tempImg ; Esi now stores tempImg ptr

                ; Save b pixel
                pextrw  eax, XMM3, 0             ; Extract blue factor
                cwd                              ; Convert to double
                cdq                              ; Convert to quad
                div    gaussSum                  ; Divide by the sum of gauss mask factors
                mov     byte ptr [esi][edi], al  ; Save in temporary array
                inc     edi                      ; Move to the next pixel of the temp array

                ; Save g pixel
                pextrw  eax, XMM3, 2             ; Extract green factor
                cwd                              ; Convert to double
                cdq                              ; Convert to quad
                div    gaussSum                  ; Divide by the sum of gauss mask factors
                mov     byte ptr [esi][edi], al  ; Save in temporary array
                inc     edi                      ; Move to the next pixel of the temp array

                ; Save r pixel 
                pextrw  eax, XMM3, 4             ; Extract red factor
                cwd                              ; Convert to double
                cdq                              ; Convert to quad
                div    gaussSum                  ; Divide by the sum of gauss mask factors
                mov     byte ptr [esi][edi], al  ; Save in temporary array
                inc     edi                      ; Move to the next pixel of the temp array


                ; ########## Actions of x loop end #########
                ; Increment x counter
                mov     eax, x
                inc     eax
                mov     x, eax
                jmp     @x1LoopStart

            @x1LoopEnd:
            
        ; ------------------------------------------------------------- 
        ; If |current line - gaussHalf| is not in bounds of data array
        ; (edges of the bitmap)
        ; -------------------------------------------------------------
        .else
            @x2LoopInitialization:
                ; Compute offset2
                mov     eax, gaussHalf
                imul    eax, rowPadded
                add     eax, offset1
                mov     esi, eax ; esi stores offset2
                
                xor     eax, eax
                mov     x, eax

            @x2LoopStart:
                ; Check x iterate conditions
                cmp     eax, args.imgWidth
                jge     @x2LoopEnd

                ; ########## Actions of x loop begin ##########

                mov     ebx, tempImg

                ; Save b pixel
                mov     al, byte ptr [esi]
                mov     byte ptr [ebx][edi], al
                inc     edi

                ; Save g pixel
                mov     al, byte ptr [esi][1]
                mov     byte ptr [ebx][edi], al
                inc     edi

                ; Save r pixel
                mov     al, byte ptr [esi][2]
                mov     byte ptr [ebx][edi], al
                inc     edi

                add     esi, 3

                ; ########## Actions of x loop end #########
                ; Increment x counter
                mov     eax, x
                inc     eax
                mov     x, eax
                jmp     @x2LoopStart

            @x2LoopEnd:
        .endif

        add     edi, rowPaddedDiff
    
        ; ########## Actions of y loop end ##########
        ; Increment y counter
        mov     eax, y
        inc     eax
        mov     y, eax
        jmp     @yLoopStart

    @yLoopEnd:
        ret

FirstIteration endp
; ¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤

; ==========================================================================
; Second iteration of the gauss blur algorithm. This part iterates over
; surrounding lines horizontally (averages left/right pixels of every pixel)
;
; ### PARAMS ###
; - args (PARAMS): Current thread parameters structure
; - tempImg (DWORD): Temporary bitmap array pointer used to store partial result
; - rowPadded (DWORD): The pixel array must begin at a memory address 
;                      that is a multiple of 4 bytes
; - rowPaddedDiff (DWORD): Difference between rowPadded and real row width
; - gaussHalf (DWORD): Half of gauss mask
; - gaussSum (DWORD): Gauss mask sum
; - gaussMask (DWORD): Gauss mask pointer
; ==========================================================================
SecondIteration proc args     :PARAMS, 
                 tempImg      :DWORD,
                 rowPadded    :DWORD,
                 rowPaddedDiff:DWORD,
                 gaussHalf    :DWORD,
                 gaussSum     :DWORD,
                 gaussMask    :PTR DWORD

    LOCAL beginCopy    : DWORD           ; Stores computed start of a fragment of bitmap to copy to the output
    LOCAL endCopy      : DWORD           ; Stores computed ejd of a fragment of bitmap to copy to the output
 
    LOCAL imgOffset    : DWORD           ; Stores current thread bitmap part offset
    LOCAL offset1      : DWORD           ; Stores offset to the current line of source bitmap 

    LOCAL maxX         : DWORD           ; Stores maximum y position that can be averaged (height - gaussWidth + 1)
    LOCAL x            : DWORD           ; Current bitmap pixel X position
    LOCAL y            : DWORD           ; Current bitmap pixel Y position
    LOCAL k            : DWORD           ; Current gauss mask position

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
    mov     beginCopy, eax    ; Init beginCopy
    mov     edi, eax          ; Edi stores currPosition

    mov     ecx, args.imgHeight   ; Ecx stores endCopy
    mov     endCopy, ecx          ; Init endCopy

    .if args.imgPartId != 0      
        ; BeginCopy = gaussHalf
        mov    eax, gaussHalf
        mov    beginCopy, eax

        ; ImgOffset += rowPadded * gaussHalf
        imul   eax, rowPadded
        add    ebx, eax    ; Ebx stores imgOffset
        mov    imgOffset, ebx
    .endif

    mov     eax, args.imgPartsCount
    dec     eax

    .if args.imgPartId != eax
        sub ecx, gaussHalf
        mov endCopy, ecx
    .endif

    ; Mask load
    mov     ecx, gaussMask  ; Ecx stores mask pointer


    @yLoopInitialization:
        mov     eax, beginCopy
        mov     y, eax
    @yLoopStart:
        ; Check y iterate conditions
        cmp     eax, endCopy
        jge     @yLoopEnd

        ; ########## Actions of y loop begin ##########

        ; Compute offset1
        imul    eax, rowPadded ; Eax = y * rowPadded
        add     eax, tempImg   ; Eax = tempImg + y * rowPadded
        mov     ebx, gaussHalf ; Ebx = gaussHalf
        imul    ebx, 3         ; Ebx = gaussHalf * 3
        sub     eax, ebx       ; Eax -= ebx
        mov     offset1, eax   ; Offset1 = tempImg + rowPadded * y - gaussHalf * 3;

        @x1LoopInitialization:
                xor     eax, eax
                mov     x, eax

        @x1LoopStart:
                ; Check x iterate conditions
                cmp     eax, args.imgWidth
                jge     @x1LoopEnd

                ; ########## Actions of x loop begin ##########

                ; Compute currX
                mov     esi, eax
                sub     esi, gaussHalf ; Esi stores currX

                ; Compute offset2
                imul    eax, 3
                add     eax, offset1
                mov     ebx, eax ; Ebx stores offset2

                ; Zero results register
                psubd   XMM3, XMM3

                ; ---------------------------------------------------------------------
                ; If |current pixel X position - gaussHalf| is in bounds of data array
                ; (edges of the bitmap)
                ; ---------------------------------------------------------------------
                .if esi >= 0 && esi < maxX
                    
                    @kLoopInitialization:
                        xor     eax, eax
                        mov     k, eax

                    @kLoopStart:
                        ; Check k iterate conditions
                        cmp     eax, args.maskSize
                        jge     @kLoopEnd

                        ; ########## Actions of k loop begin ##########

						; Offsets init part
						movd      XMM1, dword ptr [ebx]        ; Move 4 bytes (3 used) to the XMM1
						punpcklbw XMM1, XMM0                   ; XMM1: ...00 rr gg bb         -> ...0000 00rr 00gg 00bb 
						punpcklwd XMM1, XMM0                   ; XMM1: ...0000 00rr 00gg 00bb -> 00000000 000000rr 000000gg 000000bb

						; Mask init part
						movd      XMM2, dword ptr [ecx][eax*4] ; Move mask for the current pixel to XMM2
						shufps    XMM2, XMM2, 0h               ; Broadcast least significant element to all elements 

						pmullw    XMM1, XMM2                   ; Multiply offset2[0,1,2] * mask[k]
						paddw     XMM3, XMM1                   ; Linc[b,g,r] += offset2[0,1,2] * mask[k]

                        add     ebx, 3
                
                        ; ########## Actions of k loop end #########
                        ; Increment k counter
                        mov     eax, k
                        inc     eax
                        mov     k, eax
                        jmp     @kLoopStart	

                    @kLoopEnd:

                    mov     esi, imgOffset ; Esi now stores imgOffset

					; Save b pixel
					pextrw  eax, XMM3, 0             ; Extract blue factor
					cwd                              ; Convert to double
					cdq                              ; Convert to quad
					div     gaussSum                 ; Divide by the sum of gauss mask factors
					mov     byte ptr [esi][edi], al  ; Save in temporary array
					inc     edi                      ; Move to the next pixel of the destination array

					; Save g pixel
					pextrw  eax, XMM3, 2             ; Extract green factor
					cwd                              ; Convert to double
					cdq                              ; Convert to quad
					div     gaussSum                 ; Divide by the sum of gauss mask factors
					mov     byte ptr [esi][edi], al  ; Save in temporary array
					inc     edi                      ; Move to the next pixel of the destination array

					; Save r pixel 
					pextrw  eax, XMM3, 4             ; Extract red factor
					cwd                              ; Convert to double
					cdq                              ; Convert to quad
					div     gaussSum                 ; Divide by the sum of gauss mask factors
					mov     byte ptr [esi][edi], al  ; Save in temporary array
					inc     edi                      ; Move to the next pixel of the destination array

                ; -------------------------------------------------------------------------
                ; If |current pixel X position - gaussHalf| is not in bounds of data array
                ; (edges of the bitmap)
                ; -------------------------------------------------------------------------
                .else
                    ; Offset2 += gaussHalf * 3
                    mov     eax, gaussHalf
                    imul    eax, 3
                    add     ebx, eax

                    mov     esi, imgOffset ; Esi now stores imgOffset

                    ; Save b pixel
                    mov     al, byte ptr [ebx]
                    mov     byte ptr [esi][edi], al
                    inc     edi

                    ; Save g pixel
                    mov     al, byte ptr [ebx][1]
                    mov     byte ptr [esi][edi], al
                    inc     edi

                    ; Save r pixel
                    mov     al, byte ptr [ebx][2]
                    mov     byte ptr [esi][edi], al
                    inc     edi

                    add     ebx, 3

                .endif

                ; ########## Actions of x loop end #########
                ; Increment x counter
                mov     eax, x
                inc     eax
                mov     x, eax
                jmp     @x1LoopStart

            @x1LoopEnd:

            add     edi, rowPaddedDiff

        ; ########## Actions of y loop end ##########
        ; Increment y counter
        mov     eax, y
        inc     eax
        mov     y, eax
        jmp     @yLoopStart

    @yLoopEnd:
        ret

SecondIteration endp
; ¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤


; ==========================================================================
; Computes pascal triangle row basing on passed gauss triangle row (max 24)
;
; ### PARAMS ###
; - maskSize (DWORD): size of gauss mask to compute
;                     basing on the pascal triangle
; - gaussMask (DWORD PTR): pointer to the result mask
;                          returned from this procedure
; ==========================================================================
ComputePascalRow proc maskSize:DWORD, gaussMask:PTR DWORD

    LOCAL counter:DWORD ; Counter variable used to iterate in loop

    ; Setting iterator to the initial value
    mov     counter, 1

    ; Setting the first element
    mov     ebx, gaussMask
    mov     dword ptr [ebx][0], 1


    jmp @startOfFirstLoop
    @firstGaussIteration:
        ; Checking iterate conditions
        mov     eax, counter
        inc     eax
        mov     counter, eax
        mov     eax, maskSize

    ; --------------
    ; - First loop -
    ; --------------
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
        imul    eax, [ebx+ecx*4-4]

        ; row[i - 1] * (n - i + 1) / i
        cdq
        idiv    counter

        ; row[i] = row[i - 1] * (n - i + 1) / i;
        mov     dword ptr [ebx+ecx*4], eax

        jmp @firstGaussIteration

    ; ---------------
    ; - Second loop -
    ; ---------------
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
        mov     ecx, [ebx+eax*4]
        mov     eax, counter
        mov     dword ptr [ebx+eax*4], ecx

        jmp @secondGaussIteration

    @endOfSecondGaussIteration:
        ret

ComputePascalRow endp
; ¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤


; ==========================================================================
; Computes gaussian blur.
; Takes struct with current thread parameters.
;
; ### PARAMS ###
; - args (PARAMS): struct with current thread parameters
; ==========================================================================
ComputeGaussBlur proc args:PARAMS

    LOCAL tempImg       :DWORD ; Temporary bitmap array pointer used to store 
                               ; partial result after first gauss blur iteration
    LOCAL rowPadded     :DWORD ; The pixel array must begin at a memory address 
                               ; that is a multiple of 4 bytes
    LOCAL rowPaddedDiff :DWORD ; Difference between rowPadded and real row width
    LOCAL gaussHalf     :DWORD ; Half of gauss mask (DWORD)
    LOCAL gaussSum      :DWORD ; Gauss mask sum
    LOCAL gaussMask[25] :DWORD ; Gauss mask pointer

    ; Nullify used XMM registers
    psubd   XMM0, XMM0
    psubd   XMM1, XMM1
    psubd   XMM2, XMM2
    psubd   XMM3, XMM3

    ; Compute rowPadded
    mov     eax, args.imgWidth
    imul    eax, 3
    add     eax, 3
    and     eax, 0FFFFFFFCh
    mov     rowPadded, eax

    ; Allocate memory for temporary image array
    mov     ebx, args.tempImgPtr
    mov     tempImg, ebx

    ; Compute rowPaddedDiff
    mov     eax, rowPadded
    mov     ecx, args.imgWidth
    imul    ecx, 3
    sub     eax, ecx
    mov     rowPaddedDiff, eax
    
    ; Compute half of gauss mask
    mov     eax, args.maskSize
    cdq
    sub     eax, edx
    sar     eax, 1
    mov     gaussHalf, eax

    ; Compute Pascal row
    mov     ecx, args.maskSize
    dec     ecx
    invoke  ComputePascalRow, ecx, ADDR gaussMask

    ; Compute Gauss mask sum
    invoke ComputeGaussMaskSum, args.maskSize, ADDR gaussMask 
    mov     gaussSum, eax

    ; Process Gauss
    invoke FirstIteration,  args, tempImg, rowPadded, rowPaddedDiff, gaussHalf, gaussSum, ADDR gaussMask
    invoke SecondIteration, args, tempImg, rowPadded, rowPaddedDiff, gaussHalf, gaussSum, ADDR gaussMask

    ret
ComputeGaussBlur endp 
; ¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤*¤

end 