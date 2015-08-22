;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      controlservicedlg.asm 
; Описание:  диалоговое окно "Управление сервисом"
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

title  ControlServiceDlg

.386
.model flat,stdcall
option casemap:none

include ..\..\Masm32\include\windows.inc
include ..\..\Masm32\include\kernel32.inc
include ..\..\Masm32\include\user32.inc
include ..\..\Masm32\include\comdlg32.inc
include ..\..\Masm32\include\advapi32.inc

include res.inc
include global.inc
include main.inc
include memory.inc
include services.inc
include servicedlg.inc
include controlservicedlg.inc
include log.inc

.data
    szDialogCaptionControl db 'Управление сервисом ' 
    szDCName              db  SERV_NAME_LEN dup (0)

.data?
    szServDataBuffer db TMP_BUF_SIZE dup(?)

.code
;------------------------------------------------------------------------------
; ServiceControlDialogFunc - Процедура диалогового окна Управление сервисом
;   - hWnd - хэндл окна
;   - uMsg - сообщение
;   - wParam - первый параметр сообщения
;   - lParam - второй параметр сообщения 
;------------------------------------------------------------------------------
ServiceControlDialogFunc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hItem: HWND
    LOCAL lpParam: LPVOID
    LOCAL sStatus:SERVICE_STATUS
    LOCAL dwCode: DWORD
    
    xor eax, eax
    .if (uMsg==WM_INITDIALOG)
        ; сабкласим окно окно ввода 
        invoke GetDlgItem, hWnd, IDC_SCTRL_USERCODE
        mov hItem, eax
        invoke SetWindowLong, hItem, GWL_WNDPROC, addr NumEditWndProc
        invoke SetWindowLong, hItem, GWL_USERDATA, eax

        mov eax, lParam
        mov lpParam, eax
        invoke SetWindowLong, hWnd, GWL_USERDATA, eax
        
        .if (lpParam != 0)
            push ebx
            mov ebx, lpParam
            assume ebx: ptr ServiceDataParam
             
            ; обнулить  статус
            xor eax, eax
            mov [ebx].dwStatus, eax

            mov eax, [ebx].lpdwCount
            inc dword ptr [eax]

            invoke wsprintf, addr szDCName, addr szFmtS, addr [ebx].szServiceName 
            invoke SetWindowText, hWnd, addr szDialogCaptionControl
            
            ; открытие    сервиса
            invoke SetLastError, ERROR_SUCCESS
            invoke OpenService, [ebx].hSCManager, addr [ebx].szServiceName, [ebx].dwDesiredAccess
            mov [ebx].hService, eax
            invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
            invoke LogMessage, [ebx].hLog, addr [ebx].szServiceName, addr szOperationOpenService, [ebx].hService, addr szErrorCode, addr szErrorDescription
    
            .if ([ebx].hService != 0)
                invoke SetLastError, ERROR_SUCCESS
                invoke QueryServiceStatus, [ebx].hService, addr sStatus
                push eax 
                invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
                pop eax
                push eax
                invoke LogMessage, [ebx].hLog, addr [ebx].szServiceName, addr szOperationQueryServiceStatus, eax, addr szErrorCode, addr szErrorDescription
                pop eax
                .if (eax != 0)
                    invoke UpdateStatusControls, hWnd, addr sStatus                    
                .endif
            .endif
            assume ebx: nothing
            pop ebx
        .endif

        xor eax, eax
        inc eax
    .elseif (uMsg== WM_CLOSE)
        invoke CloseDialog, hWnd
    .elseif (uMsg== WM_COMMAND)
        push ebx
        invoke GetWindowLong, hWnd, GWL_USERDATA
        mov ebx, eax
        assume ebx: ptr ServiceDataParam
        
        .if (wParam == IDC_CANCEL)
            invoke CloseDialog, hWnd
        .elseif (wParam == IDC_SCTRL_START)
            .if ([ebx].hService != 0)
                invoke SetLastError, ERROR_SUCCESS
                invoke StartService, [ebx].hService, NULL, NULL
                push eax
                invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
                pop eax
                push eax
                invoke LogMessage, [ebx].hLog, addr [ebx].szServiceName, addr szOperationStart, eax, addr szErrorCode, addr szErrorDescription
                pop eax
        
                .if (eax != 0)
                    invoke WaitForServiceState, [ebx].hService, SERVICE_RUNNING, addr sStatus, SERV_WAIT_TIMEOUT
                    invoke UpdateStatusControls, hWnd, addr sStatus                    
                .endif
            .endif
        .elseif (wParam == IDC_SCTRL_STOP)
            .if ([ebx].hService != 0)
                invoke SetLastError, ERROR_SUCCESS
                invoke ControlService, [ebx].hService, SERVICE_CONTROL_STOP, addr sStatus
                push eax
                invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
                pop eax
                push eax
                invoke LogMessage, [ebx].hLog, addr [ebx].szServiceName, addr szOperationStop, eax, addr szErrorCode, addr szErrorDescription
                pop eax
        
                .if (eax != 0)
                    invoke WaitForServiceState, [ebx].hService, SERVICE_STOPPED, addr sStatus, SERV_WAIT_TIMEOUT
                    invoke UpdateStatusControls, hWnd, addr sStatus                    
                .endif
            .endif
        .elseif (wParam == IDC_SCTRL_PAUSE)
            .if ([ebx].hService != 0)
                invoke SetLastError, ERROR_SUCCESS
                invoke ControlService, [ebx].hService, SERVICE_CONTROL_PAUSE, addr sStatus
                push eax
                invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
                pop eax
                push eax
                invoke LogMessage, [ebx].hLog, addr [ebx].szServiceName, addr szOperationPauseService, eax, addr szErrorCode, addr szErrorDescription
                pop eax
        
                .if (eax != 0)
                    invoke WaitForServiceState, [ebx].hService, SERVICE_PAUSED, addr sStatus, SERV_WAIT_TIMEOUT
                    invoke UpdateStatusControls, hWnd, addr sStatus                    
                .endif
            .endif
        .elseif (wParam == IDC_SCTRL_RESUME)
            .if ([ebx].hService != 0)
                invoke SetLastError, ERROR_SUCCESS
                invoke ControlService, [ebx].hService, SERVICE_CONTROL_CONTINUE, addr sStatus
                push eax
                invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
                pop eax
                push eax
                invoke LogMessage, [ebx].hLog, addr [ebx].szServiceName, addr szOperationResumeService, eax, addr szErrorCode, addr szErrorDescription
                pop eax
        
                .if (eax != 0)
                    invoke WaitForServiceState, [ebx].hService, SERVICE_RUNNING, addr sStatus, SERV_WAIT_TIMEOUT
                    invoke UpdateStatusControls, hWnd, addr sStatus                    
                .endif
            .endif
        .elseif (wParam == IDC_SCTRL_CONTROL)
            .if ([ebx].hService != 0)
                invoke SendDlgItemMessage, hWnd, IDC_SCTRL_USERCODE, WM_GETTEXTLENGTH, 0, 0
                .if (eax !=0)
                    invoke SendDlgItemMessage, hWnd, IDC_SCTRL_USERCODE, WM_GETTEXT, TMP_BUF_SIZE, addr szServDataBuffer
                    mov dwCode, eax
                    invoke GetDwordFromString, addr szServDataBuffer, dwCode
                    mov dwCode, eax
                    
                    invoke SetLastError, ERROR_SUCCESS
                    invoke ControlService, [ebx].hService, dwCode, addr sStatus
                    push eax
                    invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
                    pop eax
                    push eax
                    invoke LogMessage, [ebx].hLog, addr [ebx].szServiceName, addr szOperationControlService, eax, addr szErrorCode, addr szErrorDescription
                    pop eax
        
                    .if (eax != 0)
                        invoke UpdateStatusControls, hWnd, addr sStatus                    
                    .endif
                .endif 
            .endif
        .elseif (wParam == IDC_SCTRL_REFRESH)
            .if ([ebx].hService != 0)
                invoke SetLastError, ERROR_SUCCESS
                invoke QueryServiceStatus, [ebx].hService, addr sStatus
                push eax 
                invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
                pop eax
                push eax
                invoke LogMessage, [ebx].hLog, addr [ebx].szServiceName, addr szOperationQueryServiceStatus, eax, addr szErrorCode, addr szErrorDescription
                pop eax
                .if (eax != 0)
                    invoke UpdateStatusControls, hWnd, addr sStatus                    
                .endif
            .endif
        .endif
        
        assume ebx: nothing
        pop ebx
    .endif

    ret
