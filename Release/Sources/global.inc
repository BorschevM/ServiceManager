;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      global.inc
; Описание:  типы данных и общие переменные
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

; константы
TB_SETBUTTONINFOW  EQU (WM_USER+64)
TB_SETBUTTONINFOA  EQU (WM_USER+66)
TB_SETBUTTONINFO   EQU TB_SETBUTTONINFOA

TBIF_BYINDEX       EQU 080000000h
TBIF_COMMAND       EQU 32
TBIF_IMAGE         EQU 1
TBIF_LPARAM        EQU 16
TBIF_SIZE          EQU 64
TBIF_STATE         EQU 4
TBIF_STYLE         EQU 8
TBIF_TEXT          EQU 2

SERVICE_CONFIG_DESCRIPTION     EQU 1
SERVICE_CONFIG_FAILURE_ACTIONS EQU 2

SC_ACTION_NONE                 EQU 0
SC_ACTION_RESTART              EQU 1
SC_ACTION_REBOOT               EQU 2
SC_ACTION_RUN_COMMAND          EQU 3

; Типы данных
DT_INTEGER      EQU 00000001h
DT_FLOAT        EQU 00000002h
DT_DATETIME     EQU 00000003h
DT_TIME         EQU 00000004h
DT_STRING       EQU 00000005h

; Типы колонок
CT_SERV_INAME       EQU 00000001h
CT_SERV_DNAME       EQU 00000002h
CT_SERV_DESCRIPTION EQU 00000003h
CT_SERV_TYPE        EQU 00000004h
CT_SERV_START_TYPE  EQU 00000005h
CT_SERV_ERROR_TYPE  EQU 00000006h
CT_SERV_LOGON       EQU 00000007h

CT_LOG_SERV         EQU 00000008h
CT_LOG_OP           EQU 00000009h
CT_LOG_STATUS       EQU 0000000Ah
CT_LOG_ERRCODE      EQU 0000000Bh
CT_LOG_ERRDESC      EQU 0000000Ch

ERROR_TIMEOUT        EQU 1460

TMP_BUF_SIZE         EQU 1024
SERV_NAME_LEN        EQU 256
SERV_CODE_LENTH      EQU 256
SERV_WAIT_TIMEOUT    EQU 5000

DIALOGPARAM_NEW      EQU 0
DIALOGPARAM_EDIT     EQU 1

QD_OPEN              EQU 1
QD_QUERYCONFIG       EQU 2
QD_QUERYDESCRIPTION  EQU 4
QD_QUERYFAILURE      EQU 8

CND_LOCALCOMP        EQU 0
CND_REMOTECOMP       EQU 1

; типы данных
HKEY TYPEDEF DWORD

; структура для работы с  ToolBar'ом
ToolBarInfo struct
    pWindowName LPSTR     ?      ; название окна

    hBitmap         HBITMAP ?    ; хендл битмапа
    IdBitmap        DWORD   ?    ; идентификатор    битмата
    BitmapCount     DWORD   ?    ; количиство  рисинков
    BitmapWidth     DWORD   ?    ; ширина битмапа
    BitmapHeight    DWORD   ?    ; высота  битмапа

    ItemCount       DWORD  ?     ; количество  кнопок
    ItemWidth       DWORD  ?     ; ширина кнопки
    ItemHeight      DWORD  ?     ; высота  кнопки
    pButtons        DWORD  ?     ; массив кнопок
ToolBarInfo ends

; структура записи ComboBox
ComboBoxRecord struct
    id              DWORD ?          ; иденификатор
    RecordName      BYTE 100 dup(0)  ; строка
ComboBoxRecord ends

; структура конолки таблицы
ColumnInfo struct
    ColumnType     DWORD ?           ; идентификатор колонки
    DataType       DWORD ?           ; тип данных для отображения
    ColumnName     BYTE 100 DUP(?)   ; название колонки
    ColumnWidth    DWORD ?           ; ширина колонки
    Color          COLORREF ?        ; цвет
    flags          DWORD ?           ; флаги
ColumnInfo ends

