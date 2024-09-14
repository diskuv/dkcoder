@ECHO OFF
REM ##########################################################################
REM # File: dkcoder\dk.cmd                                                   #
REM #                                                                        #
REM # Copyright 2023 Diskuv, Inc.                                            #
REM #                                                                        #
REM # Licensed under the Open Software License version 3.0                   #
REM # (the "License"); you may not use this file except in compliance        #
REM # with the License. You may obtain a copy of the License at              #
REM #                                                                        #
REM #     https://opensource.org/license/osl-3-0-php/                        #
REM #                                                                        #
REM ##########################################################################

REM Recommendation: Place this file in source control.

REM The canonical way to run this script is: ./dk
REM That works in Powershell on Windows, and in Unix. Copy-and-paste works!

SETLOCAL

REM Coding guidelines
REM 1. Microsoft way of getting around PowerShell permissions:
REM    https://github.com/microsoft/vcpkg/blob/71422c627264daedcbcd46f01f1ed0dcd8460f1b/bootstrap-vcpkg.bat
REM 2. Hygiene: Capitalize keywords, variables, commands, operators and options
REM 3. Detect errors with `%ERRORLEVEL% EQU` (etc). https://ss64.com/nt/errorlevel.html

REM Invoke-WebRequest guidelines
REM 1. Use $ProgressPreference = 'SilentlyContinue' always. Terrible slowdown w/o it.
REM    https://stackoverflow.com/questions/28682642

SET DK_7Z_MAJVER=23
SET DK_7Z_MINVER=01
SET DK_7Z_DOTVER=%DK_7Z_MAJVER%.%DK_7Z_MINVER%
SET DK_7Z_VER=%DK_7Z_MAJVER%%DK_7Z_MINVER%
SET DK_CMAKE_VER=3.25.3
SET DK_NINJA_VER=1.11.1
SET DK_BUILD_TYPE=Release
SET DK_SHARE=%LOCALAPPDATA%\Programs\DkCoder
SET DK_PROJ_DIR=%~dp0
SET DK_PWD=%CD%

SET DK_CKSUM_7ZR=72c98287b2e8f85ea7bb87834b6ce1ce7ce7f41a8c97a81b307d4d4bf900922b
SET DK_CKSUM_7ZEXTRA=db3a1cbe57a26fac81b65c6a2d23feaecdeede3e4c1fe8fb93a7b91d72d1094c
SET DK_CKSUM_CMAKE=d129425d569140b729210f3383c246dec19c4183f7d0afae1837044942da3b4b
SET DK_CKSUM_NINJA=524b344a1a9a55005eaf868d991e090ab8ce07fa109f1820d40e74642e289abc

REM --------- Quiet Detection ---------

SET DK_ARG1=%1
SET DK_QUIET=0
IF "%DK_ARG1:~-5%" == "Quiet" SET DK_QUIET=1
SET DK_ARG1=

REM -------------- CMAKE --------------

REM Find CMAKE.EXE
where.exe /q cmake.exe >NUL 2>NUL
IF %ERRORLEVEL% NEQ 0 (
    goto FindDownloadedCMake
)
FOR /F "tokens=* usebackq" %%F IN (`where.exe cmake.exe`) DO (
    SET "DK_CMAKE_EXE=%%F"
)

REM Check if present at <data>/cmake-VER/bin/cmake.exe
:FindDownloadedCMake
IF EXIST %DK_SHARE%\cmake-%DK_CMAKE_VER%-windows-x86_64\bin\cmake.exe (
    SET "DK_CMAKE_EXE=%DK_SHARE%\cmake-%DK_CMAKE_VER%-windows-x86_64\bin\cmake.exe"
    GOTO ValidateCMake
)

