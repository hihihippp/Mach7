::
:: Script for testing C++ pattern matching library
::
:: Written by Yuriy Solodkyy <yuriy.solodkyy@gmail.com>
:: Version 1.0 from 21st July 2011
::
:: Usage: test-pgo.bat filename.cpp ...
::                                                                           
:: This file is a part of the XTL framework (http://parasol.tamu.edu/xtl/).
:: Copyright (C) 2005-2011 Texas A&M University.
:: All rights reserved.
:: 

@echo off

if "%1" == "/?" findstr "^::" "%~f0" & goto END

if not "%VS100COMNTOOLS%" == "" call "%VS100COMNTOOLS%vsvars32.bat" && echo Using MS Visual C++ 10.0 && goto PROCEED
if not "%VS90COMNTOOLS%"  == "" call "%VS90COMNTOOLS%vsvars32.bat"  && echo Using MS Visual C++ 9.0  && goto PROCEED
if not "%VS80COMNTOOLS%"  == "" call "%VS80COMNTOOLS%vsvars32.bat"  && echo Using MS Visual C++ 8.0  && goto PROCEED
if not "%VS71COMNTOOLS%"  == "" call "%VS71COMNTOOLS%vsvars32.bat"  && echo Using MS Visual C++ 7.1  && goto PROCEED

echo ERROR: Unable to find installation of MS Visual C++ on this computer
goto END

:PROCEED

set logfile=test-pgo.log
set results=test-pgo.txt

echo Test from %date% at %time% > %logfile%
echo Test from %date% at %time% > %results%

set CXX=cl.exe
rem /Zi /nologo /W3 /WX- /O2 /Ob2 /Oi /Ot /Oy- /GL  /GF /Gm- /MT /GS- /Gy- /fp:precise /Zc:wchar_t /Zc:forScope /Gr /analyze- /errorReport:queue 
rem set CXXFLAGS=/W4 /O2 /Ob2 /Oi /Ot /Og /GR /GL /GF /GS- /Gy- /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /I%BOOST%
rem /INCREMENTAL:NO /NOLOGO /SUBSYSTEM:CONSOLE /OPT:REF /OPT:ICF /LTCG /TLBID:1 /DYNAMICBASE:NO /NXCOMPAT /MACHINE:X86 /ERRORREPORT:QUEUE 
rem set LNKFLAGS=/LTCG /MACHINE:X86

set CXXFLAGS=/I%BOOST% /Zi /nologo /W3 /WX- /O2 /Ob2 /Oi /Ot /Oy- /GL /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /GF /Gm- /MT /GS- /Gy- /fp:precise /Zc:wchar_t /Zc:forScope /Gr /analyze- /errorReport:queue 
rem Slower: set CXXFLAGS=/I%BOOST% /Zi /nologo /W3 /WX- /O2 /Ob2 /Oi /Ot      /GL /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /GF /Gm- /MT /GS- /Gy  /fp:precise /Zc:wchar_t /Zc:forScope /Gr           /errorReport:queue 
set LNKFLAGS=/INCREMENTAL:NO /NOLOGO "kernel32.lib" "user32.lib" "gdi32.lib" "winspool.lib" "comdlg32.lib" "advapi32.lib" "shell32.lib" "ole32.lib" "oleaut32.lib" "uuid.lib" "odbc32.lib" "odbccp32.lib" /MANIFEST:NO /ALLOWISOLATION /SUBSYSTEM:CONSOLE /OPT:REF /OPT:ICF /LTCG /TLBID:1 /DYNAMICBASE:NO /NXCOMPAT /ERRORREPORT:QUEUE 

rem Set up VC variables for x86 build
call "%VCINSTALLDIR%vcvarsall.bat" x86
set M=X86

rem Set up VC variables for x64 build
rem call "%VCINSTALLDIR%vcvarsall.bat" x64
rem set M=X64

:TEST_ARG
for %%i in (%1) do call :COMPILE "%%i"
shift
if "%1" == "" goto END
goto TEST_ARG

:COMPILE

set filename=%~n1
<nul (set/p output=Working on %filename%: ) 
<nul (set/p output=- compiling ) 
%CXX% %CXXFLAGS% %1 /Fo%filename%.obj /Fe%filename%.exe /link %LNKFLAGS% /MACHINE:%M% >> %logfile% 2>&1
<nul (set/p output=- instrumenting )
%CXX% %CXXFLAGS% %1 /Fo%filename%-pgo.obj /Fe%filename%-pgo.exe /link %LNKFLAGS% /MACHINE:%M% /PGD:"%filename%-pgo.pgd" /LTCG:PGINSTRUMENT >> %logfile% 2>&1
<nul (set/p output=- profiling )
%filename%-pgo.exe > nul
<nul (set/p output=- optimizing )
link %LNKFLAGS% /MACHINE:%M% /PGD:"%filename%-pgo.pgd" %filename%-pgo.obj /LTCG:PGOPTIMIZE >> %logfile% 2>&1
rem del %filename%.obj %filename%.pdb %filename%-pgo.obj %filename%-pgo.pdb %filename%-pgo.pgd %filename%-pgo*.pgc
echo.

:END
