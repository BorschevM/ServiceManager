;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      servicedlg.asm 
; Описание:  диалоговое окно "Свойства сервиса"
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

title  ServiceDlg

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
include memory.inc
include services.inc
include servicedlg.inc
include log.inc

.data
    szServiceFilter db "PE Files (*.exe, *.dll, *.sys)",0,"*.exe;*.dll;*.sys",0,0
    szLocalSystemName db 'LocalSystem', 0
    szShutDownPrivilegeName db 'SeShutdownPrivilege', 0    

    szErrorChange db 'При изменении конфигурации сервиса произошла ощибка.', 0 
    szWarningMessageNoData db 'Заполните все необходимые поля.', 0 
    szWarningMessagePassMismatch db 'Некорректный пароль.', 0 

    tpServiceProperties TabPage<'Общие', IDD_SERV_GENERAL, NULL, ServGeneralDialogFunc, 0>
                                 TabPage<'Учетная запись', IDD_SERV_LOGON, NULL, ServLogonDialogFunc, 0>
                                 TabPage<'Восстановление', IDD_SERV_RECOVERY, NULL, ServRecoveryDialogFunc, 0>
                                 TabPage<'Зависимости', IDD_SERV_DEPENDENCIES, NULL, ServDependenciesDialogFunc, 0>

    szDialogCaptionEdit db 'Свойства сервиса ' 
    szDCName            db  SERV_NAME_LEN dup (0)

.data?
    hTab HWND ?
    
    szServDataBuffer db SERV_DATA_SIZE dup(?)
    szServDataBuffer2 db SERV_DATA_SIZE dup(?)
    
    ofsPath OPENFILENAME <>
    tp TOKEN_PRIVILEGES<>

.code
;------------------------------------------------------------------------------
; ServicePropertiesDialogFunc - Процедура диалогового окна Свойства сервиса
;   - hWnd - хэндл окна
;   - uMsg - сообщение
;   - wParam - первый параметр сообщения
;   - lParam - второй параметр сообщения 
;------------------------------------------------------------------------------
ServicePropertiesDialogFunc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL lpParam: LPVOID
    LOCAL DialogRect: RECT
    LOCAL item: TCITEM
    
    xor eax, eax
    .if (uMsg==WM_INITDIALOG)
        mov eax, lParam
        mov lpParam, eax
        invoke SetWindowLong, hWnd, GWL_USERDATA, eax

        ;сооздаем закладки
        push ebx
        push edi
        
        invoke GetDlgItem, hWnd, IDC_SERV_TAB
        mov hTab, eax
        invoke GetClientRect, hTab, addr DialogRect
        invoke SendMessage, hTab, TCM_ADJUSTRECT, FALSE, addr DialogRect
        invoke MapWindowPoints, hTab, hWnd, addr DialogRect, 2        
        mov eax, DialogRect.left
        sub DialogRect.right, eax
        add DialogRect.top, 18
        mov eax, DialogRect.top
        sub DialogRect.bottom, eax
        
        mov item.imask, TCIF_TEXT

        assume ebx: ptr TabPage
        lea ebx, tpServiceProperties
        xor edi, edi 
        push ebx
        .while (edi < TABPAGE_COUNT)
            lea eax, [ebx].szPageTitle
            mov item.pszText, eax
            invoke SendMessage, hTab, TCM_INSERTITEM, edi, addr item
            invoke CreateDialogParam, hInstance, [ebx].nDialogId, hWnd, [ebx].pFunct, lParam
            mov [ebx].hWnd, eax
            invoke MoveWindow, eax, DialogRect.left, DialogRect.top, DialogRect.right, DialogRect.bottom, TRUE 
            add ebx, sizeof TabPage
            inc edi            
        .endw
        pop ebx
        invoke ShowWindow, [ebx].hWnd,SW_SHOW

        mov ebx, lpParam
        assume ebx: ptr ServiceDataParam
             
        ; обнулить  статус
        xor eax, eax
        mov [ebx].dwStatus, eax
        mov [ebx].dwCancelCode, IDC_CANCEL

        mov eax, [ebx].lpdwCount
        inc dword ptr [eax]

        .if ([ebx].dwMode == DIALOGPARAM_EDIT )
            invoke wsprintf, addr szDCName, addr szFmtS, addr [ebx].szServiceName 
            invoke SetWindowText, hWnd, addr szDialogCaptionEdit
            
            invoke LoadData, hWnd, lpParam
        .endif

        assume ebx: nothing
        pop edi
        pop ebx
        
        xor eax, eax
        inc eax
    .elseif (uMsg== WM_NOTIFY)
        push ebx
        mov ebx, lParam
        assume ebx: ptr NMHDR
        mov eax, [ebx].hwndFrom 
        .if (eax == hTab)
             invoke SendMessage, eax, TCM_GETCURSEL, 0, 0
            .if ([ebx].code == TCN_SELCHANGE)
                xor edx, edx
                mov ebx, sizeof TabPage
                mul ebx
                lea ebx, tpServiceProperties
                add ebx, eax
                invoke ShowWindow, (TabPage ptr [ebx]).hWnd, SW_SHOW
                xor eax, eax
                inc eax
            .elseif ([ebx].code == TCN_SELCHANGING)
                xor edx, edx
                mov ebx, sizeof TabPage
                mul ebx
                lea ebx, tpServiceProperties
                add ebx, eax
                invoke ShowWindow, (TabPage ptr [ebx]).hWnd, SW_HIDE
                xor eax, eax
            .endif
        .endif
        assume ebx: nothing
        pop ebx 
    .elseif (uMsg== WM_CLOSE)
        invoke ServicePropertiesClose, hWnd, IDC_CANCEL
        xor eax, eax
        inc eax
    .elseif (uMsg== WM_COMMAND)
        push ebx
        invoke GetWindowLong, hWnd, GWL_USERDATA
        mov ebx, eax
        assume ebx: ptr ServiceDataParam

        .if (wParam == IDC_OK)
            invoke CheckData, hWnd
            .if (eax != 0)
                invoke SaveData, hWnd, ebx
                .if (eax != 0)
                    invoke ServicePropertiesClose, hWnd, IDC_OK
                .else
                    invoke MessageBox, hWnd, addr szErrorChange , addr szDialogCaptionEdit, MB_ICONERROR or MB_OK
                .endif
            .endif
            xor eax, eax
            inc eax
        .elseif (wParam == IDC_APPLY)
            invoke CheckData, hWnd
            .if (eax != 0)
                invoke SaveData, hWnd, ebx
                .if (eax != 0)
                    mov [ebx].dwCancelCode, IDC_APPLY
                .else
                    invoke MessageBox, hWnd, addr szErrorChange , addr szDialogCaptionEdit, MB_ICONERROR or MB_OK
                .endif
            .endif
            xor eax, eax
            inc eax
        .elseif (wParam == IDC_CANCEL)
            invoke ServicePropertiesClose, hWnd, [ebx].dwCancelCode
            xor eax, eax
            inc eax
        .endif

        assume ebx: nothing
        pop ebx
    .endif

    ret
ServicePropertiesDialogFunc endp

;------------------------------------------------------------------------------
; ServicePropertiesClose - освободить ресурсы и закрыть  диалог 
;   - hWnd - хендл окна
;  - dwResult - код возврата
;------------------------------------------------------------------------------
ServicePropertiesClose proc hWnd: HWND, dwResult: DWORD
    push ebx

    invoke GetWindowLong,hWnd, GWL_USERDATA
    mov ebx, eax
    assume ebx: ptr ServiceDataParam
    mov eax, [ebx].lpdwCount
    dec dword ptr [eax]
    xchg eax, ebx
    assume ebx: nothing
    
    invoke mfree, eax
   
    invoke EndDialog, hWnd, dwResult
    pop ebx
    xor eax, eax
    inc eax
    ret
ServicePropertiesClose endp