REM Download CMAKE.EXE
REM     Why not CMAKE.MSI? Because we don't want to mess up the user's existing
REM     installation. `./dk` is meant to be isolated.
IF %DK_QUIET% EQU 0 (
    bitsadmin /transfer dkcoder-cmake /download /priority FOREGROUND ^
        "https://github.com/Kitware/CMake/releases/download/v%DK_CMAKE_VER%/cmake-%DK_CMAKE_VER%-windows-x86_64.zip" ^
        "%TEMP%\cmake-%DK_CMAKE_VER%-windows-x86_64.zip"
) ELSE (
    bitsadmin /transfer dkcoder-cmake /download /priority FOREGROUND ^
        "https://github.com/Kitware/CMake/releases/download/v%DK_CMAKE_VER%/cmake-%DK_CMAKE_VER%-windows-x86_64.zip" ^
        "%TEMP%\cmake-%DK_CMAKE_VER%-windows-x86_64.zip" >NUL
)
IF %ERRORLEVEL% EQU 0 (
    GOTO VerifyCMakeIntegrity
)
REM     Try PowerShell 3+ instead
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest https://github.com/Kitware/CMake/releases/download/v%DK_CMAKE_VER%/cmake-%DK_CMAKE_VER%-windows-x86_64.zip -OutFile '%TEMP%\cmake-%DK_CMAKE_VER%-windows-x86_64.zip'"
IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO.Could not download CMake %DK_CMAKE_VER%. Make sure that PowerShell is installed
    ECHO.and has not been disabled by a corporate policy.
    ECHO.
    EXIT /B 1
)
REM     Integrity check
:VerifyCMakeIntegrity
FOR /F "tokens=* usebackq" %%F IN (`certutil -hashfile "%TEMP%\cmake-%DK_CMAKE_VER%-windows-x86_64.zip" sha256 ^| findstr /v hash`) DO (
    SET "DK_CKSUM_ACTUAL=%%F"
)
IF "%DK_CKSUM_ACTUAL%" == "%DK_CKSUM_CMAKE%" (
    GOTO Download7zr
)
ECHO.
ECHO.Could not verify the integrity of CMake %DK_CMAKE_VER%.
ECHO.Expected SHA-256 %DK_CKSUM_CMAKE%
ECHO.but received %DK_CKSUM_ACTUAL%.
ECHO.Make sure that you can access the Internet, and there is nothing
ECHO.intercepting network traffic.
ECHO.
EXIT /B 1

REM Download 7zr.exe (and then 7z*-extra.7z) to do unzipping.
REM     Q: Why don't we use PowerShell `Expand-Archive`?
REM     Ans1: It is **insanely** slow. In Windows Sandbox it takes seven (7) MINUTES for
REM           CMake 3.28.1 (45,161,877 bytes). However in Windows Sandbox it
REM           takes seven (7) SECONDS to unzip using 7-Zip.
REM     Ans2: May be corporate policy to not allow PowerShell.
REM     Q: Can't we just download 7za.exe to do unzipping?
REM     Ans: That needs a dll so we would need two downloads regardless.
REM          7zr.exe can do un7z of 7z*-extra.7z which is 2 downloads as well.
REM          I guess we could repackage cmake.zip as cmake.7z and publish to GitLab CI.
REM          But it is easier to audit this using 7zr.exe and 7z*-extra.7z software
REM          from public download sites.
REM     Q: Why redirect stdout to NUL?
REM     Ans: It reduces the verbosity and errors will still be printed.
REM          Confer: https://sourceforge.net/p/sevenzip/feature-requests/1623/#0554
:Download7zr
IF %DK_QUIET% EQU 0 (
    bitsadmin /transfer dkcoder-7zr /download /priority FOREGROUND ^
        "https://github.com/ip7z/7zip/releases/download/%DK_7Z_DOTVER%/7zr.exe" ^
        "%TEMP%\7zr-%DK_7Z_DOTVER%.exe"
) ELSE (
    bitsadmin /transfer dkcoder-7zr /download /priority FOREGROUND ^
        "https://github.com/ip7z/7zip/releases/download/%DK_7Z_DOTVER%/7zr.exe" ^
        "%TEMP%\7zr-%DK_7Z_DOTVER%.exe" >NUL
)
IF %ERRORLEVEL% EQU 0 (
    GOTO Verify7zrIntegrity
)
REM     Try PowerShell 3+ instead
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest https://github.com/ip7z/7zip/releases/download/%DK_7Z_DOTVER%/7zr.exe -OutFile '%TEMP%\7zr-%DK_7Z_DOTVER%.exe'"
IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO.Could not download 7zr %DK_7Z_DOTVER%. Make sure that PowerShell is installed
    ECHO.and has not been disabled by a corporate policy.
    ECHO.
    EXIT /B 1
)
REM     Integrity check
:Verify7zrIntegrity
FOR /F "tokens=* usebackq" %%F IN (`certutil -hashfile "%TEMP%\7zr-%DK_7Z_DOTVER%.exe" sha256 ^| findstr /v hash`) DO (
    SET "DK_CKSUM_ACTUAL=%%F"
)
IF "%DK_CKSUM_ACTUAL%" == "%DK_CKSUM_7ZR%" (
    GOTO Download7zextra
)
ECHO.
ECHO.Could not verify the integrity of 7zr %DK_7Z_DOTVER%.
ECHO.Expected SHA-256 %DK_CKSUM_7ZR%
ECHO.but received %DK_CKSUM_ACTUAL%.
ECHO.Make sure that you can access the Internet, and there is nothing
ECHO.intercepting network traffic.
ECHO.
EXIT /B 1

