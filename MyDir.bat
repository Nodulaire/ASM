@echo off
 
if exist "MyDir.obj" del "MyDir.obj"
if exist "MyDir.exe" del "MyDir.exe"

\masm32\bin\ml /c /coff "MyDir.asm"
if errorlevel 1 goto errasm

\masm32\bin\PoLink /SUBSYSTEM:CONSOLE "MyDir.obj"
if errorlevel 1 goto errlink
dir "MyDir.*"
goto TheEnd

:errlink
echo _
echo Link error
goto TheEnd

:errasm
echo _
echo Assembly Error
goto TheEnd

:TheEnd
 
pause