;------------------------------------------------------------------------------
; ServGeneralDialogFunc - Процедура закладки общие
;   - hWnd - хэндл окна
;   - uMsg - сообщение
;   - wParam - первый параметр сообщения
;   - lParam - второй параметр сообщения 
;------------------------------------------------------------------------------
ServGeneralDialogFunc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL lpParam: LPVOID
    LOCAL hItem: HWND
    LOCAL lpCompName: LPCSTR

    xor eax, eax
    .if uMsg==WM_INITDIALOG
        mov eax, lParam
        mov lpParam, eax
        invoke SetWindowLong, hWnd, GWL_USERDATA, eax

        invoke GetDlgItem, hWnd, IDC_SG_TAG
        mov hItem, eax
        invoke SetWindowLong, hItem, GWL_WNDPROC, addr NumEditWndProc
        invoke SetWindowLong, hItem, GWL_USERDATA, eax
    
        ; Заполняем комбобоксы
        invoke GetDlgItem, hWnd, IDC_SG_TYPE
        mov hItem, eax
        invoke FillComboBox, hItem, addr csServiceType, SERVICE_TYPE_COUNT-1

        invoke GetDlgItem, hWnd, IDC_SG_STARTTYPE
        mov hItem, eax
        invoke FillComboBox, hItem, addr csServiceStartType, SERVICE_START_TYPE_COUNT

        invoke GetDlgItem, hWnd, IDC_SG_ERRORTYPE
        mov hItem, eax
        invoke FillComboBox, hItem, addr csServiceErrorControl, SERVICE_ERROR_CONTROL_COUNT

        invoke GetDlgItem, hWnd, IDC_SG_GROUP
        mov hItem, eax
        xor eax, eax
        mov lpCompName, eax
        
        push ebx
        mov ebx, lpParam
        assume ebx: ptr ServiceDataParam
        .if ([ebx].cdComp.dwCompFlag != CND_LOCALCOMP)&&([ebx].cdComp.lpCompName != NULL)
            push [ebx].cdComp.lpCompName
            pop lpCompName
        .endif 
        invoke FillOrderGroupCombo, hItem, lpCompName
        assume ebx: nothing
        pop ebx

        xor eax, eax
        inc eax
    .elseif uMsg==WM_COMMAND
        .if (wParam == IDC_SG_PCHANGE)
            mov ofsPath.lStructSize, sizeof ofsPath
            push hWnd
            pop ofsPath.hwndOwner
            push hInstance
            pop ofsPath.hInstance
            mov ofsPath.lpstrFilter, offset  szServiceFilter
            mov ofsPath.nFilterIndex, NULL
            mov ofsPath.lpstrFile, offset szServDataBuffer
            mov ofsPath.nMaxFile, SERV_DATA_SIZE
                    
            invoke GetOpenFileName, addr ofsPath
            .if (eax != 0)
                invoke SendDlgItemMessage, hWnd, IDC_SG_PATH, WM_SETTEXT, 0, addr szServDataBuffer
                    
                xor edx, edx
                lea eax, szServDataBuffer
                mov dx, ofsPath.nFileExtension
                add eax, edx
                dec eax
                mov byte ptr [eax], 0

                invoke SendDlgItemMessage, hWnd, IDC_SG_SNAME, WM_GETTEXTLENGTH, 0, 0
                .if (eax == 0)
                    xor eax, eax
                    lea eax, szServDataBuffer
                    mov dx, ofsPath.nFileOffset
                    add eax, edx
                    invoke SendDlgItemMessage, hWnd, IDC_SG_SNAME, WM_SETTEXT, 0, eax
                .endif

                invoke SendDlgItemMessage, hWnd, IDC_SG_DNAME, WM_GETTEXTLENGTH, 0, 0
                .if (eax == 0)
                    xor eax, eax
                    lea eax, szServDataBuffer
                    mov dx, ofsPath.nFileOffset
                    add eax, edx
                    invoke SendDlgItemMessage, hWnd, IDC_SG_DNAME, WM_SETTEXT, 0, eax
                .endif
            .endif
        .endif
        
        xor eax, eax
        inc eax
    .endif

    ret
ServGeneralDialogFunc endp

;------------------------------------------------------------------------------
; ServLogonDialogFunc - Процедура закладки учетная   запись
;   - hWnd - хэндл окна
;   - uMsg - сообщение
;   - wParam - первый параметр сообщения
;   - lParam - второй параметр сообщения 
;------------------------------------------------------------------------------
ServLogonDialogFunc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hItem: HWND

     xor eax, eax
    .if uMsg==WM_INITDIALOG
        invoke SetWindowLong, hWnd, GWL_USERDATA, lParam
        invoke SendDlgItemMessage, hWnd, IDC_SL_LOCALSYSTEM, BM_SETCHECK, BST_CHECKED, 0
        xor eax, eax
        inc eax
    .elseif uMsg==WM_COMMAND
        mov eax,wParam
        mov edx,eax
        shr edx,16
        .if (dx==BN_CLICKED)
            and eax, 0ffffh
            .if (eax == IDC_SL_LOCALSYSTEM)
                invoke GetDlgItem, hWnd, IDC_SL_ACCOUNT 
                invoke EnableWindow, eax, FALSE
                invoke GetDlgItem, hWnd, IDC_SL_ACHANGE 
                invoke EnableWindow, eax, FALSE
                invoke GetDlgItem, hWnd, IDC_SL_PASS
                invoke EnableWindow, eax, FALSE
                invoke GetDlgItem, hWnd, IDC_SL_CONFIRM 
                invoke EnableWindow, eax, FALSE
            .elseif (eax == IDC_SL_ANOTHER_ACCOUNT)
                invoke GetDlgItem, hWnd, IDC_SL_ACCOUNT 
                invoke EnableWindow, eax, TRUE
                invoke GetDlgItem, hWnd, IDC_SL_ACHANGE 
                invoke EnableWindow, eax, TRUE
                invoke GetDlgItem, hWnd, IDC_SL_PASS
                invoke EnableWindow, eax, TRUE
                invoke GetDlgItem, hWnd, IDC_SL_CONFIRM 
                invoke EnableWindow, eax, TRUE
            .endif
        .endif
    .endif

    ret
ServLogonDialogFunc endp

;------------------------------------------------------------------------------
; ServRecoveryDialogFunc - Процедура закладки востановление
;   - hWnd - хэндл окна
;   - uMsg - сообщение
;   - wParam - первый параметр сообщения
;   - lParam - второй параметр сообщения 
;------------------------------------------------------------------------------
ServRecoveryDialogFunc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hItem: HWND
    LOCAL dwFlags: DWORD
    LOCAL dwState: DWORD

    xor eax, eax
    .if uMsg==WM_INITDIALOG
        invoke SetWindowLong, hWnd, GWL_USERDATA, lParam

        ; Заполняем комбобоксы
        invoke GetDlgItem, hWnd, IDC_SR_FIRST
        mov hItem, eax
        invoke FillComboBox, hItem, addr  csSeviceFailureAcrion, SERVICE_FAILURE_ACTION_COUNT

        invoke GetDlgItem, hWnd, IDC_SR_SECOND
        mov hItem, eax
        invoke FillComboBox, hItem, addr  csSeviceFailureAcrion, SERVICE_FAILURE_ACTION_COUNT

        invoke GetDlgItem, hWnd, IDC_SR_THIRD
        mov hItem, eax
        invoke FillComboBox, hItem, addr  csSeviceFailureAcrion, SERVICE_FAILURE_ACTION_COUNT

        ; сабкласим едитбоксы
        invoke GetDlgItem, hWnd, IDC_SR_FCDELAY
        mov hItem, eax
        invoke SetWindowLong, hItem, GWL_WNDPROC, addr NumEditWndProc
        invoke SetWindowLong, hItem, GWL_USERDATA, eax

        invoke GetDlgItem, hWnd, IDC_SR_SRDELAY
        mov hItem, eax
        invoke SetWindowLong, hItem, GWL_WNDPROC, addr NumEditWndProc
        invoke SetWindowLong, hItem, GWL_USERDATA, eax

        invoke GetDlgItem, hWnd, IDC_SR_CRDELAY
        mov hItem, eax
        invoke SetWindowLong, hItem, GWL_WNDPROC, addr NumEditWndProc
        invoke SetWindowLong, hItem, GWL_USERDATA, eax
        
        ; заполняем данными по умолчанию
        invoke wsprintf, addr szServDataBuffer, addr szFmtD, 0
        invoke SendDlgItemMessage, hWnd, IDC_SR_FCDELAY, WM_SETTEXT, 0, addr szServDataBuffer
        invoke wsprintf, addr szServDataBuffer, addr szFmtD, 1000
        invoke SendDlgItemMessage, hWnd, IDC_SR_CRDELAY , WM_SETTEXT, 0, addr szServDataBuffer
        invoke SendDlgItemMessage, hWnd, IDC_SR_SRDELAY , WM_SETTEXT, 0, addr szServDataBuffer
        
        lea edx, csSeviceFailureAcrion.szString
        invoke wsprintf, addr szServDataBuffer, addr szFmtS, edx
        invoke SendDlgItemMessage, hWnd, IDC_SR_FIRST, CB_FINDSTRING, -1, addr szServDataBuffer
        invoke SendDlgItemMessage, hWnd, IDC_SR_FIRST, CB_SETCURSEL , eax, 0
        invoke SendDlgItemMessage, hWnd, IDC_SR_SECOND, CB_FINDSTRING, -1, addr szServDataBuffer
        invoke SendDlgItemMessage, hWnd, IDC_SR_SECOND, CB_SETCURSEL, eax, 0
        invoke SendDlgItemMessage, hWnd, IDC_SR_THIRD, CB_FINDSTRING, -1, addr szServDataBuffer
        invoke SendDlgItemMessage, hWnd, IDC_SR_THIRD, CB_SETCURSEL, eax, 0

        xor eax, eax
        inc eax
    .elseif uMsg==WM_COMMAND
        mov eax, wParam
        mov edx, eax
        shr edx, 16
        and eax, 0ffffh
        .if (eax == IDC_SR_PCHANGE)
            mov ofsPath.lStructSize, sizeof ofsPath
            push hWnd
            pop ofsPath.hwndOwner
            push hInstance
            pop ofsPath.hInstance
            mov ofsPath.lpstrFilter, offset  szServiceFilter
            mov ofsPath.nFilterIndex, NULL
            mov ofsPath.lpstrFile, offset szServDataBuffer
            mov ofsPath.nMaxFile, SERV_DATA_SIZE
                    
            invoke GetOpenFileName, addr ofsPath
            .if (eax != 0)
                invoke SendDlgItemMessage, hWnd, IDC_SR_PATH, WM_SETTEXT, 0, addr szServDataBuffer
            .endif
        .elseif (eax == IDC_SR_FIRST) || (eax == IDC_SR_SECOND) || (eax == IDC_SR_THIRD)
            .if (edx == CBN_SELCHANGE)
                xor eax, eax
                mov dwFlags, eax
                
                invoke GetDlgItem, hWnd, IDC_SR_FIRST
                invoke GetRecovereActionFromComboBox, eax
                or dwFlags, eax

                invoke GetDlgItem, hWnd, IDC_SR_SECOND
                invoke GetRecovereActionFromComboBox, eax
                or dwFlags, eax
                
                invoke GetDlgItem, hWnd, IDC_SR_THIRD
                invoke GetRecovereActionFromComboBox, eax
                or dwFlags, eax
                
                xor eax, eax
                mov dwState, eax
                push eax
                test dwFlags, RD_RESTARTCOMP 
                .if (!ZERO?)
                    inc dwState
                .endif
                invoke GetDlgItem, hWnd, IDC_SR_CRDELAY
                invoke EnableWindow, eax, dwState
                invoke GetDlgItem, hWnd, IDC_SR_MESSAGE
                invoke EnableWindow, eax, dwState
                
                pop dwState
                push dwState
                test dwFlags, RD_RESTARTSERV 
                .if (!ZERO?)
                    inc dwState
                .endif
                invoke GetDlgItem, hWnd, IDC_SR_SRDELAY
                invoke EnableWindow, eax, dwState
                
                pop dwState
                test dwFlags, RD_RUNPROG 
                .if (!ZERO?)
                    inc dwState
                .endif
                invoke GetDlgItem, hWnd, IDC_SR_PATH
                invoke EnableWindow, eax, dwState
                invoke GetDlgItem, hWnd, IDC_SR_PCHANGE
                invoke EnableWindow, eax, dwState
            .endif
        .endif
        
        xor eax, eax
        inc eax
    .endif

    ret
