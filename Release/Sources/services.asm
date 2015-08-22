;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      services.asm 
; Описание:  функции для работы с сервисами
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

title  Services

.386
.model flat,stdcall
option casemap:none

include ..\..\Masm32\include\windows.inc
include ..\..\Masm32\include\kernel32.inc
include ..\..\Masm32\include\advapi32.inc
include ..\..\Masm32\include\user32.inc

include global.inc
include memory.inc
include services.inc
include log.inc

.data
    szOrderGroupKey db 'SYSTEM\CurrentControlSet\Control\ServiceGroupOrder', 0
    szListValue db 'List', 0
    
    dwStatusInfoSize      DWORD SERVICE_STATUS_SIZE
    dwConfigInfoSize      DWORD SERVICE_CONFIG_SIZE
    dwDescriptionInfoSize DWORD SERVICE_DESC_SIZE
    dwFailureInfoSize     DWORD SERVICE_FAIL_SIZE
    dwGroupInfoSize     DWORD SERVICE_DESC_SIZE

    csServiceType CodeString<SERVICE_FILE_SYSTEM_DRIVER, 'FILE_SYSTEM_DRIVER'> 
                          CodeString<SERVICE_KERNEL_DRIVER, 'KERNEL_DRIVER'>
                          CodeString<SERVICE_WIN32_OWN_PROCESS, 'WIN32_OWN_PROCESS'> 
                          CodeString<SERVICE_WIN32_SHARE_PROCESS, 'WIN32_SHARE_PROCESS'>
                          CodeString<SERVICE_INTERACTIVE_PROCESS, 'INTERACTIVE_PROCESS'>
 
    csServiceState CodeString<SERVICE_CONTINUE_PENDING, 'CONTINUE_PENDING'> 
                           CodeString<SERVICE_PAUSE_PENDING, 'PAUSE_PENDING'>
                           CodeString<SERVICE_PAUSED, 'PAUSED'>
                           CodeString<SERVICE_RUNNING, 'RUNNING'>
                           CodeString<SERVICE_START_PENDING, 'START_PENDING'> 
                           CodeString<SERVICE_STOP_PENDING, 'STOP_PENDING'>
                           CodeString<SERVICE_STOPPED, 'STOPPED'>
                           
    csServiceStartType CodeString<SERVICE_AUTO_START, 'AUTO_START'> 
                                 CodeString<SERVICE_BOOT_START, 'BOOT_START'> 
                                 CodeString<SERVICE_DEMAND_START, 'DEMAND_START'> 
                                 CodeString<SERVICE_DISABLED, 'DISABLED'>
                                 CodeString<SERVICE_SYSTEM_START, 'SYSTEM_START'> 

    csServiceErrorControl CodeString<SERVICE_ERROR_IGNORE, 'ERROR_IGNORE'> 
                                    CodeString<SERVICE_ERROR_NORMAL, 'ERROR_NORMAL'>
                                    CodeString<SERVICE_ERROR_SEVERE, 'ERROR_SEVERE'>
                                    CodeString<SERVICE_ERROR_CRITICAL, 'ERROR_CRITICAL'>
                                    
    csSeviceFailureAcrion CodeString<SC_ACTION_NONE, 'SC_ACTION_NONE'>
                                     CodeString<SC_ACTION_RESTART, 'SC_ACTION_RESTART'>
                                     CodeString<SC_ACTION_REBOOT, 'SC_ACTION_REBOOT'>
                                     CodeString<SC_ACTION_RUN_COMMAND, 'SC_ACTION_RUN_COMMAND'>

.data?
    pStatusInfo      DWORD ?
    pConfigInfo      DWORD ?
    pDescriptionInfo DWORD ?
    pFailureInfo     DWORD ?
    pGroupInfo       DWORD ?
   
.code

