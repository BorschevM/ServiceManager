;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      subserventdlg.asm 
; Описание:  диалоговые окна прав доступа и соединения с удаленным компьютером
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

title  SubServentDlg

.386
.model flat,stdcall
option casemap:none

include ..\..\Masm32\include\windows.inc
include ..\..\Masm32\include\user32.inc
include ..\..\Masm32\include\gdi32.inc
include ..\..\Masm32\include\shell32.inc

includelib ..\..\Masm32\lib\shell32.lib

include res.inc
include global.inc
include memory.inc
include subserventdlg.inc

SCM_CH_COUNT     EQU 9 
SERV_CH_COUNT    EQU 14 

.data
    SCMChBoxArr CheckItemData<IDC_SCM_ALL_ACCESS, SC_MANAGER_ALL_ACCESS>
                          CheckItemData<IDC_SCM_STANDARDREAD, STANDARD_RIGHTS_READ>
                          CheckItemData<IDC_SCM_STANDARDWRITE, STANDARD_RIGHTS_WRITE>
                          CheckItemData<IDC_SCM_CONNECT, SC_MANAGER_CONNECT>
                          CheckItemData<IDC_SCM_CREATE_SERVICE, SC_MANAGER_CREATE_SERVICE>
                          CheckItemData<IDC_SCM_ENUMERATE_SERVICE, SC_MANAGER_ENUMERATE_SERVICE>
                          CheckItemData<IDC_SCM_MODIFY_BOOT_CONFIG, SC_MANAGER_MODIFY_BOOT_CONFIG>
                          CheckItemData<IDC_SCM_LOCK, SC_MANAGER_LOCK>
                          CheckItemData<IDC_SCM_QUERY_LOCK_STATUS, SC_MANAGER_QUERY_LOCK_STATUS>
    

    ServChBoxArr CheckItemData<IDC_SERV_ALL_ACCESS, SERVICE_ALL_ACCESS>
                         CheckItemData<IDC_SERV_DELETE, DELETE>
                         CheckItemData<IDC_SERV_READ_CONTROL, READ_CONTROL>
                         CheckItemData<IDC_SERV_WRITE_DAC, WRITE_DAC>
                         CheckItemData<IDC_SERV_WRITE_OWNER, WRITE_OWNER>
                         CheckItemData<IDC_SERV_QUERY_CONFIG, SERVICE_QUERY_CONFIG>
                         CheckItemData<IDC_SERV_CHANGE_CONFIG, SERVICE_CHANGE_CONFIG>
                         CheckItemData<IDC_SERV_QUERY_STATUS, SERVICE_QUERY_STATUS>
                         CheckItemData<IDC_SERV_ENUMERATE_DEPENDENTS, SERVICE_ENUMERATE_DEPENDENTS>
                         CheckItemData<IDC_SERV_START, SERVICE_START>
                         CheckItemData<IDC_SERV_STOP, SERVICE_STOP>
                         CheckItemData<IDC_SERV_PAUSE_CONTINUE, SERVICE_PAUSE_CONTINUE>
                         CheckItemData<IDC_SERV_INTERROGATE, SERVICE_INTERROGATE>
                         CheckItemData<IDC_SERV_USER_DEFINED_CONTROL, SERVICE_USER_DEFINED_CONTROL>
    
.data?