ServRecoveryDialogFunc endp

;------------------------------------------------------------------------------
; ServDependenciesDialogFunc - Процедура закладки зависимости
;   - hWnd - хэндл окна
;   - uMsg - сообщение
;   - wParam - первый параметр сообщения
;   - lParam - второй параметр сообщения 
;------------------------------------------------------------------------------
ServDependenciesDialogFunc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hItem: HWND
    LOCAL dwIndex: DWORD
    LOCAL dwCount: DWORD
    LOCAL lpCompName: LPCSTR

    xor eax, eax
    .if uMsg==WM_INITDIALOG
        invoke SetWindowLong, hWnd, GWL_USERDATA, lParam

        push ebx
        mov ebx, lParam
        assume ebx: ptr ServiceDataParam

        invoke GetDlgItem, hWnd, IDC_SD_SERVICE
        mov hItem, eax
        invoke FillServicesCombo, hItem, [ebx].hSCManager, [ebx].dwServiceType, SERVICE_STATE_ALL 
        
        invoke GetDlgItem, hWnd, IDC_SD_GROUP
        mov hItem, eax
        xor eax, eax
        mov lpCompName, eax
        .if ([ebx].cdComp.dwCompFlag != CND_LOCALCOMP)&&([ebx].cdComp.lpCompName != NULL)
            push [ebx].cdComp.lpCompName
            pop lpCompName
        .endif 
        invoke FillOrderGroupCombo, hItem, lpCompName
        
        assume ebx: nothing
        pop ebx

        xor eax, eax
        inc eax
    .elseif uMsg==WM_COMMAND
        .if (wParam == IDC_SD_ADD_GROUP)
            invoke SendDlgItemMessage, hWnd, IDC_SD_GROUP, WM_GETTEXT, SERV_DATA_SIZE, addr szServDataBuffer
            .if (eax != 0)
                invoke SendDlgItemMessage, hWnd, IDC_SD_DEPENDENCIES, LB_FINDSTRING, -1, addr szServDataBuffer
                .if (eax == LB_ERR)
                    invoke SendDlgItemMessage, hWnd, IDC_SD_DEPENDENCIES, LB_ADDSTRING, 0, addr szServDataBuffer
                .endif 
            .endif  
            xor eax, eax
            inc eax
        .elseif (wParam == IDC_SD_ADD_SERVICE)
            invoke SendDlgItemMessage, hWnd, IDC_SD_SERVICE, WM_GETTEXT, SERV_DATA_SIZE, addr szServDataBuffer
            .if (eax != 0)
                invoke SendDlgItemMessage, hWnd, IDC_SD_DEPENDENCIES, LB_FINDSTRING, -1, addr szServDataBuffer
                .if (eax == LB_ERR)
                    invoke SendDlgItemMessage, hWnd, IDC_SD_DEPENDENCIES, LB_ADDSTRING, 0, addr szServDataBuffer
                .endif 
            .endif  
            xor eax, eax
            inc eax
        .elseif (wParam == IDC_SD_DEL_SERVICE)
            invoke SendDlgItemMessage, hWnd, IDC_SD_DEPENDENCIES, LB_GETCURSEL, 0, 0
            .if (eax != LB_ERR)
                invoke SendDlgItemMessage, hWnd, IDC_SD_DEPENDENCIES, LB_DELETESTRING, eax, 0
            .endif
        .elseif (wParam == IDC_SD_UP)
            invoke GetDlgItem, hWnd, IDC_SD_DEPENDENCIES
            mov hItem, eax
            invoke SendMessage, hItem, LB_GETCURSEL, 0, 0
            .if (eax != LB_ERR)&&(eax > 0)
                mov dwIndex, eax
                invoke SendMessage, hItem, LB_GETTEXT, dwIndex, addr szServDataBuffer
                invoke SendMessage, hItem, LB_DELETESTRING, dwIndex, 0
                dec dwIndex
                invoke SendMessage, hItem, LB_INSERTSTRING, dwIndex, addr szServDataBuffer
                invoke SendMessage, hItem, LB_SETCURSEL, eax, 0
            .endif
        .elseif (wParam == IDC_SD_DOWN)
            invoke GetDlgItem, hWnd, IDC_SD_DEPENDENCIES
            mov hItem, eax
            invoke SendMessage, hItem, LB_GETCOUNT, 0, 0
            dec eax
            mov dwCount, eax
            invoke SendMessage, hItem, LB_GETCURSEL, 0, 0
            .if (eax != LB_ERR)&&(eax < dwCount)
                mov dwIndex, eax
                invoke SendMessage, hItem, LB_GETTEXT, dwIndex, addr szServDataBuffer
                invoke SendMessage, hItem, LB_DELETESTRING, dwIndex, 0
                inc dwIndex
                invoke SendMessage, hItem, LB_INSERTSTRING, dwIndex, addr szServDataBuffer
                invoke SendMessage, hItem, LB_SETCURSEL, eax, 0
            .endif
        .endif
    .endif

    ret
ServDependenciesDialogFunc endp

;------------------------------------------------------------------------------
; NumEditWndProc - оконная процедура EditBox'а для ввода тольк  цифк
;   - hWnd - хэндл окна
;   - uMsg - сообщение
;   - wParam - первый параметр сообщения
;   - lParam - второй параметр сообщения 
;------------------------------------------------------------------------------
NumEditWndProc proc hWnd:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
    LOCAL pOldProc: DWORD

    invoke GetWindowLong, hWnd, GWL_USERDATA
    mov pOldProc, eax
    
    .if uMsg==WM_CHAR
        mov eax,wParam
        .if  ( al >= '0' && al <= '9') || (al == VK_BACK)
            invoke CallWindowProc, pOldProc, hWnd, uMsg, eax, lParam
            ret
        .endif
    .else
       invoke CallWindowProc, pOldProc,hWnd, uMsg, wParam, lParam
       ret
    .endif
    
    xor eax,eax
    ret
NumEditWndProc endp

;------------------------------------------------------------------------------
; FillComboBox - заполнить   комбобокс 
;   - hCombo - хендл комбобокса
;   - lpCodeString - массив строк
;   - nSize - размер массива
;------------------------------------------------------------------------------
FillComboBox proc hCombo: HWND, lpCodeString: LPVOID, nSize: DWORD
    LOCAL dwIndex: DWORD
        
    push ebx
    push ecx
    
    mov ebx, lpCodeString
    mov ecx, nSize
    assume ebx: ptr CodeString
    
    FCL:
    push ecx
    lea eax, [ebx].szString
    invoke SendMessage, hCombo, CB_ADDSTRING, 0, eax
    invoke SendMessage, hCombo, CB_SETITEMDATA , eax, [ebx].dwCode
    add ebx, sizeof CodeString
    pop ecx
    loop FCL
    assume ebx: nothing
    
    pop ecx
    pop ebx
    ret
FillComboBox endp 

