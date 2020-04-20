SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPRUpdateValGLExp]
/***********************************************************
* Created: GG 02/06/01
* Modified: EN 4/27/01 - issue #11553 - enhancement to interface hours to GL memo acccounts
*	     GG 05/29/01 - Update current JC Dept to Timecards (#13497)
*	     allenn 02/07/02 - #14175 Phase Overrides for default GL account
*		 GG 02/14/02 - #11997 - EM GL Account overrides by Earnings and Liability Type
*		 GG 02/16/02 - #16288 - Applied Burden GL Accounts by Liability Type
*		 GG 03/09/02 - #16459 - Removed JC/EM Use Dept option, added Interco Applied Earnings and Burden GL Accounts
*		 EN 3/11/02 - issue 14181 Use Equip Phase override if one was entered
*		 SR 07/09/02 - 17738 pass phasegroup to bspJCVPHASE
*		 EN 10/9/02 - issue 18877 change double quotes to single
*		 EN 8/26/03 - issue 22250 add JCCo to the JCDept missing GL Expense Acct error message
*	     DANF 10/30/03 - 22786 Added Phase GL Account valid part over ride.
*		 EN 12/09/03 - issue 23061  added isnull check, with (nolock), and dbo
*		 GG 12/16/03 - #23326 fix bJCDO search to handle null premium and/or liability override phases
*		 EN 2/6/04 - issue 22936 add code to validate for open month in PR GL Company
*		 						and check for existence of fiscal year in GL
*		 EN 11/10/04 - issue 26035 add validation for cross reference memo accounts
*		 JE 11/15/04 - issue 26213 add flags to not re-read information
*		 GG 05/09/05 - #28621 reset post type 
*		 JE 09/30/05 - issue 29969 fix null problem with performance flags
*	     JE 10/31/05 - issue 29909 fix null problem with performance flags
*	     JE 11/7/05  - issue 30293 - GL Account for burden expense in JC GL Co# needs to check for null
*		 JE 11/15/05 - issue 30363 - needs to use @prglco for JC Appled Burrden
*		 JE 12/28/05 - issue #119731/#119733 wrong goto & check for null GLAcct
*		 GG 11/14/06 - #123034/#124685 - JC Fixed Rate Template
*		 GG 10/16/07 - #125791 - fix for DDDTShared
*		 EV 04/13/11 - #TK-04236 Derive GL accounts from SM for SM records.
*		 TJL 04/28/11 - Issue #143863, If JCTemplateFixedRate Null or 0.00 use Employee JC Fixed Rate when available
*        EV 09/06/11 - TK-07418 Modify to use SM WIP account based on work order scope status.
*        EV 09/07/11 - TK-07418 Updated SMGL tables for each SM Labor record.
*
*
* Called from bspPRUpdateValGL to validate and load GL distributions
* for earnings, addons, and liability accruals into bPRGL prior to a Pay Period update.
*
* Errors are written to bPRUR unless fatal.
*
* Inputs:
*   @prco   			PR Company
*   @prgroup  			PR Group to validate
*   @prenddate			Pay Period Ending Date
*   @employee			Employee
*   @payseq				Payment Seq #
*   @paidmth			Paid Month
*   @beginmth			Pay Period Beginning Month
*   @endmth				Pay Period Ending Month
*   @cutoffdate			Pay Period Cutoff Date
*   @prglco				PR GL Co#
*   @glaccrualacct		PR Group GL Accrual Account
*   @empjcrate			Employee JC fixed rate
*   @emrate				Employee EM fixed rate
*
* Output:
*   @errmsg      error message if error occurs
*
* Return Value:
*   0         success
*   1         failure
*****************************************************/
    (@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @employee bEmployee = null,
     @payseq tinyint = null, @paidmth bMonth = null, @beginmth bMonth = null, @endmth bMonth = null,
     @cutoffdate bDate = null, @prglco bCompany = null, @glaccrualacct bGLAcct = null, @empjcrate bUnitCost = 0,
     @emrate bUnitCost = 0, @PRLedgerUpdateDistributionID bigint, @errmsg varchar(255) = null output)
   as
   
   set nocount on

DECLARE @DebugFlag bit
SET @DebugFlag=0
   
   declare @rcode int, @openTimecard tinyint, @openActualLiab tinyint, @openLiabType tinyint, @openGLLiab tinyint,
       @errortext varchar(255), @pphase bPhase, @validphasechars int, @openEMLiabType tinyint, @openSMLiab tinyint
   
declare @postseq smallint, @postdate bDate, @jcco bCompany, @job bJob, @phasegroup bGroup, @jcphase bPhase,
	@jcdept bDept, @glco bCompany, @emco bCompany, @equipment bEquip, @emgroup bGroup, @costcode bCostCode,
	@revcode bRevCode, @emctype bJCCType, @usageunits bHrs, @prdept bDept, @earncode bEDLCode, @hours bHrs,
	@amt bDollar, @earntype bEarnType, @factor bRate, @jcctype bJCCType, @equipphase bPhase,
	@craft bCraft, @class bClass, @shift tinyint, @ratetemplate smallint, @effectivedate bDate,
	@oldjcrate bUnitCost, @newjcrate bUnitCost, @jcrate bUnitCost, @prtype char(1)
   
   declare @mth bMonth, @lastmthsubclsd bMonth, @lastmthglclsd bMonth, @maxopen tinyint, @intercoARGLAcct bGLAcct,
       @intercoAPGLAcct bGLAcct, @glacct bGLAcct, @glamt bDollar, @memoacct bGLAcct, @glhrs bHrs
   
   declare @posttype char(2), @jobstatus tinyint, @liabtemplate smallint, @premphasegroup bGroup, @premphase bPhase,
       @premcosttype bJCCType, @subtype char(1), @creditamt bDollar, @dept bDept, @liabtype bLiabilityType, @overphase bPhase,
       @overcosttype bJCCType, @calcmethod char(1), @liabrate bRate, @costtype bJCCType, @liabamt bDollar, @saveamt bDollar,  
       @emlaborct bEMCType, @burdenrate bRate, @addonrate bRate, @emdept bDept, @burdenopt char(1),
   	   @prearnglacct bGLAcct, @jcappearnglacct bGLAcct, @emappearnglacct bGLAcct, @smappearnglacct bGLAcct, @intercoappearnglacct bGLAcct,
   	   @intercoappburdenglacct bGLAcct, @ephase bPhase, @overphasegrp bGroup, @SMCostAcct bGLAcct, @SMRevenueAcct bGLAcct, @SMInterCoAPGLAcct bGLAcct, @SMInterCoARGLAcct bGLAcct,
   	   @SMGLCo bCompany, @smliabglacct bGLAcct, @InputMask varchar(30), @InputType tinyint,
   	   @SMWorkCompletedID bigint, @PRLedgerUpdateMonthID bigint, @SMWorkCompletedDesc varchar(60), @SMJobRevenueGLEntryID bigint,
   	   @JCGLCostDetailDesc varchar(60), @TransDesc varchar(60), @GLTransaction int, @SalePrice bDollar, @ActualCostTotal bDollar, @SMDetailTransactionCostID bigint
   
  -- flags for performance routines
  declare @flg1prco bCompany, @flg2glco bCompany,@flg2prglco bCompany, @flg3prco bCompany,@flg3prdept bDept, @flg3earntype bEarnType
    ,@flg4jcco bCompany, @flg5jcco bCompany, @flg5job bJob, @flg6jcco bCompany , @flg6liabtemplate smallint
    ,@flg7jcco bCompany, @flg7job bJob , @flg7jcphase bPhase, @flg7phasegroup bGroup, @flg7jcdept bDept 
    ,@flg8prco bCompany, @flg8prgroup bGroup, @flg8prenddate bDate , @flg8employee bEmployee, @flg8jcdept bDept
    ,@flgAjcco bCompany, @flgAjob bJob , @flgApremphase bPhase, @flgAphasegroup bGroup, @flgAjcdept bDept
    ,@flgBpphase bPhase, @flgCglco bCompany,  @flgCglacct bGLAcct
  	,@flgDprglco bCompany,  @flgDglacct bGLAcct
  	,@flgEprglco bCompany,  @flgEglacct bGLAcct
  	,@flgFprglco bCompany,  @flgFglacct bGLAcct
  	,@flgGprglco bCompany,  @flgGglacct bGLAcct
  	,@flgHjcco  bCompany, @flgHjob bJob, @flgHoverphase bPhase, @flgHoverphasegrp bGroup, @flgHdept bDept
    	,@flgIphase bPhase
  	,@flgKglco  bCompany,@flgKglacct bGLAcct
  	,@flgLglco  bCompany,@flgLglacct bGLAcct
  	,@flgMglco  bCompany,@flgMglacct bGLAcct
  	,@flgNglco  bCompany,@flgNglacct bGLAcct
  
  declare @v1lastmthsubclsd bMonth, @v1lastmthglclsd bMonth, @v1maxopen	tinyint 	
    ,@v2lastmthsubclsd bMonth, @v2lastmthglclsd bMonth, @v2maxopen	tinyint 	
    ,@v2intercoARGLAcct bGLAcct, @v2intercoAPGLAcct  bGLAcct 
    ,@v3prearnglacct bGLAcct, @v3jcappearnglacct bGLAcct, @v3smappearnglacct bGLAcct
    ,@v3emappearnglacct bGLAcct, @v3intercoappearnglacct bGLAcct  
    ,@v4validphasechars int, @v5jobstatus tinyint, @v5liabtemplate smallint, @v5ratetemplate smallint
    ,@v6premphasegroup bGroup, @v6premphase bPhase, @v6premcosttype bJCCType
    ,@v7dept bDept, @v9glacct bGLAcct, @vAdept bDept	
    ,@vBpphase bPhase,@vHpphase bPhase, @vHdept bDept, @vIphase bPhase
  
  declare @flgJglco bCompany, @flgJglacct bGLAcct, @flgJsubtype char(1)
  
  declare @active char(1) --#120326 active code for validating cross-reference memo fields

	DECLARE @GLEntryTransaction TABLE (
		Employee bEmployee NOT NULL, PaySeq tinyint NOT NULL, PostSeq smallint NOT NULL,
		GLTransaction int NOT NULL, [Type] tinyint NOT NULL, EarnCode bEDLCode NULL, LiabilityType bLiabilityType NULL)
  		 
   select @rcode = 0, @glhrs = 0

IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLExp Start'

   -- get Phase Format 
   select @InputMask = InputMask, @InputType= InputType
   from dbo.DDDTShared (nolock) where Datatype ='bPhase'
   
   -- create Timecard cursor
   declare bcTimecard cursor LOCAL FAST_FORWARD for
   select h.Type, h.PostSeq, h.PostDate, h.JCCo, h.Job, h.PhaseGroup, h.Phase, h.JCDept, h.GLCo, h.EMCo, h.Equipment,
       h.EMGroup, h.CostCode, h.RevCode, h.EquipCType, h.UsageUnits, h.PRDept, h.EarnCode, h.Hours, h.Amt,
       e.Factor, e.EarnType, CASE WHEN [Type] = 'S' THEN h.SMJCCostType ELSE e.JCCostType END, h.EquipPhase, h.Craft, h.Class, h.Shift
   from dbo.bPRTH h with (nolock)	-- Timecards
   join dbo.bPREC e with (nolock) on e.PRCo = h.PRCo and e.EarnCode = h.EarnCode
   where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate and h.Employee = @employee
      	and h.PaySeq = @payseq
   order by h.PostSeq
   
   open bcTimecard
   select @openTimecard = 1

   next_Timecard:
       fetch next from bcTimecard into @prtype, @postseq, @postdate, @jcco, @job, @phasegroup, @jcphase, @jcdept, @glco,
           @emco, @equipment, @emgroup, @costcode, @revcode, @emctype, @usageunits, @prdept, @earncode, @hours,
           @amt, @factor, @earntype, @jcctype, @equipphase, @craft, @class, @shift

       if @@fetch_status = -1 goto end_Timecard
       if @@fetch_status <> 0 goto next_Timecard
		
       -- expense month based on posting date
       select @mth = @beginmth
       if @endmth is not null and @cutoffdate is not null and @postdate > @cutoffdate select @mth = @endmth
   	   if @mth <> @paidmth
  		 begin
         -- validate PR GL Company and Month
  		 if @prglco=@flg1prco and @flg1prco is not null   -- Issue 26213
  			select @lastmthsubclsd = @v1lastmthsubclsd, @lastmthglclsd = @v1lastmthglclsd, @maxopen = @v1maxopen
  		 else
  			begin -- flag
 
  	         	select @lastmthsubclsd = LastMthSubClsd, @lastmthglclsd = LastMthGLClsd, @maxopen = MaxOpen
  	         	from dbo.bGLCO with (nolock) where GLCo = @prglco
  	         	if @@rowcount = 0
  				begin
  				select @flg1prco=null  -- Issue 26213
  				select @errortext = 'Invalid ''Post To'' GL Company #' + convert(varchar(4),@prglco)
  				exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  				if @rcode = 1 goto bspexit
  				goto next_Timecard
  				end
  	         	if @mth <= @lastmthglclsd or @mth > dateadd(month, @maxopen, @lastmthsubclsd)
  				begin
  					select @flg1prco=null
  					select @errortext = substring(convert(varchar(8),@mth,3),4,5) + ' is not an open Month in GL Co# ' + convert(varchar(4),@prglco)
  					exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  					if @rcode = 1 goto bspexit
  					goto next_Timecard
  				end
  			 -- issue 22936  validate Fiscal Year 
  			 if not exists (select 1 from dbo.bGLFY with (nolock)
  			 		where GLCo = @prglco and @mth >= BeginMth and @mth <= FYEMO)
  				begin
  				select @flg1prco=null
  				select @errortext = 'Missing Fiscal Year for month ' + substring(convert(varchar(8),@mth,3),4,5) + ' to GL Co# ' + convert(varchar(4),@prglco)
  				exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  				if @rcode = 1 goto bspexit
  				goto next_Timecard
  				end
  			end -- flag 1 Issue 26213
   			select @flg1prco=@prglco, @v1lastmthsubclsd=@lastmthsubclsd, @v1lastmthglclsd=@lastmthglclsd, @v1maxopen	=@maxopen  	
  		 end
	   
		-- Get SM account information
		IF @prtype = 'S'
		BEGIN
			SELECT @SMWorkCompletedID = SMWorkCompletedID, @SMWorkCompletedDesc = [Description]
			FROM dbo.SMWorkCompletedAllCurrent
			WHERE CostCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate AND PREmployee = @employee AND PRPaySeq = @payseq AND PRPostSeq = @postseq
		
			SELECT @PRLedgerUpdateMonthID = PRLedgerUpdateMonthID
			FROM dbo.vSMWorkCompleted
			WHERE SMWorkCompletedID = @SMWorkCompletedID
			
			--To prevent work completed that has had WIP transferred from being deleted when a timecard is deleted
			--the work completed is associated with the PRLedgerUpdateMonth and is deleted after all WIP transfers have been
			--reversed out.
			IF @PRLedgerUpdateMonthID IS NULL
			BEGIN
				INSERT dbo.vPRLedgerUpdateMonth (PRCo, PRGroup, PREndDate, Mth)
				VALUES (@prco, @prgroup, @prenddate, @mth)

				SET @PRLedgerUpdateMonthID = SCOPE_IDENTITY()
				
				UPDATE dbo.vSMWorkCompleted
				SET PRLedgerUpdateMonthID = @PRLedgerUpdateMonthID
				WHERE SMWorkCompletedID = @SMWorkCompletedID
			END
			ELSE
			BEGIN
				UPDATE dbo.vPRLedgerUpdateMonth
				SET Mth = @mth
				WHERE PRLedgerUpdateMonthID = @PRLedgerUpdateMonthID
			END
			
			--The GLCo captured for SM timecards should be the SM GLCo for customer work orders and the JC GLCo for job work orders
			--@glco should be set to the SM GLCo at this point and for a job work order will be changed back to the JC GLCo once
			--the PR-SM intercompany accounts are retrieved and the months are verified as open.
			SELECT @glco = GLCo, @SMGLCo = GLCo, @SMCostAcct = CurrentCostAccount, @SMRevenueAcct = CurrentRevenueAccount
			FROM dbo.vfSMGetWorkCompletedGL(@SMWorkCompletedID)
		END
	   
	   if @glco <> @prglco or @glco is null or @prglco is null
             begin
  		 if @glco=@flg2glco and @prglco=@flg2prglco and  @flg2glco is not null --  Issue 26213
  			select @lastmthsubclsd = @v2lastmthsubclsd, @lastmthglclsd = @v2lastmthglclsd, @maxopen = @v2maxopen,
  				@intercoARGLAcct = @v2intercoARGLAcct, @intercoAPGLAcct = @v2intercoAPGLAcct
  		 else
  			begin --flag2 Issue 26213
  			-- validate 'posted to' GL Company and Month - should be JC GL Co# if job costed or EM GL Co# if equipment costed
  			select @lastmthsubclsd = LastMthSubClsd, @lastmthglclsd = LastMthGLClsd, @maxopen = MaxOpen
  			from dbo.bGLCO with (nolock) where GLCo = @glco
  			if @@rowcount = 0
  				begin
  				select @flg2glco=null -- Issue 26213
  				select @errortext = 'Invalid ''Post To'' GL Company #' + convert(varchar(4),@glco)
  				exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  				if @rcode = 1 goto bspexit
  				goto next_Timecard
  				end
  			if @mth <= @lastmthglclsd or @mth > dateadd(month, @maxopen, @lastmthsubclsd)
  				begin
  				select @flg2glco=null -- Issue 26213
  				select @errortext = substring(convert(varchar(8),@mth,3),4,5) + ' is not an open Month in GL Co# ' + convert(varchar(4),@glco)
  				exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  				if @rcode = 1 goto bspexit
  				goto next_Timecard
  				end
  			 -- issue 22936  validate Fiscal Year 
  			 if not exists (select 1 from dbo.bGLFY with (nolock)
  				where GLCo = @glco and @mth >= BeginMth and @mth <= FYEMO)
  				begin
  				select @flg2glco=null -- Issue 26213
  				select @errortext = 'Missing Fiscal Year for month ' + substring(convert(varchar(8),@mth,3),4,5) + ' to GL Co# ' + convert(varchar(4),@glco)
  				exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  				if @rcode = 1 goto bspexit
  				goto next_Timecard
  				end
  
  	         -- get Intercompany GL Accounts
  			select @intercoARGLAcct = ARGLAcct, @intercoAPGLAcct = APGLAcct
  				from dbo.bGLIA with (nolock) where ARGLCo = @prglco and APGLCo = @glco
  			if @@rowcount = 0
  				begin
  				select @flg2glco=null -- Issue 26213
  				select @errortext = 'Missing Intercompany GL Accounts entry for GL Co#s ' + convert(varchar(4),@prglco)
  				+ ' and ' + convert(varchar(4),@glco)
  				exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  				if @rcode = 1 goto bspexit
  				goto next_Timecard
  				end
  	         -- validate Interco AR GL Account
  	         exec @rcode = bspGLACfPostable @prglco, @intercoARGLAcct, 'N', @errmsg output
  	         if @rcode = 1
  				begin
  				select @flg2glco=null  -- Issue 26213
  				select @errortext = 'Intercompany AR GL Account: ' + isnull(@errmsg,'')
  				exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  				if @rcode = 1 goto bspexit
  				goto next_Timecard
  				end
  	         -- validate Interco AP GL Account
  	         exec @rcode = bspGLACfPostable @glco, @intercoAPGLAcct, 'N', @errmsg output
  	         if @rcode = 1
  				begin
  				select @flg2glco=null  -- Issue 26213
  				select @errortext = 'Intercompany AP GL Account: ' + isnull(@errmsg,'')
  				exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  				if @rcode = 1 goto bspexit
  				goto next_Timecard
  				end
  		 	end --flag2
  			select @flg2glco=@glco,@flg2prglco=@prglco, @v2lastmthsubclsd=@lastmthsubclsd, @v2lastmthglclsd=@lastmthglclsd, @v2maxopen	=@maxopen,  	
  				@v2intercoARGLAcct=@intercoARGLAcct, @v2intercoAPGLAcct  = @intercoAPGLAcct 
           end
   
   	-- get PR Department Earnings Expense and Applied Earnings accounts	- #16459
  	if @flg3prco = @prco and @flg3prdept=@prdept and @flg3earntype=@earntype and @flg3prco is not null
			and @prdept is not null and @earntype is not null
  		select @prearnglacct = @v3prearnglacct, @jcappearnglacct = @v3jcappearnglacct, @smappearnglacct=@v3smappearnglacct,
  			 @emappearnglacct =@v3emappearnglacct, @intercoappearnglacct = @v3intercoappearnglacct
  	else
  		begin -- flag3 -- Issue 26213
  		select @prearnglacct = GLAcct, @jcappearnglacct = JCAppEarnGLAcct, @emappearnglacct = EMAppEarnGLAcct, @smappearnglacct = SMAppEarnGLAcct,
  			@intercoappearnglacct = IntercoAppEarnGLAcct
  			from dbo.bPRDE with (nolock)
  			where PRCo = @prco and PRDept = @prdept and EarnType = @earntype
  		if @@rowcount = 0
  			begin
  			select @flg3prco=null  -- Issue 26213
  			select @errortext = 'Missing PR Department: ' + @prdept + ' and Earnings Type: ' + convert(varchar,@earntype)
  			exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  			if @rcode = 1 goto bspexit
  			goto next_Timecard
  			end
  		select @flg3prco=@prco , @flg3prdept=@prdept, @flg3earntype=@earntype,
  			@v3prearnglacct=  @prearnglacct , @v3jcappearnglacct=@jcappearnglacct, @v3smappearnglacct=@smappearnglacct,
  			@v3emappearnglacct=@emappearnglacct , @v3intercoappearnglacct=@intercoappearnglacct  
  		end  -- flag 3 Issue 26213
  	 
     -- initialize variables to determine where GL Accounts are pulled from
     select @posttype = 'PR', @glacct = null

	--Clear the transactions from processing the previous time card entry
	DELETE @GLEntryTransaction

	-- Get SM account information
	IF @prtype = 'S'
	BEGIN
		IF @jcco IS NOT NULL AND @job IS NOT NULL AND @jcphase IS NOT NULL
		BEGIN
			SET @posttype = 'JC'

			--For SM Job integration the assumpition is that the value of @glco was the
			--SM GLCo up to this point. From this point on the @glco will represent the JC GLCo.
			SELECT @glco = GLCo, @SMInterCoAPGLAcct = @intercoAPGLAcct
			FROM dbo.bPRTH
			WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate AND Employee = @employee AND PaySeq = @payseq AND PostSeq = @postseq

			IF @glco <> @SMGLCo
			BEGIN
				SELECT @lastmthsubclsd = LastMthSubClsd, @lastmthglclsd = LastMthGLClsd, @maxopen = MaxOpen
				FROM dbo.bGLCO
				WHERE GLCo = @glco
				IF @@rowcount = 0
				BEGIN
					SET @errortext = 'Invalid ''Post To'' GL Company #' + dbo.vfToString(@glco)
					EXEC @rcode = dbo.bspPRURInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @employee = @employee, @payseq = @payseq, @postseq = @postseq, @errortext = @errortext, @errmsg = @errmsg OUTPUT
					IF @rcode = 1 GOTO bspexit
					GOTO next_Timecard
				END

				IF @mth <= @lastmthglclsd OR @mth > DATEADD(MONTH, @maxopen, @lastmthsubclsd)
				BEGIN
					SET @errortext = dbo.vfToMonthString(@mth) + ' is not an open Month in GL Co# ' + dbo.vfToString(@glco)
					EXEC @rcode =  dbo.bspPRURInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @employee = @employee, @payseq = @payseq, @postseq = @postseq, @errortext = @errortext, @errmsg = @errmsg OUTPUT
					IF @rcode = 1 GOTO bspexit
					GOTO next_Timecard
				END
				
				IF NOT EXISTS(SELECT 1 FROM dbo.bGLFY WHERE GLCo = @glco AND @mth >= BeginMth AND @mth <= FYEMO)
				BEGIN
					SET @errortext = 'Missing Fiscal Year for month ' + dbo.vfToMonthString(@mth) + ' to GL Co# ' + dbo.vfToString(@glco)
					EXEC @rcode =  dbo.bspPRURInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @employee = @employee, @payseq = @payseq, @postseq = @postseq, @errortext = @errortext, @errmsg = @errmsg OUTPUT
					IF @rcode = 1 GOTO bspexit
					GOTO next_Timecard
				END

				 -- get Intercompany GL Accounts
				SELECT @SMInterCoARGLAcct = ARGLAcct, @intercoAPGLAcct = APGLAcct
				FROM dbo.bGLIA
				WHERE ARGLCo = @SMGLCo AND APGLCo = @glco
				IF @@rowcount = 0
				BEGIN
					SET @errortext = 'Missing Intercompany GL Accounts entry for GL Co#s ' + dbo.vfToString(@SMGLCo) + ' and ' + dbo.vfToString(@glco)
					EXEC @rcode =  dbo.bspPRURInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @employee = @employee, @payseq = @payseq, @postseq = @postseq, @errortext = @errortext, @errmsg = @errmsg OUTPUT
					IF @rcode = 1 goto bspexit
					GOTO next_Timecard
				END
				
				-- validate Interco AR GL Account
				EXEC @rcode = dbo.bspGLACfPostable @glco = @SMGLCo, @glacct = @SMInterCoARGLAcct, @chksubtype = 'N', @msg = @errmsg OUTPUT
				IF @rcode = 1
				BEGIN
					SET @errortext = 'Intercompany AR GL Account: ' + dbo.vfToString(@errmsg)
					EXEC @rcode =  dbo.bspPRURInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @employee = @employee, @payseq = @payseq, @postseq = @postseq, @errortext = @errortext, @errmsg = @errmsg OUTPUT
					IF @rcode = 1 goto bspexit
					GOTO next_Timecard
				END
				
				-- validate Interco AP GL Account
				EXEC @rcode = dbo.bspGLACfPostable @glco = @glco, @glacct = @intercoAPGLAcct, @chksubtype = 'N', @msg = @errmsg OUTPUT
				IF @rcode = 1
				BEGIN
					SET @errortext = 'Intercompany AP GL Account: ' + dbo.vfToString(@errmsg)
					EXEC @rcode =  dbo.bspPRURInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @employee = @employee, @payseq = @payseq, @postseq = @postseq, @errortext = @errortext, @errmsg = @errmsg OUTPUT
					IF @rcode = 1 goto bspexit
					GOTO next_Timecard
				END
			END
		END
		ELSE
		BEGIN
			SELECT @posttype='SM', @glacct = @SMCostAcct
		END
		
		INSERT dbo.vSMDetailTransaction (IsReversing, Posted, PRLedgerUpdateDistributionID, HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, PRMth, GLCo, GLAccount, Amount)
		SELECT 0 IsReversing, 0 Posted, @PRLedgerUpdateDistributionID, CostDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, 2/*For labor*/, 'C'/*C for cost*/, @prco, @mth, @mth, @SMGLCo, @SMCostAcct, 0
		FROM
		(
			SELECT SMWorkCompleted.*, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID
			FROM dbo.SMWorkCompleted
				INNER JOIN dbo.vSMWorkOrderScope ON SMWorkCompleted.SMCo = vSMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = vSMWorkOrderScope.Scope
				INNER JOIN dbo.vSMWorkOrder ON SMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
			WHERE SMWorkCompletedID = @SMWorkCompletedID
		) NewDetailTransaction

		SET @SMDetailTransactionCostID = SCOPE_IDENTITY()

		IF @posttype = 'JC'
		BEGIN
			SELECT @JCGLCostDetailDesc = GLCostDetailDesc
			FROM dbo.bJCCO
			WHERE JCCo = @jcco

			INSERT dbo.vPRLedgerUpdateMonth (PRCo, PRGroup, PREndDate, Mth)
			VALUES (@prco, @prgroup, @prenddate, @mth)

			SET @PRLedgerUpdateMonthID = SCOPE_IDENTITY()

			EXEC @SMJobRevenueGLEntryID = dbo.vspGLCreateEntry @Source = 'SM Job', @TransactionsShouldBalance = 0, @PRLedgerUpdateMonthID = @PRLedgerUpdateMonthID, @msg = @errmsg OUTPUT
		END
	END
	   
     -- get JC Company info
     if @jcco is not null and @job is not null and @jcphase is not null 
        begin 
  		 if @flg4jcco=@jcco and @flg4jcco is not null
  			select @validphasechars=@v4validphasechars, @posttype = 'JC'	-- #28621 set post type 
  		 else
  		 begin -- flag 4  -- Issue 26213
           	select @posttype = 'JC'   -- entry is job costed
      		select @validphasechars = ValidPhaseChars
   				from dbo.bJCCO with (nolock) where JCCo = @jcco
      		if @@rowcount = 0
            begin	
  				select @flg4jcco=null
      	    	select @errortext = 'Missing JC Company #' + convert(varchar(4),@jcco)
      	    	exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	    if @rcode = 1 goto bspexit
               	goto next_Timecard
          	end
  			select @flg4jcco=@jcco, @v4validphasechars =@validphasechars 
         end --flag 4  -- Issue 26213
  
         -- get Job info
  		 if @flg5jcco=@jcco and @flg5job=@job and @flg5jcco is not null
  			select @jobstatus = @v5jobstatus, @liabtemplate = @v5liabtemplate, @ratetemplate = @v5ratetemplate
  		 else
  		 begin -- flag 5  -- Issue 26213
  	         select @jobstatus = JobStatus, @liabtemplate = LiabTemplate, @ratetemplate = RateTemplate
  	         from dbo.bJCJM with (nolock) where JCCo = @jcco and Job = @job
  	         if @@rowcount = 0
  	         begin
  					select @flg5jcco = null
  	    	    	select @errortext = 'Invalid Job: ' + @job
  	    	    	exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	             if @rcode = 1 goto bspexit
  	             goto next_Timecard
  	         end
  			 select  @flg5jcco=@jcco , @flg5job=@job,  @v5jobstatus=@jobstatus,  @v5liabtemplate=@liabtemplate, @v5ratetemplate=@ratetemplate
  		 end --flag 5 -- Issue 26213
  
           -- get premium phase and cost type overrides from Liability Template
  		 if @flg6jcco=@jcco and @flg6liabtemplate=@liabtemplate and @flg6jcco is not null
  			select @premphasegroup = @v6premphasegroup, @premphase = @v6premphase, @premcosttype=@v6premcosttype
  		 else
  			 begin --flag 6 -- Issue 26213
  	         select @premphase = null, @premcosttype  = null
  	         if @liabtemplate is not null
  	             begin
  	             select @premphasegroup=PhaseGroup, @premphase = Phase, @premcosttype = CostType
  	             from dbo.bJCTH with (nolock) where JCCo = @jcco and LiabTemplate = @liabtemplate
  	             if @@rowcount = 0
                   	begin
  					select @flg6jcco=null
      	        	select @errortext = 'Invalid Liability Template: ' + convert(varchar(6),@liabtemplate)
      	        	exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          			if @rcode = 1 goto bspexit
                   	goto next_Timecard
          			end
  	             end
  			 select @flg6jcco=@jcco , @flg6liabtemplate=@liabtemplate, @v6premphasegroup=@premphasegroup,
  				 @v6premphase=@premphase, @v6premcosttype=@premcosttype		 
  			 end --flag 6 -- Issue 26213
  
   		-- get current JC Dept and update Timecard (#13497)
  		 if @flg7jcco=@jcco and @flg7job=@job and @flg7jcphase=@jcphase and @flg7phasegroup=@phasegroup and @flg7jcdept=@jcdept
 			and @flg7jcco is not null and @flg7jcdept is not null
  			select @dept=@v7dept, @jcdept=@flg7jcdept
  		 else
  			 begin -- flag 7 -- Issue 26213
  	 		 exec @rcode = bspJCVPHASE @jcco, @job, @jcphase,@phasegroup, 'N', @dept = @jcdept output, @msg = @errortext output
  	         if @rcode = 1
  	             begin
  			     select @flg7jcco=null
  	             select @errortext = 'Posted Phase: ' + isnull(@errortext,'')
  	             exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	     	     if @rcode = 1 goto bspexit
  	             goto next_Timecard
  	             end
  			 select @flg7jcco=@jcco , @flg7job=@job , @flg7jcphase=@jcphase , @flg7phasegroup=@phasegroup ,
  				 @flg7jcdept=@jcdept, @v7dept=@dept	 
  			 end -- flag 7 -- Issue 26213
  
   		-- update Timecard
          if @flg8prco<>@prco or @flg8prgroup <> @prgroup or @flg8prenddate <> @prenddate or @flg8employee <> @employee
  			or @flg8jcdept<>@jcdept or @flg8prco is null
  			begin   --flag 8 -- Issue 26213
  			if not exists(select 1 from dbo.bPRTH  where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
  				 and Employee = @employee and PaySeq = @payseq and PostSeq = @postseq and JCDept=@jcdept) 
  				begin
  		 		update dbo.bPRTH set JCDept = @jcdept
  		 		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
  		 	    	and PaySeq = @payseq and PostSeq = @postseq	
  					and JCDept<>@jcdept  -- issue 26213
  		 		if @@rowcount <> 1
  			 	    	begin
  					select @flg8prco=null
  			 	    	select @errortext = 'Unable to update current JC Dept into timecard entry.'
IF (@DebugFlag=1) PRINT '15  error='
IF (@DebugFlag=1) PRINT @errortext
  			 	    	exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  			     	if @rcode = 1 goto bspexit
  			          goto next_Timecard
  		     	    	end
  				end
  			select @flg8prco=@prco , @flg8prgroup = @prgroup , @flg8prenddate = @prenddate , @flg8employee = @employee
  				, @flg8jcdept=@jcdept
  			end   -- flag 8 -- Issue 26213
  
   		-- get JC Department Earnings account - check for override by Phase - #14175
       	select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
      	 	from dbo.bJCDO with (nolock)
      	 	where JCCo = @jcco and Department = @jcdept and PhaseGroup = @phasegroup and Phase = @jcphase and ExcludePR = 'N'
   		if @@rowcount = 0 and @validphasechars > 0
   			begin
  				begin -- flag 9 -- Issue 26213
  	 			-- check using valid portion
  	 			--select @pphase = substring(@jcphase,1,@validphasechars) + '%'
  	 			select @pphase  = substring(@jcphase,1,@validphasechars)
  	     		exec @rcode = bspHQFormatMultiPart @pphase, @InputMask, @pphase output
  	 			select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
  	 			from dbo.bJCDO with (nolock)
  	 			where JCCo = @jcco and Department = @jcdept and PhaseGroup = @phasegroup and Phase = @pphase and ExcludePR = 'N'
  				end			
   			end 
   		if @glacct is null 
   			begin
   			-- if no Phase override, get GL Account by Cost Type 
   	        select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
   	        from dbo.bJCDC with (nolock)
   	        where JCCo = @jcco and Department = @jcdept and PhaseGroup = @phasegroup and CostType = @jcctype
   	        -- check for Earnings Type override
   	        select @glacct = case @jobstatus when 3 then ClosedLaborAcct else OpenLaborAcct end
   	        from dbo.bJCDE with (nolock)
   	        where JCCo = @jcco and Department = @jcdept and EarnType = @earntype
   	        end
       end
   
       -- Mechanics timecards
       if @emco is not null and @equipment is not null and @costcode is not null
           begin
           select @posttype = 'EM'
           -- get EM Labor Cost Type 
           select @emlaborct = LaborCT from dbo.bEMCO with (nolock) where EMCo = @emco
           if @@rowcount = 0
               begin
               select @errortext = 'Missing EM Company #: ' + convert(varchar(4),@emco)
IF (@DebugFlag=1) PRINT '16  error='
IF (@DebugFlag=1) PRINT @errortext
      			exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	    if @rcode = 1 goto bspexit
               goto next_Timecard
               end
           -- get EM Department 
           select @emdept = Department
           from dbo.bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
           if @@rowcount = 0
               begin
               select @errortext = 'Missing Equipment: ' + @equipment
IF (@DebugFlag=1) PRINT '17  error='
IF (@DebugFlag=1) PRINT @errortext
      			exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	    if @rcode = 1 goto bspexit
               goto next_Timecard
               end
    		-- get EM Department Earnings GL Account - start with labor cost type
           select @glacct = GLAcct
           from dbo.bEMDG with (nolock)
   		where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and CostType = @emlaborct
           -- check for Cost Code override 
           select @glacct = GLAcct
           from dbo.bEMDO with (nolock)
   		where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and CostCode = @costcode and ExcludePR = 'N'
   		if @@rowcount = 0
   			begin
   			-- check for Earnings Type override - #11997 
   			select @glacct = GLAcct 
   			from dbo.bEMDE with (nolock) where EMCo = @emco and Department = @emdept and EarnType = @earntype
   			end
       end
	    
       -- validate Expense GL Account for Earnings
       if @posttype = 'PR' select @glacct = @prearnglacct, @subtype = 'N'   -- must be null
       if @posttype = 'JC' select @subtype = 'J'
       if @posttype = 'EM' select @subtype = 'E'
       if @posttype = 'SM' select @subtype = 'S'
   	 if @flgJglco is null or @flgJglco<>@glco or @flgJglacct is null or @flgJglacct<>@glacct 
  		or @flgJsubtype is null or @flgJsubtype<>@subtype or @flgJglacct is null or @glacct is null-- Issue #29969
  	 	begin
       		exec @rcode = bspGLACfPostable @glco, @glacct, @subtype, @errmsg output
  		    select @flgJglco=@glco , @flgJglacct=@glacct , @flgJsubtype=@subtype
       		if @rcode = 1
          	 begin
  		        select @flgJglco=null -- reset that this is not a valid acct
  		        if @posttype = 'PR' select @errortext = 'PR Dept: ' + @prdept 
  		        if @posttype = 'JC' select @errortext = 'JC Co#: ' + convert(varchar,@jcco) + ', JC Dept: ' + @jcdept --issue 22250
  		        if @posttype = 'EM' select @errortext = 'EM Dept: ' + @emdept
  		        if @posttype = 'SM' select @errortext = 'SM: ' 
  		        select @errortext = @errortext + ' and Earnings Type: ' + convert(varchar,@earntype) + ' - GL Expense: ' + isnull(@errmsg,'')
  		        exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  		        if @rcode = 1 goto bspexit
  		        goto next_Timecard
  		     end
  		end -- Issue #29969
	
	-- #123034 - JC Fixed Rate Template
	if @posttype = 'JC'
		begin
		if @ratetemplate is null
			begin
			select @jcrate = @empjcrate	-- use employee rate if no rate template assigned to job
			goto assign_glamt
			end
		else
			begin
			-- validate fixed rate template and get effective date
			select @effectivedate = EffectiveDate from dbo.bJCRT (nolock)
			where JCCo = @jcco and RateTemplate = @ratetemplate
			if @@rowcount = 0
				begin
				select @errortext = 'Job: ' + @job + ' assigned invalid Fixed Rate Template.'
				exec @rcode = dbo.bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
				if @rcode = 1 goto bspexit
				goto next_Timecard
				end
			-- get rates from JC Fixed Rate Template
			exec @rcode = dbo.bspPRUpdateGetFixedRate @jcco, @ratetemplate, @prco, @craft, @class,
				@shift, @factor, @employee, @oldjcrate output, @newjcrate output
			-- assign rate based on timecard post date and template effective date
			select @jcrate = @oldjcrate
			if @postdate >= @effectivedate select @jcrate = @newjcrate
			if @jcrate = 0.00 select @jcrate = @empjcrate		--Issue #143863, Conditions Rate Template not NULL but don't match employee
			end
		end

	assign_glamt:
       -- determine Earnings amount to post
       select @glamt = @amt, @glhrs = 0
       if @posttype = 'JC' and @jcrate <> 0 select @glamt = @hours * @jcrate   -- jc fixed rate
       if @posttype = 'JC' and @jcrate = 0 and @factor > 1 select @glamt = @amt / @factor, @saveamt = @glamt  -- straight time portion
       if @posttype = 'EM' and @emrate <> 0 select @glamt = @hours * @emrate   -- em fixed rate
       -- @posttype = 'SM' Uses amt from timecard

       if @glamt <> 0
           begin
			IF @prtype = 'S'
			BEGIN
				UPDATE dbo.vSMDetailTransaction
				SET Amount = Amount + @glamt
				WHERE SMDetailTransactionID = @SMDetailTransactionCostID
			END
           
			IF @posttype = 'JC' AND @prtype = 'S'
			BEGIN
				EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @SMGLCo, @glacct = @SMCostAcct, @employee = @employee, @payseq = @payseq, @amt = @glamt, @hours = @glhrs
				
				SELECT @creditamt = -(@glamt), @glhrs = 0
				
				IF @prglco <> @SMGLCo
				BEGIN
					EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @SMGLCo, @glacct = @SMInterCoAPGLAcct, @employee = @employee, @payseq = @payseq, @amt = @creditamt, @hours = @glhrs
					
					EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @prglco, @glacct = @intercoARGLAcct, @employee = @employee, @payseq = @payseq, @amt = @glamt, @hours = @glhrs
				END

				SELECT @TransDesc = @JCGLCostDetailDesc,
					@TransDesc = REPLACE(@TransDesc, 'Job', RTRIM(dbo.vfToString(@job))),
					@TransDesc = REPLACE(@TransDesc, 'Phase', RTRIM(dbo.vfToString(@jcphase))),
					@TransDesc = REPLACE(@TransDesc, 'CT', RTRIM(dbo.vfToString(@jcctype))),
					@TransDesc = REPLACE(@TransDesc, 'Trans Type', 'PR'),
					@TransDesc = REPLACE(@TransDesc, 'Desc', RTRIM(dbo.vfToString(@SMWorkCompletedDesc)))

				SET @GLTransaction = dbo.vfGLEntryNextTransaction(@SMJobRevenueGLEntryID)

				INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, [Source], GLCo, GLAccount, Amount, ActDate, [Description])
				VALUES (@SMJobRevenueGLEntryID, @GLTransaction, 'JC Cost', @glco, @glacct, @glamt, @prenddate, @TransDesc)

				INSERT @GLEntryTransaction
				VALUES (@employee, @payseq, @postseq, @GLTransaction, 1, NULL, NULL)
			END
			ELSE
			BEGIN
           -- add GL distribution to Debit Earnings Expense - 'Post to' GL Co#, Expense month
           exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @glacct, @employee, @payseq, @glamt, @glhrs
		   -- Update SM
           -- add Interco AP and AR entries
           if @glco <> @prglco
              begin
               -- Credit Intercompany AP  - 'Post to' GL Co#, Expense month
               select @creditamt = -(@glamt), @glhrs = 0
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @intercoAPGLAcct, @employee, @payseq, @creditamt, @glhrs
               -- Debit Intercompany AR - PR GL Co#, Expense montb 
 
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @intercoARGLAcct, @employee, @payseq, @glamt, @glhrs
               end
			END
           -- 'debit' hours if Cross Reference Memo Account exists
           select @memoacct = CrossRefMemAcct from dbo.bGLAC with (nolock) where GLCo = @glco and GLAcct = @glacct
           if @memoacct is not null
               begin
                if (select AcctType from dbo.bGLAC with (nolock) where GLCo = @glco and GLAcct = @memoacct) <> 'M'
                   begin
                    select @errortext = 'Earnings code ' + convert(varchar(6),@earncode) + ' Hours Memo : ' + 'GL Account ' + @memoacct + ' must be a Memo Account!'
                    exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
                  	 if @rcode = 1 goto bspexit
                    goto next_Timecard
                   end
  	           -- validate Cross Reference Memo Account
			   if @flgKglco<>@glco or @flgKglacct<>@memoacct or @flgKglco is null or @flgKglacct is null
  			      begin
  				    select @flgKglco=@glco, @flgKglacct=@memoacct 
					--#120326 validate cross-reference memo in-code rather than using bspGLACfPostable because that code is not suitable for PR purposes
					select @active = Active from bGLAC with (nolock) where GLCo = @glco and GLAcct = @memoacct
					if @@rowcount = 0
  						 begin
  						 select @flgKglco=null
  						 select @errortext = 'Cross Reference Memo Account: GL Co: ' + isnull(convert(varchar(3),@glco),'') + ' GL Account: ' + @memoacct + ' not found!'
  						 exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	        				if @rcode = 1 goto bspexit
  						 goto next_Timecard
  						 end

					if @active = 'N'
  						 begin
  						 select @flgKglco=null
  						 select @errortext = 'Cross Reference Memo Account: GL Co: ' + isnull(convert(varchar(3),@glco),'') + ' GL Account: ' + @memoacct + ' is inactive!'
  						 exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	        				if @rcode = 1 goto bspexit
  						 goto next_Timecard
  						 end
  	 		      end
   			      select @glamt = 0, @glhrs = @hours
                  exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @memoacct, @employee, @payseq, @glamt, @glhrs
               end
           end
   
       -- update premium time
       if @posttype = 'JC' and @jcrate = 0 and @factor > 1 -- must be job costed, not using fixed rate, and factor > 1
           begin
           select @glamt = @amt - @saveamt, @dept = @jcdept, @glhrs = 0     -- premium portion of posted earnings
           -- may use a different GL Account if directed to another cost type
           -- get JC Dept if phase overridden
  
           if @premphase is not null and @premphase <> @jcphase
               begin
  		 	 if @flgAjcco=@jcco and @flgAjob=@job and @flgApremphase=@premphase and @flgAphasegroup=@phasegroup and @flgAjcdept=@jcdept
 				and @flgAjcco is not null
  				select @dept=@vAdept
  		 	 else
  				 begin -- flag A -- Issue 26213
  	             exec @rcode = bspJCVPHASE @jcco, @job, @premphase, @premphasegroup, 'N', @dept = @dept output, @msg = @errortext output
  		 	 	 if @rcode >0 
 					select @flgAjcco = null
 					else
 					select @flgAjcco=@jcco , @flgAjob=@job , @flgApremphase=@premphase , @flgAphasegroup=@phasegroup,
  					  @flgAjcdept=@jcdept, @vAdept=@dept	
  	             end -- flag A -- Issue 26213
 		
  			 end
  
           if @dept <> @jcdept or (@premcosttype is not null and @premcosttype <> @jcctype)
   			begin
   			select @glacct = null	-- reset Job expense GL Account
   			-- check for GL Account override by Phase
   			select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
   			from dbo.bJCDO with (nolock)
   			where JCCo = @jcco and Department = @jcdept and PhaseGroup = @phasegroup and Phase = isnull(@premphase,@jcphase)	-- #23326 handle null premium phase
   				and ExcludePR = 'N'
   			if @@rowcount = 0 and @validphasechars > 0
   				begin
   				-- check using valid portion
   				--select @pphase = substring(isnull(@premphase,@jcphase),1,@validphasechars) + '%'	
   				select @pphase  = substring(isnull(@premphase,@jcphase),1,@validphasechars)	-- #23326 handle null premium phase
  				if @flgBpphase=@pphase and @flgBpphase is not null
  					select @pphase=@vBpphase --already have the full formated phasesaved
  				else
  					begin -- Issue 26213 bspHQFormatMultiPart is slow, skip running if possible
  					select @flgBpphase=@pphase -- set flag to partial phase
       				exec @rcode = dbo.bspHQFormatMultiPart @pphase, @InputMask, @pphase output
  					select @vBpphase=@pphase -- set phase value equal to the full phase
  					end -- Issue 26213
  				select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
   				from dbo.bJCDO with (nolock)
   				where JCCo = @jcco and Department = @jcdept and PhaseGroup = @phasegroup and Phase = @pphase and ExcludePR = 'N'
   				end 
   			if @glacct is null
   				begin
   				-- if no Phase override, get GL Account by Cost Type
   	            select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
   	            from dbo.bJCDC with (nolock)
   	            where JCCo = @jcco and Department = @dept and PhaseGroup = @phasegroup and CostType = @premcosttype
   	            -- check for Earnings Type override
   	            select @glacct = case @jobstatus when 3 then ClosedLaborAcct else OpenLaborAcct end
   	            from dbo.bJCDE with (nolock)
   	            where JCCo = @jcco and Department = @dept and EarnType = @earntype
   				end
   	        -- validate GL Account for premium earnings debit
			if @flgCglco<>@glco or @flgCglacct<>@glacct or @flgCglco is null or @glacct is null
  				begin  -- Issue 26213
  	 	        exec @rcode = bspGLACfPostable @glco, @glacct, 'J', @errmsg output
  	 	        if @rcode = 1
  	 	        	begin
  					select @flgCglco=null -- in case of error rest to null
  	 	            select @errortext = 'Premium portion of Earnings code ' + convert(varchar(6),@earncode) + '.  ' + isnull(@errmsg,'')
  	 	            exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	 	       	    if @rcode = 1 goto bspexit
  	 	            goto next_Timecard
  	 	            end
                  select @flgCglco=@glco , @flgCglacct=@glacct
   				end -- Issue 26213
  			end
           -- update GL distributions with debit for premium portion of posted earnings - posted in Expense Month
           if @glamt <> 0
               begin

				SELECT @creditamt = -(@glamt)

				IF @prtype='S'
				BEGIN
					UPDATE dbo.vSMDetailTransaction
					SET Amount = Amount + @glamt
					WHERE SMDetailTransactionID = @SMDetailTransactionCostID

					EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @SMGLCo, @glacct = @SMCostAcct, @employee = @employee, @payseq = @payseq, @amt = @glamt, @hours = @glhrs
					
					IF @prglco <> @SMGLCo
					BEGIN
						EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @SMGLCo, @glacct = @SMInterCoAPGLAcct, @employee = @employee, @payseq = @payseq, @amt = @creditamt, @hours = @glhrs
						
						EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @prglco, @glacct = @intercoARGLAcct, @employee = @employee, @payseq = @payseq, @amt = @glamt, @hours = @glhrs
					END

					SELECT @TransDesc = @JCGLCostDetailDesc,
						@TransDesc = REPLACE(@TransDesc, 'Job', RTRIM(dbo.vfToString(@job))),
						@TransDesc = REPLACE(@TransDesc, 'Phase', RTRIM(dbo.vfToString(isnull(@premphase,@jcphase)))),
						@TransDesc = REPLACE(@TransDesc, 'CT', RTRIM(dbo.vfToString(@jcctype))),
						@TransDesc = REPLACE(@TransDesc, 'Trans Type', 'PR'),
						@TransDesc = REPLACE(@TransDesc, 'Desc', RTRIM(dbo.vfToString(@SMWorkCompletedDesc)))

					SET @GLTransaction = dbo.vfGLEntryNextTransaction(@SMJobRevenueGLEntryID)

					INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, [Source], GLCo, GLAccount, Amount, ActDate, [Description])
					VALUES (@SMJobRevenueGLEntryID, @GLTransaction, 'JC Cost', @glco, @glacct, @glamt, @prenddate, @TransDesc)
					
					INSERT @GLEntryTransaction
					VALUES (@employee, @payseq, @postseq, @GLTransaction, 2, NULL, NULL)
				END
				ELSE
				BEGIN
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @glacct, @employee, @payseq, @glamt, @glhrs
               -- add Interco AP and AR entries
               if @glco <> @prglco
                   begin
                   exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @intercoAPGLAcct, @employee, @payseq, @creditamt, @glhrs

                   exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @intercoARGLAcct, @employee, @payseq, @glamt, @glhrs
                   end
               end
				END
           end
   
       -- additional distributions to PR Department needed if earnings are posted to Job, Equip, SM, or Intercompany
       if @posttype in ('JC','EM','SM') or @prglco <> @glco
           begin
           -- debit earnings to Payroll Expense GL Account based on PR Dept and Earnings type
           select @glamt = @amt, @glacct = @prearnglacct, @glhrs = 0
		 if @flgDprglco<>@prglco or @flgDglacct<>@glacct or @flgDprglco is null or @glacct is null
  			begin  -- Issue 26213
           	exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output
           	if @rcode = 1
               	begin
  				select @flgDprglco=null -- in case of error rest to null
               	select @errortext = 'Payroll Expense - PR Dept: ' + @prdept + ' and Earnings Type: ' + convert(varchar(4),@earntype) + '.  ' + isnull(@errmsg,'')
IF (@DebugFlag=1) PRINT '23  error='
IF (@DebugFlag=1) PRINT @errortext
               	exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	    if @rcode = 1 goto bspexit
               	goto next_Timecard
               	end
               select @flgDprglco=@prglco , @flgDglacct=@glacct
   			 end -- Issue 26213
           if @glamt <> 0
               begin
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLExp Exp8: GLCo='+Convert(varchar,@prglco)+' GLAcct='+ISNULL(@glacct,'NULL')+' GLAmt='+convert(varchar,@glamt)+' GLHrs='+convert(varchar,@glhrs)
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glacct, @employee, @payseq, @glamt, @glhrs
			end
   		-- credit Applied Earnings - unless interfaced to JC/EM at fixed rate
   		if (@posttype = 'JC' and @jcrate = 0) or (@posttype = 'EM' and @emrate = 0) or @posttype = 'PR' or @posttype='SM'
   			begin
   			select @glacct = case @posttype when 'SM' then @smappearnglacct when 'JC' then @jcappearnglacct when 'EM' then @emappearnglacct else @intercoappearnglacct end
   			select @creditamt = -(@glamt)
			if @flgEprglco<>@prglco or @flgEglacct<>@glacct	or @flgEprglco is null or @glacct is null
  				begin  -- Issue 26213		
   				exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output
  	         	if @rcode = 1
  	             	begin
  					select @flgEprglco=null -- in case of error rest to null
  	             	select @errortext = 'Applied Earnings - PR Dept: ' + @prdept + ' and Earnings Type: ' + convert(varchar(4),@earntype) + '.  ' + isnull(@errmsg,'')
  	             	exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	        	    if @rcode = 1 goto bspexit
  	             	goto next_Timecard
  	             	end
               	select @flgEprglco=@prglco , @flgEglacct=@glacct
   			 	end -- Issue 26213	
           	if @creditamt <> 0
               	begin
               	exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glacct, @employee, @payseq, @creditamt, @glhrs
   				end
   			end
           -- credit PR Dept Fixed Rate Contra Account if JC/EM interfaced at fixed rate
           -- SM always uses actuals - No fixed rates
   		if (@posttype = 'JC' and @jcrate <> 0) or (@posttype = 'EM' and @emrate <> 0)
   			begin
        		if @posttype = 'JC' select @glamt = -(@hours * @jcrate)
           	if @posttype = 'EM' select @glamt = -(@hours * @emrate)
           	select @glacct = case @posttype when 'JC' then JCFixedRateGLAcct else EMFixedRateGLAcct end
           		from dbo.bPRDP with (nolock) where PRCo = @prco and PRDept = @prdept
			if @flgFprglco<>@prglco or @flgFglacct<>@glacct	or @flgFprglco is null or @glacct is null
  				begin  -- Issue 26213	
           		exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output
  	         	if @rcode = 1
  	             	begin
  					select @flgFprglco=null -- in case of error rest to null
  	             	select @errortext = 'Fixed Rate Contra Account - PR Dept: ' + @prdept + ' ' + isnull(@errmsg,'')