REM Download 7z*-extra.7z to do unzipping.
:Download7zextra
IF %DK_QUIET% EQU 0 (
    bitsadmin /transfer dkcoder-7zextra /download /priority FOREGROUND ^
        "https://github.com/ip7z/7zip/releases/download/%DK_7Z_DOTVER%/7z%DK_7Z_VER%-extra.7z" ^
        "%TEMP%\7z%DK_7Z_VER%-extra.7z"
) ELSE (
    bitsadmin /transfer dkcoder-7zextra /download /priority FOREGROUND ^
        "https://github.com/ip7z/7zip/releases/download/%DK_7Z_DOTVER%/7z%DK_7Z_VER%-extra.7z" ^
        "%TEMP%\7z%DK_7Z_VER%-extra.7z" >NUL
)
IF %ERRORLEVEL% EQU 0 (
    GOTO Verify7zextraIntegrity
)
REM     Try PowerShell 3+ instead
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest https://github.com/ip7z/7zip/releases/download/%DK_7Z_DOTVER%/7z%DK_7Z_VER%-extra.7z -OutFile '%TEMP%\7z%DK_7Z_VER%-extra.7z'"
IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO.Could not download 7z%DK_7Z_VER%-extra.7z. Make sure that PowerShell is installed
    ECHO.and has not been disabled by a corporate policy.
    ECHO.
    EXIT /B 1
)
REM     Integrity check
:Verify7zextraIntegrity
FOR /F "tokens=* usebackq" %%F IN (`certutil -hashfile "%TEMP%\7z%DK_7Z_VER%-extra.7z" sha256 ^| findstr /v hash`) DO (
    SET "DK_CKSUM_ACTUAL=%%F"
)
IF "%DK_CKSUM_ACTUAL%" == "%DK_CKSUM_7ZEXTRA%" (
    GOTO Extract7zextra
)
ECHO.
ECHO.Could not verify the integrity of 7z%DK_7Z_VER%-extra.7z.
ECHO.Expected SHA-256 %DK_CKSUM_7ZEXTRA%
ECHO.but received %DK_CKSUM_ACTUAL%.
ECHO.Make sure that you can access the Internet, and there is nothing
ECHO.intercepting network traffic.
ECHO.
EXIT /B 1

REM Extract 7z*-extra.7z
:Extract7zextra
IF EXIST "%DK_SHARE%\7z%DK_7Z_VER%-extra" (
    RMDIR /S /Q "%DK_SHARE%\7z%DK_7Z_VER%-extra"
)
"%TEMP%\7zr-%DK_7Z_DOTVER%.exe" x -o"%DK_SHARE%\7z%DK_7Z_VER%-extra" "%TEMP%\7z%DK_7Z_VER%-extra.7z" >NUL
IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO.Could not extract 7z%DK_7Z_VER%-extra.7z.
    ECHO.
    EXIT /B 1
)
GOTO UnzipCMakeZip

REM Unzip CMAKE.EXE (use PowerShell; could download unzip.exe and sha256sum.exe as well in case corporate policy)
:UnzipCMakeZip
IF EXIST %DK_SHARE%\cmake-%DK_CMAKE_VER%-windows-x86_64 (
    RMDIR /S /Q %DK_SHARE%\cmake-%DK_CMAKE_VER%-windows-x86_64
)
"%DK_SHARE%\7z%DK_7Z_VER%-extra\7za" x -o"%DK_SHARE%" "%TEMP%\cmake-%DK_CMAKE_VER%-windows-x86_64.zip" >NUL
IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO.Could not unzip CMake %DK_CMAKE_VER%.
    ECHO.
    EXIT /B 1
)
SET "DK_CMAKE_EXE=%DK_SHARE%\cmake-%DK_CMAKE_VER%-windows-x86_64\bin\cmake.exe"