; структура страницы TabControl
TabPage struct
    szPageTitle    BYTE 100 DUP(?)   ; название закладки
    nDialogId      DWORD ?           ; идентификатор диалога
    hWnd           HWND ?            ; хендл окна отображаемого на закладке
    pFunct         LPVOID ?          ; диалоговая функция окна
    nFlags         DWORD ?           ; флаги
TabPage ends

; структура    элемента   TreeView
TreeViewItem struct
    hItem          HANDLE ?        ; хендл елемента
    hParent        HANDLE ?        ; хендл родителя
    
    iImage         DWORD ?         ; индекс картинки
    iSelectedImage DWORD ?         ; индекс картинки
    lParam         DWORD ?         ; данные елемента

    ItemString     BYTE 100 dup(?) ; строка
TreeViewItem ends

; структура    для работы   с TreeView
TreeViewInfo struct
    hImageList    HANDLE ?    ; хендл списка иконок
    
    IdBitmap      DWORD ?     ; идентификатор битмата
    IdMask        DWORD ?     ; идентификатор битмата
    ImageCount    DWORD ?     ; количиство рисинков
    ImageWidth    DWORD ?     ; ширина битмапа
    ImageHeight   DWORD ?     ; высота битмапа

    ItemCount     DWORD ?     ; количество  элеметнов
    pItems        DWORD ?     ; массив кнопок
TreeViewInfo ends

; структура параметров для функции обработки сообщений URL
sUrlParam struct
    pOldProc      DWORD ?    ; старый обработчик сообщений
    pNewProc      DWORD ?    ; новый обработчик сообщений
    hCursor       HANDLE ?   ; курсор
sUrlParam ends

; данные чекбоксов
CheckItemData struct
    ItemId        DWORD ?
    ItemCode      DWORD ?
CheckItemData ends

ComputorNameData struct 
    dwCompFlag      DWORD ?
    dwCompNameSize  DWORD ?
    lpCompName      LPCSTR ?
ComputorNameData ends 

ServiceDataParam struct
    hSCManager      HANDLE ?
    hService        HANDLE ?
    dwServiceType   DWORD ?
    dwDesiredAccess DWORD ?
    szServiceName   BYTE  SERV_NAME_LEN dup(?)
    cdComp          ComputorNameData <?>
    hLog            HWND ?
    lpdwCount       LPDWORD ?
    dwMode          DWORD ?
    dwCancelCode DWORD ?
    dwStatus        DWORD ?
ServiceDataParam ends

CodeString struct
    dwCode DWORD ?
    szString BYTE SERV_CODE_LENTH dup(0)    
CodeString ends

SERVICE_DESCRIPTION struct
    lpDescription LPCSTR ?
SERVICE_DESCRIPTION ends

SC_ACTION struct
    dwActionType DWORD ?
    dwDelay      DWORD ?
SC_ACTION ends

SERVICE_FAILURE_ACTIONS struct
    dwResetPeriod DWORD ?
    lpRebootMsg   LPCSTR ?
    lpCommand     LPCSTR ?
    cActions      DWORD ?
    lpsaActions   LPVOID ?
SERVICE_FAILURE_ACTIONS ends

CHANGE_SERVICE_CONFIG struct
  dwServiceType         DWORD ?
  dwStartType           DWORD ?
  dwErrorControl        DWORD ?
  lpBinaryPathName      DWORD ?
  lpLoadOrderGroup      DWORD ?
  dwTagId               DWORD ?
  lpDependencies        DWORD ?
  lpServiceStartName    DWORD ?
  lpPass                DWORD ?
  lpDisplayName         DWORD ?
CHANGE_SERVICE_CONFIG ends

; переменные
EXTERNDEF hInstance: HINSTANCE
EXTERNDEF hMainWnd: HWND
EXTERNDEF hMainToolBar: HWND
EXTERNDEF hMainStatus: HWND
EXTERNDEF hMainTreeView: HWND
EXTERNDEF hServiceList: HWND
EXTERNDEF hLogList: HWND

EXTERNDEF dwSCMAccess: DWORD
EXTERNDEF dwServAccess: DWORD
EXTERNDEF dwServiceEnumType: DWORD

EXTERNDEF szOpen: BYTE
EXTERNDEF szFmtS: BYTE
EXTERNDEF szFmtD: BYTE
EXTERNDEF szFmtX: BYTE
