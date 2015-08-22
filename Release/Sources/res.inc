;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      res.inc
; Описание:  идентификаторы ресурсов
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

IDC_MAINICON           EQU 200
IDC_BIGICON            EQU 250
IDC_BUTTONS            EQU 300
IDC_TREEVIEWITEMS      EQU 350
IDC_TREEVIEWMASK       EQU 400
IDC_MAINSTATUS         EQU 450

IDC_SPLITV             EQU 500    
IDC_SPLITH             EQU 550

;----------------- МЕНЮ --------------------------------------------------------
IDM_CONNECTTO          EQU 1001
IDM_EXPORT             EQU 1002
IDM_EXIT               EQU 1003
IDM_SCM_ACCESS         EQU 1004
IDM_SCM_OPEN           EQU 1005
IDM_SCM_CLOSE          EQU 1006
IDM_SCM_LOCK           EQU 1007
IDM_SCM_UNLOCK         EQU 1008
IDM_SERV_ACCESS        EQU 1009
IDM_SERV_SECURITY      EQU 1010
IDM_SERV_NEW           EQU 1011
IDM_SERV_EDIT          EQU 1012
IDM_SERV_DELETE        EQU 1013
IDM_SERV_START         EQU 1014
IDM_SERV_STOP          EQU 1015
IDM_SERV_PAUSE         EQU 1016
IDM_SERV_RESUME        EQU 1017
IDM_SERV_RESTART       EQU 1018
IDM_SERV_IOCONTROL     EQU 1019
IDM_REFRESH            EQU 1020
IDM_HELP               EQU 1021
IDM_ABOUT              EQU 1022

;----------------- ТУЛБАР ------------------------------------------------------
IDB_SCM_OPEN           EQU 51
IDB_SCM_CLOSE          EQU 52
IDB_SERV_NEW           EQU 53
IDB_SERV_EDIT          EQU 54
IDB_SERV_DELETE        EQU 55
IDB_SERV_START         EQU 56
IDB_SERV_STOP          EQU 57
IDB_SERV_PAUSE         EQU 58
IDB_SERV_RESUME        EQU 59
IDB_SERV_RESTART       EQU 60
IDB_REFRESH            EQU 61
IDB_HELP               EQU 62
  

;----------------- Диалоги ------------------------------------------------------
IDC_OK                 EQU 1101
IDC_CANCEL             EQU 1102
IDC_APPLY              EQU 1103

IDD_ABOUT              EQU 1200
IDC_ABOUT_DEVMAIL      EQU 1201

IDD_SCM_ACCESS             EQU 1300
IDC_SCM_ALL_ACCESS         EQU 1301
IDC_SCM_STANDARDREAD       EQU 1302
IDC_SCM_STANDARDWRITE      EQU 1303
IDC_SCM_CONNECT            EQU 1304
IDC_SCM_CREATE_SERVICE     EQU 1305
IDC_SCM_ENUMERATE_SERVICE  EQU 1306
IDC_SCM_MODIFY_BOOT_CONFIG EQU 1307
IDC_SCM_LOCK               EQU 1308
IDC_SCM_QUERY_LOCK_STATUS  EQU 1309

IDD_SERV_ACCESS               EQU 1400
IDC_SERV_ALL_ACCESS           EQU 1401
IDC_SERV_DELETE               EQU 1402
IDC_SERV_READ_CONTROL         EQU 1403
IDC_SERV_WRITE_DAC            EQU 1405
IDC_SERV_WRITE_OWNER          EQU 1406
IDC_SERV_QUERY_CONFIG         EQU 1407
IDC_SERV_CHANGE_CONFIG        EQU 1408
IDC_SERV_QUERY_STATUS         EQU 1409
IDC_SERV_ENUMERATE_DEPENDENTS EQU 1410
IDC_SERV_START                EQU 1411
IDC_SERV_STOP                 EQU 1412
IDC_SERV_PAUSE_CONTINUE       EQU 1413
IDC_SERV_INTERROGATE          EQU 1414
IDC_SERV_USER_DEFINED_CONTROL EQU 1415

IDD_SERVICE_PROPERTIES        EQU 1500
IDC_SERV_TAB                  EQU 1501

IDD_SERV_GENERAL              EQU 1600
IDC_SG_SNAME                  EQU 1601
IDC_SG_DNAME                  EQU 1602
IDC_SG_TYPE                   EQU 1603
IDC_SG_STARTTYPE              EQU 1604
IDC_SG_ERRORTYPE              EQU 1605
IDC_SG_GROUP                  EQU 1606
IDC_SG_TAG                    EQU 1607
IDC_SG_PATH                   EQU 1608
IDC_SG_PCHANGE                EQU 1609
IDC_SG_DESCRIPTION            EQU 1610
IDC_SG_INTERACTIVFLAG         EQU 1611

IDD_SERV_LOGON                EQU 1700
IDC_SL_LOCALSYSTEM            EQU 1701
IDC_SL_ANOTHER_ACCOUNT        EQU 1702
IDC_SL_ACCOUNT                EQU 1703
IDC_SL_ACHANGE                EQU 1704
IDC_SL_PASS                   EQU 1705
IDC_SL_CONFIRM                EQU 1706

IDD_SERV_RECOVERY             EQU 1800
IDC_SR_FIRST                  EQU 1801
IDC_SR_SECOND                 EQU 1802
IDC_SR_THIRD                  EQU 1803
IDC_SR_FCDELAY                EQU 1804
IDC_SR_SRDELAY                EQU 1805
IDC_SR_CRDELAY                EQU 1806
IDC_SR_PATH                   EQU 1807
IDC_SR_PCHANGE                EQU 1808
IDC_SR_MESSAGE                EQU 1809

IDD_SERV_DEPENDENCIES         EQU 1900
IDC_SD_SERVICE                EQU 1901   
IDC_SD_ADD_SERVICE            EQU 1902
IDC_SD_GROUP                  EQU 1903
IDC_SD_ADD_GROUP              EQU 1904
IDC_SD_DEPENDENCIES           EQU 1905
IDC_SD_DEL_SERVICE            EQU 1906
IDC_SD_UP                     EQU 1907
IDC_SD_DOWN                   EQU 1908

IDD_SERV_CONTROL              EQU 2000
IDC_SCTRL_TYPE                EQU 2001
IDC_SCTRL_STATUS              EQU 2002
IDC_SCTRL_OPERATION           EQU 2003
IDC_SCTRL_WIN32EXITCODE       EQU 2004
IDC_SCTRL_SERVEXITCODE        EQU 2005
IDC_SCTRL_CHECKPOINT          EQU 2006
IDC_SCTRL_WAITHINT            EQU 2007
IDC_SCTRL_START               EQU 2008
IDC_SCTRL_STOP                EQU 2009
IDC_SCTRL_PAUSE               EQU 2010
IDC_SCTRL_RESUME              EQU 2011
IDC_SCTRL_REFRESH             EQU 2012
IDC_SCTRL_USERCODE            EQU 2013
IDC_SCTRL_CONTROL             EQU 2014

IDD_CONNECT_TO                EQU 2100
IDC_CT_LOCAL                  EQU 2101
IDC_CT_REMOTE                 EQU 2102
IDC_CT_COMPNAME               EQU 2103