REM Validate cmake.exe
:ValidateCMake
"%DK_CMAKE_EXE%" -version >NUL 2>NUL
if %ERRORLEVEL% NEQ 0 (
	ECHO.
	ECHO.%DK_CMAKE_EXE%
	ECHO.is not responding to the -version option. Make sure that
	ECHO.CMake is installed correctly.
	ECHO.
	EXIT /B 1
)

REM -------------- NINJA --------------

REM Find NINJA.EXE
where.exe /q ninja.exe >NUL 2>NUL
IF %ERRORLEVEL% NEQ 0 (
    goto FindDownloadedNinja
)
FOR /F "tokens=* usebackq" %%F IN (`where.exe ninja.exe`) DO (
    SET "DK_NINJA_EXE=%%F"
)

REM Check if present at <data>/ninja-VER/bin/ninja.exe
:FindDownloadedNinja
IF EXIST %DK_SHARE%\ninja-%DK_NINJA_VER%-windows-x86_64\bin\ninja.exe (
    SET "DK_NINJA_EXE=%DK_SHARE%\ninja-%DK_NINJA_VER%-windows-x86_64\bin\ninja.exe"
    GOTO ValidateNinja
)

REM Download NINJA.EXE
IF %DK_QUIET% EQU 0 (
    bitsadmin /transfer dkcoder-ninja /download /priority FOREGROUND ^
        "https://github.com/ninja-build/ninja/releases/download/v%DK_NINJA_VER%/ninja-win.zip" ^
        "%TEMP%\ninja-%DK_NINJA_VER%-windows-x86_64.zip"
) ELSE (
    bitsadmin /transfer dkcoder-ninja /download /priority FOREGROUND ^
        "https://github.com/ninja-build/ninja/releases/download/v%DK_NINJA_VER%/ninja-win.zip" ^
        "%TEMP%\ninja-%DK_NINJA_VER%-windows-x86_64.zip" >NUL
)
IF %ERRORLEVEL% EQU 0 (
    GOTO VerifyNinjaIntegrity
)
REM     Try PowerShell 3+ instead
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest https://github.com/ninja-build/ninja/releases/download/v%DK_NINJA_VER%/ninja-win.zip -OutFile '%TEMP%\ninja-%DK_NINJA_VER%-windows-x86_64.zip'"
IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO.Could not download Ninja %DK_NINJA_VER%. Make sure that PowerShell is installed
    ECHO.and has not been disabled by a corporate policy.
    ECHO.
    EXIT /B 1
)
REM     Integrity check
:VerifyNinjaIntegrity
FOR /F "tokens=* usebackq" %%F IN (`certutil -hashfile "%TEMP%\ninja-%DK_NINJA_VER%-windows-x86_64.zip" sha256 ^| findstr /v hash`) DO (
    SET "DK_CKSUM_ACTUAL=%%F"
)
IF "%DK_CKSUM_ACTUAL%" == "%DK_CKSUM_NINJA%" (
    GOTO UnzipNinjaZip
)
ECHO.
ECHO.Could not verify the integrity of Ninja %DK_NINJA_VER%.
ECHO.Expected SHA-256 %DK_CKSUM_NINJA%
ECHO.but received %DK_CKSUM_ACTUAL%.
ECHO.Make sure that you can access the Internet, and there is nothing
ECHO.intercepting network traffic.
ECHO.
EXIT /B 1

REM Unzip NINJA.EXE (use PowerShell; could download unzip.exe and sha256sum.exe as well in case corporate policy)
:UnzipNinjaZip
IF EXIST %DK_SHARE%\ninja-%DK_NINJA_VER%-windows-x86_64 (
    RMDIR /S /Q %DK_SHARE%\ninja-%DK_NINJA_VER%-windows-x86_64
)
"%DK_SHARE%\7z%DK_7Z_VER%-extra\7za" x -o"%DK_SHARE%\ninja-%DK_NINJA_VER%-windows-x86_64\bin" "%TEMP%\ninja-%DK_NINJA_VER%-windows-x86_64.zip" >NUL
IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO.Could not unzip Ninja %DK_NINJA_VER%.
    ECHO.
    EXIT /B 1
)
SET "DK_NINJA_EXE=%DK_SHARE%\ninja-%DK_NINJA_VER%-windows-x86_64\bin\ninja.exe"

