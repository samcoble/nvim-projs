@echo off
cls

REM Default action
set filename=eagle_mode
set action=run
set pid=0

REM Check for command line arguments
if "%1" == "-c" (
    if not "%2" == "" (
        set action=run
        if "%2%" == "b" (
            set action=build
        )
        set pid=%3
    )
)

REM g++ -o myprog main.cpp

if "%action%"=="build" (
    echo Building project...
    REM g++ -o myprog main.cpp
    gcc %filename%.c -o %filename%.exe
    set result=Build
) else (
    echo.
    echo /-/-----------------\-\
    echo ^|    ...RUNNING...    ^|
    echo \-\-----------------/-/
    echo PID: %pid%
    gcc %filename%.c -o %filename%.exe
    start cmd /c .\%filename%.exe -pid %pid%
    set result=Run
)

echo You chose to %result% the project.