;------------------------------------------------------------------------------
; FillServicesList - Заполнить список сервисов
;   - hList - хендл окна сервисов
;   - hLog - хендл окна логов
;   - hSCManager - хендл соединение с SCM
;   - dwServicesType - тип сервисов для перечисления
;   - dwServicesState - состояние сервисов для перечисления
;------------------------------------------------------------------------------
FillServicesList proc hList:HWND, hLog:HWND, hSCManager: HANDLE, dwServiceType: DWORD, dwServiceState: DWORD
    LOCAL dwBytesNeeded: DWORD
    LOCAL dwServiceCount: DWORD
    LOCAL dwResumeHandle: DWORD
    LOCAL dwReturnFlag: DWORD
    LOCAL dwLastErr: DWORD
    LOCAL szBuffer[SERV_CODE_LENTH]: BYTE
    
    LOCAL hService: HANDLE
    LOCAL item:LV_ITEM

    pushad 

    invoke SendMessage, hList, LVM_DELETEALLITEMS, 0, 0

    xor eax, eax
    mov item.iItem, eax
    mov item.imask, LVIF_TEXT
    mov item.iSubItem, eax
    
    mov dwResumeHandle, eax
    mov dwReturnFlag, eax

    .if (hSCManager != NULL)
        .while (dwReturnFlag == 0)
            invoke SetLastError, ERROR_SUCCESS
            invoke EnumServicesStatus, hSCManager, dwServiceType, dwServiceState, pStatusInfo, dwStatusInfoSize, addr dwBytesNeeded, addr dwServiceCount, addr dwResumeHandle
        
            push eax
            invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
            mov dwLastErr, eax
            pop eax
        
            .if (eax == 0)
                .if (dwLastErr != ERROR_MORE_DATA)
                    inc dwReturnFlag    
                    mov dwServiceCount, eax
                .endif
            .else
                inc dwReturnFlag    
            .endif
        
            invoke LogMessage, hLog, addr szSCM, addr szOperationEnumServices , eax, addr szErrorCode, addr szErrorDescription 

            xor edi, edi
            mov ebx, pStatusInfo
            assume ebx: ptr ENUM_SERVICE_STATUS
            .while (edi < dwServiceCount)
                ; Получить   дополнительные  данные о сервисе
                invoke OpenService, hSCManager, [ebx].lpServiceName, dwServAccess
                mov hService, eax

                invoke QueryServiceConfig, hService, pConfigInfo, dwConfigInfoSize, addr dwBytesNeeded
                .if (eax == 0)
                    invoke GetLastError
                    .if (eax == ERROR_INSUFFICIENT_BUFFER)
                        ; выделить  буфер и получить  информацию
                        mov eax, dwBytesNeeded
                        invoke realloc, pConfigInfo, eax
                        mov pConfigInfo, eax 
                        .if (eax == 0)
                            mov dwConfigInfoSize, eax
                        .elseif
                            mov eax, dwBytesNeeded
                            mov dwConfigInfoSize, eax
                            invoke QueryServiceConfig, hService, pConfigInfo, dwConfigInfoSize, addr dwBytesNeeded
                        .endif
                    .endif
                .endif

                invoke QueryServiceConfig2, hService, SERVICE_CONFIG_DESCRIPTION, pDescriptionInfo, dwDescriptionInfoSize, addr dwBytesNeeded
                .if (eax == 0)
                    invoke GetLastError
                    .if (eax == ERROR_INSUFFICIENT_BUFFER)
                        ; выделить  буфер и получить  информацию
                        mov eax, dwBytesNeeded
                        invoke realloc, pDescriptionInfo, eax
                        mov pDescriptionInfo, eax 
                        .if (eax == 0)
                            mov dwDescriptionInfoSize, eax
                        .elseif
                            mov eax, dwBytesNeeded
                            mov dwDescriptionInfoSize, eax
                            invoke QueryServiceConfig2, hService, SERVICE_CONFIG_DESCRIPTION, pDescriptionInfo, dwDescriptionInfoSize, addr dwBytesNeeded
                        .endif
                    .endif
                .endif

                invoke CloseServiceHandle, hService
            
                xor eax, eax
                mov item.iSubItem, eax
                
                ; внутеренние  имя сервиса
                mov eax, [ebx].lpServiceName
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_INSERTITEM,0, addr item
                mov item.iItem, eax
            
                ; отображаемое   имя сервиса
                inc item.iSubItem
                mov eax, [ebx].lpDisplayName
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item
            
                inc item.iSubItem
               
                ; тип  сервиса
                invoke FillBufferFromFlag, [ebx].ServiceStatus.dwServiceType, addr szBuffer, SERV_CODE_LENTH, addr csServiceType, SERVICE_TYPE_COUNT                 
                inc item.iSubItem
                lea eax, szBuffer
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item
            
                ; статус   сервиса
                invoke FillBufferFromCode, [ebx].ServiceStatus.dwCurrentState , addr szBuffer, SERV_CODE_LENTH, addr csServiceState, SERVICE_STATE_COUNT
                inc item.iSubItem
                lea eax, szBuffer
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item

                push ebx
                mov ebx, pConfigInfo
                mov  item.iSubItem, 2 
                assume ebx: ptr QUERY_SERVICE_CONFIG

                ; путь  к исполняемому файлу
                mov eax, [ebx].lpBinaryPathName
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item

                ; тип  запуска
                add item.iSubItem, 3
                invoke FillBufferFromCode, [ebx].dwStartType, addr szBuffer, SERV_CODE_LENTH, addr csServiceStartType, SERVICE_START_TYPE_COUNT
                lea eax, szBuffer
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item
                
                ; контроль  ошибок 
                inc item.iSubItem
                invoke FillBufferFromCode, [ebx].dwErrorControl, addr szBuffer, SERV_CODE_LENTH, addr csServiceErrorControl, SERVICE_ERROR_CONTROL_COUNT
                lea eax, szBuffer
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item

                ; учетная  запись
                inc item.iSubItem
                mov eax, [ebx].lpServiceStartName
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item
                
                mov ebx, pDescriptionInfo
                assume ebx: ptr SERVICE_DESCRIPTION
                ; описание
                inc item.iSubItem
                mov eax, [ebx].lpDescription
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item

                assume ebx: ptr ENUM_SERVICE_STATUS
                pop ebx
                
                add ebx, sizeof ENUM_SERVICE_STATUS
                inc edi
            .endw
            assume ebx: nothing
        .endw
    .endif
    
    popad
    ret