;------------------------------------------------------------------------------
; GetRecovereActionFromComboBox - получить  флаг   
;   - hCombo - хендл комбобокса
;------------------------------------------------------------------------------
GetRecovereActionFromComboBox proc hCombo: HWND
    invoke SendMessage, hCombo, CB_GETCURSEL , 0, 0
    invoke SendMessage, hCombo, CB_GETITEMDATA , eax, 0
    
    .if (eax == SC_ACTION_RESTART)
        mov eax, RD_RESTARTSERV
    .elseif (eax == SC_ACTION_REBOOT)
        mov eax, RD_RESTARTCOMP 
    .elseif (eax == SC_ACTION_RUN_COMMAND)
        mov eax, RD_RUNPROG
    .else 
        xor eax, eax        
    .endif
    ret
GetRecovereActionFromComboBox endp 

;------------------------------------------------------------------------------
; FillDependenciesList - Заполнить список зависимостей
;   - hList - список
;   - lpBuffer - данные
;   - dwSize - размер данных
;------------------------------------------------------------------------------
FillDependenciesList proc hList:HWND, lpBuffer: LPCSTR, dwSize: DWORD
    pushad
    
    .if (lpBuffer != NULL)
        mov edi, lpBuffer
        mov ecx, dwSize
        .while (byte ptr [edi] != 0)
            xor eax, eax
            mov esi, edi
            repnz scasb
            push ecx
            invoke SendMessage, hList, LB_ADDSTRING, 0, esi
            pop ecx
        .endw
    .endif
    popad
     
    ret
FillDependenciesList endp

;------------------------------------------------------------------------------
; SetFailureAction - заполнить  комбобокс и связанные с ним контролы   даннями о сбое
;   - hWnd - хендл диалога
;   - dwControl - идентификатор    комбобокса
;   - dwType - тип  действия
;   - dwDelay - задерка
;------------------------------------------------------------------------------
SetFailureAction proc hWnd:HWND, dwControl: DWORD, dwType: DWORD, dwDelay: DWORD
    LOCAL hItem: HWND
    pushad
    
    .if (dwType != SC_ACTION_NONE)
        invoke wsprintf, addr szServDataBuffer, addr szFmtD, dwDelay

        mov eax, dwType
        .if (eax == SC_ACTION_RESTART)
            invoke SendDlgItemMessage, hWnd, IDC_SR_SRDELAY, WM_SETTEXT, 0, addr szServDataBuffer 
        .elseif (eax == SC_ACTION_REBOOT)
            invoke SendDlgItemMessage, hWnd, IDC_SR_CRDELAY, WM_SETTEXT, 0, addr szServDataBuffer 
        .endif
    .endif
    
    invoke FillBufferFromCode, dwType, addr szServDataBuffer, SERV_DATA_SIZE, addr csSeviceFailureAcrion, SERVICE_FAILURE_ACTION_COUNT
    invoke GetDlgItem, hWnd, dwControl
    mov hItem, eax
    invoke SendMessage, hItem, CB_FINDSTRING, -1, addr szServDataBuffer
    invoke SendMessage, hItem, CB_SETCURSEL, eax, 0

    mov edx, CBN_SELCHANGE
    shl edx, 16
    mov eax, dwControl
    mov dx, ax
    invoke SendMessage, hWnd, WM_COMMAND, edx, hItem
    
    popad 
    ret
SetFailureAction endp

;------------------------------------------------------------------------------
; SetFailureAction - заполнить  комбобокс и связанные с ним контролы   даннями о сбое
;   - hWnd - хендл диалога
;   - lpParam - глобальные данные диалога
;   - dwControl - идентификатор    комбобокса
;   - lpAction - адрес FailureAction
;------------------------------------------------------------------------------
GetFailureAction proc hWnd:HWND, lpParam: LPVOID, dwControl: DWORD, lpAction: LPVOID
    LOCAL lpComp: LPVOID
    LOCAL dwReturn: DWORD

    push ebx
    push esi
    
    xor eax, eax
    mov dwReturn, eax

    mov ebx, lpParam
    assume ebx: ptr ServiceDataParam
    .if ([ebx].cdComp.dwCompFlag != CND_LOCALCOMP)
        mov eax, [ebx].cdComp.lpCompName
    .else
        xor eax, eax
    .endif
    mov lpComp, eax

    invoke SendDlgItemMessage, hWnd, dwControl, CB_GETCURSEL, 0, 0
    invoke SendDlgItemMessage, hWnd, dwControl, CB_GETITEMDATA, eax, 0

    mov ebx, lpAction    
    assume ebx: ptr SC_ACTION
    mov [ebx].dwActionType, eax
    .if (eax == SC_ACTION_RESTART)
        mov dwControl, IDC_SR_SRDELAY
    .elseif (eax == SC_ACTION_REBOOT)
        mov dwControl, IDC_SR_CRDELAY
        invoke SetTokenPrivilege, lpComp, addr tp, addr szShutDownPrivilegeName        
    .else
        xor eax, eax
        mov dwControl, eax
    .endif
            
    xor eax, eax                             
    .if (dwControl != 0)
        invoke SendDlgItemMessage, hWnd, dwControl, WM_GETTEXTLENGTH, 0, 0
        mov esi, eax
        .if (esi != 0)
            invoke SendDlgItemMessage, hWnd, dwControl, WM_GETTEXT,  SERV_DATA_SIZE, addr szServDataBuffer
            invoke GetDwordFromString, addr szServDataBuffer, esi
        .endif
    .endif
    mov [ebx].dwDelay, eax
    inc dwReturn

    assume ebx: nothing
    pop esi
    pop ebx
    mov eax, dwReturn
    ret
GetFailureAction endp

