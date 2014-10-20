.686 
.387
.model flat, stdcall 
.xmm
.data
.code

GetInt proc uses ebx a:DWORD, b:DWORD

mov eax,a
mov ebx,b
add eax, ebx
ret

GetInt endp 

end 