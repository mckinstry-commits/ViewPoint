SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPRUpdateValGLAddons]
/***********************************************************
* Created: GG 07/01/98
* Modified: GG 03/17/99
*			GG 08/12/99  Added GL distributions for EM
*           GG 09/23/99  Fixed EM burden calcs
*           EN 6/06/01 - issue #11553 - enhancement to interface hours to GL memo acccounts
*	        GG 02/16/02 - #14175 - JC Department override by Phase
*			GG 02/16/02 - #11997 - EM Department override by Earnings Type
*			GG 02/16/02 - #16288 - Applied Burden by Liab Type
*			GG 03/09/02 - #16459 - Removed JC/EM Use Dept option, added Interco Applied Earnings and Burden GL Accounts
*			SR 07/09/02 - 17738 pass @overphasegrp to bspJCVPHASE
*			GG 07/23/02 - #18054 - pull PR Dept GL Accounts earlier
*			bc 08/27/02 - #18392 Reinitialize @glacct for bcAddon every loop.
*			GH 09/04/02 - #18479 - not creating gl entries for multiple addons on equipment timecards
*			EN 10/9/02 - issue 18877 change double quotes to single
*			DANF 10/30/03 - 22786 Added Phase GL Account valid part over ride.
*			EN 12/09/03 - issue 23061  added isnull check, with (nolock), and dbo
*			GG 12/16/03 - #23326 fix bJCDO search to handle null premium and/or liability override phases
*			GG 10/16/07 - #125791 - fix for DDDTShared
*           EV 04/13/11 - TK-04236 Post burden to GL account based on SM or SM type records
*
* Called from bspPRUpdateValGLExp procedure to validate and load
* GL distributions for a timecards' addons.
*
* Errors are written to bPRUR unless fatal.
*
* Inputs:
*   @prco   		   PR Company
*   @prgroup  		   PR Group to validate
*   @prenddate		   Pay Period Ending Date
*   @employee          Employee
*   @payseq            Payment Sequence
*   @postseq           Timecard posting sequence
*   @posttype          Type of entry 'JC', 'EM', or 'PR' if expensed to GL
*   @jcrate            Employee's JC fixed rate
*   @emrate            Employee's EM fixed rate
*   @jcco              JC Co# posted on timecard
*   @job               Job posted on timecard
*   @jobstatus         Job Status - 3 = closed, use 'Closed Job' GL Accounts
*   @jcdept            Job Department from timecard
*   @phasegroup        Phase Group used by JC Co#
*   @jcphase           Phase posted on timecard
*   @glco              GL Co# posted on timecard
*   @prglco            Payroll GL Co#
*   @intercoAPGLAcct   Intercompany AP GL Account
*   @intercoARGLAcct   Intercompany AR GL Account
*   @prdept            Employee's PR Department
*   @mth               Expense month for earnings - based on Pay Pd cutoff date
*   @paidmth           Paid month for Employee/PaySeq
*   @glaccrualacct     Payroll Accrual GL Account from PR Group
*   @liabtemplate      Liability Template assigned to Job
*   @emco              EM Co# posted on timecard
*   @emdept            EM Department of posted equipment
*   @emgroup           EM Group
*   @emlaborct         EM Cost Type for labor
*   @costcode          EM Cost Code posted with equipment
*   @validphasechars   Valid # of characters in Phase code
*   @SMGLCo            SM GL Company
*   @SMCostAcct        SM Cost Account
*	@SMJobRevenueGLEntryID GLEntryEntryID for the job work order gl
*	@SMInterCoAPGLAcct	SM Inter Company AP GL Acct for job work orders
*	@SMWorkCompletedID	SMWorkCompletedID for time card entry
*	@prtype				Timecard type
*	@JCGLCostDetailDesc	JC GL cost description for job related work orders
*	@SMWorkCompletedDesc Work Completed description
*
* Output:
*   @errmsg      error message if error occurs
*
* Return Value:
*   0         success
*   1         failure
*****************************************************/
   	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @employee bEmployee = null,
   	 @payseq tinyint = null, @postseq smallint = null, @posttype char(2) = null, @jcrate bUnitCost = null,
   	 @emrate bUnitCost = null, @jcco bCompany = null, @job bJob = null,
   	 @jobstatus tinyint = null, @jcdept bDept = null, @phasegroup bGroup = null, @jcphase bPhase = null,
   	 @glco bCompany = null, @prglco bCompany = null, @intercoAPGLAcct bGLAcct = null, @intercoARGLAcct bGLAcct = null,
   	 @prdept bDept = null, @mth bMonth = null, @paidmth bMonth = null, @glaccrualacct bGLAcct = null,
   	 @liabtemplate smallint = null, @emco bCompany = null, @emdept bDept = null, @emgroup bGroup = null,
   	 @emlaborct bEMCType = null, @costcode bCostCode = null, @validphasechars int = null, 
   	 @SMGLCo bCompany, @SMCostAcct bGLAcct, @SMJobRevenueGLEntryID bigint, @SMInterCoAPGLAcct bGLAcct, @SMWorkCompletedID bigint,
   	 @prtype char(1), @JCGLCostDetailDesc varchar(60), @SMWorkCompletedDesc varchar(60), @SMDetailTransactionCostID bigint,
   	 @errmsg varchar(255) output)
   
   as
   
   set nocount on

   declare @rcode int, @errortext varchar(255), @openAddon tinyint, @earncode bEDLCode, @addonamt bDollar,
     	@jcctype bJCCType, @subtype char(1), @glamt bDollar, @openLiabType tinyint, @liabtype bLiabilityType,
   
     	@overphase bPhase, @overcosttype bJCCType, @liabrate bRate, @dept bDept, @costtype bJCCType, @earntype bEarnType,
     	@glacct bGLAcct, @liabamt bDollar, @glhrs bHrs, @burdenopt char(1), @burdenrate bRate, @addonrate bRate,
   	@pphase bPhase,	@openEMLiabType tinyint, @prearnglacct bGLAcct, @jcappearnglacct bGLAcct, @emappearnglacct bGLAcct,
   	@smappearnglacct bGLAcct, @intercoappearnglacct bGLAcct, @creditamt bDollar, @overphasegrp tinyint,
   	@InputMask varchar(30), @InputType tinyint, @GLTransaction int, @TransDesc varchar(60)
   
   	DECLARE @GLEntryTransaction TABLE (
		Employee bEmployee NOT NULL, PaySeq tinyint NOT NULL, PostSeq smallint NOT NULL,
		GLTransaction int NOT NULL, [Type] smallint NOT NULL, EarnCode bEDLCode NULL, LiabilityType bLiabilityType NULL)
   
   select @rcode = 0, @glhrs = 0
   
   -- get Phase Format 
   select @InputMask = InputMask, @InputType= InputType
   from dbo.DDDTShared (nolock) where Datatype ='bPhase'
   
   -- process Addon earnings associated with the timecard
   declare bcAddon cursor for
   select a.EarnCode, a.Amt, e.EarnType, e.JCCostType
   from dbo.bPRTA a with (nolock)
   join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
   where a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate and a.Employee = @employee
   	and a.PaySeq = @payseq and a.PostSeq = @postseq and a.Amt <> 0  -- skip 0.00 amount addons
   
   open bcAddon
   select @openAddon = 1
   
   next_Addon:
   	fetch next from bcAddon into @earncode, @addonamt, @earntype, @jcctype
       if @@fetch_status = -1 goto bspexit
       if @@fetch_status <> 0 goto next_Addon
   
       -- reinitialize variable
       select @glacct = null
   
       -- get PR Department Earnings Expense and Applied Earnings accounts	- #16459
   		select @prearnglacct = GLAcct, @smappearnglacct=SMAppEarnGLAcct, @jcappearnglacct = JCAppEarnGLAcct, @emappearnglacct = EMAppEarnGLAcct,
   			@intercoappearnglacct = IntercoAppEarnGLAcct
		   from dbo.bPRDE with (nolock)
   		where PRCo = @prco and PRDept = @prdept and EarnType = @earntype
   		if @@rowcount = 0
           begin
      	    select @errortext = 'Missing PR Department: ' + @prdept + ' and Earnings Type: ' + convert(varchar,@earntype)
      	    exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	if @rcode = 1 goto bspexit
           goto next_Addon
          	end
   
   	-- skip subledger expense for addon earnings if using a fixed rate
       if (@posttype = 'JC' and @jcrate <> 0) or (@posttype = 'EM' and @emrate <> 0) goto process_AddonExp
   
       -- get GL Account to debit for earnings
       if @posttype = 'PR' select @glacct = @prearnglacct
       if @posttype = 'JC'
   		begin
   		-- check for GL Account override by Phase - #14175
           select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
           from dbo.bJCDO with (nolock)
           where JCCo = @jcco and Department = @jcdept and PhaseGroup = @phasegroup and Phase = @jcphase and ExcludePR = 'N'
   		if @@rowcount = 0 and @validphasechars > 0
   			begin
   			-- check using valid portion
   			--select @pphase = substring(@jcphase,1,@validphasechars) + '%'
   			select @pphase  = substring(@jcphase,1,@validphasechars)
       		exec @rcode = dbo.bspHQFormatMultiPart @pphase, @InputMask, @pphase output
   			select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
   			from dbo.bJCDO with (nolock)
   			where JCCo = @jcco and Department = @jcdept and PhaseGroup = @phasegroup and Phase = @pphase and ExcludePR = 'N'
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
   	if @posttype = 'EM'
   		begin
           select @glacct = GLAcct
           from dbo.bEMDG with (nolock) where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and CostType = @emlaborct
           -- check for Cost Code override
           select @glacct = GLAcct
           from dbo.bEMDO with (nolock)
   		   where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and CostCode = @costcode	and ExcludePR = 'N'
           if @@rowcount = 0
   			begin
   			-- check for Earnings Type override - #11997 
   			select @glacct = GLAcct 
   			from dbo.bEMDE with (nolock) where EMCo = @emco and Department = @emdept and EarnType = @earntype
   			end
   		end
       /* GL distributions for add-on earnings interfaced to SM */
       if @posttype = 'SM'
        begin
			SELECT @glacct=@SMCostAcct
        end   
   
   	-- validate Expense GL Account for Addon Earnings
       if @posttype = 'PR' select @subtype = 'N'   -- must be null
       if @posttype = 'JC' select @subtype = 'J'
       if @posttype = 'EM' select @subtype = 'E'
       if @posttype = 'SM' select @subtype = 'S'
       exec @rcode = bspGLACfPostable @glco, @glacct, @subtype, @errmsg output
       if @rcode = 1
       begin
           select @errortext = 'Earnings code ' + convert(varchar(6),@earncode) + ' Debit : ' + isnull(@errmsg,'')
   
		   exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
           if @rcode = 1 goto bspexit
   		   goto next_Addon
       end

		IF @prtype = 'S'
		BEGIN
			UPDATE dbo.vSMDetailTransaction
			SET Amount = Amount + @addonamt
			WHERE SMDetailTransactionID = @SMDetailTransactionCostID
		END

		-- update GL distributions with debit for earnings amount - 'Post to' GL Co#, Expense Month
		IF @posttype = 'JC' AND @prtype = 'S'
		BEGIN
			EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @SMGLCo, @glacct = @SMCostAcct, @employee = @employee, @payseq = @payseq, @amt = @addonamt, @hours = @glhrs

			--Capture SM Revenue
			SELECT @TransDesc = @JCGLCostDetailDesc,
				@TransDesc = REPLACE(@TransDesc, 'Job', RTRIM(dbo.vfToString(@job))),
				@TransDesc = REPLACE(@TransDesc, 'Phase', RTRIM(dbo.vfToString(@jcphase))),
				@TransDesc = REPLACE(@TransDesc, 'CT', RTRIM(dbo.vfToString(@jcctype))),
				@TransDesc = REPLACE(@TransDesc, 'Trans Type', 'PR'),
				@TransDesc = REPLACE(@TransDesc, 'Desc', RTRIM(dbo.vfToString(@SMWorkCompletedDesc)))

			SET @GLTransaction = dbo.vfGLEntryNextTransaction(@SMJobRevenueGLEntryID)

			INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, [Source], GLCo, GLAccount, Amount, ActDate, [Description])
			VALUES (@SMJobRevenueGLEntryID, @GLTransaction, 'JC Cost', @glco, @glacct, @addonamt, @prenddate, @TransDesc)

			INSERT @GLEntryTransaction
			VALUES (@employee, @payseq, @postseq, @GLTransaction, 4, @earncode, NULL)
		END
		ELSE
		BEGIN
       exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @glacct, @employee, @payseq, @addonamt, @glhrs
		END

		SELECT @glamt = -(@addonamt)

		-- add Interco AP and AR entries - credit AP in 'posted to' GL Co#, debit AR in PR GL Co#
		IF @posttype = 'JC' AND @prtype='S'
		BEGIN
			IF @prglco <> @SMGLCo
			BEGIN
				EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @SMGLCo, @glacct = @SMInterCoAPGLAcct, @employee = @employee, @payseq = @payseq, @amt = @glamt, @hours = @glhrs

				EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @prglco, @glacct = @intercoARGLAcct, @employee = @employee, @payseq = @payseq, @amt = @addonamt, @hours = @glhrs
			END
		END
		ELSE
		BEGIN
       IF @glco <> @prglco
       BEGIN
           EXEC bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @intercoAPGLAcct, @employee, @payseq, @glamt, @glhrs

           EXEC bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @intercoARGLAcct, @employee, @payseq, @addonamt, @glhrs
       END
		END

   
       process_AddonExp: -- additional distributions to PR Department needed if earnings are posted to JC, EM, or Intercompany 
   		if @posttype in ('JC', 'EM', 'SM') or @prglco <> @glco
           	begin
           	select @glacct = @prearnglacct
               exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output
               if @rcode = 1
                begin
                   select @errortext = 'Payroll Expense - PR Dept ' + @prdept + ' and Earnings type ' + convert(varchar(4),@earntype) + '.  ' + isnull(@errmsg,'')
                   exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
         	        if @rcode = 1 goto bspexit
   				goto next_Addon
                end

                exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glacct, @employee, @payseq, @addonamt, @glhrs
               -- credit Applied Earnings - unless interfaced to JC/EM at fixed rate
   			if (@posttype = 'JC' and @jcrate = 0) or (@posttype = 'EM' and @emrate = 0) or @posttype = 'PR' or @posttype = 'SM'
   			begin
   				select @glacct = case @posttype when 'SM' then @smappearnglacct when 'JC' then @jcappearnglacct when 'EM' then @emappearnglacct else @intercoappearnglacct end
   				select @creditamt = -(@addonamt)
   				exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output
           		if @rcode = 1
                begin
               		select @errortext = 'Applied Earnings - PR Dept: ' + @prdept + ' and Earnings Type: ' + convert(varchar(4),@earntype) + '.  ' + isnull(@errmsg,'')
               		exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	    		if @rcode = 1 goto bspexit
               		goto next_Addon
                end

               	exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glacct, @employee, @payseq, @creditamt, @glhrs

            end
   		end
   
   		-- credit to PR Dept Fixed Rate Contra GL Account already made with posted hours
   
   
   	process_AddonAccrual: -- Accrual entries needed if expensed and paid in different months - use actual amts
   		if @mth <> @paidmth
               begin
               -- Payroll Accrual GL Account from PR Group has already been validated
               -- credit posted to PR GL Co# in expense month
               select @glamt = -(@addonamt)

               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glaccrualacct, @employee, @payseq, @glamt, @glhrs
               
               -- debit posted to PR GL Co# in paid month
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @paidmth, @prglco, @glaccrualacct, @employee, @payseq, @addonamt, @glhrs
               end
   
   	-- skip Addon burden if fixed rate was used to update JC or EM, or a GL timecard
       if (@posttype = 'JC' and @jcrate <> 0) or (@posttype = 'EM' and @emrate <> 0) or @posttype = 'PR' or @posttype = 'SM' goto next_Addon
   
   	-- Addon burden for Job Costed Timecards 
       if @posttype = 'JC'
   		begin
           -- skip Addon burden if Job does not have a Liability Template
           if @liabtemplate is null goto next_Addon
             
   		declare bcLiabType cursor for
           select LiabType, Phase, CostType, LiabilityRate, PhaseGroup
           from dbo.bJCTL with (nolock)
           where JCCo = @jcco and LiabTemplate = @liabtemplate
           	and CalcMethod = 'R'    -- process 'rate calculated' burden only - 'exact' updated with posted earnings
             
   		open bcLiabType
           select @openLiabType = 1
   
           next_LiabType:
           	fetch next from bcLiabType into @liabtype, @overphase, @overcosttype, @liabrate, @overphasegrp
               if @@fetch_status = -1 goto end_LiabType
               if @@fetch_status <> 0 goto next_LiabType
   
               select @liabamt = 0, @glacct = null, @glhrs = 0
     	        if exists(select 1 from dbo.bJCTE with (nolock) where JCCo = @jcco and LiabTemplate = @liabtemplate
                              and LiabType = @liabtype and EarnCode = @earncode)
                     select @liabamt = @addonamt * @liabrate    -- earnings must be subject to liability
   
               if @liabamt = 0 goto next_LiabType
   
   			-- get Burden Expense GL Account to debit
               select @dept = @jcdept, @costtype = @jcctype
               if @overcosttype is not null select @costtype = @overcosttype
               -- get JC Dept if phase overridden
               if @overphase is not null and @overphase <> @jcphase
               	exec @rcode = bspJCVPHASE @jcco, @job, @overphase, @overphasegrp, 'N', @dept = @dept output, @msg = @errortext output
   
   			-- get GL Account from JC Dept
   			select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
   			from dbo.bJCDO with (nolock)
   			where JCCo = @jcco and Department = @dept and PhaseGroup = @phasegroup and Phase = isnull(@overphase,@jcphase)	-- #23326 handle null override phase
   				and ExcludePR = 'N'
   			if @@rowcount = 0 and @validphasechars > 0
   				begin
   				--select @pphase = substring(isnull(@overphase,@jcphase),1,@validphasechars) + '%'	
   				select @pphase  = substring(isnull(@overphase,@jcphase),1,@validphasechars)	-- #23326 handle null override phase
       			exec @rcode = dbo.bspHQFormatMultiPart @pphase, @InputMask, @pphase output
   				select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
   				from dbo.bJCDO with (nolock)
   				where JCCo = @jcco and Department = @dept and PhaseGroup = @phasegroup and Phase = @pphase and ExcludePR = 'N'
   				end 
   			if @glacct is null
   				begin
   				-- if no Phase override, get GL Account by Cost Type
   	            select @glacct = case @jobstatus when 3 then ClosedExpAcct else OpenWIPAcct end
   	            from dbo.bJCDC with (nolock)
   	            where JCCo = @jcco and Department = @dept and PhaseGroup = @phasegroup and CostType = @costtype
   	            -- check for Liability Type override
   	            select @glacct = case @jobstatus when 3 then ClosedBurdenAcct else OpenBurdenAcct end
   	            from dbo.bJCDL with (nolock)
   	            where JCCo = @jcco and Department = @dept and LiabType = @liabtype
   				end
   			-- validate GL Account for burden expense in JC GL Co#
               exec @rcode = bspGLACfPostable @glco, @glacct, 'J', @errmsg output
               if @rcode = 1
                   begin
                   select @errortext = 'Burden Expense - JC Dept: ' + @dept + ' Liability Type: ' + convert(varchar(6),@liabtype) + '.  ' + isnull(@errmsg,'')
                   exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
         	        if @rcode = 1 goto bspexit
   				goto next_LiabType
                   end

               -- update GL distributions
               -- Debit for liability expense - JC GL Co# - Expense Month
			IF @prtype='S'
			BEGIN
				UPDATE dbo.vSMDetailTransaction
				SET Amount = Amount + @liabamt
				WHERE SMDetailTransactionID = @SMDetailTransactionCostID

				EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @SMGLCo, @glacct = @SMCostAcct, @employee = @employee, @payseq = @payseq, @amt = @liabamt, @hours = @glhrs
				
				--Capture SM Revenue
				SELECT @TransDesc = @JCGLCostDetailDesc,
					@TransDesc = REPLACE(@TransDesc, 'Job', RTRIM(dbo.vfToString(@job))),
					@TransDesc = REPLACE(@TransDesc, 'Phase', RTRIM(dbo.vfToString(ISNULL(@overphase, @jcphase)))),
					@TransDesc = REPLACE(@TransDesc, 'CT', RTRIM(dbo.vfToString(@costtype))),
					@TransDesc = REPLACE(@TransDesc, 'Trans Type', 'PR'),
					@TransDesc = REPLACE(@TransDesc, 'Desc', RTRIM(dbo.vfToString(@SMWorkCompletedDesc)))
					
				SET @GLTransaction = dbo.vfGLEntryNextTransaction(@SMJobRevenueGLEntryID)

				INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, [Source], GLCo, GLAccount, Amount, ActDate, [Description])
				VALUES (@SMJobRevenueGLEntryID, @GLTransaction, 'JC Cost', @glco, @glacct, @liabamt, @prenddate, @TransDesc)

				INSERT @GLEntryTransaction
				VALUES (@employee, @payseq, @postseq, @GLTransaction, 5, @earncode, @liabtype)
			END
			ELSE
			BEGIN
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @glacct, @employee, @payseq, @liabamt, @glhrs
			END

               -- Credit to PR Dept JC Applied Burden GL Account - PR GL Co# - Expense Month
               select @glacct = null
               select @glacct = JCAppBurdenGLAcct
               from dbo.bPRDG with (nolock) where PRCo = @prco and PRDept = @prdept and LiabType = @liabtype
               exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output
               if @rcode = 1
   				begin
                   select @errortext = 'JC Applied Burden for PR Dept ' + convert(varchar(6),@prdept)
   					+ ' Liab Type: ' + convert(varchar(6),@liabtype) + '.  ' + isnull(@errmsg,'')
                   exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
         	        if @rcode = 1 goto bspexit
   				goto next_LiabType
                   end

               select @glamt = -(@liabamt)
               exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glacct, @employee, @payseq, @glamt, @glhrs
               
               -- add Interco AP and AR entries
				IF @prtype='S'
				BEGIN
					IF @prglco <> @SMGLCo
					BEGIN
						EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @SMGLCo, @glacct = @SMInterCoAPGLAcct, @employee = @employee, @payseq = @payseq, @amt = @glamt, @hours = @glhrs

						EXEC dbo.bspPRGLInsert @prco = @prco, @prgroup = @prgroup, @prenddate = @prenddate, @mth = @mth, @glco = @prglco, @glacct = @intercoARGLAcct, @employee = @employee, @payseq = @payseq, @amt = @liabamt, @hours = @glhrs
					END
				END
				ELSE
				BEGIN               
               if @glco <> @prglco
                  begin
                  -- credit InterCo AP in 'posted to' GL Co#
                  select @glamt = -(@liabamt)
                  exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @intercoAPGLAcct, @employee, @payseq, @glamt, @glhrs
                  
                  -- debit InterCo AR in PR GL Co#
                  exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @intercoARGLAcct, @employee, @payseq, @liabamt, @glhrs
                  end
				END
   
             goto next_LiabType
   
             end_LiabType:
                 close bcLiabType
                 deallocate bcLiabType
                 select @openLiabType = 0
                 goto next_Addon
   		end

		IF @posttype = 'JC' AND @prtype = 'S'
		BEGIN
			--The xml is used to capture information available during validation and only needed
			--up until the records are posted. Specifically this data is used to figure out what
			--JCCostEntryTransactions correspond to what GLEntryTransactions.
			UPDATE vPRLedgerUpdateMonth
			SET DistributionXML = (SELECT Employee, PaySeq, PostSeq, GLTransaction, [Type], EarnCode, LiabilityType FROM @GLEntryTransaction GLEntryTransaction FOR XML AUTO, TYPE)
			FROM dbo.vGLEntry
				INNER JOIN dbo.vPRLedgerUpdateMonth ON vGLEntry.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
			WHERE vGLEntry.GLEntryID = @SMJobRevenueGLEntryID
		END
		
   	-- GL distributions for liabilities interfaced to EM
       if @posttype = 'EM'
   		begin
   		-- handle burden for addon earnings using a cursor on Liability types subject to addon earnings
           declare bcEMLiabType cursor for
   		select LiabType, BurdenType, BurdenRate, AddonRate
           from dbo.bEMPB with (nolock)
           where EMCo = @emco 	-- process all types
           	
           open bcEMLiabType
           select @openEMLiabType = 1
   
           next_EMLiabType:
               fetch next from bcEMLiabType into @liabtype, @burdenopt, @burdenrate, @addonrate
               if @@fetch_status = -1 goto end_EMLiabType
               if @@fetch_status <> 0 goto next_EMLiabType
   
             	select @liabamt = 0, @glacct = null, @glhrs = 0
   			-- assumes all earnings are subject to liability
             	if @burdenopt = 'A' select @liabamt = @addonamt * @addonrate    -- actual liabs included with posted earnings
             	if @burdenopt = 'R' select @liabamt = @addonamt * @burdenrate 	-- calculated burden 
   
             	if @liabamt = 0 goto next_EMLiabType
   
   			-- get EM Burden Expense account 
               select @glacct = GLAcct
               from dbo.bEMDG with (nolock)
               where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and CostType = @emlaborct
               -- check for Cost Code override
               select @glacct = GLAcct
               from dbo.bEMDO with (nolock)
               where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and CostCode = @costcode and ExcludePR = 'N'
   			if @@rowcount = 0
   				begin
   				-- check for Liability Type override
   				select @glacct = GLAcct
   				from dbo.bEMDL with (nolock) where EMCo = @emco and Department = @emdept and LiabType = @liabtype
   				end
   			-- validate GL Account for burden expense in 'post to' GL Co#
               exec @rcode = bspGLACfPostable @glco, @glacct, 'E', @errmsg output
               if @rcode = 1
                   begin
                   select @errortext = 'Burden Expense - EM Dept: ' + @emdept + ' Liability Type: ' + convert(varchar(6),@liabtype) + '.  ' + isnull(@errmsg,'')
                   exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
          	        if @rcode = 1 goto bspexit
                   goto next_EMLiabType
                   end
             -- update GL distributions
             -- Debit for liability expense - EM GL Co# - Expense Month
             exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @glacct, @employee, @payseq, @liabamt, @glhrs
             -- Credit to PR Dept EM Applied Burden GL Account - PR GL Co# - Expense Month
             select @glacct = null
             select @glacct = EMAppBurdenGLAcct
             from dbo.bPRDG with (nolock) where PRCo = @prco and PRDept = @prdept and LiabType = @liabtype
             exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output
             if @rcode = 1
                 begin
                 select @errortext = 'EM Applied Burden for PR Dept: ' + convert(varchar(6),@prdept)
   					+ ' Liability Type: ' + convert(varchar(6),@liabtype) + '.  ' + isnull(@errmsg,'')
                 exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @errortext, @errmsg output
         	      if @rcode = 1 goto bspexit
                 goto next_EMLiabType
                 end
             select @glamt = -(@liabamt)

             exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @glacct, @employee, @payseq, @glamt, @glhrs
             if @glco <> @prglco
                 begin
                 -- add Interco AP and AR entries
                 exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @glco, @intercoAPGLAcct, @employee, @payseq, @glamt, @glhrs
                 exec bspPRGLInsert @prco, @prgroup, @prenddate, @mth, @prglco, @intercoARGLAcct, @employee, @payseq, @liabamt, @glhrs
                 end

   
   		goto next_EMLiabType
   
   		end_EMLiabType:
               close bcEMLiabType
               deallocate bcEMLiabType
               select @openEMLiabType = 0
   	    goto next_Addon
   
   	end
   
     bspexit:  -- cleanup after all addons have been processed for a timecard
         if @openAddon = 1
             begin
             close bcAddon
             deallocate bcAddon
             end
         if @openLiabType = 1
             begin
             close bcLiabType
             deallocate bcLiabType
             end
   	if @openEMLiabType = 1
           begin
           close bcEMLiabType
           deallocate bcEMLiabType
           end
   
         --select @errmsg = @errmsg + char(13) + char(10) + 'bspPRUpdateValGLAddons'
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdateValGLAddons] TO [public]
GO
