;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      res.h 
; Описание:  идентификаторы ресурсов
; Автор:     Иванцов Илья Сергеевич, YormLokison.yandex.ru
;------------------------------------------------------------------------------

#define VS_VERSION_INFO        1
#define IDC_MAINICON           200
#define IDC_BIGICON            250
#define IDC_BUTTONS            300
#define IDC_TREEVIEWITEMS      350
#define IDC_TREEVIEWMASK       400
#define IDC_MAINSTATUS         450

#define IDC_SPLITV             500    
#define IDC_SPLITH             550

;----------------- МЕНЮ --------------------------------------------------------
#define IDM_CONNECTTO          1001
#define IDM_EXPORT             1002
#define IDM_EXIT               1003
#define IDM_SCM_ACCESS         1004
#define IDM_SCM_OPEN           1005
#define IDM_SCM_CLOSE          1006
#define IDM_SCM_LOCK           1007
#define IDM_SCM_UNLOCK         1008
#define IDM_SERV_ACCESS        1009
#define IDM_SERV_SECURITY      1010
#define IDM_SERV_NEW           1011
#define IDM_SERV_EDIT          1012
#define IDM_SERV_DELETE        1013
#define IDM_SERV_START         1014
#define IDM_SERV_STOP          1015
#define IDM_SERV_PAUSE         1016
#define IDM_SERV_RESUME        1017
#define IDM_SERV_RESTART       1018
#define IDM_SERV_IOCONTROL     1019
#define IDM_REFRESH            1020
#define IDM_HELP               1021
#define IDM_ABOUT              1022

;----------------- ТУЛБАР ------------------------------------------------------
#define IDB_SCM_OPEN           51
#define IDB_SCM_CLOSE          52
#define IDB_SERV_NEW           53
#define IDB_SERV_EDIT          54
#define IDB_SERV_DELETE        55
#define IDB_SERV_START         56
#define IDB_SERV_STOP          57
#define IDB_SERV_PAUSE         58
#define IDB_SERV_RESUME        59
#define IDB_SERV_RESTART       60
#define IDB_REFRESH            61
#define IDB_HELP               62

;----------------- Диалоги ------------------------------------------------------
#define	IDC_OK                 1101
#define	IDC_CANCEL             1102
#define IDC_APPLY              1103


#define	IDD_ABOUT              1200
#define	IDC_ABOUT_DEVMAIL      1201

#define	IDD_SCM_ACCESS             1300
#define	IDC_SCM_ALL_ACCESS         1301
#define	IDC_SCM_STANDARDREAD       1302
#define	IDC_SCM_STANDARDWRITE      1303
#define	IDC_SCM_CONNECT            1304
#define	IDC_SCM_CREATE_SERVICE     1305
#define	IDC_SCM_ENUMERATE_SERVICE  1306
#define	IDC_SCM_MODIFY_BOOT_CONFIG 1307
#define	IDC_SCM_LOCK               1308
#define	IDC_SCM_QUERY_LOCK_STATUS  1309

#define	IDD_SERV_ACCESS               1400
#define	IDC_SERV_ALL_ACCESS           1401
#define	IDC_SERV_DELETE               1402
#define	IDC_SERV_READ_CONTROL         1403
#define	IDC_SERV_WRITE_DAC            1405
#define	IDC_SERV_WRITE_OWNER          1406
#define	IDC_SERV_QUERY_CONFIG         1407
#define	IDC_SERV_CHANGE_CONFIG        1408
#define	IDC_SERV_QUERY_STATUS         1409
#define	IDC_SERV_ENUMERATE_DEPENDENTS 1410
#define	IDC_SERV_START                1411
#define	IDC_SERV_STOP                 1412
#define	IDC_SERV_PAUSE_CONTINUE       1413
#define	IDC_SERV_INTERROGATE          1414
#define	IDC_SERV_USER_DEFINED_CONTROL 1415

#define IDD_SERVICE_PROPERTIES        1500
#define IDC_SERV_TAB                  1501

#define IDD_SERV_GENERAL              1600
#define IDC_SG_SNAME                  1601
#define IDC_SG_DNAME                  1602
#define IDC_SG_TYPE                   1603
#define IDC_SG_STARTTYPE              1604
#define IDC_SG_ERRORTYPE              1605
#define IDC_SG_GROUP                  1606
#define IDC_SG_TAG                    1607
#define IDC_SG_PATH                   1608
#define IDC_SG_PCHANGE                1609
#define IDC_SG_DESCRIPTION            1610
#define IDC_SG_INTERACTIVFLAG         1611

#define IDD_SERV_LOGON                1700
#define IDC_SL_LOCALSYSTEM            1701
#define IDC_SL_ANOTHER_ACCOUNT        1702
#define IDC_SL_ACCOUNT                1703
#define IDC_SL_ACHANGE                1704
#define IDC_SL_PASS                   1705
#define IDC_SL_CONFIRM                1706

#define IDD_SERV_RECOVERY             1800
#define IDC_SR_FIRST                  1801
#define IDC_SR_SECOND                 1802
#define IDC_SR_THIRD                  1803
#define IDC_SR_FCDELAY                1804
#define IDC_SR_SRDELAY                1805
#define IDC_SR_CRDELAY                1806
#define IDC_SR_PATH                   1807
#define IDC_SR_PCHANGE                1808
#define IDC_SR_MESSAGE                1809

#define IDD_SERV_DEPENDENCIES         1900
#define IDC_SD_SERVICE                1901   
#define IDC_SD_ADD_SERVICE            1902
#define IDC_SD_GROUP                  1903
#define IDC_SD_ADD_GROUP              1904
#define IDC_SD_DEPENDENCIES           1905
#define IDC_SD_DEL_SERVICE            1906
#define IDC_SD_UP                     1907
#define IDC_SD_DOWN                   1908

#define IDD_SERV_CONTROL              2000
#define IDC_SCTRL_TYPE                2001
#define IDC_SCTRL_STATUS              2002
#define IDC_SCTRL_OPERATION           2003
#define IDC_SCTRL_WIN32EXITCODE       2004
#define IDC_SCTRL_SERVEXITCODE        2005
#define IDC_SCTRL_CHECKPOINT          2006
#define IDC_SCTRL_WAITHINT            2007
#define IDC_SCTRL_START               2008
#define IDC_SCTRL_STOP                2009
#define IDC_SCTRL_PAUSE               2010
#define IDC_SCTRL_RESUME              2011
#define IDC_SCTRL_REFRESH             2012
#define IDC_SCTRL_USERCODE            2013
#define IDC_SCTRL_CONTROL             2014

#define IDD_CONNECT_TO                2100
#define IDC_CT_LOCAL                  2101
#define IDC_CT_REMOTE                 2102
#define IDC_CT_COMPNAME               2103
