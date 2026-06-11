@echo off
rem Relocatable Windows launcher for the clautolisp/alfe binaries.
rem
rem Shipped as %PREFIX%\bin\<prog>.cmd (clautolisp, alfe, read-autolisp);
rem dispatches to the per-arch, per-Lisp executable under
rem   %PREFIX%\libexec\clautolisp\binaries\windows\<arch>\<prog>-<lisp>.exe
rem PREFIX is derived from this script's own location (%~dp0\..), so the
rem install tree is relocatable. No symbolic links are used: each program
rem gets its own copy of this trampoline; %~n0 selects the program.
rem
rem Lisp selection: CLAUTOLISP_LISP (or ALFE_LISP for alfe), else sbcl.
setlocal EnableExtensions

set "_A=%PROCESSOR_ARCHITECTURE%"
if /I "%_A%"=="AMD64" set "_A=x86-64"
if /I "%_A%"=="ARM64" set "_A=arm64"

set "_L=%CLAUTOLISP_LISP%"
if /I "%~n0"=="alfe" if not "%ALFE_LISP%"=="" set "_L=%ALFE_LISP%"
if "%_L%"=="" set "_L=sbcl"

set "_BIN=%~dp0..\libexec\clautolisp\binaries\windows\%_A%\%~n0-%_L%.exe"
if not exist "%_BIN%" (
  echo %~n0: no binary for windows/%_A% with lisp=%_L% 1>&2
  echo   expected: %_BIN% 1>&2
  exit /b 127
)
"%_BIN%" %*
exit /b %ERRORLEVEL%