;------------------------------------------------------------------------------
; LoadData - загрузить  данные и заполнить  контролы   
;  - hWnd - хендл диалогового окна   
;  - lpParam - глобальные данные диалога
;------------------------------------------------------------------------------
LoadData proc hWnd: HWND, lpParam: LPVOID
    LOCAL hDialog: HWND
    LOCAL hItem: HWND
    LOCAL dwControl: DWORD
    LOCAL dwBytes: DWORD
    LOCAL dwServiceCount: DWORD
    LOCAL dwReturn: DWORD

    pushad

    mov esi, lpParam
    assume esi: ptr ServiceDataParam
        
    ; открытие    сервиса
    invoke SetLastError, ERROR_SUCCESS
    invoke OpenService, [esi].hSCManager, addr [esi].szServiceName, [esi].dwDesiredAccess
    mov [esi].hService, eax
    invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
    invoke LogMessage, [esi].hLog, addr [esi].szServiceName, addr szOperationOpenService, [esi].hService, addr szErrorCode, addr szErrorDescription
    
    .if ([esi].hService != 0)
        ; заполнение контролов  информацией
        invoke SetLastError, ERROR_SUCCESS
        xor eax, eax
        mov edi, 5
        .while (eax == 0)&&(edi > 0)
            push dwConfigInfoSize
            pop dwBytes
            invoke QueryServiceConfig, [esi].hService, pConfigInfo, dwConfigInfoSize, addr dwBytes
            push eax
            .if (eax == 0)
                invoke GetLastError
               .if (eax == ERROR_INSUFFICIENT_BUFFER)
                    mov eax, dwBytes
                    invoke realloc, pConfigInfo, eax
                    mov pConfigInfo, eax 
                    .if (eax != 0)
                        mov eax, dwBytes
                    .endif
                    mov dwConfigInfoSize, eax
               .else
                    xor edi, edi
                    inc edi 
               .endif
            .endif
            pop eax
            dec edi
        .endw

        mov dwReturn, eax 
        invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
        invoke LogMessage, [esi].hLog, addr [esi].szServiceName, addr szOperationQueryServiceConfig, dwReturn, addr szErrorCode, addr szErrorDescription

        .if (dwReturn != 0)
            mov eax, tpServiceProperties.hWnd
            mov hDialog, eax
    
            mov ebx, pConfigInfo
            assume ebx: ptr QUERY_SERVICE_CONFIG
             
            invoke SendDlgItemMessage, hDialog, IDC_SG_SNAME, WM_SETTEXT, 0, addr [esi].szServiceName
            mov eax, [ebx].lpDisplayName
            .if (eax != NULL)
                invoke SendDlgItemMessage, hDialog, IDC_SG_DNAME, WM_SETTEXT, 0, eax
            .endif 
            mov eax, [ebx].lpBinaryPathName
            .if (eax != NULL)
                invoke SendDlgItemMessage, hDialog, IDC_SG_PATH, WM_SETTEXT, 0, eax
            .endif
            
            mov eax, [ebx].dwServiceType
            and eax, SERVICE_INTERACTIVE_PROCESS
            .if (!ZERO?)
                mov eax, BST_CHECKED
            .elseif
                mov eax, BST_UNCHECKED
            .endif
            invoke SendDlgItemMessage, hDialog, IDC_SG_INTERACTIVFLAG, BM_SETCHECK, eax, 0
            
            mov eax, SERVICE_INTERACTIVE_PROCESS
            not eax
            and eax, [ebx].dwServiceType
            invoke FillBufferFromCode, eax, addr  szServDataBuffer, SERV_DATA_SIZE, addr csServiceType, SERVICE_TYPE_COUNT-1
            invoke SendDlgItemMessage, hDialog, IDC_SG_TYPE,CB_FINDSTRING, -1, addr szServDataBuffer
            invoke SendDlgItemMessage, hDialog, IDC_SG_TYPE,CB_SETCURSEL, eax, 0

            invoke FillBufferFromCode, [ebx].dwStartType, addr  szServDataBuffer, SERV_DATA_SIZE, addr csServiceStartType, SERVICE_START_TYPE_COUNT
            invoke SendDlgItemMessage, hDialog, IDC_SG_STARTTYPE,CB_FINDSTRING, -1, addr szServDataBuffer
            invoke SendDlgItemMessage, hDialog, IDC_SG_STARTTYPE,CB_SETCURSEL, eax, 0

            invoke FillBufferFromCode, [ebx].dwErrorControl, addr  szServDataBuffer, SERV_DATA_SIZE, addr csServiceErrorControl, SERVICE_ERROR_CONTROL_COUNT
            invoke SendDlgItemMessage, hDialog, IDC_SG_ERRORTYPE,CB_FINDSTRING, -1, addr szServDataBuffer
            invoke SendDlgItemMessage, hDialog, IDC_SG_ERRORTYPE,CB_SETCURSEL, eax, 0
             
            mov eax, [ebx].lpLoadOrderGroup
            .if (eax != NULL)
                invoke SendDlgItemMessage, hDialog, IDC_SG_GROUP,CB_FINDSTRING, -1, eax
                invoke SendDlgItemMessage, hDialog, IDC_SG_GROUP,CB_SETCURSEL, eax, 0
            .endif

            .if ([ebx].dwTagId != 0) 
                invoke wsprintf, addr szServDataBuffer, addr szFmtD, [ebx].dwTagId 
                invoke SendDlgItemMessage, hDialog, IDC_SG_TAG, WM_SETTEXT, 0, addr szServDataBuffer
            .endif

            ; Учетная  запись
            lea eax, tpServiceProperties
            add eax, sizeof TabPage
            push (TabPage ptr[eax]).hWnd
            pop hDialog
            mov eax, [ebx].lpServiceStartName
            .if (eax != NULL) && (byte ptr [eax] != 0)
                push eax
                .if (eax != 0)
                    invoke lstrcmpi, addr szLocalSystemName, eax
                .else
                    inc eax
                .endif
                pop edx
                .if (eax != 0)
                    invoke SendDlgItemMessage, hDialog, IDC_SL_ACCOUNT, WM_SETTEXT, 0, edx
                    invoke SendDlgItemMessage, hDialog, IDC_SL_ANOTHER_ACCOUNT, BM_CLICK, 0, 0
                .endif
            .endif 

            ; Зависимости
            lea eax, tpServiceProperties
            add eax, 3*(sizeof TabPage)
            push (TabPage ptr[eax]).hWnd
            pop hDialog
                    
            invoke GetDlgItem, hDialog, IDC_SD_DEPENDENCIES
            mov hItem, eax
            mov eax, [ebx].lpDependencies
            .if (eax != NULL)
                invoke FillDependenciesList, hItem, eax, -1
            .endif 
            
            assume ebx: nothing 
        .elseif
            or [esi].dwStatus, QD_QUERYCONFIG 
        .endif

        invoke SetLastError, ERROR_SUCCESS
        xor eax, eax
        mov edi, 5
        .while (eax == 0)&&(edi > 0)
            push dwFailureInfoSize
            pop dwBytes
            invoke QueryServiceConfig2W, [esi].hService, SERVICE_CONFIG_FAILURE_ACTIONS, pFailureInfo, dwFailureInfoSize, addr dwBytes
            push eax
            .if (eax == 0)
                invoke GetLastError
               .if (eax == ERROR_INSUFFICIENT_BUFFER)
                    mov eax, dwBytes
                    invoke realloc, pFailureInfo, eax
                    mov pFailureInfo, eax 
                    .if (eax != 0)
                        mov eax, dwBytes
                    .endif
                    mov dwFailureInfoSize, eax
               .else
                    xor edi, edi
                    inc edi 
               .endif
            .endif
            pop eax
            dec edi
        .endw

        mov dwReturn, eax 
        invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
        invoke LogMessage, [esi].hLog, addr [esi].szServiceName, addr szOperationQueryServiceConfig, dwReturn, addr szErrorCode, addr szErrorDescription

        .if (dwReturn != 0)
            lea eax, tpServiceProperties
            add eax, 2*(sizeof TabPage)
            push (TabPage ptr[eax]).hWnd
            pop hDialog
    
            mov ebx, pFailureInfo
            assume ebx: ptr SERVICE_FAILURE_ACTIONS
        
            mov eax, [ebx].lpCommand
            .if (eax != NULL)
                invoke SendDlgItemMessageW, hDialog, IDC_SR_PATH, WM_SETTEXT, 0, eax
            .endif

            mov eax, [ebx].lpRebootMsg
            .if (eax != NULL)
                invoke SendDlgItemMessageW, hDialog, IDC_SR_MESSAGE, WM_SETTEXT, 0, eax
            .endif
        
            invoke wsprintf, addr szServDataBuffer, addr szFmtD, [ebx].dwResetPeriod        
            invoke SendDlgItemMessage, hDialog, IDC_SR_FCDELAY, WM_SETTEXT, 0, addr szServDataBuffer

            mov edi, [ebx].cActions
            mov ebx, [ebx].lpsaActions
            .if (edi > 3)
                mov edi, 3
            .endif
            mov dwControl, IDC_SR_FIRST
            assume ebx: ptr SC_ACTION   
                      
            .while (edi != 0) && (ebx != NULL)
                invoke SetFailureAction, hDialog, dwControl, [ebx].dwActionType, [ebx].dwDelay
                add ebx, sizeof SC_ACTION
                inc dwControl
                dec edi
            .endw

            assume ebx: nothing
        .elseif
            or [esi].dwStatus, QD_QUERYFAILURE 
        .endif

        invoke SetLastError, ERROR_SUCCESS
        xor eax, eax
        mov edi, 5
        .while (eax == 0)&&(edi > 0)
            push dwConfigInfoSize
            pop dwBytes
            invoke QueryServiceConfig2, [esi].hService, SERVICE_CONFIG_DESCRIPTION, pDescriptionInfo, dwDescriptionInfoSize, addr dwBytes
            push eax
            .if (eax == 0)
                invoke GetLastError
               .if (eax == ERROR_INSUFFICIENT_BUFFER)
                    mov eax, dwBytes
                    invoke realloc, pDescriptionInfo, eax
                    mov pDescriptionInfo, eax 
                    .if (eax != 0)
                        mov eax, dwBytes
                    .endif
                    mov dwDescriptionInfoSize, eax
               .else
                    xor edi, edi
                    inc edi 
               .endif
            .endif
            pop eax
            dec edi
        .endw

        mov dwReturn, eax 
        invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
        invoke LogMessage, [esi].hLog, addr [esi].szServiceName, addr szOperationQueryServiceConfig, dwReturn, addr szErrorCode, addr szErrorDescription

        .if (dwReturn != 0)
            mov eax, tpServiceProperties.hWnd
            mov hDialog, eax

            mov ebx, pDescriptionInfo
            assume ebx: ptr SERVICE_DESCRIPTION

            mov eax, [ebx].lpDescription
            .if (eax != NULL)
                invoke SendDlgItemMessage, hDialog, IDC_SG_DESCRIPTION, WM_SETTEXT, 0, eax
            .endif 

            assume ebx: nothing
        .elseif
            or [esi].dwStatus, QD_QUERYDESCRIPTION 
        .endif
        
        invoke CloseServiceHandle, [esi].hService
    .elseif
        or [esi].dwStatus, QD_OPEN
        xor eax, eax
        mov dwReturn, eax 
    .endif
    
    assume esi: nothing
    
    popad
    mov eax, dwReturn 
    ret
LoadData endp

