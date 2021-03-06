@echo off

if not defined source_root goto missing_root
if not defined target_platform goto missing_target_platform

if "%target_platform%" == "amd64" goto setup_amd64
if "%target_platform%" == "x86" goto setup_x86

echo Unknown platform: %target_platform%. Must be amd64 or x86
set ERRORLEVEL=1
goto eof

:setup_x86
echo Setting up Visual Studio environment for x86
call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86
goto setup_environment

:setup_amd64
echo Setting up Visual Studio environment for amd64
call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" amd64
goto setup_environment

:setup_environment
rem Unfortunately we need to have all of the directories
rem we build dll's in in the path in order to run make
rem test in a module..

echo Setting compile environment for building Couchbase server
set OBJDIR=\build
set MODULEPATH=%SOURCE_ROOT%%OBJDIR%\platform
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\libvbucket
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\cbsasl
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\memcached
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\couchstore
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\libmemcached
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\sigar\build-src
set PATH=%MODULEPATH%;%PATH%;%SOURCE_ROOT%\install\bin
set OBJDIR=
SET MODULEPATH=
cd %SOURCE_ROOT%
if "%target_platform%" == "amd64" set PATH=%PATH%;%SOURCE_ROOT%\install\x86\bin
goto eof

:missing_root
echo source_root should be set in the source root
set ERRORLEVEL=1
goto eof

:missing_target_platform
echo target_platform must be set in environment to x86 or amd64
set ERRORLEVEL=1
goto eof

:eof
