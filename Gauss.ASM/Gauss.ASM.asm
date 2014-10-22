.686 
.387
.model flat, stdcall 
.xmm
.data
.code

ComputeGaussBlur proc uses ebx a:DWORD, b:DWORD

mov eax,a
mov ebx,b
add eax, ebx
ret

ComputeGaussBlur endp 

end 