;------------------------------------------------------------------------------
; SaveData - сохранить  данные   
;   - hWnd - хендл диалогового окна   
;   - lpParam - глобальные данные диалога
;------------------------------------------------------------------------------
SaveData proc hWnd: HWND, lpParam: LPVOID
    LOCAL hDialog: HWND
    LOCAL dwReturn: DWORD
    LOCAL dwGetDataFlag: DWORD

    xor eax, eax
    mov dwReturn, eax
    pushad
    
    mov esi, lpParam
    assume esi: ptr ServiceDataParam
    
    invoke GetGeneralData, addr pConfigInfo, addr dwConfigInfoSize
    mov dwGetDataFlag, eax
     
    .if ([esi].dwMode == DIALOGPARAM_NEW)
        ; создание нового сервиса
        .if (dwGetDataFlag != 0)
            mov eax, tpServiceProperties.hWnd
            mov hDialog, eax
            invoke SendDlgItemMessage, hDialog, IDC_SG_SNAME, WM_GETTEXT,  SERV_NAME_LEN, addr [esi].szServiceName
            
            mov ebx, pConfigInfo
            assume ebx: ptr CHANGE_SERVICE_CONFIG
            invoke CreateService, [esi].hSCManager, addr [esi].szServiceName, [ebx].lpDisplayName, [esi].dwDesiredAccess, [ebx].dwServiceType, [ebx].dwStartType, [ebx].dwErrorControl, [ebx].lpBinaryPathName, [ebx].lpLoadOrderGroup, NULL, [ebx].lpDependencies, [ebx].lpServiceStartName, [ebx].lpPass
            mov [esi].hService, eax
            .if (eax != 0)
                mov [esi].dwMode, DIALOGPARAM_EDIT
                inc dwReturn
            .endif
            invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
            invoke LogMessage, [esi].hLog, addr [esi].szServiceName, addr szOperationCrateService, [esi].hService, addr szErrorCode, addr szErrorDescription
            
            assume ebx: nothing
        .else
            xor eax, eax
            mov [esi].hService, eax
        .endif
    .elseif
        test [esi].dwStatus, QD_OPEN
        .if (ZERO?)
            ; изменение существующего
            invoke SetLastError, ERROR_SUCCESS
            invoke OpenService, [esi].hSCManager, addr [esi].szServiceName, [esi].dwDesiredAccess
            mov [esi].hService, eax
            invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
            invoke LogMessage, [esi].hLog, addr [esi].szServiceName, addr szOperationOpenService, [esi].hService, addr szErrorCode, addr szErrorDescription
            
            test [esi].dwStatus, QD_QUERYCONFIG
            .if (ZERO?) && (dwGetDataFlag != 0)
                mov ebx, pConfigInfo
                assume ebx: ptr CHANGE_SERVICE_CONFIG
                
                xor eax, eax
                .if (dwGetDataFlag != 0)
                    invoke ChangeServiceConfig, [esi].hService, [ebx].dwServiceType, [ebx].dwStartType, [ebx].dwErrorControl, [ebx].lpBinaryPathName, [ebx].lpLoadOrderGroup, NULL, [ebx].lpDependencies, [ebx].lpServiceStartName, [ebx].lpPass, [ebx].lpDisplayName
                .endif
                .if (eax != 0)
                    inc dwReturn
                .endif
                mov dwGetDataFlag, eax
                invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
                invoke LogMessage, [esi].hLog, addr [esi].szServiceName, addr szOperationChangeServiceConfig, dwGetDataFlag, addr szErrorCode, addr szErrorDescription
                
                assume ebx: nothing
            .elseif
                invoke CloseServiceHandle, [esi].hService
                xor eax, eax 
                mov [esi].hService, eax
            .endif
        .else
            xor eax, eax 
            mov [esi].hService, eax
        .endif    
    .endif
    
    .if ([esi].hService != 0)
        ; обновление параметров   востановления
        test [esi].dwStatus, QD_QUERYFAILURE
        .if (ZERO?)
            invoke GetDescriptionData, addr pDescriptionInfo, addr dwDescriptionInfoSize
            .if (eax != 0)
                invoke ChangeServiceConfig2, [esi].hService, SERVICE_CONFIG_DESCRIPTION, pDescriptionInfo        
            .endif    
            mov dwGetDataFlag, eax
            invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
            invoke LogMessage, [esi].hLog, addr [esi].szServiceName, addr szOperationChangeServiceConfig, dwGetDataFlag, addr szErrorCode, addr szErrorDescription
        .endif
        
        ; обновление описания
        test [esi].dwStatus, QD_QUERYDESCRIPTION
        .if (ZERO?)
            invoke GetFailureData, addr pFailureInfo, addr dwFailureInfoSize
            .if (eax != 0)
                invoke ChangeServiceConfig2, [esi].hService, SERVICE_CONFIG_FAILURE_ACTIONS, pFailureInfo        
            .endif    
            mov dwGetDataFlag, eax
            invoke GetLastErrorString, addr szErrorDescription, ERROR_DESC_SIZE, addr szErrorCode, ERROR_CODE_SIZE
            invoke LogMessage, [esi].hLog, addr [esi].szServiceName, addr szOperationChangeServiceConfig, dwGetDataFlag, addr szErrorCode, addr szErrorDescription
        .endif
        
        invoke CloseServiceHandle, [esi].hService
    .endif
    
    assume esi: nothing
    
    popad
    mov eax, dwReturn
    ret
SaveData endp

;------------------------------------------------------------------------------
; GetGeneralData - заполнить  буфер общими данными сервиса
;  - lplpBuffer - указатель  на указатель  буфер для хранения данных
;  - lpdwBufferSize - размер буфера   
;------------------------------------------------------------------------------
GetGeneralData proc lplpBuffer: LPVOID, lpdwBufferSize: LPDWORD
    LOCAL hDialog: HWND
    LOCAL dwSize: DWORD
    LOCAL lpBuffer: LPVOID
    LOCAL dwReturn: DWORD

    pushad
    ; расчет  необходимого размера буфера
    mov eax, lplpBuffer
    mov eax, [eax]
    mov lpBuffer, eax
    
    mov eax, tpServiceProperties.hWnd
    mov hDialog, eax

    mov ebx, sizeof CHANGE_SERVICE_CONFIG
    add ebx, 2*LSA_NAME_LEN
    invoke SendDlgItemMessage, hDialog, IDC_SG_DNAME, WM_GETTEXTLENGTH, 0, 0
    add ebx, eax
    inc ebx
    invoke SendDlgItemMessage, hDialog, IDC_SG_PATH, WM_GETTEXTLENGTH, 0, 0
    add ebx, eax
    inc ebx
    invoke SendDlgItemMessage, hDialog, IDC_SG_GROUP, WM_GETTEXTLENGTH, 0, 0
    add ebx, eax
    inc ebx
    
    lea eax, tpServiceProperties
    add eax, sizeof TabPage
    push (TabPage ptr[eax]).hWnd
    pop hDialog
    invoke SendDlgItemMessage, hDialog, IDC_SL_ACCOUNT, WM_GETTEXTLENGTH, 0, 0
    add ebx, eax
    inc ebx
    invoke SendDlgItemMessage, hDialog, IDC_SL_PASS, WM_GETTEXTLENGTH, 0, 0
    add ebx, eax
    inc ebx

    lea eax, tpServiceProperties
    add eax, 3*(sizeof TabPage)
    push (TabPage ptr[eax]).hWnd
    pop hDialog
    invoke SendDlgItemMessage, hDialog, IDC_SD_DEPENDENCIES, LB_GETCOUNT, 0, 0
    mov ecx, eax
    .while (ecx != 0)
        dec ecx    
        push ecx
        invoke SendDlgItemMessage, hDialog, IDC_SD_DEPENDENCIES, LB_GETTEXTLEN, ecx, 0
        add ebx, eax
        inc ebx
        pop ecx
    .endw
    inc ebx
    inc ebx
    mov dwSize, ebx

    mov eax, [lpdwBufferSize]
    .if (ebx > eax)
        invoke realloc, lpBuffer, ebx
        mov lpBuffer, eax
        mov ebx, lplpBuffer
        mov [ebx], eax
        mov ebx, lpdwBufferSize
        .if (eax != 0)
            mov eax, dwSize
        .endif
        mov [ebx], eax
    .endif

    .if (lpBuffer != NULL)
        mov ebx, lpBuffer
        assume ebx: ptr CHANGE_SERVICE_CONFIG

        mov eax, tpServiceProperties.hWnd
        mov hDialog, eax

        invoke SendDlgItemMessage, hDialog, IDC_SG_TYPE, CB_GETCURSEL, 0, 0
        invoke SendDlgItemMessage, hDialog, IDC_SG_TYPE, CB_GETITEMDATA, eax, 0
        mov [ebx].dwServiceType, eax

        invoke SendDlgItemMessage, hDialog, IDC_SG_INTERACTIVFLAG, BM_GETCHECK, 0, 0
        .if (eax == BST_CHECKED)
            mov eax, SERVICE_INTERACTIVE_PROCESS
            or [ebx].dwServiceType, eax
        .endif
        
        invoke SendDlgItemMessage, hDialog, IDC_SG_STARTTYPE, CB_GETCURSEL, 0, 0
        invoke SendDlgItemMessage, hDialog, IDC_SG_STARTTYPE, CB_GETITEMDATA, eax, 0
        mov [ebx].dwStartType, eax

        invoke SendDlgItemMessage, hDialog, IDC_SG_ERRORTYPE, CB_GETCURSEL, 0, 0
        invoke SendDlgItemMessage, hDialog, IDC_SG_ERRORTYPE, CB_GETITEMDATA, eax, 0
        mov [ebx].dwErrorControl, eax

        invoke SendDlgItemMessage, hDialog, IDC_SG_TAG, WM_GETTEXTLENGTH, 0, 0
        mov esi, eax
        .if (esi != 0)
            invoke SendDlgItemMessage, hDialog, IDC_SG_TAG, WM_GETTEXT,  SERV_DATA_SIZE, addr szServDataBuffer
            invoke GetDwordFromString, addr szServDataBuffer, esi
        .endif
        mov [ebx].dwTagId, eax
        
        mov edi, ebx
        add edi, sizeof CHANGE_SERVICE_CONFIG
        
        mov [ebx].lpDisplayName, edi
        invoke SendDlgItemMessage, hDialog, IDC_SG_DNAME, WM_GETTEXTLENGTH, 0, 0
        mov esi, eax
        .if (esi != 0)
            inc esi
            invoke SendDlgItemMessage, hDialog, IDC_SG_DNAME, WM_GETTEXT,  esi, edi
            add edi, esi
        .else
            xor eax, eax
            stosb    
        .endif
        
        mov [ebx].lpBinaryPathName, edi
        invoke SendDlgItemMessage, hDialog, IDC_SG_PATH, WM_GETTEXTLENGTH, 0, 0
        mov esi, eax
        .if (esi != 0)
            inc esi
            invoke SendDlgItemMessage, hDialog, IDC_SG_PATH, WM_GETTEXT,  esi, edi
            add edi, esi
        .else
            xor eax, eax
            stosb    
        .endif
        
        mov [ebx].lpLoadOrderGroup, edi
        invoke SendDlgItemMessage, hDialog, IDC_SG_GROUP, WM_GETTEXTLENGTH, 0, 0
        mov esi, eax
        .if (esi != 0)
            inc esi
            invoke SendDlgItemMessage, hDialog, IDC_SG_GROUP, WM_GETTEXT,  esi, edi
            add edi, esi
        .elseif
            xor eax, eax
            stosb    
        .endif

        ; учетная запись        
        lea eax, tpServiceProperties
        add eax, sizeof TabPage
        push (TabPage ptr[eax]).hWnd
        pop hDialog

        mov [ebx].lpServiceStartName, edi
        invoke SendDlgItemMessage, hDialog, IDC_SL_ACCOUNT, WM_GETTEXTLENGTH, 0, 0
        mov esi, eax
        invoke SendDlgItemMessage, hDialog, IDC_SL_LOCALSYSTEM, BM_GETCHECK, NULL, NULL
        .if (eax != BST_CHECKED) && (esi != 0) 
            inc esi
            invoke SendDlgItemMessage, hDialog, IDC_SL_ACCOUNT, WM_GETTEXT,  esi, edi
            add edi, esi
            
            mov [ebx].lpPass, edi
            invoke SendDlgItemMessage, hDialog, IDC_SL_PASS, WM_GETTEXTLENGTH, 0, 0
            mov esi, eax
            .if (esi != 0)
                inc esi
                invoke SendDlgItemMessage, hDialog, IDC_SL_PASS, WM_GETTEXT,  esi, edi
                add edi, esi
            .else
                xor eax, eax
                stosb    
            .endif 
        .elseif
            invoke wsprintf, edi, addr szFmtS, addr szLocalSystemName
            add edi, LSA_NAME_LEN
            xor eax, eax
            stosb    
            mov [ebx].lpPass, edi
            stosb    
        .endif
        
        ; зависимости
        lea eax, tpServiceProperties
        add eax, 3*(sizeof TabPage)
        push (TabPage ptr[eax]).hWnd
        pop hDialog

        mov [ebx].lpDependencies, edi
        invoke SendDlgItemMessage, hDialog, IDC_SD_DEPENDENCIES, LB_GETCOUNT, 0, 0
        mov ebx, eax
        xor ecx, ecx
        .while (ecx <  ebx)
            push ecx
            invoke SendDlgItemMessage, hDialog, IDC_SD_DEPENDENCIES, LB_GETTEXTLEN, ecx, 0
            mov esi, eax
            .if (esi != 0)
                pop ecx
                push ecx
                invoke SendDlgItemMessage, hDialog, IDC_SD_DEPENDENCIES, LB_GETTEXT, ecx, edi
                inc esi
                add edi, esi
            .endif
            pop ecx
            inc ecx    
        .endw
        xor eax, eax
        stosw
                
        assume ebx: nothing
        
        xor eax, eax
        inc eax
        mov dwReturn, eax
        invoke SetLastError, ERROR_SUCCESS
    .elseif
        xor eax, eax
        mov dwReturn, eax
        invoke SetLastError, ERROR_NOT_ENOUGH_MEMORY
    .endif
    
    popad
    mov eax, dwReturn
    ret
