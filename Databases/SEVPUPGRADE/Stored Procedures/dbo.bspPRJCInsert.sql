SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRJCInsert    Script Date: 8/28/99 9:35:33 AM ******/
   CREATE  procedure [dbo].[bspPRJCInsert]
   /***********************************************************
    * Created: GG 06/12/98
    * Last Modified: GG 07/09/98
    *                  GG 07/30/99     -- Changes for EM Usage
    *                  GG 05/18/00     -- Added Shift to bPRJC
    *					EN 10/8/02 - issue 18877 change double quotes to single
    *
    * Called from bspPRUpdateValJC procedure to insert or update
    * JC distributions in bPRJC prior to an update.
    *
    * Inputs:
    *   @prco          PR Company
    *   @prgroup       PR Group
    *   @prenddate	    Pay Period Ending Date
    *   @mth	    Month to be exppensed
    *   @jcco          JC Company
    *   @job           Job
    *   @phasegroup    Phase Group
    *   @phase         Phase
    *   @jcctype       Cost Type
    *   @type          Record type 'L' = labor, 'B' = burden, 'E' = equipment usage
    *   @jcfields      JC interface fields - determines level of detail interfaced to JCCD
    *   @employee      Employee #
    *   @payseq        Payment Sequence
    *   @postseq       Posting Sequence of timecard
    *   @postdate      Timecard date
    *   @craft         Craft code
    *   @class         Class code
    *   @crew          Crew code
    *   @factor        Factor of posted earnings code
    *   @earntype	    Earnings type
    *   @shift         Shift
    *   @liabtype	    Liability type
    *   @emco          EM Company
    *   @equipment     Equipment code
    *   @emgroup       EM Group
    *   @revcode       Equipment Revenue code
    *   @jcglco        JC GL Co#
    *   @jcglacct      JC Expense GL Account
    *   @timeum        UM for time based Revenue codes
    *   @timeunits     Usage units for time based Revenue codes
    *   @workum        UM for unit based Revenue codes
    *   @workunits     Usage units for units based Revenue codes
    *   @hrs           # of hours to update
    *   @amt           $ amount based on type
    *   @jcum          JC UM based on job, phase, and cost type
    *   @jcunits       Usage units expressed in JC UM - unit based revenue codes only
    *
    * Output:
    *   none
    *
    * Return Value:
    *   none
    *****************************************************/
       (@prco bCompany, @prgroup bGroup, @prenddate bDate, @mth bMonth, @jcco bCompany, @job bJob,
        @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @type char(1), @jcfields char(70),
        @employee bEmployee, @payseq tinyint, @postseq smallint, @postdate bDate, @craft bCraft,
        @class bClass, @crew varchar(10), @factor bRate, @earntype bEarnType, @shift tinyint,
        @liabtype bLiabilityType, @emco bCompany, @equipment bEquip, @emgroup bGroup, @revcode bRevCode,
        @jcglco bCompany, @jcglacct bGLAcct, @timeum bUM, @timeunits bUnits, @workum bUM, @workunits bUnits,
        @hrs bHrs, @amt bDollar, @jcum bUM, @jcunits bUnits)
   as
   set nocount on
   
   update bPRJC set TimeUnits = TimeUnits + @timeunits, WorkUnits = WorkUnits + @workunits,
       Hrs = Hrs + @hrs, Amt = Amt + @amt, JCUnits = JCUnits + @jcunits
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Mth = @mth and JCCo = @jcco and
       Job = @job and PhaseGroup = @phasegroup and Phase = @phase and JCCostType = @jcctype and Type = @type
       and JCFields = @jcfields and Employee = @employee and PaySeq = @payseq and PostSeq = @postseq
   if @@rowcount = 0
       begin
       insert bPRJC (PRCo, PRGroup, PREndDate, Mth, JCCo, Job, PhaseGroup, Phase, JCCostType, Type, JCFields,
       	Employee,PaySeq, PostSeq, PostDate, Craft, Class, Crew, Factor, EarnType, Shift, LiabType, EMCo, Equipment,
    	EMGroup, RevCode, JCGLCo, JCGLAcct, TimeUM, TimeUnits, WorkUM, WorkUnits, Hrs, Amt, JCUM, JCUnits,
       OldWorkUnits, OldHrs, OldAmt, OldJCUnits)
       values (@prco, @prgroup, @prenddate, @mth, @jcco, @job, @phasegroup, @phase, @jcctype, @type, @jcfields,
      	    @employee, @payseq, @postseq, @postdate, @craft, @class, @crew, @factor, @earntype, @shift, @liabtype,
           @emco, @equipment, @emgroup, @revcode, @jcglco, @jcglacct, @timeum, @timeunits, @workum, @workunits,
           @hrs, @amt, @jcum, @jcunits, 0, 0, 0, 0)
       end
   return

GO
GRANT EXECUTE ON  [dbo].[bspPRJCInsert] TO [public]
GO