FillServicesList endp

;------------------------------------------------------------------------------
; FillServicesCombo - Заполнить список сервисов
;   - hCombo - хендл окна сервисов
;   - hSCManager - хендл соединение с SCM
;   - dwServicesType - тип сервисов для перечисления
;   - dwServicesState - состояние сервисов для перечисления
;------------------------------------------------------------------------------
FillServicesCombo proc hCombo:HWND, hSCManager: HANDLE, dwServiceType: DWORD, dwServiceState: DWORD
    LOCAL dwBytesNeeded: DWORD
    LOCAL dwServiceCount: DWORD
    LOCAL dwResumeHandle: DWORD
    LOCAL dwReturnFlag: DWORD

    pushad 

    xor eax, eax
    mov dwResumeHandle, eax
    mov dwReturnFlag, eax
    invoke SendMessage, hCombo, CB_ADDSTRING, 0,  addr dwReturnFlag

    .if (hSCManager != NULL)
        .while (dwReturnFlag == 0)
            invoke SetLastError, ERROR_SUCCESS
            invoke EnumServicesStatus, hSCManager, dwServiceType, dwServiceState, pStatusInfo, dwStatusInfoSize, addr dwBytesNeeded, addr dwServiceCount, addr dwResumeHandle
            .if (eax == 0)
                invoke GetLastError                
                .if (eax != ERROR_MORE_DATA)
                    inc dwReturnFlag
                    xor eax, eax    
                    mov dwServiceCount, eax
                .endif
            .else
                inc dwReturnFlag    
            .endif

            xor edi, edi
            mov ebx, pStatusInfo
            assume ebx: ptr ENUM_SERVICE_STATUS
            .while (edi < dwServiceCount)
                mov eax, [ebx].lpServiceName
                invoke SendMessage, hCombo, CB_ADDSTRING, 0, eax
                add ebx, sizeof ENUM_SERVICE_STATUS
                inc edi
            .endw
            assume ebx: nothing
        .endw
    .endif
    
    popad
    ret
FillServicesCombo endp

;------------------------------------------------------------------------------
; FillServicesCombo - Заполнить список сервисов
;   - hCombo - хендл окна сервисов
;   - lpCompName -  имя удаленного компьютера
;------------------------------------------------------------------------------
FillOrderGroupCombo proc hCombo:HWND, lpCompName: LPCSTR
    LOCAL hRemoteKey: HKEY
    LOCAL hKey: HKEY
    LOCAL dwReturn: DWORD
    LOCAL dwBytes: DWORD
    
    pushad
    xor eax, eax
    mov hRemoteKey, eax
    mov hKey, eax
    invoke SendMessage, hCombo, CB_ADDSTRING, 0,  addr hKey
     
    .if (lpCompName != NULL)
        ; удаленная машина
        invoke RegConnectRegistry, lpCompName, HKEY_LOCAL_MACHINE, addr hRemoteKey
        mov dwReturn, eax
        .if (eax == ERROR_SUCCESS) 
            invoke RegOpenKeyEx, hRemoteKey, addr szOrderGroupKey, 0, KEY_QUERY_VALUE, addr hKey
            mov dwReturn, eax
         .endif
    .else
        ; локальная машина
        invoke RegOpenKeyEx, HKEY_LOCAL_MACHINE, addr szOrderGroupKey, 0, KEY_QUERY_VALUE, addr hKey
        mov dwReturn, eax
    .endif

    .if (dwReturn == ERROR_SUCCESS)
        mov eax, ERROR_MORE_DATA
        mov edi, 5
        .while (eax == ERROR_MORE_DATA)&&(edi > 0)
            push dwGroupInfoSize
            pop dwBytes
            invoke RegQueryValueEx, hKey, addr szListValue, NULL, NULL, pGroupInfo, addr dwBytes
            push eax
            .if (eax == ERROR_MORE_DATA)
                mov eax, dwBytes
                invoke realloc, pGroupInfo, eax
                mov pGroupInfo, eax 
                .if (eax != 0)
                    mov eax, dwBytes
                .endif
                mov dwGroupInfoSize, eax
            .endif
            pop eax
            dec edi
        .endw
        
        mov dwReturn, eax
        .if(eax == ERROR_SUCCESS)
            mov edi, pGroupInfo
            mov ecx, dwBytes
            .while (byte ptr [edi] != 0)
                xor eax, eax
                mov esi, edi
                repnz scasb
                ;inc edi
                push ecx
                invoke SendMessage, hCombo, CB_ADDSTRING, 0, esi
                pop ecx
            .endw
        .endif
    .endif 
    
     invoke RegCloseKey, hRemoteKey
     invoke RegCloseKey, hKey
     
     popad
     
     mov eax, dwReturn
     ret