REM Validate ninja.exe
:ValidateNinja
"%DK_NINJA_EXE%" --version >NUL 2>NUL
if %ERRORLEVEL% NEQ 0 (
	ECHO.
	ECHO.%DK_NINJA_EXE%
	ECHO.is not responding to the --version option. Make sure that
	ECHO.Ninja is installed correctly.
	ECHO.
	EXIT /B 1
)

REM -------------- DkML PATH ---------
REM We get "git-sh-setup: file not found" in Git for Windows because
REM Command Prompt has the "Path" environment variable, while PowerShell
REM and `with-dkml` use the PATH environment variable. Sadly both
REM can be present in Command Prompt at the same time. Git for Windows
REM (called by FetchContent in CMake) does not comport with what Command
REM Prompt is using. So we let Command Prompt be the source of truth by
REM removing any duplicated PATH twice and resetting to what Command Prompt
REM thinks the PATH is.

SET _DK_PATH=%PATH%
SET PATH=
SET PATH=
SET PATH=%_DK_PATH%
SET _DK_PATH=

REM -------------- Escape command line --------------
REM We pack the entire command line into a double-quoted CMake -D option.
REM So we need to escape the double quotes for the CMake command line parser: " --> \"
SET DK_CMDLINE=%*
IF NOT "%DK_CMDLINE%" == "" SET DK_CMDLINE=%DK_CMDLINE:"=\"%

REM --- Create an 8-byte nonce ---
REM We should rely on Command Prompt not being compromised. Obviously
REM there is nothing we can do if it is compromised. But if it is
REM obviously compromised (ex. someone sets RANDOM) then fail fast.

SET DK_NONCE=%RANDOM%%RANDOM%%RANDOM%%RANDOM%
SET DK_NONCE2=%RANDOM%%RANDOM%%RANDOM%%RANDOM%
IF "%DK_NONCE%" == "%DK_NONCE2%" (
	ECHO.The RANDOM variable was preset rather than random.
	ECHO.This typically means your terminal session has been
	ECHO.compromised by malware. Consult with:
    ECHO.  https://consumer.ftc.gov/articles/how-recognize-remove-avoid-malware
	EXIT /B 1
)
SET DK_NONCE2=

REM -------------- Clear environment -------

SET DK_QUIET=

REM --------------- Console ----------------
REM Until https://github.com/ocaml/ocaml/pull/1408 fixed
REM Confer: https://stackoverflow.com/a/52139735
2>NUL >NUL TIMEOUT /T 0 && (
  REM stdin not redirected or piped
  CHCP 65001 >NUL
  SET DK_TTY=1
) || (
  REM stdin has been redirected or is receiving piped input
  SET DK_TTY=0
)

REM -------------- Run finder --------------

SET DK_WORKDIR=%DK_SHARE%\work

CD /d %DK_PROJ_DIR%
"%DK_CMAKE_EXE%" -D CMAKE_GENERATOR=Ninja -D "CMAKE_MAKE_PROGRAM=%DK_NINJA_EXE%" -D "DKCODER_PWD:FILEPATH=%DK_PWD%" -D "DKCODER_WORKDIR:FILEPATH=%DK_WORKDIR%" -D "DKCODER_NONCE:STRING=%DK_NONCE%" -D "DKCODER_TTY:STRING=%DK_TTY%" -D "DKCODER_CMDLINE:STRING=%DK_CMDLINE%" -P __dk.cmake
IF %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%

REM --------------- Execute post-command outside of CMake --------------
REM Sometimes a command wants to own the terminal or the command line arguments.
REM CMake, for example, intercepts the Ctrl-C signal in buggy ways:
REM https://stackoverflow.com/questions/75071180/pass-ctrlc-to-cmake-custom-command-under-vscode

REM     We don't use nested parentheses or else we'd have to be concerned about delayed
REM     variable expansion. https://stackoverflow.com/questions/24866477/if-call-exit-and-errorlevel-in-a-bat
IF EXIST "%DK_WORKDIR%\%DK_NONCE%.cmd" CALL "%DK_WORKDIR%\%DK_NONCE%.cmd" %*
@ECHO OFF
SET CALLERROR=%ERRORLEVEL%
IF EXIST "%DK_WORKDIR%\%DK_NONCE%.cmd" DEL /Q /F "%DK_WORKDIR%\%DK_NONCE%.cmd"
IF %CALLERROR% NEQ 0 EXIT /B %CALLERROR%
