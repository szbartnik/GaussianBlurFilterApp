.686 
.387
.model flat, stdcall 
.xmm
.data
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

ComputeGaussBlur proc args:PARAMS

ret

ComputeGaussBlur endp 

end 