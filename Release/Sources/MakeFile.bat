..\..\MASM32\BIN\Rc.exe /v main.rc

..\..\MASM32\BIN\ML.EXE /c /coff /Cp /nologo main.asm
..\..\MASM32\BIN\ML.EXE /c /coff /Cp /nologo memory.asm
..\..\MASM32\BIN\ML.EXE /c /coff /Cp /nologo log.asm
..\..\MASM32\BIN\ML.EXE /c /coff /Cp /nologo services.asm
..\..\MASM32\BIN\ML.EXE /c /coff /Cp /nologo servicedlg.asm
..\..\MASM32\BIN\ML.EXE /c /coff /Cp /nologo controlservicedlg.asm
..\..\MASM32\BIN\ML.EXE /c /coff /Cp /nologo subserventdlg.asm
..\..\MASM32\BIN\ML.EXE /c /coff /Cp /nologo about.asm

..\..\MASM32\BIN\LINK.EXE /SUBSYSTEM:WINDOWS /RELEASE /OUT:ServiceManager.exe main.res main.obj memory.obj log.obj services.obj servicedlg.obj controlservicedlg.obj subserventdlg.obj about.obj