FillOrderGroupCombo endp

;------------------------------------------------------------------------------
; UpdateServiceRecord - обновить   строку   таблицы
;   - hList - хендл окна сервисов
;   - dwIndex - индекс строки  
;   - hSCManager - хендл соединение с SCM
;------------------------------------------------------------------------------
UpdateServiceRecord proc hList:HWND, dwIndex:DWORD, hSCManager: HANDLE
    LOCAL dwBytesNeeded: DWORD
    LOCAL hService: HANDLE
    LOCAL sStatus:SERVICE_STATUS
    LOCAL item:LV_ITEM
    LOCAL szBuffer[SERV_CODE_LENTH]: BYTE

    pushad 

    .if (hSCManager != NULL)
        ; получить  имя сервиса
        mov eax, dwIndex        
        mov item.iItem, eax
        mov item.imask, LVIF_TEXT
        mov item.iSubItem, 0
        lea eax, szBuffer
        mov item.pszText, eax
        mov item.cchTextMax, SERV_CODE_LENTH
        invoke SendMessage, hList, LVM_GETITEM, 0, addr item
    
        .if (eax == TRUE)
            ; получить  информацию  о сервисе
            invoke OpenService, hSCManager, addr szBuffer, dwServAccess
            mov hService, eax
            .if (eax != 0)
                invoke QueryServiceStatus, hService, addr sStatus 

                invoke QueryServiceConfig, hService, pConfigInfo, dwConfigInfoSize, addr dwBytesNeeded
                .if (eax == 0)
                    invoke GetLastError
                    .if (eax == ERROR_INSUFFICIENT_BUFFER)
                        ; выделить  буфер и получить  информацию
                        mov eax, dwBytesNeeded
                        invoke realloc, pConfigInfo, eax
                        mov pConfigInfo, eax 
                        .if (eax == 0)
                            mov dwConfigInfoSize, eax
                        .elseif
                            mov eax, dwBytesNeeded
                            mov dwConfigInfoSize, eax
                            invoke QueryServiceConfig, hService, pConfigInfo, dwConfigInfoSize, addr dwBytesNeeded
                        .endif
                    .endif
                .endif

                invoke QueryServiceConfig2, hService, SERVICE_CONFIG_DESCRIPTION, pDescriptionInfo, dwDescriptionInfoSize, addr dwBytesNeeded
                .if (eax == 0)
                    invoke GetLastError
                    .if (eax == ERROR_INSUFFICIENT_BUFFER)
                        ; выделить  буфер и получить  информацию
                        mov eax, dwBytesNeeded
                        invoke realloc, pDescriptionInfo, eax
                        mov pDescriptionInfo, eax 
                        .if (eax == 0)
                            mov dwDescriptionInfoSize, eax
                        .elseif
                            mov eax, dwBytesNeeded
                            mov dwDescriptionInfoSize, eax
                            invoke QueryServiceConfig2, hService, SERVICE_CONFIG_DESCRIPTION, pDescriptionInfo, dwDescriptionInfoSize, addr dwBytesNeeded
                        .endif
                    .endif
                .endif
                
                invoke CloseServiceHandle, hService

                ; обновить  информацию
                mov ebx, pConfigInfo
                assume ebx: ptr QUERY_SERVICE_CONFIG

                ; отображаемое   имя сервиса
                inc item.iSubItem
                mov eax, [ebx].lpDisplayName
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item
            
                ; путь  к исполняемому файлу
                inc item.iSubItem
                mov eax, [ebx].lpBinaryPathName
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item
               
                lea ebx, sStatus
                assume ebx: ptr SERVICE_STATUS

                ; тип  сервиса
                invoke FillBufferFromFlag, [ebx].dwServiceType, addr szBuffer, SERV_CODE_LENTH, addr csServiceType, SERVICE_TYPE_COUNT                 
                inc item.iSubItem
                lea eax, szBuffer
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item
            
                ; статус   сервиса
                invoke FillBufferFromCode, [ebx].dwCurrentState , addr szBuffer, SERV_CODE_LENTH, addr csServiceState, SERVICE_STATE_COUNT
                inc item.iSubItem
                lea eax, szBuffer
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item

                mov ebx, pConfigInfo
                assume ebx: ptr QUERY_SERVICE_CONFIG

                ; тип  запуска
                inc item.iSubItem
                invoke FillBufferFromCode, [ebx].dwStartType, addr szBuffer, SERV_CODE_LENTH, addr csServiceStartType, SERVICE_START_TYPE_COUNT
                lea eax, szBuffer
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item
                
                ; контроль  ошибок 
                inc item.iSubItem
                invoke FillBufferFromCode, [ebx].dwErrorControl, addr szBuffer, SERV_CODE_LENTH, addr csServiceErrorControl, SERVICE_ERROR_CONTROL_COUNT
                lea eax, szBuffer
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item

                ; учетная  запись
                inc item.iSubItem
                mov eax, [ebx].lpServiceStartName
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item
                
                mov ebx, pDescriptionInfo
                assume ebx: ptr SERVICE_DESCRIPTION
                ; описание
                inc item.iSubItem
                mov eax, [ebx].lpDescription
                mov item.pszText, eax
                invoke SendMessage, hList, LVM_SETITEM, 0, addr item

                assume ebx: nothing
            .endif
        .endif
    .endif
    
    popad
    ret
