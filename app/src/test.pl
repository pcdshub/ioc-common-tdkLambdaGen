#! /usr/bin/perl -w
#=============================================================================#
#                                                                             #
#                         Copyright (c) PSI 2007                              #
#                                                                             #
#=============================================================================#
#
#
# COMPONENT:
#  $Id: test.pl,v 1.1 2014/04/07 22:32:50 luchini Exp $
#
# TYPE:
#  perl test script.
#
# PURPOSE:
#  To test all the PV's
#
#
# FUNCTION:
#
#
#
# INTERFACES:
#  Call from the shell:
#       G_GENESYS-test -C <crate-name> -P <pvprefix>

#
#  Returns:
#       0 if no tests failed or
#       positive integer representing the number of failed tests
#
#
# DEPENDENCIES:
#    requires file G_GENESYS_<CRATE-NAME>_pvnames.list
#    requires xmessage program.
#    requires SOFTMON project PV names.
#
# AUTHOR:
#  $Author: luchini $
#
# HISTORY
#  $Log: test.pl,v $
#  Revision 1.1  2014/04/07 22:32:50  luchini
#   PS test perl script
#
#  Revision 1.2  2007/08/27 09:38:18  armstrong
#  Set current to zero after testing
#
#  Revision 1.1  2007/08/16 09:50:11  armstrong
#  initial import
#
#
#
#
###########################################################################
# Test Number - Requirement Id - Purpose 
# test        -                - Check all PVs exist
#                      
#
# Procedure Steps
# Describe how to log,
#               setup,
#               start,
#             procede,
#             measure,
#            shutdown,
#             restart,
#                stop,
#       wrap the test,
# handle contingencies
#
# @(#)$Source: /afs/slac/g/pcd/cvs/epics/iocTop/PowerSupplies/Genesys/geneSysApp/src/test.pl,v $
#

use Sys::Syslog qw(:DEFAULT setlogsock);
use POSIX;
# EPICS module for the perl interface
use Pezca;
# command line options
use Getopt::Std;

#### Variables ####
# Adjust the values of $path and $base to suit the testing environment
$pass=0;
$fail=0;
$status=0;
$testnum=0;
$cratename='unknown';
$modulename='GENESYS';
$pvname='unknown';
$prefix='unknown';
$base='';
$path='/sls/bin/G_';
$filename='_pvnames.list';
$description='';
$debug=0;
$tstpvname='';
$dbgpvname='';
$tagpvname='';
$datpvname='';
$ppvname='unknown';
$tag='';
$dat='';
$count=0;
$power=0.0;

###### program ######
openlog($modulename.'-test','ndelay','user');
setlogsock('unix');
# get options
#  -C CRATE-NAME       ie ARIAL-VME-1
#  -d debug_value
#  -P prefix  (macro $NAME)  ie PSU-01
getopt("CdP",\%args);
$cratename=$args{C};
$debug=$args{d};
$prefix=$args{P};
# check we have a parameter for the crate name
if(!$cratename)
 {
    $errorstring="No crate name supplied for ".$modulename." module testing";
    syslog ('info','INFO %s',$errorstring);
    system("xmessage -nearmouse -timeout 10 '$errorstring'&");
    closelog;
    $fail = 999;
    exit $fail;
  }
# check we have a parameter for the debug value (default to 0 = no debug)
if(!$debug)
  {
    $debug=0;
  }
#
# check we have a prefix for the name
if(!$prefix)
 {
    $errorstring="No prefix supplied to create PV names ".$modulename." module testing";
    syslog ('info','INFO %s',$errorstring);
    system("xmessage -nearmouse -timeout 10 '$errorstring'&");
    closelog;
    $fail = 999;
    exit $fail;
  }
