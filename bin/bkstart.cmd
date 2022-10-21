@echo off
setlocal

if "%~1" == "batch" goto :START_BATCH
if "%~1" == "info" goto :START_INFO
if "%~1" == "scan" goto :START_SCAN

set "LOG_NEEDED=true"

if "%~1" == "backup" goto :START_BACKUP
if "%~1" == "check" goto :START_COMMAND
if "%~1" == "forget" goto :START_COMMAND
if "%~1" == "key" goto :START_COMMAND
if "%~1" == "prune" goto :START_COMMAND
if "%~1" == "rebuild-index" goto :START_COMMAND
if "%~1" == "recover" goto :START_COMMAND
if "%~1" == "restore" goto :START_COMMAND
if "%~1" == "tag" goto :START_COMMAND
if "%~1" == "unlock" goto :START_COMMAND

set "LOG_NEEDED=false"

if "%~1" == "cache" goto :START_COMMAND
if "%~1" == "cat" goto :START_COMMAND
if "%~1" == "diff" goto :START_COMMAND
if "%~1" == "dump" goto :START_COMMAND
if "%~1" == "find" goto :START_COMMAND
if "%~1" == "list" goto :START_COMMAND
if "%~1" == "ls" goto :START_COMMAND
if "%~1" == "snapshots" goto :START_COMMAND
if "%~1" == "stats" goto :START_COMMAND

rem Unsupported restic commands:
rem copy, generate, help, init, migrate, mount, self-update, version

call :INIT_ENV

echo:
echo %~n0 is a wrapper for the restic backup program:
"%RESTIC%" version

echo:
echo Usage: %~n0 {command} [{flags}...]
echo:
echo Wrapper commands:
echo   info
echo   batch
echo   scan
echo:
echo Restic commands:
echo   backup
echo   cache
echo   cat
echo   check
echo   diff
echo   dump
echo   find
echo   forget
echo   key
echo   list
echo   ls
echo   prune
echo   rebuild-index
echo   recover
echo   restore
echo   snapshots
echo   stats
echo   tag
echo   unlock
echo:
echo For more details about supported restic commands listed above type: restic {command} --help

goto :EOF


:INIT_ENV
set "BIN_PATH=%~dp0"

set "THIS=%~f0"
set "RESTIC=%BIN_PATH%restic"
set "TEE=%BIN_PATH%coreutils\tee"

set "CONF_PATH=%BIN_PATH%..\conf\"
call :CANONIZE_PATH "CONF_PATH"

set "BACKUP_LIST_CONF=.bklist"

set "REPO_NAME="
set "REPO_NAME_CONF=.bkrepo"
if exist "%REPO_NAME_CONF%" set /p REPO_NAME=<"%REPO_NAME_CONF%"
if not defined REPO_NAME set "REPO_NAME=default"

set "REPO_PATH="
set "REPO_PATH_CONF=%CONF_PATH%repo_path"
if exist "%REPO_PATH_CONF%" set /p REPO_PATH=<"%REPO_PATH_CONF%"
if not defined REPO_PATH set "REPO_PATH=%BIN_PATH%..\repo\"
if not "%REPO_PATH:~-1%" == "\" set "REPO_PATH=%REPO_PATH%\"
call :CANONIZE_PATH "REPO_PATH"

goto :EOF


:INIT_LOGGING
call :INIT_ENV

set "LOG_PATH=%REPO_PATH%..\logs\"
if not exist "%LOG_PATH%" mkdir "%LOG_PATH%" || (
    echo Cannot create log directory. >&2
    exit 1
)
call :CANONIZE_PATH "LOG_PATH"

set "LOG_FILE=%LOG_PATH%%REPO_NAME%.log"

echo: >> "%LOG_FILE%"
echo STARTING SCRIPT >> "%LOG_FILE%"
echo %DATE% %TIME% >> "%LOG_FILE%"
echo: >> "%LOG_FILE%"

goto :EOF


:INIT_ARGS {SKIP_COUNT} {ARGS...}
setlocal
set "ARGS="
set "COUNT=%~1"

:INIT_ARGS_01
shift
if "%~1" == "" goto :INIT_ARGS_03
if %COUNT% LEQ 0 goto :INIT_ARGS_03
set /a "COUNT-=1"
goto :INIT_ARGS_01

