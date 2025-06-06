TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

#=============================
# Build an ioc application
# Use PROD_IOC_RTEMS for RTEMS only
# Use PROD_IOC_Linux for Linux only
PROD_IOC = geneSys

PROD_SYS_LIBS_DEFAULT += pcre

# geneSys.dbd will be created and installed
DBD += geneSys.dbd

# geneSys.dbd will be made up from these files:
geneSys_DBD += base.dbd
geneSys_DBD += iocAdmin.dbd
geneSys_DBD += asSupport.dbd
geneSys_DBD += asyn.dbd
geneSys_DBD += stream.dbd
geneSys_DBD += drvAsynIPPort.dbd
geneSys_DBD += drvAsynSerialPort.dbd
geneSys_DBD += caPutLog.dbd

# <name>_registerRecordDeviceDriver.cpp will be created from <name>.dbd
geneSys_SRCS += geneSys_registerRecordDeviceDriver.cpp
geneSys_SRCS_DEFAULT += geneSysMain.cpp

# Add locally compiled object code
#geneSys_SRCS += dbSubExample.c
geneSys_SRCS += subPS.c

geneSys_LIBS += devIocStats
geneSys_LIBS += autosave
geneSys_LIBS += asyn
geneSys_LIBS += stream
geneSys_LIBS += caPutLog
geneSys_LIBS += $(EPICS_BASE_IOC_LIBS)

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE
