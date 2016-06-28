echo off
REM ################################################################
REM rsyncvmshare.bat
REM OurCIO(r) 20150901
REM ################################################################
REM rsync a guest directory to a direcory on the host 
REM coreos-vagrant guest on windows host
REM expects that a folder name of share<obj_vm_name> exists in this directory
REM expects that a folder name of /home/core/<obj_vm_name> exists on guest
REM see jschott2 on modifications of Vagrantfile to support this on 
REM Windows 7 host
REM core-01 core-02 core-03 guests
REM extensible for any $instance_name_prefix
REM ################################################################

REM Check to see if the variable exist
if "%1%" == "" GOTO USAGE
if "%2%"=="" GOTO USAGE
REM Maybe they just want to find out how things work
if "%1%" == "-h" GOTO USAGE
if "%1%" == "-H" GOTO USAGE
if "%1%" == "/?" GOTO USAGE
if "%1%" == "/h" GOTO USAGE
if "%1%" == "/H" GOTO USAGE
if "%1%" == "--help" GOTO USAGE
if "%1%" == "--HELP" GOTO USAGE

REM If you didn't use one of these then you are reading this for help!

REM Get a local environment on the Windows host
SetLocal

REM Set some environment variables 
REM These avoided problems in the rsync command using just %1% and %2%
set obj_vm_name=%1%
set obj_vm_username=%2%
IF "%3" NEQ "y" IF "%3%" NEQ "Y" GOTO RSYNC
echo "Contents before..."
dir c:\Users\jwsii\Documents\GitHub\coreos-vagrant\share%obj_vm_name%

:RSYNC
echo "Running rsync..."
rsync -a %obj_vm_username%@%obj_vm_name%:/home/core/%obj_vm_name%/ share%obj_vm_name%

IF "%3" NEQ "y" IF "%3%" NEQ "Y" GOTO END
echo "Contents after..."
dir c:\Users\jwsii\Documents\GitHub\coreos-vagrant\share%obj_vm_name%
GOTO END

REM Usage for the bat file named rsyncvmshare.bat
:USAGE
echo Usage for rsyncvmshare: syntax
echo "
echo "   rsyncvmshare <vmname> <username> <BeforeAfterSwitch>
echo "
echo "   where <vmname> is the name of the vm to act on and
echo "         <username> is a valid usename with password on that <vmname>
echo "            Note: if /home/<username> directory does not exist on <vmname>
echo "                  and error "No such file or directory" is thrown by rsync 
echo "                  AFTER the rsync command finishes.  Files are synced.
echo "         <BeforeAfterSwitch> set to "Y" or "y" will show 
echo "                             local dir contents before and after rsync
echo "                             This is optional and can be omitted.
echo "
echo "   you will be prompted for a password for <username>
echo "   it cannot be passed in the command
echo "

REM This is the Housekeeping end of things
:END
REM Clean up env variables used
REM      -- BELT --
set obj_vm_name=
set obj_vm_username=
REM Destroy the local environment we set up
REM   -- Suspenders --
EndLocal
echo on