GetGeneralData endp

;------------------------------------------------------------------------------
; GetFailureData - заполнить  буфер параметрами  восстановления  сервиса
;  - lplpBuffer - указатель  на указатель  буфер для хранения данных
;  - lpdwBufferSize - размер буфера   
;------------------------------------------------------------------------------
GetFailureData proc lplpBuffer: LPVOID, lpdwBufferSize: LPDWORD
    LOCAL hDialog: HWND
    LOCAL dwControl: DWORD
    LOCAL dwSize: DWORD
    LOCAL lpBuffer: LPVOID
    LOCAL dwReturn: DWORD
    LOCAL dwCount: DWORD
    LOCAL lpParam: LPVOID

    pushad
    ; расчет  необходимого размера буфера
    mov eax, lplpBuffer
    mov eax, [eax]
    mov lpBuffer, eax
    
    lea eax, tpServiceProperties
    add eax, 2*(sizeof TabPage)
    push (TabPage ptr[eax]).hWnd
    pop hDialog
    
    invoke GetWindowLong, hDialog, GWL_USERDATA
    mov lpParam, eax
    
    mov ebx, sizeof SERVICE_FAILURE_ACTIONS + 3*(sizeof SC_ACTION+1)
    invoke SendDlgItemMessage, hDialog, IDC_SR_PATH, WM_GETTEXTLENGTH, 0, 0
    add ebx, eax
    inc ebx
    invoke SendDlgItemMessage, hDialog, IDC_SR_MESSAGE, WM_GETTEXTLENGTH, 0, 0
    add ebx, eax
    inc ebx

    mov eax, [lpdwBufferSize]
    .if (ebx > eax)
        invoke realloc, lpBuffer, ebx
        mov lpBuffer, eax
        mov ebx, lplpBuffer
        mov [ebx], eax
        mov ebx, lpdwBufferSize
        .if (eax != 0)
            mov eax, dwSize
        .endif
        mov [ebx], eax
    .endif

    .if (lpBuffer != NULL)
        mov ebx, lpBuffer
        assume ebx: ptr SERVICE_FAILURE_ACTIONS

        invoke SendDlgItemMessage, hDialog, IDC_SR_FCDELAY, WM_GETTEXTLENGTH, 0, 0
        mov esi, eax
        .if (esi != 0)
            invoke SendDlgItemMessage, hDialog, IDC_SR_FCDELAY, WM_GETTEXT,  SERV_DATA_SIZE, addr szServDataBuffer
            invoke GetDwordFromString, addr szServDataBuffer, esi
        .endif
        mov [ebx].dwResetPeriod, eax

        mov edi, ebx
        add edi, sizeof CHANGE_SERVICE_CONFIG

        xor eax, eax
        mov dwCount, eax
        
        mov [ebx].lpsaActions, edi
        invoke GetFailureAction,  hDialog, lpParam, IDC_SR_FIRST, edi
        .if (eax != 0)
            inc dwCount
            add edi, sizeof SC_ACTION
        .endif

        invoke GetFailureAction,  hDialog, lpParam, IDC_SR_SECOND, edi
        .if (eax != 0)
            inc dwCount
            add edi, sizeof SC_ACTION
        .endif

        invoke GetFailureAction,  hDialog, lpParam, IDC_SR_THIRD, edi
        .if (eax != 0)
            inc dwCount
            add edi, sizeof SC_ACTION
        .endif
        xor eax, eax
        stosw
        
        push dwCount
        pop [ebx].cActions

        mov [ebx].lpCommand, edi
        invoke SendDlgItemMessage, hDialog, IDC_SR_PATH, WM_GETTEXTLENGTH, 0, 0
        mov esi, eax
        .if (esi != 0)
            inc esi
            invoke SendDlgItemMessage, hDialog, IDC_SR_PATH, WM_GETTEXT,  esi, edi
            add edi, esi
        .else
            xor eax, eax
            stosb    
        .endif
        
        mov [ebx].lpRebootMsg, edi
        invoke SendDlgItemMessage, hDialog, IDC_SR_MESSAGE, WM_GETTEXTLENGTH, 0, 0
        mov esi, eax
        .if (esi != 0)
            inc esi
            invoke SendDlgItemMessage, hDialog, IDC_SR_MESSAGE, WM_GETTEXT,  esi, edi
            add edi, esi
        .else
            xor eax, eax
            stosb    
        .endif
                
        assume ebx: nothing
        
        xor eax, eax
        inc eax
        mov dwReturn, eax
        invoke SetLastError, ERROR_SUCCESS
    .elseif
        xor eax, eax
        mov dwReturn, eax
        invoke SetLastError, ERROR_NOT_ENOUGH_MEMORY
    .endif
    
    popad
    mov eax, dwReturn
    ret
GetFailureData endp

