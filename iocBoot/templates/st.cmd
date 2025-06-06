#!$$IOCTOP/bin/$$IF(ARCH,$$ARCH,rhel7-x86_64)/geneSys

< envPaths
epicsEnvSet( "ENGINEER" , "$$ENGINEER" )
epicsEnvSet( "IOCSH_PS1", "$$IOCNAME>" )
epicsEnvSet( "IOC_PV",    "$$IOC_PV"   )
epicsEnvSet( "LOCATION",  "$$IF(LOCATION,$$LOCATION,$$IOC_PV)")
epicsEnvSet( "IOCTOP",    "$$IOCTOP"   )
epicsEnvSet( "TOP",       "$$TOP"      )
epicsEnvSet(streamDebug, 0)
## Add the path to the protocol files
epicsEnvSet("STREAM_PROTOCOL_PATH", "$(IOCTOP)/protocol")
epicsEnvSet("PROTO", "geneSys_psu.proto")

cd( "$(IOCTOP)" )

# Run common startup commands for linux soft IOC's
< /reg/d/iocCommon/All/pre_linux.cmd

# Register all support components
dbLoadDatabase("dbd/geneSys.dbd")
geneSys_registerRecordDeviceDriver(pdbbase)

#------------------------------------------------------------------------------
# Asyn support

# Initialize IP Asyn support
$$LOOP(GENESYS)
drvAsynIPPortConfigure("GENESYS$$INDEX","$$PORT TCP",0,0,0)
$$ENDLOOP(GENESYS)

$$LOOP(GENESYS)
$$IF(ASYNTRACE)
asynSetTraceIOMask("GENESYS$$INDEX", 0, 0x6)
asynSetTraceMask  ("GENESYS$$INDEX", 0, 0x9)
asynSetTraceFile("GENESYS$$INDEX", 0, "/reg/d/iocData/$(IOC)/logs/GENESYS$$INDEX.log")
$$ELSE(ASYNTRACE)
$$ENDIF(ASYNTRACE)
$$ENDLOOP(GENESYS)

# Load record instances
dbLoadRecords("db/iocSoft.db",             "IOC=$(IOC_PV)")
dbLoadRecords("db/save_restoreStatus.db",  "P=$(IOC_PV):")

# Note: 
# The macro ADR is the address of the supply,
# which is set on the front panel (default=6)
# Note: the default port speed on device is set to 9600, COMSPD parameter below is just for gui display, actual communication speed is set in moxa/digi terminal server
$$LOOP(GENESYS)
dbLoadRecords("db/geneSys.db","DEV=$$BASE,PORT=GENESYS$$INDEX,ADR=$$IF(ADR,$$ADR,6),COMSPD=$$IF(COMSPD,$$COMSPD,9600),COMDEV=$$PORT,DSCAN=$$IF(DATASCAN,$$DATASCAN,1),CSCAN=$$IF(CONFSCAN,$$CONFSCAN,5)")
$$ENDLOOP(GENESYS)

# Setup autosave
set_savefile_path( "$(IOC_DATA)/$(IOC)/autosave" )
set_requestfile_path( "$(TOP)/autosave" )
save_restoreSet_status_prefix( "$(IOC_PV)" )
save_restoreSet_IncompleteSetsOk( 1 )
save_restoreSet_DatedBackupFiles( 1 )
set_pass0_restoreFile( "$(IOC).sav" )
set_pass1_restoreFile( "$(IOC).sav" )

# Initialize the IOC and start processing records
iocInit()

# Start autosave backups
create_monitor_set( "$(IOC).req", 5, "IOC=$(IOC_PV)" )

# All IOCs should dump some common info after initial startup.
< /reg/d/iocCommon/All/post_linux.cmd
