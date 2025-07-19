@echo off
setlocal EnableDelayedExpansion


goto :init

:init
    set "__root_path=%~dp0"
    set "__script_path=%__root_path%\scripts"
    set "__binary_path=%__root_path%\Release"
    set "__externals_path=%__root_path%\externals"
    set "__protect_project_path=%__root_path%\Protect.crproj"
    set "__protected_path=%__binary_path%\protected"
    set "__solution_file=%__root_path%\Confuser2.sln"
    set "__script_file=%~0"
    set "__target=%~1"
    set "__Confuser2_Sln=%__externals_path%\neo-ConfuserEx\Confuser2.sln"
    set "__compiler=%__script_path%\run_compiler.bat"
    set "__confuser_ex=%__externals_path%\neo-ConfuserEx\Release\bin\Confuser.CLI.exe"
    set "__PsRunnerApp=%__binary_path%\Release\PsRunnerApp.exe"
    set "__PsWrapperLib=%__binary_path%\Release\PsWrapperLib.dll"
    set "__build_cancelled=0"
    goto :prepare


:prepare
    rmdir /S /Q %__binary_path%
    ping localhost -n 2 >nul
    goto :output

:build_debug
    call %__compiler% "%__solution_file%" "/t:build" "/p:Configuration=Debug"
    goto :eof

:build_release
    call %__compiler% "%__solution_file%" "/t:build" "/p:Configuration=Release"
    goto :eof

:output
    echo "Compiler is %__compiler% and solution %__solution_file%"
    goto :build

:: ==============================================================================
::   Build
:: ==============================================================================
:build
	call :build_debug ""
    goto :finished


:finished
    goto :eof