UpdateServiceRecord endp

;------------------------------------------------------------------------------
; FillBufferFromFlag - Заполнить  буфер строковыми   значениями флагов
;   - dwFlag - флаги
;   - lpBuffer - буфер
;   - dwBufferSize - размер буфера
;   - lpcodeString - массив значения строк
;   - dwArrSize - размер массива
;------------------------------------------------------------------------------
FillBufferFromFlag proc dwFlag: DWORD, lpBuffer: LPCSTR, dwBufferSize: DWORD, lpCodeString: LPVOID, dwArrSize: DWORD
    pushad
    
    mov ebx, lpCodeString
    mov ecx, dwArrSize
    mov edi, lpBuffer
    mov edx, edi
    add edx, dwBufferSize
    dec edx
    assume ebx: ptr CodeString
    
    .while (ecx != 0)
        mov eax, dwFlag
        and eax, [ebx].dwCode
        .if( eax == [ebx].dwCode)
            push ecx

            xor eax, eax
            mov ecx, SERV_CODE_LENTH
            push ecx
            push edi
            lea edi, [ebx].szString
            mov esi, edi
            repne scasb
            pop edi
            pop eax
            sub eax, ecx
            dec eax
            xchg eax, ecx

            mov eax, edi
            add eax, ecx
            .if (eax >= edx)
                sub eax, edx
                xchg eax, ecx                
            .endif
             
            rep movsb
            mov ax, ', '
            stosw
           
            pop ecx
            
        .endif
        add ebx, sizeof CodeString
        dec ecx    
    .endw
    
    .if (esi != lpBuffer)
        dec edi
        dec edi
    .endif
    
    xor eax, eax
    stosb
    
    assume ebx: nothing
    popad
    ret
FillBufferFromFlag endp

;------------------------------------------------------------------------------
; FillBufferFromCode - Заполнить  буфер строковыми  значением кода
;   - dwCode - код
;   - lpBuffer - буфер
;   - dwBufferSize - размер буфера
;   - lpcodeString - массив значения строк
;   - dwArrSize - размер массива
;------------------------------------------------------------------------------
FillBufferFromCode proc dwCode: DWORD, lpBuffer: LPCSTR, dwBufferSize: DWORD, lpCodeString: LPVOID, dwArrSize: DWORD
    pushad
    
    mov ebx, lpCodeString
    mov ecx, dwArrSize
    mov edi, lpBuffer
    mov edx, edi
    add edx, dwBufferSize
    dec edx
    assume ebx: ptr CodeString
    
    .while (ecx != 0)
        mov eax, dwCode
        .if (eax == [ebx].dwCode)
            push ecx

            xor eax, eax
            mov ecx, SERV_CODE_LENTH
            push ecx
            push edi
            lea edi, [ebx].szString
            mov esi, edi
            repne scasb
            pop edi
            pop eax
            sub eax, ecx
            xchg eax, ecx
            
            mov eax, edi
            add eax, ecx
            .if (eax > edx)
                sub eax, edx
                xchg eax, ecx                
            .endif
             
            rep movsb
            pop ecx
            xor ecx, ecx
            inc ecx
        .endif
        add ebx, sizeof CodeString
        dec ecx    
    .endw
    
    xor eax, eax
    stosb
    
    assume ebx: nothing
    popad
    ret
FillBufferFromCode endp

