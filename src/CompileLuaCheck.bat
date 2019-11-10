@echo off
IF EXIST CompileTemp.bat DEL /F /Q CompileTemp.bat >> NUL
IF EXIST main.exe DEL /F /Q main.exe >> NUL
IF EXIST LuaCheck.exe DEL /F /Q LuaCheck.exe >> NUL


echo|set /p="luastatic luacheck\main.lua " >> CompileTemp.bat

setlocal disableDelayedExpansion
for /f "delims=" %%A in ('forfiles /s /m *.lua /c "cmd /c echo @relpath"') do (
  set "file=%%~A"
  setlocal enableDelayedExpansion
  echo|set /p="!file:~2! " >> CompileTemp.bat
  endlocal
)

echo|set /p="lfs.a lanes.a " >> CompileTemp.bat

call CompileTemp.bat
ren main.exe LuaCheck.exe

IF EXIST CompileTemp.bat DEL /F /Q CompileTemp.bat >> NUL