#
syslog ('info','INFO %s testing module <%s>',$cratename,$modulename);
# commmon test pv names from SOFTMON module
$tstpvname=$cratename.':'.$modulename.'-TST';
$dbgpvname=$cratename.':'.$modulename.'-DBG';
$tagpvname=$cratename.':'.$modulename.'-TAG';
$datpvname=$cratename.':'.$modulename.'-DAT';
#
$base= $ENV{SLSBASE};
#
# ----- TO BE DONE -----
# check which SLSBASE we are testing /prod or /work as it should be the
# same as the SLSBASE which the ioc crate booted from
# check this from the oracle database and report if different
#
# if ($base.ne.$cratebase)
# {
#    $errorstring=" Crate booted from $cratebase but testing is being done from $base (correct SLSBASE required for testing)";
#    syslog ('info','INFO %s',$errorstring);
#    system("xmessage -nearmouse -timeout 10 '$errorstring'&");
#    closelog;
#    $fail = 999;
#    exit $fail;
# }
# ----- TO BE DONE ----
#
# STANDARD TEST check we can read all PV's
# we open the list of pv's in file G_$(MODULE)_(CRATE-NAME)_pvnames.list
#
$base= $ENV{SLSBASE};
# path to pv name list
$path=$base.$path.$modulename."_".$cratename.$filename;
# file open
sysopen(FILEHANDEL,$path,O_RDONLY)
    or die "couldn't open $path for reading: $!\n";
#
# read pv names from file
# check the pv exists by reading the DESC field
while (<FILEHANDEL>)
  {
    $testnum=$testnum+1;
    chomp;
    $pvname=$_.".DESC";
    ($status,$description)= Pezca::GetString($pvname);
    if ($status!=0)
      {
	$errorstring=" ".$cratename." test".$testnum." failed PV <".$pvname."> status was ".$status;
	syslog('warning','ALARM %s',$errorstring);
	$fail=9999;
#       status 1 =
#       status 2 =
#       status 3 =
#       status 4 =
#       status 5 = channel not currently connected
        closelog;
	print "$errorstring\n";
	exit $fail;
      }
    else
      {
	$pass=$pass+1;
	if ($debug!=0)
	  {
	    print "$cratename $pvname <$description>\n";
	  }
      }
  }
#
# all the above tests should have passed without error
syslog('info','INFO %s All PV names have been read',$cratename);
#
# requires SOFTMON module tag data
($status,$tag)= Pezca::GetString($tagpvname);
if ($status!=0)
  {
    $errorstring=" ".$cratename." failed to read PV <".$pvname."> status was ".$status;
    syslog('warning','ALARM %s',$errorstring);
    $fail=1;
    closelog;
    print "$errorstring\n";
    exit $fail;
  }
#
# date data
($status,$dat)= Pezca::GetString($datpvname);
if ($status!=0)
  {
    $errorstring=" ".$cratename." failed to read PV <".$pvname."> status was ".$status;
    syslog('warning','ALARM %s',$errorstring);
    $fail=1;
    closelog;
    print "$errorstring\n";
    exit $fail;
  }
#
syslog('info','INFO %s Testing tagged version <%s> installed on <%s>',$cratename,$tag,$dat);
syslog('info','INFO Using <%s> and <%s> for testing',$tstpvname,$dbgpvname);
#
# set test mode and debug mode for unit testing
#
# We switch on the test mode and check the GUI and alarm systen for correct responses
#
$status=Pezca::PutString($tstpvname,"1");
if ($status!=0)
  {
    $errorstring=" ".$cratename." failed to set testmode the status was ".$status;
    syslog('warning','ALARM %s',$errorstring);
    $fail=1;
    closelog;
    print "$errorstring\n";
    exit $fail;
  }
