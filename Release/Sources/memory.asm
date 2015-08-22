;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      memory.asm 
; Описание:  функции для работы с памятью
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
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
; malloc - выделить память из кучи процесса
;   - dwSize - требуемый размер памяти
;------------------------------------------------------------------------------
malloc proc dwSize: DWORD
    invoke GetProcessHeap
    invoke HeapAlloc, eax, HEAP_ZERO_MEMORY, dwSize
    ret
malloc endp

;------------------------------------------------------------------------------
; realloc - изменить размер памяти(без переноса данных!)
;   - lpMemBlock - адрес раннее выделенного блока
;   - dwSize - требуемый размер памяти
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
; free - освободить память
;   - lpMemBlock - адрес раннее выделенного блока
;------------------------------------------------------------------------------
mfree proc lpMemBlock:LPVOID
    invoke GetProcessHeap
    invoke HeapFree, eax, 0, lpMemBlock
    ret
mfree endp

end
