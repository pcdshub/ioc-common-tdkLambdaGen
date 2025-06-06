/*                                Copyright 1996
**                                      by
**                         The Board of Trustees of the
**                       Leland Stanford Junior University.
**                              All rights reserved.
**
**
**         Work supported by the U.S. Department of Energy under contract
**       DE-AC03-76SF00515.
**
**                               Disclaimer Notice
**
**        The items furnished herewith were developed under the sponsorship
**   of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
**   Leland Stanford Junior University, nor their employees, makes any war-
**   ranty, express or implied, or assumes any liability or responsibility
**   for accuracy, completeness or usefulness of any information, apparatus,
**   product or process disclosed, or represents that its use will not in-
**   fringe privately-owned rights.  Mention of any product, its manufactur-
**   er, or suppliers shall not, nor is it intended to, imply approval, dis-
**   approval, or fitness for any particular use.  The U.S. and the Univer-
**   sity at all times retain the right to use and disseminate the furnished
**   items for any purpose whatsoever.                       Notice 91 02 01
*/
/*=============================================================================

  Abs:  PS Calculations.

  Name: subPS.c      
	   subPSRegister   - Register All Subroutines
           subPSMainLimits - Alarm Limits for Main Power Supplies
           subPSCorLimits  - Alarm Limits for Corrector Power Supplies

  Proto: not required and not used.  All functions called by the
         subroutine record get passed one argument:

         psub                       Pointer to the subroutine record data.
          Use:  pointer               
          Type: struct subRecord *    
          Acc:  read/write            
          Mech: reference

         All functions return a long integer.  0 = OK, -1 = ERROR.
         The subroutine record ignores the status returned by the Init
         routines.  For the calculation routines, the record status (STAT) is
         set to SOFT_ALARM (unless it is already set to LINK_ALARM due to
         severity maximization) and the severity (SEVR) is set to psub->brsv
         (BRSV - set by the user in the database though it is expected to
          be invalid).

  Auth: 08-Jan-2004, Stephanie Allison

=============================================================================*/

#include <subRecord.h>        /* for struct subRecord      */
#include <registryFunction.h> /* for epicsRegisterFunction */
#include <epicsExport.h>      /* for epicsRegisterFunction */

long subPSMainLimits(struct subRecord *psub)
{
  /*
   * Calculate alarm limits from desired current.  If desired current is 0,
   * setpoint is changing, or the PS is off, then use max/min values to
   * disable alarms.
   *
   * Inputs:
   *          A = Desired Current
   *          B = Maximum (DRVH, or DRVL for negative main) 
   *          C = Not Used
   *          D = Fraction for Alarm   Limits (HIHI, LOLO) (0 = disable)
   *          E = Fraction for Warning Limits (HIGH, LOW)  (0 = disable)
   *          F = Setpoint currently changing? (0=no, 1=yes)
   *                                     (0=calc limits, 1=set limits to min/max)
   *          G = State    (0=off, 1=on) (1=calc limits, 0=set limits to min/max)
   *          H = Minimum allowed offset
   * Outputs:
   *          I = HIHI value
   *          J = HIGH value
   *          K = LOW  value
   *          L = LOLO value
   *        VAL = 1 for positive maximum, -1 for negative maximum
   */
  if (psub->b == 0.0) {
    if (psub->a < 0) psub->val = -1;
    else             psub->val =  1;
    psub->b = psub->a + psub->val;
  }
  else if (psub->b < 0) psub->val = -1;
  else                  psub->val =  1;
  psub->i = psub->j = psub->b + psub->val;
  psub->k = psub->l = -2 * psub->val;
  if (((psub->val * psub->a) > 0.02) && (psub->f < 0.01) && (psub->g > 0.01)) {
    if (psub->d > 0.0) {
      psub->l = psub->d * psub->a * psub->val;
      if (psub->l < psub->h) psub->l = psub->h;
      psub->i = psub->a + psub->l;
      psub->l = psub->a - psub->l;
    }
    if (psub->e > 0.0) {
      psub->k = psub->e * psub->a * psub->val;
      if (psub->k < psub->h) psub->k = psub->h;
      psub->j = psub->a + psub->k;
      psub->k = psub->a - psub->k;
    }
  }  
  return 0;
}

long subPSCorLimits(struct subRecord *psub)
{
  /*
   * Calculate alarm limits from gold value or setpoint.
   * If the alarms are disabled or the setpoint is currently changing,
   * then use max/min values to disable alarms.
   *
   * Inputs:
   *          A = Current Setpoint
   *          B = Maximum (DRVH)
   *          C = Gold Current
   *          D = Delta      for Warning Limits (HIGH, LOW)
   *          E = Multiplier for Alarm Limits
   *          F = Setpoint currently changing? (0=no, 1=yes)
   *              (0=calc limits, 1=set limits to min/max)
   *          G = State    (0=off, 1=on)
   *          H = Limits State
   *              (0=set limits to min/max, 1=use gold, 2=use setpoint)
   * Outputs:
   *          I = HIHI value
   *          J = HIGH value
   *          K = LOW  value
   *          L = LOLO value
   *        VAL = Delta for Alarm Limits (HIHI, LOLO)
   */
  if      (psub->b == 0.0) psub->b = psub->a + 1;
  else if (psub->b <  0.0) psub->b = -psub->b;
  psub->i =  psub->b;
  psub->l = -psub->b;
  psub->val = psub->d * psub->e;
  if ((psub->f < 0.5) && (psub->g > 0.5)) {
    if      (psub->h > 1.5) psub->i = psub->l = psub->a;
    else if (psub->h > 0.5) psub->i = psub->l = psub->c;
  }
  psub->j  = psub->i;
  psub->k  = psub->l;
  psub->i += psub->val;
  psub->j += psub->d;
  psub->k -= psub->d;
  psub->l -= psub->val;
  return 0;
}

epicsRegisterFunction(subPSMainLimits);
epicsRegisterFunction(subPSCorLimits);