.code
;------------------------------------------------------------------------------
; SCMPropertyDialogFunc - Процедура диалогового окна Права доступа к SCM
;   - hWnd - хэндл окна
;   - uMsg - сообщение
;   - wParam - первый параметр сообщения
;   - lParam - второй параметр сообщения 
;------------------------------------------------------------------------------
SCMAccessDialogFunc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .if uMsg==WM_INITDIALOG
        push ebx
        push edi
        push esi

        invoke SetWindowLong, hWnd, GWL_USERDATA, lParam
        mov eax, lParam
        mov edi, [eax]
            
        mov ebx, offset SCMChBoxArr
        mov esi, ebx
        add esi, SCM_CH_COUNT*(sizeof CheckItemData)
        assume ebx: ptr CheckItemData
        .while (ebx < esi)
            mov eax, edi
            and eax, [ebx].ItemCode
            .if (eax == [ebx].ItemCode)
                invoke SendDlgItemMessage, hWnd, [ebx].ItemId, BM_SETCHECK, BST_CHECKED, NULL
            .endif
                
            add ebx, sizeof CheckItemData
        .endw   
        assume ebx: nothing

        pop esi
        pop edi
        pop ebx
        
        xor eax, eax
        inc eax
        ret
    .elseif uMsg== WM_CLOSE
            invoke EndDialog, hWnd, IDC_CANCEL
    .elseif uMsg== WM_COMMAND
        .if (wParam == IDC_OK)
            push ebx
            push edi
            push esi
            
            xor eax, eax
            mov edi, eax
            
            mov ebx, offset SCMChBoxArr
            mov esi, ebx
            add esi, SCM_CH_COUNT*(sizeof CheckItemData)
            assume ebx: ptr CheckItemData
            .while (ebx < esi)
                invoke SendDlgItemMessage, hWnd, [ebx].ItemId, BM_GETCHECK, NULL, NULL
                .if (eax == BST_CHECKED)
                    or edi, [ebx].ItemCode 
                .endif
                
                add ebx, sizeof CheckItemData
            .endw   
            assume ebx: nothing

            invoke GetWindowLong, hWnd, GWL_USERDATA
            mov [eax], edi
            
            pop esi
            pop edi
            pop ebx
        
            invoke EndDialog, hWnd, IDC_OK
        .elseif (wParam == IDC_CANCEL)
            invoke EndDialog, hWnd, IDC_CANCEL
        .elseif (lParam != 0)
            mov eax,wParam
            mov edx,eax
            shr edx,16
            .if (dx==BN_CLICKED)
                push ebx
                push esi
            
                and eax, 0ffffh
                .if (eax == IDC_SCM_ALL_ACCESS)
                    invoke SendDlgItemMessage, hWnd, eax, BM_GETCHECK, NULL, NULL
                    .if (eax == BST_CHECKED)
                        mov ebx, offset SCMChBoxArr
                        mov esi, ebx
                        add esi, (SCM_CH_COUNT-1)*(sizeof CheckItemData)
                        assume ebx: ptr CheckItemData
                        .while (ebx < esi)
                            add ebx, sizeof CheckItemData
                            invoke SendDlgItemMessage, hWnd, [ebx].ItemId, BM_SETCHECK, BST_CHECKED, NULL
                        .endw   
                        assume ebx: nothing
                    .endif
                .else
                    invoke SendDlgItemMessage, hWnd, eax, BM_GETCHECK, NULL, NULL
                    .if (eax == BST_UNCHECKED)
                        invoke SendDlgItemMessage, hWnd, IDC_SCM_ALL_ACCESS, BM_SETCHECK, BST_UNCHECKED, NULL
                    .endif
                .endif 
            
                pop esi
                pop ebx
            .endif
        .endif
    .endif

    xor eax, eax
    ret
SCMAccessDialogFunc endp

;------------------------------------------------------------------------------
; ServPropertyDialogFunc - Процедура диалогового окна Права доступа к сервисам
;   - hWnd - хэндл окна
;   - uMsg - сообщение
;   - wParam - первый параметр сообщения
;   - lParam - второй параметр сообщения 
;------------------------------------------------------------------------------
ServAccessDialogFunc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .if uMsg==WM_INITDIALOG
        push ebx
        push edi
        push esi

        invoke SetWindowLong, hWnd, GWL_USERDATA, lParam
        mov eax, lParam
        mov edi, [eax]
            
        mov ebx, offset ServChBoxArr
        mov esi, ebx
        add esi, SERV_CH_COUNT*(sizeof CheckItemData)
        assume ebx: ptr CheckItemData
        .while (ebx < esi)
            mov eax, edi
            and eax, [ebx].ItemCode
            .if (eax == [ebx].ItemCode)
                invoke SendDlgItemMessage, hWnd, [ebx].ItemId, BM_SETCHECK, BST_CHECKED, NULL
            .endif
                
            add ebx, sizeof CheckItemData
        .endw   
        assume ebx: nothing

        pop esi
        pop edi
        pop ebx
        
        xor eax, eax
        inc eax
        ret
    .elseif uMsg== WM_CLOSE
            invoke EndDialog, hWnd, IDC_CANCEL
    .elseif uMsg== WM_COMMAND
        .if (wParam == IDC_OK)
            push ebx
            push edi
            push esi
            
            xor eax, eax
            mov edi, eax
            
            mov ebx, offset ServChBoxArr
            mov esi, ebx
            add esi, SERV_CH_COUNT*(sizeof CheckItemData)
            assume ebx: ptr CheckItemData
            .while (ebx < esi)
                invoke SendDlgItemMessage, hWnd, [ebx].ItemId, BM_GETCHECK, NULL, NULL
                .if (eax == BST_CHECKED)
                    or edi, [ebx].ItemCode 
                .endif
                
                add ebx, sizeof CheckItemData
            .endw   
            assume ebx: nothing

            invoke GetWindowLong, hWnd, GWL_USERDATA
            mov [eax], edi
            
            pop esi
            pop edi
            pop ebx
        
            invoke EndDialog, hWnd, IDC_OK
        .elseif (wParam == IDC_CANCEL)
            invoke EndDialog, hWnd, IDC_CANCEL
        .elseif (lParam != 0)
            mov eax,wParam
            mov edx,eax
            shr edx,16
            .if (dx==BN_CLICKED)
                push ebx
                push esi
            
                and eax, 0ffffh
                .if (eax == IDC_SERV_ALL_ACCESS)
                    invoke SendDlgItemMessage, hWnd, eax, BM_GETCHECK, NULL, NULL
                    .if (eax == BST_CHECKED)
                        mov ebx, offset ServChBoxArr
                        mov esi, ebx
                        add esi, (SERV_CH_COUNT-1)*(sizeof CheckItemData)
                        assume ebx: ptr CheckItemData
                        .while (ebx < esi)
                            add ebx, sizeof CheckItemData
                            invoke SendDlgItemMessage, hWnd, [ebx].ItemId, BM_SETCHECK, BST_CHECKED, NULL
                        .endw   
                        assume ebx: nothing
                    .endif
                .else
                    invoke SendDlgItemMessage, hWnd, eax, BM_GETCHECK, NULL, NULL
                    .if (eax == BST_UNCHECKED)
                        invoke SendDlgItemMessage, hWnd, IDC_SERV_ALL_ACCESS, BM_SETCHECK, BST_UNCHECKED, NULL
                    .endif
                .endif 
            
                pop esi
                pop ebx
            .endif
        .endif
    .endif

    xor eax, eax
    ret