ServiceControlDialogFunc endp

;------------------------------------------------------------------------------
; CloseDialog - освободить ресурсы и закрыть  диалог 
;   - hWnd - хендл окна
;------------------------------------------------------------------------------
CloseDialog proc hWnd: HWND
    push ebx

    invoke GetWindowLong,hWnd, GWL_USERDATA

    mov ebx, eax
    assume ebx: ptr ServiceDataParam
    
    .if ([ebx].hService != 0)
        invoke CloseServiceHandle, [ebx].hService
    .endif

    mov eax, [ebx].lpdwCount
    dec dword ptr [eax]
    xchg eax, ebx
    assume ebx: nothing
    
    invoke mfree, eax
   
    invoke EndDialog, hWnd, IDC_CANCEL
    pop ebx
    xor eax, eax
    inc eax
    ret
CloseDialog endp

;------------------------------------------------------------------------------
; UpdateStatusControls - Обновить  статусную инфрмацию 
;   - hWnd - хендл окна
;   - lpStatus - статус  сервиса
;------------------------------------------------------------------------------
UpdateStatusControls proc hWnd: HWND, lpStatus: LPVOID

    push ebx
    mov ebx, lpStatus
    assume ebx: ptr SERVICE_STATUS
    
    ; тип  сервиса
    invoke FillBufferFromFlag, [ebx].dwServiceType, addr szServDataBuffer, TMP_BUF_SIZE, addr csServiceType, SERVICE_TYPE_COUNT                 
    invoke SendDlgItemMessage, hWnd, IDC_SCTRL_TYPE, WM_SETTEXT, 0, addr szServDataBuffer
            
    ; статус   сервиса
    invoke FillBufferFromCode, [ebx].dwCurrentState , addr szServDataBuffer, TMP_BUF_SIZE, addr csServiceState, SERVICE_STATE_COUNT
    invoke SendDlgItemMessage, hWnd, IDC_SCTRL_STATUS, WM_SETTEXT, 0, addr szServDataBuffer
    
    invoke wsprintf, addr szServDataBuffer, addr szFmtX, [ebx].dwControlsAccepted
    invoke SendDlgItemMessage, hWnd, IDC_SCTRL_OPERATION, WM_SETTEXT, 0, addr szServDataBuffer
    invoke wsprintf, addr szServDataBuffer, addr szFmtX, [ebx].dwWin32ExitCode
    invoke SendDlgItemMessage, hWnd, IDC_SCTRL_WIN32EXITCODE, WM_SETTEXT, 0, addr szServDataBuffer
    invoke wsprintf, addr szServDataBuffer, addr szFmtX, [ebx].dwServiceSpecificExitCode
    invoke SendDlgItemMessage, hWnd, IDC_SCTRL_SERVEXITCODE, WM_SETTEXT, 0, addr szServDataBuffer
    invoke wsprintf, addr szServDataBuffer, addr szFmtX, [ebx].dwCheckPoint
    invoke SendDlgItemMessage, hWnd, IDC_SCTRL_CHECKPOINT, WM_SETTEXT, 0, addr szServDataBuffer
    invoke wsprintf, addr szServDataBuffer, addr szFmtX, [ebx].dwWaitHint
    invoke SendDlgItemMessage, hWnd, IDC_SCTRL_WAITHINT, WM_SETTEXT, 0, addr szServDataBuffer

    assume ebx: nothing
    pop ebx
    ret
UpdateStatusControls endp

end