;------------------------------------------------------------------------------
; WaitForServiceState - ожидать  пока состояния  сервиса не изменится  до желаемого или не выйдет  таймаут
;   - hService - хендл сервиса
;   - dwState - состояние  сервиса
;   - lpServiceStatus - указатель  на структуру   данных статуса    сервиса
;   - dwMilliseconds - время ожидания
;------------------------------------------------------------------------------
WaitForServiceState proc hService: HANDLE, dwState: DWORD, lpServiceStatus: LPVOID, dwMilliseconds:DWORD
    LOCAL dwLastState: DWORD
    LOCAL dwLastCheckPoint: DWORD
    LOCAL dwTimeOut: DWORD
    LOCAL dwFirst: DWORD
    LOCAL dwReturn: DWORD

    pushad
    
    xor eax, eax
    mov dwFirst, eax
    ;mov dwLastState, eax
    ;mov dwLastCheckPoint, eax

    invoke GetTickCount
    add eax, dwMilliseconds
    mov dwTimeOut, eax
    
    mov ebx, lpServiceStatus
    assume ebx: ptr SERVICE_STATUS
    .while (TRUE)
        invoke QueryServiceStatus, hService, ebx
        mov dwReturn, eax
        .break .if (eax != TRUE)

        mov eax, [ebx].dwCurrentState
        .break .if (eax == dwState)
            
        invoke GetTickCount
        .if (dwMilliseconds != INFINITE) && (eax > dwTimeOut)
            mov dwReturn, FALSE
            invoke SetLastError, ERROR_TIMEOUT
            .break; 
        .endif            
            
        .if (dwFirst == 0)
            inc dwFirst
            push [ebx].dwCurrentState
            pop dwLastState
            push [ebx].dwCheckPoint
            pop dwLastCheckPoint
        .else
            mov eax, [ebx].dwCurrentState
            .if (eax != dwLastState)
                mov dwLastState, eax
                mov eax, [ebx].dwCheckPoint
                mov dwLastCheckPoint, eax
            .else
                mov eax, [ebx].dwCheckPoint
                .if (eax >= dwLastCheckPoint)
                    mov dwLastCheckPoint, eax
                .else
                    mov dwReturn, FALSE
                    .break     
                .endif
            .endif
        .endif
        
        mov eax, [ebx].dwWaitHint
        xor edx, edx
        mov ecx, 10
        div ecx
        .if (eax < 1000) 
            mov eax, 1000
        .elseif (eax > 10000)
            mov eax, 10000
        .endif
        invoke Sleep, eax
    .endw
    assume ebx: nothing
    
    popad

    mov eax, dwReturn
    ret
WaitForServiceState endp

;------------------------------------------------------------------------------
; GetServiceStatus - получить  статусную   информацию сервиса
;   - hSCManager - хендл SCM
;   - lpServiceName - имя сервиса
;   - dwAccess - права доступа
;   - lpSeviceStatus - указатель  на структуры    статуса
;------------------------------------------------------------------------------
GetServiceStatus proc hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD, lpServiceStatus: LPVOID
    LOCAL hService: HANDLE
    
    invoke OpenService, hSCManager, lpServiceName, dwServAccess
    .if (eax != 0)        
        mov hService, eax
        invoke QueryServiceStatus, hService, lpServiceStatus
        push eax
        invoke CloseServiceHandle, hService
        pop eax
    .endif

    ret
GetServiceStatus endp

;------------------------------------------------------------------------------
; ServiceStartOperation - запустить   сервис
;   - hLog - окно логов
;   - hSCManager - хендл SCM
;   - lpServiceName - имя сервиса
;   - dwAccess - права доступа
;------------------------------------------------------------------------------
ServiceStartOperation proc hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
    LOCAL hService: HANDLE
    LOCAL sStatus:SERVICE_STATUS
    LOCAL dwReturn: DWORD

    mov dwReturn, FALSE
    
    invoke SetLastError, ERROR_SUCCESS
    invoke OpenService, hSCManager, lpServiceName, dwServAccess
    mov hService, eax
    invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
    invoke LogMessage, hLogList, lpServiceName, addr szOperationOpenService, hService, addr szErrorCode, addr szErrorDescription
    
    .if (hService != 0)        
        invoke SetLastError, ERROR_SUCCESS
        invoke StartService, hService, NULL, NULL
        mov dwReturn, eax
        invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
        invoke LogMessage, hLogList, lpServiceName, addr szOperationStart, dwReturn, addr szErrorCode, addr szErrorDescription
        
        .if (dwReturn != 0)
            invoke WaitForServiceState, hService, SERVICE_RUNNING, addr sStatus, SERV_WAIT_TIMEOUT
        .endif
        invoke CloseServiceHandle, hService
    .endif

    mov eax, dwReturn
    ret
ServiceStartOperation endp