ServAccessDialogFunc endp

;------------------------------------------------------------------------------
; ConnectToDialogFunc - Процедура диалогового окна Подключение к удаленному компьютеру
;   - hWnd - хэндл окна
;   - uMsg - сообщение
;   - wParam - первый параметр сообщения
;   - lParam - второй параметр сообщения 
;------------------------------------------------------------------------------
ConnectToDialogFunc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL dwSize: DWORD
    
    .if uMsg==WM_INITDIALOG
        invoke SetWindowLong, hWnd, GWL_USERDATA, lParam

        push ebx
        assume ebx: ptr ComputorNameData
        mov ebx, lParam
        mov eax, [ebx].lpCompName
        .if (eax != NULL) && (byte ptr [eax] != 0)
            invoke SendDlgItemMessage, hWnd, IDC_CT_COMPNAME, WM_SETTEXT, 0, eax
        .endif

        .if ([ebx].dwCompFlag == CND_LOCALCOMP)
            mov eax, IDC_CT_LOCAL
        .else
            mov eax, IDC_CT_REMOTE
        .endif
        invoke SendDlgItemMessage, hWnd, eax, BM_CLICK, 0, 0
        assume ebx: nothing
        pop ebx
        
        xor eax, eax
        inc eax
        ret
    .elseif uMsg== WM_CLOSE
        invoke EndDialog, hWnd, IDC_CANCEL
    .elseif uMsg== WM_COMMAND
        .if (wParam == IDC_OK)
            push ebx
            invoke GetWindowLong, hWnd, GWL_USERDATA
            xchg eax, ebx
            assume ebx: ptr ComputorNameData
            
            invoke SendDlgItemMessage, hWnd, IDC_CT_COMPNAME, WM_GETTEXTLENGTH, 0, 0
            .if (eax > [ebx].dwCompNameSize)
                mov dwSize, eax
                invoke realloc, [ebx].lpCompName, eax
                mov [ebx].lpCompName, eax 
                .if (eax != 0)
                    mov eax, dwSize
                .endif
                mov [ebx].dwCompNameSize, eax
            .endif
            
            .if ([ebx].lpCompName != NULL)
                invoke SendDlgItemMessage, hWnd, IDC_CT_COMPNAME, WM_GETTEXT, [ebx].dwCompNameSize, [ebx].lpCompName
            .endif
            
            invoke SendDlgItemMessage, hWnd, IDC_CT_LOCAL, BM_GETCHECK, NULL, NULL
            .if (eax == BST_CHECKED)
                mov [ebx].dwCompFlag, CND_LOCALCOMP
            .else
                mov [ebx].dwCompFlag, CND_REMOTECOMP
            .endif 
        
            invoke EndDialog, hWnd, IDC_OK
            assume ebx: nothing
            pop ebx
        .elseif (wParam == IDC_CANCEL)
            invoke EndDialog, hWnd, IDC_CANCEL
        .elseif (lParam != 0)
            mov eax,wParam
            mov edx,eax
            shr edx,16
            .if (dx==BN_CLICKED)
                and eax, 0ffffh
                .if (eax == IDC_CT_LOCAL)
                    invoke GetDlgItem, hWnd, IDC_CT_COMPNAME 
                    invoke EnableWindow, eax, FALSE
                .elseif (eax == IDC_CT_REMOTE)
                    invoke GetDlgItem, hWnd, IDC_CT_COMPNAME
                    invoke EnableWindow, eax, TRUE
                .endif
            .endif
        .endif
    .endif

    xor eax, eax
    ret
ConnectToDialogFunc endp

end