IF (@DebugFlag=1) PRINT '25  error='
IF (@DebugFlag=1) PRINT @errortext
  	             	exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	        	    	if @rcode = 1 goto bspexit
  	             	goto next_Timecard
               		end
               	select @flgFprglco=@prglco , @flgFglacct=@glacct
   			 	end -- Issue 26213	
           	if @glamt <> 0
               	begin
               	exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glacct, @employee, @payseq, @glamt, @glhrs
               	end
           	end
   		end
   
       -- Accrual entries needed for all entries if expensed and paid in different months - use actual earnings - post in PR GL Co#
       if @mth <> @paidmth
           begin
           if @amt <> 0
               begin
               -- Payroll Accrual GL Account from PR Group has already been validated
               -- credit posted in expense month
               select @creditamt = -(@amt), @glhrs = 0
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLExp Exp11: GLCo='+Convert(varchar,@prglco)+' GLAcct='+@glaccrualacct+' GLAmt='+convert(varchar,@creditamt)+' GLHrs='+convert(varchar,@glhrs)
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glaccrualacct, @employee, @payseq, @creditamt, @glhrs
               -- debit posted in paid month
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLExp Exp12: GLCo='+Convert(varchar,@prglco)+' GLAcct='+@glaccrualacct+' GLAmt='+convert(varchar,@amt)+' GLHrs='+convert(varchar,@glhrs)
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @paidmth, @prglco, @glaccrualacct, @employee, @payseq, @amt, @glhrs
               end
           end
   
       -- GL distributions for actual liabilities - debited to PR Dept Liability accounts in PR GL Co#
       -- Applied Burden GL Account will be credited with interfaced burden 
       declare bcActualLiab cursor LOCAL FAST_FORWARD for
       select d.LiabType, isnull(convert(numeric(12,2),sum(l.Amt)),0)
       from dbo.bPRTL l with (nolock)
       join dbo.bPRDL d with (nolock) on d.PRCo = l.PRCo and d.DLCode = l.LiabCode
       where l.PRCo = @prco and l.PRGroup = @prgroup and l.PREndDate = @prenddate and l.Employee = @employee
            and l.PaySeq = @payseq and l.PostSeq = @postseq
       group by d.LiabType
   
       open bcActualLiab
       select @openActualLiab = 1, @glhrs = 0
   
       next_ActualLiab:
           fetch next from bcActualLiab into @liabtype, @liabamt
           if @@fetch_status = -1 goto end_ActualLiab
           if @@fetch_status <> 0 goto next_ActualLiab
   
           if @liabamt = 0 goto next_ActualLiab
           -- get Burden Expense GL Account from PR Dept
           select @glacct = null
           select @glacct = GLAcct
           from dbo.bPRDG with (nolock) where PRCo = @prco and PRDept = @prdept and LiabType = @liabtype
           -- validate GL Account
 		   if @flgGprglco<>@prglco or @flgGglacct<>@glacct or @flgGprglco is null or @glacct is null
  		   begin  -- Issue 26213	
  	         exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output
  	         if @rcode = 1
  	             begin
  				 select @flgGprglco=null
  	             select @errortext = 'Payroll Burden - PR Dept: ' + @prdept + ' - Liability Type: ' + convert(varchar(6),@liabtype) + '.  ' + isnull(@errmsg,'') 