;------------------------------------------------------------------------------
; ServiceStopOperation - остановить    сервис
;   - hLog - окно логов
;   - hSCManager - хендл SCM
;   - lpServiceName - имя сервиса
;   - dwAccess - права доступа
;------------------------------------------------------------------------------
ServiceStopOperation proc hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
    LOCAL hService: HANDLE
    LOCAL sStatus:SERVICE_STATUS
    LOCAL dwReturn: DWORD

    mov dwReturn, FALSE

    invoke SetLastError, ERROR_SUCCESS
    invoke OpenService, hSCManager, lpServiceName, dwServAccess
    mov hService, eax
    invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
    invoke LogMessage, hLogList, lpServiceName, addr szOperationOpenService, hService, addr szErrorCode, addr szErrorDescription
    
    .if (hService != 0)        
        invoke SetLastError, ERROR_SUCCESS
        invoke ControlService, hService, SERVICE_CONTROL_STOP, addr sStatus
        mov dwReturn, eax
        invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
        invoke LogMessage, hLogList, lpServiceName, addr szOperationStop, dwReturn, addr szErrorCode, addr szErrorDescription
        
        .if (dwReturn != 0)
            invoke WaitForServiceState, hService, SERVICE_STOPPED, addr sStatus, SERV_WAIT_TIMEOUT
        .endif
        invoke CloseServiceHandle, hService
    .endif

    mov eax, dwReturn
    ret
ServiceStopOperation endp

;------------------------------------------------------------------------------
; ServicePauseOperation - приостановить    сервис
;   - hLog - окно логов
;   - hSCManager - хендл SCM
;   - lpServiceName - имя сервиса
;   - dwAccess - права доступа
;------------------------------------------------------------------------------
ServicePauseOperation proc hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
    LOCAL hService: HANDLE
    LOCAL sStatus:SERVICE_STATUS
    LOCAL dwReturn: DWORD

    mov dwReturn, FALSE

    invoke SetLastError, ERROR_SUCCESS
    invoke OpenService, hSCManager, lpServiceName, dwServAccess
    mov hService, eax
    invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
    invoke LogMessage, hLogList, lpServiceName, addr szOperationOpenService, hService, addr szErrorCode, addr szErrorDescription
    
    .if (hService != 0)        
        invoke SetLastError, ERROR_SUCCESS
        invoke ControlService, hService, SERVICE_CONTROL_PAUSE, addr sStatus
        mov dwReturn, eax
        invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
        invoke LogMessage, hLogList, lpServiceName, addr szOperationPauseService, dwReturn, addr szErrorCode, addr szErrorDescription
        
        .if (dwReturn != 0)
            invoke WaitForServiceState, hService, SERVICE_PAUSED, addr sStatus, SERV_WAIT_TIMEOUT
        .endif
        invoke CloseServiceHandle, hService
    .endif

    mov eax, dwReturn
    ret
ServicePauseOperation endp

;------------------------------------------------------------------------------
; ServiceResumeOperation - возобновить  работу   сервиса
;   - hLog - окно логов
;   - hSCManager - хендл SCM
;   - lpServiceName - имя сервиса
;   - dwAccess - права доступа
;------------------------------------------------------------------------------
ServiceResumeOperation proc hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
    LOCAL hService: HANDLE
    LOCAL sStatus:SERVICE_STATUS
    LOCAL dwReturn: DWORD

    mov dwReturn, FALSE

    invoke SetLastError, ERROR_SUCCESS
    invoke OpenService, hSCManager, lpServiceName, dwServAccess
    mov hService, eax
    invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
    invoke LogMessage, hLogList, lpServiceName, addr szOperationOpenService, hService, addr szErrorCode, addr szErrorDescription
    
    .if (hService != 0)        
        invoke SetLastError, ERROR_SUCCESS
        invoke ControlService, hService, SERVICE_CONTROL_CONTINUE, addr sStatus
        mov dwReturn, eax
        invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
        invoke LogMessage, hLogList, lpServiceName, addr szOperationResumeService, dwReturn, addr szErrorCode, addr szErrorDescription
        
        .if (dwReturn != 0)
            invoke WaitForServiceState, hService, SERVICE_RUNNING, addr sStatus, SERV_WAIT_TIMEOUT
        .endif
        invoke CloseServiceHandle, hService
    .endif

    mov eax, dwReturn
    ret
ServiceResumeOperation endp