#
# define special tests for system
# UNIT software tests (no GENESYS Power Supply units need be connected)
# tests are non fatal as we can read all pv's
# but do require investigation as the database is BROKEN!!!
#
syslog('info','INFO %s testmode is ON',$cratename);
# enable serial communications
# to allow record processing
$pvname=$prefix.':COMSTAT';
$status=Pezca::PutString($pvname,"1");
#
# simulate the fault condition register
# Bit 0 not tested
# info description --------- val - pv string - zero msg ------ one msg
@testscr = (
["Mains Power Failure",       2, "FLT-ACF",   "AC OK",        "AC Fail"],
["Over Temperature Shutdown", 4, "FLT-OTP",   "OTP OK",       "OTP Alarm"],
["Foldback Shutdown",         8, "FLT-FOLD",  "FOLD OK",      "FOLD Alarm"],
["Over Voltage Shutdown",    16, "FLT-OVP",   "OVP OK",       "OVP Alarm"],
["Rear Panel Shutoff",       32, "FLT-SO",    "Shut-Off OK",  "Shut-Off Alarm"],
["Front Panel OUT button",   64, "FLT-OFF",   "FP OUT ON",    "FP OUT OFF"],
["Rear Panel Enable",       128, "FLT-ENA",   "ENABLE OK",    "ENABLE Open Alarm"],
);
#
#  Zero the FCR
$pvname=$prefix.':FCR.SVAL';
$status=Pezca::PutString($pvname,"0");
if ($status!=0)
  {
    $errorstring=" ".$cratename." failed to set fault condition register the status was ".$status;
    syslog('warning','ALARM %s',$errorstring);
    $fail=$fail+1;
    print "$errorstring\n";
  }
sleep 1;
# for each bit in the array
for ($count=0; $count<7; $count++)
{
  syslog('info','INFO %s testing %s display',$cratename, $testscr[$count][0]);
  $testnum=$testnum+1;
  $ppvname=$prefix.":".$testscr[$count][2];
  ($status,$description)= Pezca::GetString($ppvname);
  if ($description eq $testscr[$count][3])
    {
      $pass=$pass+1;
      if ($debug!=0)
	{
	  print "$cratename $ppvname $testscr[$count][4] Bit reset OK\n";
	}
    }
  else
    {
      # Error not OK
      $errorstring=" ".$cratename." test".$testnum." failed PV <".$ppvname."> ".$testscr[$count][4]." Bit not reset";
      syslog('warning','ALARM %s',$errorstring);
      $fail=$fail+1;
      print "$errorstring\n";
    }
  # set the bit
  $status=Pezca::PutString($pvname,$testscr[$count][1]);
  $testnum=$testnum+1;
  sleep 5;
  ($status,$description)= Pezca::GetString($ppvname);
  if ($description eq $testscr[$count][4])
    {
      # bit is set
      $pass=$pass+1;
      if ($debug!=0)
	{
	  print "$cratename $ppvname $testscr[$count][4] Bit set OK\n";
	}
    }
  else
    {
      $errorstring=" ".$cratename." test".$testnum." failed PV <".$ppvname."> ".$testscr[$count][4]." Bit not set";
      syslog('warning','ALARM %s',$errorstring);
      $fail=$fail+1;
      print "$errorstring\n";
    }
}
#
#
# reset all bits
$status=Pezca::PutString($pvname,"0");
sleep 5;
#
#
# simulate status condition register
#     Bit 6 not tested
# info description --------- val - pv string - zero msg ------ one msg
@testscr = (
["(Not CV/Constant Voltage)", 1, "STAT-CV",   "NOT CV",       "Constant Voltage"],
["(Not CC/Constant Current)", 2, "STAT-CC",   "NOT CC",       "Constant Current"],
["(Fault Active/Normal)"    , 4, "STAT-NFLT", "Fault Active", "Normal"],
["(NO Fault/Fault)"         , 8, "STAT-FLT",  "NO Fault",     "Fault"],
["(Safe Start/Auto Restart)",16, "STAT-AST",  "Safe Start",   "Auto Restart"],
["(Fb Disabled/Fb Enabled)" ,32, "STAT-FDE",  "Fb Disabled",  "Fb Enabled"],
["(REM or LL/Local Mode)"   ,128,"STAT-LCL",  "REM or LL",    "Local Mode"],
);
#
$pvname=$prefix.':SCR.SVAL';
$status=Pezca::PutString($pvname,"0");
if ($status!=0)
  {
    $errorstring=" ".$cratename." failed to set status condition register the status was ".$status;
    syslog('warning','ALARM %s',$errorstring);
    $fail=$fail+1;
    print "$errorstring\n";
  }
