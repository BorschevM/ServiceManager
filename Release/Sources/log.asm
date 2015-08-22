;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      log.asm 
; Описание:  функции для работы с ошибками и сообщениями
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

title  Log

.386
.model flat,stdcall
option casemap:none

include ..\..\Masm32\include\windows.inc
include ..\..\Masm32\include\user32.inc
include ..\..\Masm32\include\kernel32.inc

include global.inc
include log.inc

.data
    szSCM db 'SCM', 0
    szOperationOpen  db 'open',0
    szOperationClose  db 'close',0
    szOperationLock  db 'lock',0
    szOperationUnlock  db 'unlock',0
    
    szOperationCrateService  db 'create service',0
    szOperationDeleteService  db 'delete service',0

    szOperationOpenService  db 'open service',0
    szOperationCloseService  db 'close service',0
    szOperationControlService  db 'control service',0
    szOperationPauseService  db 'pause service',0
    szOperationResumeService  db 'resume service',0

    szOperationEnumServices  db 'enum services',0
    szOperationQueryServiceConfig  db 'query service config',0
    szOperationChangeServiceConfig  db 'change service config',0
    szOperationEnumDependentServices  db 'enum dependent services',0
    szOperationQueryServiceStatus  db 'query service status',0
    szOperationStart  db 'start',0
    szOperationStop  db 'stop',0
    
    szOperationQuerySecurity  db 'query object security',0
    szOperationSetSecurity  db 'set object security',0
    
    szSuccess db 'SUCCESS', 0
    szFailure db 'FAILURE', 0
    
.data?
    szErrorDescription db ERROR_DESC_SIZE dup(?)
    szErrorCode db ERROR_CODE_SIZE dup(?)
    
.code
;------------------------------------------------------------------------------
; GetLastErrorString - заполнить  буфер строкой   описания ошибки
;   - lpDescription- указатель  на буфер со строкой   описания
;   - nDescriptionSize - размер буфера описания
;   - lpCode - указатель  на буфер с кодом ошибки (строковое  представление)
;   - nCodeSize - размер буфера кода ошибки
;------------------------------------------------------------------------------
GetLastErrorString proc lpDescription: DWORD, nDescriptionSize:DWORD, lpCode:DWORD, nCodeSize:DWORD
    LOCAL dwCode: DWORD
    
    pushad
    
    invoke GetLastError
    mov dwCode, eax

    invoke RtlZeroMemory, lpDescription, nDescriptionSize
    mov ecx, SUBLANG_DEFAULT
    shl ecx, 10
    add ecx, LANG_NEUTRAL
    invoke FormatMessage, FORMAT_MESSAGE_FROM_SYSTEM OR FORMAT_MESSAGE_MAX_WIDTH_MASK, NULL, \
    						dwCode, ecx, lpDescription, nDescriptionSize, NULL
    invoke wsprintf, lpCode, addr szFmtX, dwCode
    
    popad
    mov eax, dwCode 
    ret 
GetLastErrorString endp 

;------------------------------------------------------------------------------
; LogMessage - Вставить    строку  статуса    в окно логов
;   - hList - хендл окна логов
;   - lpSource - строка  источника   
;   - lpOperation - строка  операции
;   - dwStatus - статус    операции
;   - lpCode - строка   кода ошибки
;   - lpDescription - строка  описания ошибки
;------------------------------------------------------------------------------
LogMessage proc hList:DWORD,  lpSource: DWORD, lpOperation:DWORD, dwStatus: DWORD, lpCode: DWORD, lpDescription: DWORD 
    LOCAL item:LV_ITEM
    LOCAL dwCount: DWORD
    LOCAL dwTopIndex: DWORD
    LOCAL dwHeight: DWORD
    LOCAL rItemRect: RECT

    pushad 
    
    invoke SendMessage, hList, LVM_GETITEMCOUNT, 0,0
    mov dwCount, eax
    push eax

    invoke SendMessage, hList, LVM_GETTOPINDEX, 0,0
    mov dwTopIndex, eax
    
    mov rItemRect.left, LVIR_BOUNDS
    invoke SendMessage, hList, LVM_GETITEMRECT, dwTopIndex, addr rItemRect
    mov eax, rItemRect.bottom
    sub eax, rItemRect.top
    mov dwHeight, eax
    
    pop eax
    mov item.iItem, eax 
    mov item.imask, LVIF_TEXT
    push lpSource
    pop item.pszText
    xor eax, eax
    mov item.iSubItem, eax
    invoke SendMessage, hList, LVM_INSERTITEM,0, addr item
    mov item.iItem, eax

    inc item.iSubItem
    push lpOperation
    pop item.pszText
    invoke SendMessage, hList, LVM_SETITEM, 0, addr item

    inc item.iSubItem
    .if(dwStatus != 0)
        lea eax, szSuccess
    .elseif
        lea eax, szFailure
    .endif
    mov item.pszText, eax
    invoke SendMessage, hList, LVM_SETITEM, 0, addr item

    inc item.iSubItem
    push lpCode
    pop item.pszText
    invoke SendMessage, hList, LVM_SETITEM, 0, addr item

    inc item.iSubItem
    push lpDescription
    pop item.pszText
    invoke SendMessage, hList, LVM_SETITEM, 0, addr item
    
    mov eax, dwCount
    sub eax, dwTopIndex
    mul dwHeight
    invoke SendMessage, hList, LVM_SCROLL, 0, eax

    popad
    ret
LogMessage endp

end