;------------------------------------------------------------------------------
; GetDescriptionData - заполнить  буфер описанием сервиса
;  - lplpBuffer - указатель  на указатель  буфер для хранения данных
;  - lpdwBufferSize - размер буфера   
;------------------------------------------------------------------------------
GetDescriptionData proc lplpBuffer: LPVOID, lpdwBufferSize: LPDWORD
    LOCAL hDialog: HWND
    LOCAL dwSize: DWORD
    LOCAL lpBuffer: LPVOID
    LOCAL dwReturn: DWORD

    pushad
    ; расчет  необходимого размера буфера
    mov eax, lplpBuffer
    mov eax, [eax]
    mov lpBuffer, eax
    
    mov eax, tpServiceProperties.hWnd
    mov hDialog, eax

    mov ebx, sizeof SERVICE_DESCRIPTION
    invoke SendDlgItemMessage, hDialog, IDC_SG_DESCRIPTION, WM_GETTEXTLENGTH, 0, 0
    add ebx, eax
    inc ebx
    inc ebx
    mov dwSize, ebx

    mov eax, [lpdwBufferSize]
    .if (ebx > eax)
        invoke realloc, lpBuffer, ebx
        mov lpBuffer, eax
        mov ebx, lplpBuffer
        mov [ebx], eax
        mov ebx, lpdwBufferSize
        .if (eax != 0)
            mov eax, dwSize
        .endif
        mov [ebx], eax
    .endif

    .if (lpBuffer != NULL)
        mov ebx, lpBuffer
        assume ebx: ptr SERVICE_DESCRIPTION

        mov edi, ebx
        add edi, sizeof SERVICE_DESCRIPTION
        
        mov [ebx].lpDescription, edi
        invoke SendDlgItemMessage, hDialog, IDC_SG_DESCRIPTION, WM_GETTEXTLENGTH, 0, 0
        mov esi, eax
        .if (esi != 0)
            inc esi
            invoke SendDlgItemMessage, hDialog, IDC_SG_DESCRIPTION, WM_GETTEXT, esi, edi
            add edi, esi
        .else
            xor eax, eax
            stosb    
        .endif
                
        assume ebx: nothing
        
        xor eax, eax
        inc eax
        mov dwReturn, eax
        invoke SetLastError, ERROR_SUCCESS
    .elseif
        xor eax, eax
        mov dwReturn, eax
        invoke SetLastError, ERROR_NOT_ENOUGH_MEMORY
    .endif
    
    popad
    mov eax, dwReturn
    ret
GetDescriptionData endp

;------------------------------------------------------------------------------
; CheckData - проверить  данные на правильность
;  - hWnd - хендл диалогового окна   
;------------------------------------------------------------------------------
CheckData proc hWnd: HWND
    LOCAL hDialog: HWND
    LOCAL hItem: HWND
    LOCAL lpErrorMessage: LPCSTR
    LOCAL dwIndex: DWORD
    
    xor eax, eax
    mov dwIndex, eax
     
    ; общие данные
    mov eax, tpServiceProperties.hWnd
    mov hDialog, eax
    
    invoke SendDlgItemMessage, hDialog, IDC_SG_SNAME, WM_GETTEXTLENGTH, 0, 0
    .if (eax == 0)
        lea eax, szWarningMessageNoData
        mov lpErrorMessage, eax
        invoke GetDlgItem, hDialog, IDC_SG_SNAME
        mov hItem, eax
        jmp cdError
    .endif
    
    invoke SendDlgItemMessage, hDialog, IDC_SG_DNAME, WM_GETTEXTLENGTH, 0, 0
    .if (eax == 0)
        lea eax, szWarningMessageNoData
        mov lpErrorMessage, eax
        invoke GetDlgItem, hDialog, IDC_SG_DNAME
        mov hItem, eax
        jmp cdError
    .endif

    invoke SendDlgItemMessage, hDialog, IDC_SG_PATH, WM_GETTEXTLENGTH, 0, 0
    .if (eax == 0)
        lea eax, szWarningMessageNoData
        mov lpErrorMessage, eax
        invoke GetDlgItem, hDialog, IDC_SG_PATH
        mov hItem, eax
        jmp cdError
    .endif

    invoke SendDlgItemMessage, hDialog, IDC_SG_TYPE, CB_GETCURSEL, 0, 0
    .if (eax == CB_ERR)
        lea eax, szWarningMessageNoData
        mov lpErrorMessage, eax
        invoke GetDlgItem, hDialog, IDC_SG_TYPE
        mov hItem, eax
        jmp cdError
    .endif

    invoke SendDlgItemMessage, hDialog, IDC_SG_STARTTYPE, CB_GETCURSEL, 0, 0
    .if (eax == CB_ERR)
        lea eax, szWarningMessageNoData
        mov lpErrorMessage, eax
        invoke GetDlgItem, hDialog, IDC_SG_STARTTYPE
        mov hItem, eax
        jmp cdError
    .endif

    invoke SendDlgItemMessage, hDialog, IDC_SG_ERRORTYPE, CB_GETCURSEL, 0, 0
    .if (eax == CB_ERR)
        lea eax, szWarningMessageNoData
        mov lpErrorMessage, eax
        invoke GetDlgItem, hDialog, IDC_SG_ERRORTYPE
        mov hItem, eax
        jmp cdError
    .endif
    
    ; учетная  запись
    inc dwIndex
     
    lea eax, tpServiceProperties
    add eax, sizeof TabPage
    mov eax, (TabPage ptr [eax]).hWnd
    mov hDialog, eax

    invoke SendDlgItemMessage, hDialog, IDC_SL_ANOTHER_ACCOUNT, BM_GETCHECK, NULL, NULL
    .if (eax == BST_CHECKED)
        invoke SendDlgItemMessage, hDialog, IDC_SL_ACCOUNT, WM_GETTEXTLENGTH, 0, 0
        .if (eax != 0)
            invoke SendDlgItemMessage, hDialog, IDC_SL_PASS, WM_GETTEXT, SERV_DATA_SIZE, addr szServDataBuffer
            invoke SendDlgItemMessage, hDialog, IDC_SL_CONFIRM, WM_GETTEXT, SERV_DATA_SIZE, addr szServDataBuffer2
            invoke lstrcmpi, addr szServDataBuffer, addr szServDataBuffer2
            
            .if (eax != 0)
                lea eax, szWarningMessagePassMismatch
                mov lpErrorMessage, eax
                invoke GetDlgItem, hDialog, IDC_SL_PASS
                mov hItem, eax
                jmp cdError
            .endif
        .endif
    .endif
    
    xor eax, eax
    inc eax
    ret
    
cdError:
    invoke SendDlgItemMessage, hWnd, IDC_SERV_TAB, TCM_GETCURSEL, 0, 0
    push ebx
    xor edx, edx
    mov ebx, sizeof TabPage
    mul ebx
    lea ebx, tpServiceProperties
    add ebx, eax
    invoke ShowWindow, (TabPage ptr [ebx]).hWnd, SW_HIDE
    mov eax, dwIndex
    xor edx, edx
    mov ebx, sizeof TabPage
    mul ebx
    lea ebx, tpServiceProperties
    add ebx, eax
    invoke ShowWindow, (TabPage ptr [ebx]).hWnd, SW_SHOW
    pop ebx
    invoke SendDlgItemMessage, hWnd, IDC_SERV_TAB, TCM_SETCURSEL, dwIndex, 0
    invoke MessageBox, hWnd, lpErrorMessage , addr szDialogCaptionEdit, MB_ICONWARNING or MB_OK
    invoke SetFocus, hItem
    xor eax, eax
    ret    
    
CheckData endp

;------------------------------------------------------------------------------
; GetDwordFromString - перевести  строку в целое
;  - lpBuffer - строка   
;  - dwSize - размер 
;------------------------------------------------------------------------------
GetDwordFromString proc lpBuffer: LPCSTR, dwSize: DWORD
    push edx
    push ecx
    push ebx
    pushfd
    
    mov esi, lpBuffer
    cld
    
    xor eax, eax
    xor edx, edx
    xor ebx, ebx
    mov ecx, dwSize
    .if (ecx > 10)
        mov ecx, 10
    .endif   
    
    .while (al < 10) && (ecx != 0)
        lodsb
        sub al, "0"
        .if (!SIGN?)&&(al < 10)
            shl edx, 1
            mov ebx, edx
            shl edx, 2
            add edx, ebx
            add edx, eax
            dec ecx
        .else
            xor ecx, ecx
        .endif
    .endw
    
    mov eax, edx
    popfd
    pop ebx
    pop ecx
    pop edx
    
    ret
GetDwordFromString endp

;------------------------------------------------------------------------------
; SetTokenPrivilege  - установить   привилегии для текучщего маркера
;  - lpComp   
;  - lpTP - адрес структуры   TOKEN_PRIVILEGES
;  - lpPrivilege - строково  значене привилегии
;------------------------------------------------------------------------------
SetTokenPrivilege proc lpComp: LPSTR, lpTP: LPVOID, lpPrivilege: LPCSTR
    LOCAL hProcess: HANDLE
    LOCAL hToken: HANDLE
    
    push ebx
    mov ebx, lpTP

    assume ebx: ptr TOKEN_PRIVILEGES
    invoke GetCurrentProcess
    mov hProcess, eax
    invoke OpenProcessToken, hProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, addr hToken
    .if (eax != 0)
        invoke LookupPrivilegeValue, lpComp, lpPrivilege, addr [ebx].Privileges
        .if (eax != 0)
            mov [ebx].PrivilegeCount, 1
            mov [ebx].Privileges.Attributes, SE_PRIVILEGE_ENABLED
            invoke AdjustTokenPrivileges, hToken, FALSE, ebx, 0, NULL, NULL 
        .endif         
    .endif
    assume ebx: nothing

    pop ebx
    ret
SetTokenPrivilege endp
        
end
