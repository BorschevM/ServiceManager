;------------------------------------------------------------------------------
; �������� �������� Windows
;
; ����:      memory.asm 
; ��������:  ������� ��� ������ � �������
; �����:     ������� ���� ���������, YormLokison@yandex.ru
;------------------------------------------------------------------------------

title  Memory

.386
.model flat,stdcall
option casemap:none

include ..\..\Masm32\include\windows.inc
include ..\..\Masm32\include\kernel32.inc

include memory.inc

.code

;------------------------------------------------------------------------------
; malloc - �������� ������ �� ���� ��������
;   - dwSize - ��������� ������ ������
;------------------------------------------------------------------------------
malloc proc dwSize: DWORD
    invoke GetProcessHeap
    invoke HeapAlloc, eax, HEAP_ZERO_MEMORY, dwSize
    ret
malloc endp

;------------------------------------------------------------------------------
; realloc - �������� ������ ������(��� �������� ������!)
;   - lpMemBlock - ����� ������ ����������� �����
;   - dwSize - ��������� ������ ������
;------------------------------------------------------------------------------
realloc proc lpMemBlock:LPVOID, dwSize: DWORD
    invoke GetProcessHeap
    push eax
    invoke HeapFree, eax, 0, lpMemBlock
    .if (eax != 0)
        pop eax
        invoke HeapAlloc, eax, HEAP_ZERO_MEMORY, dwSize
    .else
        pop eax
        xor eax, eax
    .endif
    ret
realloc endp

;------------------------------------------------------------------------------
; free - ���������� ������
;   - lpMemBlock - ����� ������ ����������� �����
;------------------------------------------------------------------------------
mfree proc lpMemBlock:LPVOID
    invoke GetProcessHeap
    invoke HeapFree, eax, 0, lpMemBlock
    ret
mfree endp

end