:INIT_ARGS_02
shift
:INIT_ARGS_03
set "ARGS=%ARGS%%1 "
if not "%~1" == "" goto :INIT_ARGS_02

endlocal & set "ARGS=%ARGS:~0,-2%"
goto :EOF


:CANONIZE_PATH {PATH_VARIABLE}
call pushd "%%%~1%%" 2>NUL || goto :EOF
set "%~1=%__CD__%"
popd
goto :EOF


:ECHO_INFO
echo repo name: %REPO_NAME%
echo repo path: %REPO_PATH%
echo directory: %__CD__%
echo:
goto :EOF


:START_LABEL {LABEL} {ARGS...}
call :INIT_ARGS 1 %*
if not "%LOG_FILE%" == "" goto :START_LABEL_01
if not "%LOG_NEEDED%" == "false" goto START_LABEL_02

call :INIT_ENV

:START_LABEL_01
call :%~1 %ARGS%
goto :EOF

:START_LABEL_02
call :INIT_LOGGING
"%THIS%" %ARGS% 2>&1 | "%TEE%" -a "%LOG_FILE%"
goto :EOF


:START_COMMAND {ARGS...}
call :START_LABEL "START_COMMAND_01" %*
goto :EOF

:START_COMMAND_01
call :ECHO_INFO
goto :START_RESTIC


:START_RESTIC {ARGS...}
set "ARGS=%*"
if "%~1" == "" goto :START_RESTIC_01

set "EXTRA_ARGS="
set "EXTRA_ARGS_CONF=%CONF_PATH%args\%~1"
if exist "%EXTRA_ARGS_CONF%" set /p EXTRA_ARGS=<"%EXTRA_ARGS_CONF%"
if not defined EXTRA_ARGS goto :START_RESTIC_01

call :INIT_ARGS 1 %ARGS%
set "ARGS=%1 %EXTRA_ARGS% %ARGS%"

:START_RESTIC_01
echo STARTING:  restic %ARGS%
echo:

"%RESTIC%" --repo "%REPO_PATH%%REPO_NAME%" %ARGS%
echo:

goto :EOF


:START_INFO
call :INIT_ENV

call :ECHO_INFO

if exist "%BACKUP_LIST_CONF%" (
    echo backup list:
    type "%BACKUP_LIST_CONF%"
) else (
    echo All content of the current directory is to be backed up.
)
goto :EOF


:START_SCAN
call :INIT_ENV

set "SCAN_PATH=%~2"
if "%SCAN_PATH%" == "" (
    echo Scan path does not specified. >&2
    exit 1
)
if not exist "%SCAN_PATH%\" (
    echo Scan path does not exists. >&2
    exit 1
)

call :START_SCAN_01 "%SCAN_PATH%"
for /d /r "%SCAN_PATH%" %%a in (*) do call :START_SCAN_01 "%%a"
goto :EOF

:START_SCAN_01
setlocal
if exist "%~1\%BACKUP_LIST_CONF%" goto :START_SCAN_02
if exist "%~1\%REPO_NAME_CONF%" goto :START_SCAN_02
goto :EOF

:START_SCAN_02
setlocal
set "FOUND_PATH=%~1"
call :CANONIZE_PATH "FOUND_PATH"
echo %FOUND_PATH%
goto :EOF


:START_BATCH
call :INIT_ENV

echo Not implemented yet. >&2
exit 1


:START_BACKUP {ARGS...}
call :START_LABEL "START_BACKUP_01" %*
goto :EOF

:START_BACKUP_01
call :ECHO_INFO

if exist "%REPO_PATH%%REPO_NAME%" goto :START_BACKUP_02

echo No repo found with name "%REPO_NAME%", creating new one.
echo:

if not exist "%REPO_PATH%" (
    mkdir "%REPO_PATH%" || (
        echo Cannot create repo directory. >&2
        exit 1
    )
    call :CANONIZE_PATH "REPO_PATH"
)

call :START_RESTIC init

:START_BACKUP_02
call :INIT_ARGS 1 %*

if exist "%BACKUP_LIST_CONF%" (
    set "ARGS=--files-from "%BACKUP_LIST_CONF%" %ARGS%"
) else if "%CD:~-1%" == "\" (
    set "ARGS="%CD%." %ARGS%"
) else (
    set "ARGS="%CD%" %ARGS%"
)

call :START_RESTIC backup %ARGS%
goto :EOF