;------------------------------------------------------------------------------
; ServiceRestartOperation - перезапустить   сервис
;   - hLog - окно логов
;   - hSCManager - хендл SCM
;   - lpServiceName - имя сервиса
;   - dwAccess - права доступа
;------------------------------------------------------------------------------
ServiceRestartOperation proc hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
    LOCAL hService: HANDLE
    LOCAL sStatus:SERVICE_STATUS
    LOCAL dwReturn: DWORD

    mov dwReturn, FALSE

    invoke SetLastError, ERROR_SUCCESS
    invoke OpenService, hSCManager, lpServiceName, dwServAccess
    mov hService, eax
    invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
    invoke LogMessage, hLogList, lpServiceName, addr szOperationOpenService, hService, addr szErrorCode, addr szErrorDescription
    
    .if (hService != 0)        
        invoke SetLastError, ERROR_SUCCESS
        invoke ControlService, hService, SERVICE_CONTROL_STOP, addr sStatus
        mov dwReturn, eax
        invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
        invoke LogMessage, hLogList, lpServiceName, addr szOperationStop, dwReturn, addr szErrorCode, addr szErrorDescription
        
        .if (dwReturn != 0)
            invoke WaitForServiceState, hService, SERVICE_STOPPED, addr sStatus, SERV_WAIT_TIMEOUT
            
            invoke SetLastError, ERROR_SUCCESS
            invoke StartService, hService, NULL, NULL
            mov dwReturn, eax
            invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
            invoke LogMessage, hLogList, lpServiceName, addr szOperationStart, dwReturn, addr szErrorCode, addr szErrorDescription
        
            .if (dwReturn != 0)
                invoke WaitForServiceState, hService, SERVICE_RUNNING, addr sStatus, SERV_WAIT_TIMEOUT
            .endif
        .endif
        
        invoke CloseServiceHandle, hService
    .endif

    mov eax, dwReturn
    ret
ServiceRestartOperation endp

;------------------------------------------------------------------------------
; ServiceControlOperation - послать  сервису управляющий код
;   - hLog - окно логов
;   - hSCManager - хендл SCM
;   - lpServiceName - имя сервиса
;   - dwAccess - права доступа
;   - dwCode - код 
;------------------------------------------------------------------------------
ServiceControlOperation proc hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD, dwCode: DWORD
    LOCAL hService: HANDLE
    LOCAL sStatus:SERVICE_STATUS
    LOCAL dwReturn: DWORD
    LOCAL dwWaitCode: DWORD
    LOCAL lpOperation: LPCSTR

    mov dwReturn, FALSE

    invoke SetLastError, ERROR_SUCCESS
    invoke OpenService, hSCManager, lpServiceName, dwServAccess
    mov hService, eax
    invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
    invoke LogMessage, hLogList, lpServiceName, addr szOperationOpenService, hService, addr szErrorCode, addr szErrorDescription
    
    .if (hService != 0)
        .if (dwCode == SERVICE_CONTROL_STOP)
            mov dwWaitCode, SERVICE_STOPPED
            mov lpOperation, offset szOperationStop
        .elseif (dwCode == SERVICE_CONTROL_PAUSE)
            mov dwWaitCode, SERVICE_PAUSED
            mov lpOperation, offset szOperationPauseService
        .elseif (dwCode == SERVICE_CONTROL_CONTINUE)
            mov dwWaitCode, SERVICE_RUNNING
            mov lpOperation, offset szOperationResumeService
        .else
            xor eax, eax
            dec eax
            mov dwWaitCode, eax
            mov lpOperation, offset szOperationControlService
        .endif
    
        invoke SetLastError, ERROR_SUCCESS
        invoke ControlService, hService, dwCode, addr sStatus
        mov dwReturn, eax
        invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
        invoke LogMessage, hLogList, lpServiceName, lpOperation, dwReturn, addr szErrorCode, addr szErrorDescription
        
        .if (dwReturn != 0)
            invoke WaitForServiceState, hService, SERVICE_STOPPED, addr sStatus, SERV_WAIT_TIMEOUT
        .endif
        
        invoke CloseServiceHandle, hService
    .endif

    mov eax, dwReturn
    ret
ServiceControlOperation endp

;------------------------------------------------------------------------------
; ServiceDeleteOperation - удалить  сервис
;   - hLog - окно логов
;   - hSCManager - хендл SCM
;   - lpServiceName - имя сервиса
;   - dwAccess - права доступа
;------------------------------------------------------------------------------
ServiceDeleteOperation proc hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
    LOCAL hService: HANDLE
    LOCAL sStatus:SERVICE_STATUS
    LOCAL dwReturn: DWORD

    mov dwReturn, FALSE

    invoke SetLastError, ERROR_SUCCESS
    invoke OpenService, hSCManager, lpServiceName, dwServAccess
    mov hService, eax
    invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
    invoke LogMessage, hLogList, lpServiceName, addr szOperationOpenService, hService, addr szErrorCode, addr szErrorDescription
    
    .if (hService != 0)        
        invoke SetLastError, ERROR_SUCCESS
        invoke DeleteService,hService
        mov dwReturn, eax
        invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
        invoke LogMessage, hLogList, lpServiceName, addr szOperationDeleteService, dwReturn, addr szErrorCode, addr szErrorDescription

        invoke CloseServiceHandle, hService
    .endif

    mov eax, dwReturn
    ret
ServiceDeleteOperation endp

end