IF (@DebugFlag=1) PRINT '26  error='
IF (@DebugFlag=1) PRINT @errortext
  	             exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
  	        	    if @rcode = 1 goto bspexit
  	             goto next_ActualLiab

  	             end
  			select @flgGprglco=@prglco, @flgGglacct=@glacct	
  		   end  -- Issue 26213	
           -- update GL distributions
           -- Debit Burden Expense to PR Dept Liab Acct - PR GL Co# - Expense Month
 
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLExp Exp13: GLCo='+Convert(varchar,@prglco)+' GLAcct='+ISNULL(@glacct,'NULL')+' GLAmt='+convert(varchar,@liabamt)+' GLHrs='+convert(varchar,@glhrs)+' LiabType='+Convert(varchar,@liabtype)
           exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glacct, @employee, @payseq, @liabamt, @glhrs

           if @mth <> @paidmth
               begin
               -- Payroll Accrual GL Account from PR Group has already been validated
               -- credit posted in expense month
               select @creditamt = -(@liabamt)
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLExp Exp14: GLCo='+Convert(varchar,@prglco)+' GLAcct='+@glaccrualacct+' GLAmt='+convert(varchar,@creditamt)+' GLHrs='+convert(varchar,@glhrs)
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glaccrualacct, @employee, @payseq, @creditamt, @glhrs
               -- debit posted in paid month
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLExp Exp15: GLCo='+Convert(varchar,@prglco)+' GLAcct='+@glaccrualacct+' GLAmt='+convert(varchar,@liabamt)+' GLHrs='+convert(varchar,@glhrs)
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @paidmth, @prglco, @glaccrualacct, @employee, @payseq, @liabamt, @glhrs
               end
          goto next_ActualLiab
   
       end_ActualLiab:
          close bcActualLiab
          deallocate bcActualLiab
          select @openActualLiab = 0
   
       /* GL distributions for burden interfaced to JC - options controlled by Job and Liability Template*/
       if @posttype = 'JC' and @jcrate = 0		-- skip if interfaced using fixed rate
           begin
           -- handle burden for the posted earnings using a cursor on Liability types assigned to Jobs' Liability Template
           declare bcLiabType cursor LOCAL FAST_FORWARD for
           select LiabType, Phase, CostType, CalcMethod, LiabilityRate, PhaseGroup
           from dbo.bJCTL with (nolock)
           where JCCo = @jcco and LiabTemplate = @liabtemplate
   
           open bcLiabType
           select @openLiabType = 1
   
           next_LiabType:
               fetch next from bcLiabType into @liabtype, @overphase, @overcosttype, @calcmethod, @liabrate, @overphasegrp
               if @@fetch_status = -1 goto end_LiabType
               if @@fetch_status <> 0 goto next_LiabType
   
               select @glamt = 0, @glacct = null, @glhrs = 0
               if @calcmethod = 'E'    -- interface exact amounts - done only once with posted earnings
                   begin
                   select @glamt = isnull(sum(l.Amt),0)
                   from dbo.bPRTL l with (nolock)
                   join dbo.bPRDL d with (nolock) on d.PRCo = l.PRCo and d.DLCode = l.LiabCode
                   where l.PRCo = @prco and l.PRGroup = @prgroup and l.PREndDate = @prenddate and l.Employee = @employee
                              and l.PaySeq = @payseq and l.PostSeq = @postseq and d.LiabType = @liabtype
                   end
               if @calcmethod = 'R'    -- interface as a rate of earnings
                   begin
      	            if exists(select 1 from dbo.bJCTE with (nolock) where JCCo = @jcco and LiabTemplate = @liabtemplate
                                  and LiabType = @liabtype and EarnCode = @earncode)
                   select @glamt = @amt * @liabrate    -- earnings must be subject to liability
                   end
               if @glamt = 0 goto next_LiabType
   
               -- get Burden Expense GL Account to debit
               select @dept = @jcdept, @costtype = @jcctype
               if @overcosttype is not null select @costtype = @overcosttype
               -- get JC Dept if phase overridden
               if @overphase is not null and @overphase <> @jcphase 
  	             begin
  		             exec @rcode = bspJCVPHASE @jcco, @job, @overphase, @overphasegrp, 'N', @dept = @dept output, @msg = @errortext output
  				 end
  
               -- get GL Account from JC Dept
   			select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
   			from dbo.bJCDO with (nolock)
   			where JCCo = @jcco and Department = @dept and PhaseGroup = @phasegroup and Phase = isnull(@overphase,@jcphase)	-- #23326 handle null override phase
   				and ExcludePR = 'N'
   			if @@rowcount = 0 and @validphasechars > 0
 
   				begin
   				if @flgIphase = @jcphase and @vIphase is not null  -- check if same phase as last time
  					select @pphase = @vIphase
  				else
  					begin
  	 				select @pphase  = substring(isnull(@overphase,@jcphase),1,@validphasechars)	-- #23326 handle null override phase
  	     			exec @rcode = dbo.bspHQFormatMultiPart @pphase, @InputMask, @pphase output
  					select @flgIphase = @jcphase, @vIphase=@pphase
  					end
  				select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
   				from dbo.bJCDO with (nolock)
   				where JCCo = @jcco and Department = @dept and PhaseGroup = @phasegroup and Phase = @pphase and ExcludePR = 'N'
   				end 
   			if @glacct is null
   				begin
   	            select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
   	            from dbo.bJCDC with (nolock)
   	            where JCCo = @jcco and Department = @dept and PhaseGroup = @phasegroup and CostType = @costtype
   	            -- check for Liability Type override
   	            select @glacct = case @jobstatus when 3 then ClosedBurdenAcct else OpenBurdenAcct end
   	            from dbo.bJCDL with (nolock)
   	            where JCCo = @jcco and Department = @dept and LiabType = @liabtype
   	            end
               -- validate GL Account for burden expense in JC GL Co# - must be subleder type 'J'
  		    if @flgLglco is null or @flgLglco<>@glco or @flgLglacct is null or @flgLglacct<>@glacct or @glacct is null  -- Issue #29969 & 30293
  			begin
  		     	    exec @rcode = bspGLACfPostable @glco, @glacct, 'J', @errmsg output
  			    select @flgLglco=@glco, @flgLglacct=@glacct 
               		if @rcode = 1
                   	  begin
  			          select @flgLglco=null
                    	  select @errortext = 'Burden Expense - JC Dept: ' + @dept + ' Liability Type: ' + convert(varchar(6),@liabtype)  +  ' - ' + isnull(@errmsg,'')
                   	  exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	          if @rcode = 1 goto bspexit
                       goto next_LiabType
     	 		end --Issue #29969               	  
  			end -- Issue #29969
               -- update GL distributions
               -- Debit for liability expense - JC GL Co# - Expense Month
 
				IF @prtype='S'
				BEGIN
					UPDATE dbo.vSMDetailTransaction
					SET Amount = Amount + @glamt
					WHERE SMDetailTransactionID = @SMDetailTransactionCostID

					EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @SMGLCo, @glacct = @SMCostAcct, @employee = @employee, @payseq = @payseq, @amt = @glamt, @hours = @glhrs
					
					--Capture SM Revenue
					SELECT @TransDesc = @JCGLCostDetailDesc,
						@TransDesc = REPLACE(@TransDesc, 'Job', RTRIM(dbo.vfToString(@job))),
						@TransDesc = REPLACE(@TransDesc, 'Phase', RTRIM(dbo.vfToString(ISNULL(@overphase, @jcphase)))),
						@TransDesc = REPLACE(@TransDesc, 'CT', RTRIM(dbo.vfToString(@costtype))),
						@TransDesc = REPLACE(@TransDesc, 'Trans Type', 'PR'),
						@TransDesc = REPLACE(@TransDesc, 'Desc', RTRIM(dbo.vfToString(@SMWorkCompletedDesc)))

					SET @GLTransaction = dbo.vfGLEntryNextTransaction(@SMJobRevenueGLEntryID)

					INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, [Source], GLCo, GLAccount, Amount, ActDate, [Description])
					VALUES (@SMJobRevenueGLEntryID, @GLTransaction, 'JC Cost', @glco, @glacct, @glamt, @prenddate, @TransDesc)

					INSERT @GLEntryTransaction
					VALUES (@employee, @payseq, @postseq, @GLTransaction, 3, NULL, @liabtype)
				END
				ELSE	
				BEGIN
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @glacct, @employee, @payseq, @glamt, @glhrs
				END
				
               -- Credit to PR Dept JC Applied Burden GL Account - PR GL Co# - Expense Month
               select @glacct = null
               select @glacct = JCAppBurdenGLAcct
               from dbo.bPRDG with (nolock) where PRCo = @prco and PRDept = @prdept and LiabType = @liabtype
    	        if @flgMglco is null or @flgMglco<>@prglco or @flgMglacct is null or @flgMglacct<>@glacct or @glacct is null  -- Issue #29969, 30363
  		      begin
  		      exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output  --Issue 30363
                   select @flgMglco=@prglco, @flgMglacct=@glacct  --Issue 30363
              	if @rcode = 1
                        begin
  	                 select @flgMglco=null
                        select @errortext = 'JC Applied Burden - PR Dept: ' + convert(varchar(6),@prdept)
   					+ ' Liability Type: ' + convert(varchar(6),@liabtype) + ' - ' + isnull(@errmsg,'')
                        exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	           if @rcode = 1 
                              goto bspexit
                        goto next_LiabType
   		           end
                   end -- Issue #29969
			
               select @creditamt = -(@glamt)
			
				IF @prtype='S'
				BEGIN
					EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @prglco, @glacct = @glacct, @employee = @employee, @payseq = @payseq, @amt = @creditamt, @hours = @glhrs

					IF @prglco <> @SMGLCo
					BEGIN
						EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @SMGLCo, @glacct = @SMInterCoAPGLAcct, @employee = @employee, @payseq = @payseq, @amt = @creditamt, @hours = @glhrs
						
						EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @prglco, @glacct = @intercoARGLAcct, @employee = @employee, @payseq = @payseq, @amt = @glamt, @hours = @glhrs
					END
				END
				ELSE
				BEGIN
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glacct, @employee, @payseq, @creditamt, @glhrs
   			  if @glco <> @prglco
   
                   begin
                   -- add Interco AP and AR entries
                   exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @intercoAPGLAcct, @employee, @payseq, @creditamt, @glhrs
 
                   exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @intercoARGLAcct, @employee, @payseq, @glamt, @glhrs
                   end
				END
               goto next_LiabType
   
           end_LiabType:
               close bcLiabType
               deallocate bcLiabType
               select @openLiabType = 0
           end
   
       -- GL distributions for liabilities interfaced to EM - #11997 
       if @posttype = 'EM' and @emrate = 0		-- skip if interfaced to EM using a fixed rate
           begin
   		-- handle burden for the posted earnings using a cursor on Liability types assigned in EM Company
   		-- Liability Types must be setup in EM to be interfaced
           declare bcEMLiabType cursor LOCAL FAST_FORWARD for
   		   select LiabType, BurdenType, BurdenRate, AddonRate
           from dbo.bEMPB with (nolock) where EMCo = @emco 
   
           open bcEMLiabType
           select @openEMLiabType = 1
   
           next_EMLiabType:
               fetch next from bcEMLiabType into @liabtype, @burdenopt, @burdenrate, @addonrate
               if @@fetch_status = -1 goto end_EMLiabType
               if @@fetch_status <> 0 goto next_EMLiabType
   
   			select @glamt = 0, @glacct = null, @glhrs = 0
               if @burdenopt = 'A'    -- addon burden, includes actual liab
                   begin
                   select @liabamt = isnull(sum(l.Amt),0)
                   from dbo.bPRTL l with (nolock)
                   join dbo.bPRDL d with (nolock) on d.PRCo = l.PRCo and d.DLCode = l.LiabCode
                   where l.PRCo = @prco and l.PRGroup = @prgroup and l.PREndDate = @prenddate and l.Employee = @employee
                              and l.PaySeq = @payseq and l.PostSeq = @postseq and d.LiabType = @liabtype
   				-- actual liability plus rate of earnings
   				select @glamt = @liabamt + (@addonrate * @amt)
                   end
               if @burdenopt = 'R'    -- override actual burden using rate of earnings - all earnings are included
                   begin
      	            select @glamt = @amt * @burdenrate     -- calculated burden
           		end
               
   			if @glamt = 0 goto next_EMLiabType
   
   			-- get EM Burden Expense account 
               select @glacct = GLAcct
               from dbo.bEMDG with (nolock)
        		where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and CostType = @emlaborct
               -- check for Cost Code override
               select @glacct = GLAcct
               from dbo.bEMDO with (nolock)
               where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and CostCode = @costcode
   				and ExcludePR = 'N'
   			if @@rowcount = 0
   				begin
   				-- if no override by Cost Code, check for Liab Type override
   				select @glacct = GLAcct
   				from dbo.bEMDL with (nolock)
   				where EMCo = @emco and Department = @emdept and LiabType = @liabtype
   				end
           	-- validate GL Account for burden expense in EM GL Co# - must be subleder type 'E'

			   if @flgNglco is null or @flgNglco<>@glco or @flgNglacct is null or @flgNglacct<>@glacct or @glacct is null -- Issue #29969
  				begin
  				exec @rcode = bspGLACfPostable @glco, @glacct, 'E', @errmsg output
  				select @flgNglco=@glco, @flgNglacct =@glacct 
  				-- end  -- Issue #29969 
               	if @rcode = 1
                   	begin
  			  		select @flgNglco=null
                   	select @errortext = 'Burden Expense - EM Dept: ' + @emdept + ' Liability Type: ' + convert(varchar(6),@liabtype) + ' - ' + isnull(@errmsg,'')
                   	exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	        if @rcode = 1 goto bspexit
                   	goto next_EMLiabType
                   	end
  				end  -- Issue #29969 
           	-- update GL distributions
           	-- Debit for liability expense - EM GL Co# - Expense Month
  
           	exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @glacct, @employee, @payseq, @glamt, @glhrs
           	-- Credit to PR Dept EM Applied Burden GL Account - PR GL Co# - Expense Month
           	select @glacct = null
           	select @glacct = EMAppBurdenGLAcct
           	from dbo.bPRDG with (nolock) where PRCo = @prco and PRDept = @prdept and LiabType = @liabtype
           	exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output
           	if @rcode = 1
               	begin
               	select @errortext = 'EM Applied Burden for PR Dept: ' + convert(varchar(6),@prdept)
   					+ ' Liability Type: ' + convert(varchar(6),@liabtype) + ' - ' + isnull(@errmsg,'')
               	exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	    	if @rcode = 1 goto bspexit
               	goto next_EMLiabType
               	end
           	select @creditamt = -(@glamt)
  
           	exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glacct, @employee, @payseq, @creditamt, @glhrs
           	if @glco <> @prglco
               	begin
               	-- add Interco AP and AR entries
 
               	exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @intercoAPGLAcct, @employee, @payseq, @creditamt, @glhrs
               	exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @intercoARGLAcct, @employee, @payseq, @glamt, @glhrs
               	end
   
   			goto next_EMLiabType
     
   			end_EMLiabType:
               	close bcEMLiabType
               	deallocate bcEMLiabType
               	select @openEMLiabType = 0
   		end
       /* GL distributions for burden interfaced to SM */
       if @posttype = 'SM'
   		begin
  --- bspPRUpdateValGLExpLiab

		   SELECT @smliabglacct = @SMCostAcct
           -- validate GL Account
           exec @rcode = bspGLACfPostable @glco, @smliabglacct, 'S', @errmsg output
           if @rcode = 1
                begin
                select @errortext = 'Burden Expense - SM - ' + isnull(@errmsg,'')
                exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
      	         if @rcode = 1 goto bspexit
                goto end_SMLiab
                end
		   
           declare bcSMLiab cursor LOCAL FAST_FORWARD for
           select d.LiabType, isnull(convert(numeric(12,2),sum(l.Amt)),0)
           from dbo.bPRTL l with (nolock)
           join dbo.bPRDL d with (nolock) on d.PRCo = l.PRCo and d.DLCode = l.LiabCode
           where l.PRCo = @prco and l.PRGroup = @prgroup and l.PREndDate = @prenddate and l.Employee = @employee
               and l.PaySeq = @payseq and l.PostSeq = @postseq
           group by d.LiabType
   
           open bcSMLiab
           select @openSMLiab = 1
   
           next_SMLiabType:
               fetch next from bcSMLiab into @liabtype, @amt
   
               if @@fetch_status = -1 goto end_SMLiab
               if @@fetch_status <> 0 goto next_SMLiabType
   
               if @amt = 0 goto next_SMLiabType
               -- get Burden Expense and Applied Burden GL Accounts from PR Dept
               select @glacct = null
               select @glacct = @smliabglacct

				UPDATE dbo.vSMDetailTransaction
				SET Amount = Amount + @amt
				WHERE SMDetailTransactionID = @SMDetailTransactionCostID
				
				-- update GL distributions
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @smliabglacct, @employee, @payseq, @amt, @glhrs

           		-- Credit to PR Dept SM Applied Burden GL Account - PR GL Co# - Expense Month
           		select @glacct = null
           		select @glacct = SMAppBurdenGLAcct
           		from dbo.bPRDG with (nolock) where PRCo = @prco and PRDept = @prdept and LiabType = @liabtype
           		exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output
           		if @rcode = 1
               		begin
               		select @errortext = 'SM Applied Burden for PR Dept: ' + convert(varchar(6),@prdept)
   						+ ' Liability Type: ' + convert(varchar(6),@liabtype) + ' - ' + isnull(@errmsg,'')
               		exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	    		if @rcode = 1 goto bspexit
               		goto next_SMLiabType
               		end
           		select @creditamt = -(@amt)
	  
           		exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glacct, @employee, @payseq, @creditamt, @glhrs

           		if @glco <> @prglco
               		begin
               		-- add Interco AP and AR entries 
               		exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @intercoAPGLAcct, @employee, @payseq, @creditamt, @glhrs
               		exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @intercoARGLAcct, @employee, @payseq, @amt, @glhrs
               		end
	   
   			goto next_SMLiabType
   
           end_SMLiab:
			   if @openSMLiab=1
			   begin
				   close bcSMLiab
				   deallocate bcSMLiab
				   select @openSMLiab = 0
				end
           end
   
   
   	/* GL distributions for liabilities interfaced to intercompany GL  - only option is to interface actual amounts */
       if @posttype = 'PR' and @prglco <> @glco
   		begin
  --- bspPRUpdateValGLExpLiab
           declare bcGLLiab cursor LOCAL FAST_FORWARD for
           select d.LiabType, isnull(convert(numeric(12,2),sum(l.Amt)),0)
           from dbo.bPRTL l with (nolock)
           join dbo.bPRDL d with (nolock) on d.PRCo = l.PRCo and d.DLCode = l.LiabCode
           where l.PRCo = @prco and l.PRGroup = @prgroup and l.PREndDate = @prenddate and l.Employee = @employee
               and l.PaySeq = @payseq and l.PostSeq = @postseq
           group by d.LiabType
   
           open bcGLLiab
           select @openGLLiab = 1
   
           next_GLLiab:
               fetch next from bcGLLiab into @liabtype, @amt
   
               if @@fetch_status = -1 goto end_GLLiab
               if @@fetch_status <> 0 goto next_GLLiab
   
               if @amt = 0 goto next_GLLiab
               -- get Burden Expense and Applied Burden GL Accounts from PR Dept
               select @glacct = null, @intercoappburdenglacct = null
               select @glacct = GLAcct, @intercoappburdenglacct = IntercoAppBurdenGLAcct
               from dbo.bPRDG with (nolock) where PRCo = @prco and PRDept = @prdept and LiabType = @liabtype
               -- validate GL Account
               exec @rcode = bspGLACfPostable @glco, @glacct, 'N', @errmsg output
               if @rcode = 1
                    begin
                    select @errortext = 'Burden Expense - PR Dept: ' + @prdept + ' - Liability Type ' + convert(varchar(6),@liabtype) +  ' - ' + isnull(@errmsg,'')
                    exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	         if @rcode = 1 goto bspexit
                    goto next_GLLiab
                    end
               -- update GL distributions
               -- Debit liability expense - 'Post to' GL Co# - Expense Month
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLExp Exp28: GLCo='+Convert(varchar,@glco)+' GLAcct='+ISNULL(@glacct,'NULL')+' GLAmt='+convert(varchar,@amt)+' GLHrs='+convert(varchar,@glhrs)
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @glacct, @employee, @payseq, @amt, @glhrs
   			-- Credit to PR Dept Intercompany Applied Burden GL Account - PR GL Co# - Expense Month
               exec @rcode = bspGLACfPostable @prglco, @intercoappburdenglacct, 'N', @errmsg output
               if @rcode = 1
                   begin
                   select @errortext = 'Intercompany Applied Burden - PR Dept: ' + convert(varchar(6),@prdept)
   					+ ' Liability Type: ' + convert(varchar(6),@liabtype) + ' - ' + isnull(@errmsg,'')
                   exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	        if @rcode = 1 goto bspexit
                   goto next_GLLiab
                   end
               select @creditamt = -(@amt)
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLExp Exp29: GLCo='+Convert(varchar,@prglco)+' GLAcct='+@intercoappburdenglacct+' GLAmt='+convert(varchar,@creditamt)+' GLHrs='+convert(varchar,@glhrs)
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @intercoappburdenglacct, @employee, @payseq, @creditamt, @glhrs
               if @glco <> @prglco
                   begin
                   -- add Interco AP and AR entries
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLExp Exp30: GLCo='+Convert(varchar,@glco)+' GLAcct='+@intercoAPGLAcct+' GLAmt='+convert(varchar,@creditamt)+' GLHrs='+convert(varchar,@glhrs)
                   exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @intercoAPGLAcct, @employee, @payseq, @creditamt, @glhrs
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLExp Exp31: GLCo='+Convert(varchar,@prglco)+' GLAcct='+@intercoARGLAcct+' GLAmt='+convert(varchar,@amt)+' GLHrs='+convert(varchar,@glhrs)
                   exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @intercoARGLAcct, @employee, @payseq, @amt, @glhrs
                   end
               goto next_GLLiab
   
           end_GLLiab:
               close bcGLLiab
               deallocate bcGLLiab
               select @openGLLiab = 0
           end
           
       process_Addons:     -- process Addon earnings associated with the timecard
           exec @rcode = bspPRUpdateValGLAddons @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @posttype,
                @jcrate, @emrate, @jcco, @job, @jobstatus, @jcdept, @phasegroup, @jcphase, @glco, @prglco,
                @intercoAPGLAcct, @intercoARGLAcct, @prdept, @mth, @paidmth, @glaccrualacct, @liabtemplate, @emco,
                @emdept, @emgroup, @emlaborct, @costcode, @validphasechars, @SMGLCo, @SMCostAcct, @SMJobRevenueGLEntryID, @SMInterCoAPGLAcct, @SMWorkCompletedID,
                @prtype, @JCGLCostDetailDesc, @SMWorkCompletedDesc, @SMDetailTransactionCostID, @errmsg output
           if @rcode = 1 goto bspexit

		IF @posttype = 'JC' AND @prtype= 'S'
		BEGIN
			SELECT @ActualCostTotal = SUM(Amount)
			FROM dbo.vGLEntryTransaction
			WHERE GLEntryID = @SMJobRevenueGLEntryID

			IF EXISTS(SELECT 1 
				FROM dbo.vSMWorkCompleted
					INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
				WHERE vSMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID AND vSMWorkOrder.CostingMethod = 'Revenue')
			BEGIN
				SELECT @SalePrice = PriceTotal
				FROM dbo.SMWorkCompletedAllCurrent
				WHERE SMWorkCompletedID = @SMWorkCompletedID

				--Update each line with the appropriate percentage of the sale price
				UPDATE dbo.vGLEntryTransaction
				SET Amount = Amount * @SalePrice / @ActualCostTotal
				WHERE GLEntryID = @SMJobRevenueGLEntryID

				--Handle rounding
				UPDATE TOP (1) dbo.vGLEntryTransaction
				SET Amount = Amount + @SalePrice - (SELECT SUM(Amount) FROM dbo.vGLEntryTransaction WHERE GLEntryID = @SMJobRevenueGLEntryID)
				WHERE GLEntryID = @SMJobRevenueGLEntryID
				
				SET @ActualCostTotal = @SalePrice
			END
			
			SELECT @TransDesc = dbo.vfToString(vSMCO.GLDetlDesc),
				@TransDesc = REPLACE(@TransDesc, 'SM Company', RTRIM(dbo.vfToString(vSMCO.SMCo))),
				@TransDesc = REPLACE(@TransDesc, 'Work Order', RTRIM(dbo.vfToString(SMWorkCompletedAllCurrent.WorkOrder))),
				@TransDesc = REPLACE(@TransDesc, 'Scope', RTRIM(dbo.vfToString(SMWorkCompletedAllCurrent.Scope))),
				@TransDesc = REPLACE(@TransDesc, 'Line Type', '2'),
				@TransDesc = REPLACE(@TransDesc, 'Line Sequence', RTRIM(dbo.vfToString(SMWorkCompletedAllCurrent.WorkCompleted)))
			FROM dbo.SMWorkCompletedAllCurrent
				INNER JOIN dbo.vSMCO ON SMWorkCompletedAllCurrent.SMCo = vSMCO.SMCo
			WHERE SMWorkCompletedAllCurrent.SMWorkCompletedID = @SMWorkCompletedID
			
			--Handle intercompany for sm job work orders
			IF @SMGLCo <> @glco
			BEGIN
				SET @GLTransaction = dbo.vfGLEntryNextTransaction(@SMJobRevenueGLEntryID) - 1

				--Create the offsetting entry from the job entries by copying the job entries and reversing the amount for the intercompany account.
				INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, [Source], GLCo, GLAccount, Amount, ActDate, [Description])
				SELECT GLEntryID, @GLTransaction + GLTransaction, [Source], @glco, @intercoAPGLAcct, -Amount, ActDate, [Description]
				FROM dbo.vGLEntryTransaction
				WHERE GLEntryID = @SMJobRevenueGLEntryID
				
				--Add the gl entries to the GLEntryTransaction table so that the trans value in the description can be updated on post
				INSERT @GLEntryTransaction
				SELECT Employee, PaySeq, PostSeq, @GLTransaction + GLTransaction, [Type], EarnCode, LiabilityType
				FROM @GLEntryTransaction
				
				--Add the gl entry for the SM intercompany ar gl account
				INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, [Source], GLCo, GLAccount, Amount, ActDate, [Description])
				VALUES (@SMJobRevenueGLEntryID, dbo.vfGLEntryNextTransaction(@SMJobRevenueGLEntryID), 'SM Job', @SMGLCo, @SMInterCoARGLAcct, @ActualCostTotal, @prenddate, @TransDesc)
			END

			SET @GLTransaction = dbo.vfGLEntryNextTransaction(@SMJobRevenueGLEntryID)

			INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, [Source], GLCo, GLAccount, Amount, ActDate, [Description])
			VALUES (@SMJobRevenueGLEntryID, @GLTransaction, 'SM Job', @SMGLCo, @SMRevenueAcct, -@ActualCostTotal, @prenddate, @TransDesc)

			-- check to see if debits and credits balance
			IF EXISTS(SELECT 1 FROM dbo.vGLEntryTransaction WHERE GLEntryID = @SMJobRevenueGLEntryID GROUP BY GLCo HAVING SUM(Amount) <> 0)
			BEGIN
				SET @errortext = 'GL Debits and Credits do not balance!'
				EXEC @rcode = dbo.bspPRURInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @employee = @employee, @payseq = @payseq, @postseq = @postseq, @errortext = @errortext, @errmsg = @errmsg OUTPUT
				IF @rcode = 1 GOTO bspexit
				GOTO next_Timecard
			END
			
			INSERT dbo.vSMWorkCompletedGLEntry (GLEntryID, GLTransactionForSMDerivedAccount, SMWorkCompletedID)
			VALUES (@SMJobRevenueGLEntryID, @GLTransaction, @SMWorkCompletedID)

			--Capture the reconciliation for revenue
			INSERT dbo.vSMDetailTransaction (IsReversing, Posted, PRLedgerUpdateDistributionID, HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, PRMth, GLCo, GLAccount, Amount)
			SELECT 0 IsReversing, 0 Posted, @PRLedgerUpdateDistributionID, CostDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, 2/*For labor*/, 'R'/*R for revenue*/, @prco, @mth, @mth, @SMGLCo, @SMRevenueAcct, -@ActualCostTotal
			FROM
			(
				SELECT SMWorkCompleted.*, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID
				FROM dbo.SMWorkCompleted
					INNER JOIN dbo.vSMWorkOrderScope ON SMWorkCompleted.SMCo = vSMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = vSMWorkOrderScope.Scope
					INNER JOIN dbo.vSMWorkOrder ON SMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
				WHERE SMWorkCompletedID = @SMWorkCompletedID
			) NewDetailTransaction

			--The add-on validation may have created more GLEntryTransactions so those values
			--are copied into the temp table so that they can be included in the XML
			INSERT @GLEntryTransaction
			SELECT Employee, PaySeq, PostSeq, GLTransaction, [Type], EarnCode, LiabilityType
			FROM PRLedgerUpdateGLEntryTransaction
			WHERE GLEntryID = @SMJobRevenueGLEntryID

			--The xml is used to capture information available during validation and only needed
			--up until the records are posted. Specifically this data is used to figure out what
			--JCCostEntryTransactions correspond to what GLEntryTransactions.
			UPDATE vPRLedgerUpdateMonth
			SET DistributionXML = (SELECT Employee, PaySeq, PostSeq, GLTransaction, [Type], EarnCode, LiabilityType FROM @GLEntryTransaction GLEntryTransaction FOR XML AUTO, TYPE)
			FROM dbo.vGLEntry
				INNER JOIN dbo.vPRLedgerUpdateMonth ON vGLEntry.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
			WHERE vGLEntry.GLEntryID = @SMJobRevenueGLEntryID
		END
   
       process_EquipUse:   -- process Equipment costs on the Job, and revenue to the Equipment
           if isnull(@usageunits,0) = 0 goto next_Timecard   -- skip if no usage
   
   		-- issue 14181 use/validate equip phase override if any
   		select @ephase = @jcphase
           if @equipphase is not null
   			begin
   			select @ephase = @equipphase
   			exec @rcode = bspJCVPHASE @jcco, @job, @ephase, @phasegroup,'N', @dept = @jcdept output, @msg = @errortext output
   	        if @rcode = 1
   	            begin
   	            select @errortext = 'Equip Phase: ' + isnull(@errortext,'')
   	            exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
   	    	    if @rcode = 1 goto bspexit
   	            goto next_Timecard
   	            end
   			end
   
           -- use this procedure to generate revenue credits, equipment expense debits, and intercompany entries
           exec @rcode = bspPRUpdateValGLUsage @prco, @prgroup, @prenddate, @employee, @payseq, @postseq,
                @emco, @equipment, @emgroup, @revcode, @jcco, @job, @jobstatus, @jcdept, @phasegroup,
                @ephase, @emctype, @usageunits, @glco, @mth, @validphasechars, @errortext output
           if @rcode = 1 goto bspexit
   
       goto next_Timecard
   
       end_Timecard:     -- finished with timecards for the Employee/Pay Seq
            close bcTimecard
      		 deallocate bcTimecard
      		 select @openTimecard = 0
   
   -- check to see if debits and credits balance for this Employee and PaySeq
   if exists(select * from dbo.bPRGL g with (nolock) join dbo.bGLAC a with (nolock) on a.GLCo = g.GLCo and a.GLAcct = g.GLAcct
                  where g.PRCo = @prco and g.PRGroup = @prgroup and g.PREndDate = @prenddate
                  and g.Employee = @employee and g.PaySeq = @payseq and a.AcctType <> 'M'
                  group by g.Mth, g.GLCo having sum(isnull(g.Amt,0))<>0)
       begin
       select @errortext = 'GL Debits and Credits do not balance!'
       exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
       if @rcode = 1 goto bspexit
       end
   
   -- finished with Employee/Pay Seq - return to bspUpdateValGL
   bspexit:    -- clean up all cursors
       if @openLiabType = 1
           begin
           close bcLiabType
           deallocate bcLiabType
           end
       if @openTimecard = 1
           begin
           close bcTimecard
           deallocate bcTimecard
           end
       if @openActualLiab = 1
           begin
           close bcActualLiab
           deallocate bcActualLiab
           end
       if @openSMLiab = 1
			begin
			close bcSMLiab
			deallocate bcSMLiab
			end
       if @openGLLiab = 1
           begin
           close bcGLLiab
           deallocate bcGLLiab
           end
   	if @openEMLiabType = 1
           begin
           close bcEMLiabType
           deallocate bcEMLiabType
           end
   
       --select @errmsg = @errmsg + char(13) + char(10) + 'bspPRUpdateValGLExp'
      	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspPRUpdateValGLExp] TO [public]
GO
