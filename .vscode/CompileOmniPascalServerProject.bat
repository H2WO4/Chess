@echo off

SET MSBUILD="C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"
SET RSVARS="D:\Developement\Delphi\bin\rsvars.bat"
SET PROJECT="C:\Users\arthu\Documents\GitHub\Chess\Chess.dproj"

call %RSVARS%
%MSBUILD% %PROJECT% "/t:Clean,Make" "/verbosity:minimal"

if %ERRORLEVEL% NEQ 0 GOTO END

echo. 

if "%1"=="" goto END

if /i %1%==test (
  pushd "C:\Users\arthu\Documents\GitHub\Chess\Win32\Debug"
  "C:\Users\arthu\Documents\GitHub\Chess\Win32\Debug\Chess.exe" 
  popd
)
:END