sleep 1;
# for each bit in the array
for ($count=0; $count<7; $count++)
{
  syslog('info','INFO %s testing %s display',$cratename, $testscr[$count][0]);
  $testnum=$testnum+1;
  $ppvname=$prefix.":".$testscr[$count][2];
  ($status,$description)= Pezca::GetString($ppvname);
  if ($description eq $testscr[$count][3])
    {
      $pass=$pass+1;
      if ($debug!=0)
	{
	  print "$cratename $ppvname $testscr[$count][4] Bit reset OK\n";
	}
    }
  else
    {
      # Error not OK
      $errorstring=" ".$cratename." test".$testnum." failed PV <".$ppvname."> ".$testscr[$count][4]." Bit not reset";
      syslog('warning','ALARM %s',$errorstring);
      $fail=$fail+1;
      print "$errorstring\n";
    }
  # set the bit
  $status=Pezca::PutString($pvname,$testscr[$count][1]);
  $testnum=$testnum+1;
  sleep 5;
  ($status,$description)= Pezca::GetString($ppvname);
  if ($description eq $testscr[$count][4])
    {
      # bit is set
      $pass=$pass+1;
      if ($debug!=0)
	{
	  print "$cratename $ppvname $testscr[$count][4] Bit set OK\n";
	}
    }
  else
    {
      $errorstring=" ".$cratename." test".$testnum." failed PV <".$ppvname."> ".$testscr[$count][4]." Bit not set";
      syslog('warning','ALARM %s',$errorstring);
      $fail=$fail+1;
      print "$errorstring\n";
    }
}
#
# Test power calculation
# Set Voltage
$pvname=$prefix.':GETVOLTS.SVAL';
$testnum=$testnum+1;
$status=Pezca::PutString($pvname,"250.0");
if ($status!=0)
  {
    $errorstring=" ".$cratename." failed to set GETVOLTS the status was ".$status;
    syslog('warning','ALARM %s',$errorstring);
    $fail=$fail+1;
    print "$errorstring\n";
  }
else
  {
    $pass=$pass+1;
    if ($debug!=0)
      {
	print "$cratename $ppvname voltage set to 250.0\n";
      }
  }
sleep 1;
# Set Current
$testnum=$testnum+1;
$pvname=$prefix.':GETCUR.SVAL';
$status=Pezca::PutString($pvname,"2.0");
if ($status!=0)
  {
    $errorstring=" ".$cratename." failed to set GETCUR the status was ".$status;
    syslog('warning','ALARM %s',$errorstring);
    $fail=$fail+1;
    print "$errorstring\n";
  }
else
  {
    $pass=$pass+1;
    if ($debug!=0)
      {
	print "$cratename $ppvname current set to 2.0\n";
      }
  }
# display power
syslog('info','INFO %s testing power calculation (500 Watts)',$cratename);
$testnum=$testnum+1;
sleep 10;
$pvname=$prefix.':CALCPWR';
($status,$power)= Pezca::GetDouble($pvname);
if ($power!=500.0)
  {
    $errorstring=" ".$cratename." failed calculation value should be 500 calculated as ".$power;
    syslog('warning','ALARM %s',$errorstring);
    $fail=$fail+1;
    print "$errorstring\n";
  }
else
  {
    $pass=$pass+1;
    if ($debug!=0)
      {
	print "$cratename $ppvname power calculated OK\n";
      }
  }
# reset voltage and current to zero
$pvname=$prefix.':GETCUR.SVAL';
$status=Pezca::PutString($pvname,"0.0");
$pvname=$prefix.':GETVOLTS.SVAL';
$status=Pezca::PutString($pvname,"0.0");
sleep 2;
#
#
#
#   -------  Finished -------
# disable serial communications
$pvname=$prefix.':COMSTAT';
$status=Pezca::PutString($pvname,"0");
# Switch off test mode
  $status= Pezca::PutString($tstpvname,"0");
#
if ($fail!=0)
  {
    syslog('warning','ALARM %s total number of tests = %d ( passed = %d  failed = %d)',$cratename,$testnum,$pass,$fail);
  }
else
  {
    syslog('info','INFO %s total number of tests = %d ( passed = %d  failed = %d)',$cratename,$testnum,$pass,$fail);
  }

closelog;

# return the number of failed tests
exit $fail;
