SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRProcessState]
/***********************************************************
* CREATED BY:  GG  03/14/98
* MODIFIED BY: GG 04/09/99
*              LM 06/15/99  - Added username column in PRPE for SQL 7.0
*              GG 07/06/99 - Added routine procedure check
*              EN 10/30/99 - Changed how Indiana routine is called to include @addexempts amount in parameter list
*              GG 01/06/00 = fixed AP Vendor info update to bPRDT
*              GG 03/24/00 - add call to bspPRNYD##, moved from bspPRProcessLocal
*              DANF 08/17/00 - remove reference to system user id
*	             GH 12/06/00 - Employee addon amounts applied only if calculation basis > 0 not calcamt
*              GG 01/30/01 - skip calculations for both dedns and liabs if calculation basis = 0 (#11690)
*              GG 03/23/01 - default Fed Tax filing status and exemptions (#12689)
*              GG 06/01/01 - fix to use correct State tax routine when posting difference to resident state
*              DANF 06/04/01 - fix order in which resident and tax state deduction codes are processed for posting difference to resident state
*				 EN 11/13/01 - issue 15016 - change to exec for N. Dakota routine
*		 MV 1/28/02 - issue 15711 - check for correct CalcCategory
*			    - issue 13977 - round @calcamt if RndToDollar flag is set. 
*		EN 2/14/02 - issue 15752 - add # of Pay Periods to list of parameters pass into Arizona state tax routine 
*		GG 01/06/03 - #19867 - remove @limitmth param when calling bspPRProcessGetYTDSUIElig
*				EN 3/24/03 - issue 11030 rate of earnings liability limit
*				GG 02/10/04 - #23655 fix to dist liab override amt when calc basis = 0.00
*			EN 7/28/04 - issue 24545  call new routine bspPRExemptRateOfGross
*			EN 8/10/04 issue 25331  modify New York disability to calculate using bspPRProcessRateBased and use bspPRNYD98 routine to return correct rate only
*				EN	9/24/04 - issue 20562  change from using bPRCO_LiabDist to bPREC_IncldLiabDist to determine whether an earnings code is included in liab distribs
*				EN	11/18/04 - issue 26219  pass resident status into Maryland tax routine
*				EN	12/07/04 - issue 26418  pass Exemption for age 65 and over into Virginia tax routine bspPRVAT05
*				EN	3/24/05 - issue 26943  pass Misc Factor to Arkansas tax routine
*				EN	4/8/05 - issue 28379  added @@error check to see if SQL error occured when routine was called
*				EN	3/7/08 - #127081  in declare statements change State declarations to varchar(4)
*				EN	8/6/08 - #127167  Post difference to Resident State feature in PRStates does not work if posted state has no income tax
*				EN	3/09/2010	- #136099 call new routine to compute Virgin Islands tax
*				EN	5/26/2010	- #139365  after 7/1/2010 we no longer need to pass fedtax and fedbasis to Arizona tax routine
*				CHS	10/14/2010	- #139417 Added Guam
*				CHS 10/15/2010	- #140541 - change bPRDB.EarnCode to EDLCode	
*				CHS 02/21/2011	- #143229
*				CHS 04/08/2011	- #142367
*				EN 04/14/2011  B-02266 #142672 Enable Non Resident Alien option for Maine
*				CHS 05/12/11	- #142867 added Saipan.
*				EN 11/03/2011  TK-09327 / #144387 Added ability to call Puerto Rico tax routine with additional
*									parameter for misc amt and also refactored section of code that handles routines
*									to apply SQL best practices
*				CHS 12/27/2011	B-08264 added parameter for FICA to Massachusettes routine
*				EN 5/31/2013 - User Story 39007 / Task 51803 declare @addonrateamt as bUnitCost so that addon rates with more than 2 decimal places will work properly
*				MV 10/14/2013	64211/64212 Incorrect deduction amt if bPRSI 'Post Deff to Resident State' = Y. Pass 2 more param values to bspPRProcessGetBasis
*				CHS	10/15/2013	- TFS 49417 PR - (US) States need option to accumulate earnings in resident state
*
* USAGE:
* Calculates Tax and Unemployment State deductions and liabilities for a select Employee and Pay Seq.
* Called from main bspPRProcess procedure.
* Will  calculate most dedn/liab methods
*
* INPUT PARAMETERS
*   @prco	PR Company
*   @prgroup	PR Group
*   @prenddate	PR Ending Date
*   @employee	Employee to process
*   @payseq	Payment Sequence #
*   @ppds      # of pay periods in a year
*   @limitmth  Pay Period limit month
*   @stddays   standard # of days in Pay Period
*   @bonus     indicates a Bonus Pay Sequence - Y or N
*   @posttoall earnings posted to all days in Pay Period - Y or N
*   @fedtax    Federal Income Tax - used by some State Tax routines
*   @fedbasis  Federal Income Tax basis earnings
*

* OUTPUT PARAMETERS
*   @errmsg  	Error message if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
     	@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
         @ppds tinyint, @limitmth bMonth, @stddays tinyint, @bonus bYN,
         @posttoall bYN, @fedtax bDollar, @fedbasis bDollar, @errmsg varchar(255) output
     as
     set nocount on
    
     declare @rcode int, @resstate varchar(4), @restaxdedn bEDLCode, @taxdedn bEDLCode, @res char(1),
     @state varchar(4), @rate bUnitCost, @calcdiff char(1), @calcamt bDollar, @procname varchar(30),
     @eligamt bDollar, @amt2dist bDollar, @accumelig bDollar, @accumsubj bDollar, @accumamt bDollar,
     @ytdelig bDollar, @ytdamt bDollar, @calcbasis bDollar, @accumbasis bDollar,
     @liabbasis bDollar, @statetaxamt bDollar, @taxdiff char(1), @diff char(1), @basedon char(1),
     @sutaliab bEDLCode, @ytdsuielig bDollar, @miscamt bDollar, @overmiscamt bYN, @empmiscamt bDollar,
     @accumhrswks char(1), @sutahrswks bHrs, @fedtaxdedn bEDLCode, @fedfilestatus char(1), @fedexempts tinyint,
     @routinestate varchar(4), @resident varchar(1), @FICArate bRate, @FICAcodeSS bEDLCode, @FICAcodeMed bEDLCode,
     @exemptamt bDollar, @AccumSubjEarn char(1)
    
    
     -- Standard deduction/liability variables
     declare @dlcode bEDLCode, @dldesc bDesc, @dltype char(1), @method varchar(10), @routine varchar(10),
     @rate1 bUnitCost, @rate2 bUnitCost, @seq1only bYN, @ytdcorrect bYN, @bonusover bYN, @bonusrate bRate,
     @limitbasis char(1), @limitamt bDollar, @limitperiod char(1), @limitcorrect bYN, @autoAP bYN,
     @vendorgroup bGroup, @vendor bVendor, @apdesc bDesc, @calccategory varchar (1), @rndtodollar bYN,
     @limitrate bRate, @empllimitrate bRate, @outaccumbasis bDollar /*issue 11030*/
    
     -- Employee deduction/liability override variables
     declare @filestatus char(1), @regexempts tinyint, @addexempts tinyint, @overcalcs char(1), @emprateamt bUnitCost,
     @overlimit bYN, @emplimit bDollar, @addontype char(1), @addonrateamt bUnitCost, @empvendor bVendor,
     @miscfactor bRate
    
     -- Payment Sequence Total variables
     declare @dtvendorgroup bGroup, @dtvendor bVendor, @dtAPdesc bDesc, @useover bYN, @overprocess bYN, @overamt bDollar
    
    -- cursor flags
    declare @openState tinyint, @openStateDL tinyint

    -- Employee NonResAlienYN flag (issue 120519)
	declare @nonresalienyn bYN
    
    select @rcode = 0
    
    -- get Fed Tax and Filing Status for defaults
    select @fedfilestatus = 'S', @fedexempts = 0
    
    select @fedtaxdedn = TaxDedn, @FICAcodeSS = MiscFedDL1, @FICAcodeMed = MiscFedDL2
    from dbo.bPRFI with (nolock) where PRCo = @prco  -- already validated
    
    select @fedfilestatus = FileStatus, @fedexempts = RegExempts
    from dbo.bPRED with (nolock)
    where PRCo = @prco and Employee = @employee and DLCode = @fedtaxdedn
      
    -- get Employee's Resident Tax State info
    select @resstate = TaxState, @nonresalienyn = NonResAlienYN
    from dbo.bPREH with (nolock)
    where PRCo = @prco and Employee = @employee
     if @@rowcount = 0
         begin
         select @errmsg = 'Missing Employee header entry!', @rcode = 1
         goto bspexit
         end
    
     -- see if difference between posted and resident State Tax will need to be calculated
     select @restaxdedn = null, @taxdiff = 'N'
    
     if @resstate is not null
         begin
         select @restaxdedn = TaxDedn, @taxdiff = TaxDiff, @AccumSubjEarn = AccumulateSubjectEarningsYN
         from dbo.bPRSI with (nolock) where PRCo = @prco and State = @resstate
         end
    
     -- create cursor for posted States
     declare bcState cursor for
      select distinct TaxState, 'T'       -- 'T' used for Tax State
         from dbo.bPRTH
         where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
         union
         select distinct UnempState, 'U'    -- 'U' used for Unemployment State
         from dbo.bPRTH
         where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
    
    
     open bcState
    
     select @openState = 1
    
     -- loop through States
     next_State:
    
         fetch next from bcState into @state, @basedon
         if @@fetch_status = -1 goto end_State
         if @@fetch_status <> 0 goto next_State
    
         -- save State's Tax Dedn for possible difference calculation
         if @basedon = 'T'
             begin
             select @taxdedn = TaxDedn from dbo.bPRSI with (nolock) where PRCo = @prco and State = @state
             end
    
         -- save State's Unemployment liability - needs special limit handling
         if @basedon = 'U'
             begin
             select @sutaliab = SUTALiab, @accumhrswks = AccumHrsWks
             from dbo.bPRSI with (nolock) where PRCo = @prco and State = @state
             end
    
         -- check for residency - controls rates
         select @res = 'N'
         if @state = @resstate select @res = 'Y'
    
         -- clear Process Earnings
         delete dbo.bPRPE where VPUserName = SUSER_SNAME()
    
         if @basedon = 'T'
         	begin
         	-- load Process Earnings with all earnings posted to this Tax State
         	insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt ) --issue 20562
            select SUSER_SNAME(), t.PostSeq, t.PostDate, t.EarnCode, e.Factor, e.IncldLiabDist, t.Hours, t.Rate, t.Amt --issue 20562
            from dbo.bPRTH t
            join dbo.bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
            where t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
                     and t.PaySeq = @payseq and t.TaxState = @state
         	insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt )    -- Addons --issue 20562
            select SUSER_SNAME(), t.PostSeq, t.PostDate, a.EarnCode, e.Factor, e.IncldLiabDist, 0, a.Rate, a.Amt --issue 20562
            from dbo.bPRTA a
            join dbo.bPRTH t on t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate and
                 t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
            join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
            where a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate and a.Employee = @employee
    
                 and a.PaySeq = @payseq and t.TaxState = @state
            end
    
         if @basedon = 'U'
         	begin
         	-- load Process Earnings with all earnings posted to this Unemployment State
         	insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt )   -- Timecards --issue 20562
            select SUSER_SNAME(), t.PostSeq, t.PostDate, t.EarnCode, e.Factor, e.IncldLiabDist, t.Hours, t.Rate, t.Amt --issue 20562
            from dbo.bPRTH t
            join dbo.bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
            where t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
          and t.PaySeq = @payseq and t.UnempState = @state
         	insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt )   -- Addons --issue 20562
            select SUSER_SNAME(), t.PostSeq, t.PostDate, a.EarnCode, e.Factor, e.IncldLiabDist, 0, a.Rate, a.Amt --issue 20562
        from dbo.bPRTA a
            join dbo.bPRTH t on t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate and
                 t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
            join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
            where a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate and a.Employee = @employee
                 and a.PaySeq = @payseq and t.UnempState = @state
            end
    
    
         -- create cursor for Tax State DLs - resident 'N' or 'Y' and Dedn/Liab code and Difference flag - 'N' = don't calc diff, 'Y' = calc diff
         -- process resident 'Y' last for correct calculation of tax difference.
         if @basedon = 'T'
             begin
             declare bcStateDL cursor for
             select 'N' AS CalcDiff, TaxDedn from dbo.bPRSI with (nolock) where PRCo = @prco and State = @state and TaxDedn is not null
             union
             select 'N' AS CalcDiff, DLCode from dbo.bPRSD with (nolock) where PRCo = @prco and State = @state and BasedOn = 'T'
             union
             select 'Y' AS CalcDiff, @restaxdedn where @restaxdedn is not null and @taxdiff = 'Y' and isnull(@taxdedn,'') <> @restaxdedn --#127167 enclosed @taxdedn in isnull
             Order by CalcDiff, TaxDedn
             end
    
         -- create a cursor for Unemployment State DLs - no difference calculations
         if @basedon = 'U'
             begin
             declare bcStateDL cursor for
             select 'N' AS CalcDiff,SUTALiab from dbo.bPRSI with (nolock) where PRCo = @prco and State = @state and SUTALiab is not null
             union
             select 'N' AS CalcDiff,DLCode from dbo.bPRSD with (nolock) where PRCo = @prco and State = @state and BasedOn = 'U'
             end
    
         open bcStateDL
         select @openStateDL = 1
    
         -- loop through State DL cursor
         next_StateDL:
             fetch next from bcStateDL into @calcdiff,@dlcode
             if @@fetch_status = -1 goto end_StateDL
    
             if @@fetch_status <> 0 goto next_StateDL
    
    
             -- get standard DL info
             select @dldesc = Description, @dltype = DLType, @method = Method, @routine = Routine, @rate1 = RateAmt1,
                 @rate2 = RateAmt2, @seq1only = SeqOneOnly, @ytdcorrect = YTDCorrect, @bonusover = BonusOverride,
                 @bonusrate = BonusRate, @limitbasis = LimitBasis, @limitamt = LimitAmt, @limitperiod = LimitPeriod,
                 @limitcorrect = LimitCorrect, @autoAP = AutoAP, @vendorgroup = VendorGroup, @vendor = Vendor,
    	     @calccategory = CalcCategory, @rndtodollar=RndToDollar, @limitrate = LimitRate /*issue 11030*/
             from dbo.bPRDL with (nolock)
             where PRCo = @prco and DLCode = @dlcode
             if @@rowcount = 0
                 begin
     		    select @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' not setup!', @rcode = 1
    
     		    goto bspexit
     		    end
    
    	 /* validate calccategory*/
    	if @calccategory not in ('S','A')
    		begin
    		select @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' should be calculation category S or A!', @rcode = 1
     		goto bspexit
     		end
    
             -- check for Payment Sequence #1 restriction
             if @seq1only = 'Y' and @payseq <> 1 goto next_StateDL
    
             select @rate = @rate2       -- non-resident rate
             if @res = 'Y' or @dlcode = @restaxdedn select @rate = @rate1    -- resident rate
    
             -- get Employee info and overrides for this dedn/liab
             select @filestatus = @fedfilestatus, @regexempts = @fedexempts, @addexempts = 0, @overmiscamt = 'N',
             	@empmiscamt = 0.00, @miscfactor = 0.00, @empvendor = null, @apdesc = null,
             	@overcalcs = 'N', @overlimit = 'N', @addontype = 'N'
             select @filestatus = FileStatus, @regexempts = RegExempts, @addexempts = AddExempts, @overmiscamt = OverMiscAmt,
             	@empmiscamt = MiscAmt, @miscfactor = MiscFactor, @empvendor = Vendor, @apdesc = APDesc,
             	@overcalcs = OverCalcs, @emprateamt = isnull(RateAmt,0.00), @overlimit = OverLimit, @emplimit = isnull(Limit,0.00),
             	@addontype = AddonType, @addonrateamt = isnull(AddonRateAmt,0.00),
    			@empllimitrate = isnull(LimitRate,0.00) /*issue 11030*/
             from dbo.bPRED with (nolock)
             where PRCo = @prco and Employee = @employee and DLCode = @dlcode
    
     	if @regexempts is null select @regexempts = 0
     	if @addexempts is null select @addexempts = 0
    
             -- check for calculation override on Bonus sequence
             if @bonus = 'Y' and @bonusover = 'Y' select @method = 'G', @rate = @bonusrate
    
             -- check for Employee calculation and rate overrides
             if @overcalcs = 'M' select @method = 'G', @rate = @emprateamt
             if @overcalcs = 'R' select @rate = @emprateamt
             if @overlimit = 'Y' select @limitamt = @emplimit
    		 if @overlimit = 'Y' select @limitrate = @empllimitrate /*issue 11030*/
    
             -- get calculation, accumulation, and liability distribution basis
             exec @rcode = bspPRProcessGetBasis @prco, @prgroup, @prenddate, @employee, @payseq, @method,
                 @posttoall, @dlcode, @dltype, @stddays, @taxdedn, @calcdiff, @calcbasis output, @accumbasis output, --issue 20562
                 @liabbasis output, @errmsg output
             if @rcode <> 0 goto bspexit
    
     	 select @sutahrswks = 0		-- initialize SUTA hrs/weeks
    
             -- check for 0 basis - skip accumulations and calculations
             if @calcbasis = 0.00
                 begin
                 select @calcamt = 0.00, @eligamt = 0.00
                 goto calc_end
                 end
    
             -- accumulate actual, subject, and eligible amounts if needed
             if @limitbasis = 'C' or @limitbasis = 'S' or @ytdcorrect = 'Y'
                 begin
                 exec @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
                     @dlcode, @dltype, @limitperiod, @limitmth, @ytdcorrect, @accumamt output,
    
                     @accumsubj output, @accumelig output, @ytdamt output, @ytdelig output, @errmsg output
                 if @rcode <> 0 goto bspexit
                 end
    
             -- if SUTA liability accum year-to-date eligible earnings for all SUTA liabilities
    
             -- assumes reciprocal agreements among all states, method is 'G',
             -- limit based on 'subject earnings', applied 'annually', limit and ytd correct are both 'N'
             if @dlcode = @sutaliab
                 begin
				--#142367 need to pass @state and @dlcode to SP
                 exec @rcode = bspPRProcessGetYTDSUIElig @prco, @prgroup, @prenddate, @employee, @payseq,
                 	@state, @dlcode, @ytdsuielig output, @errmsg output
                 if @rcode <> 0 goto bspexit
    
                 select @accumelig = @ytdsuielig	-- use ytd sui eligible for accumulated eligible
    
    
                 -- get Hours or Weeks for Unemployement Liab
                 if @accumhrswks = 'H'
                 	begin
    
                 	 -- accumulate subject hours
         		select @sutahrswks = isnull(sum(e.Hours),0.00)
    
         		from dbo.bPRPE e with (nolock)
         		join dbo.bPRDB b with (nolock) on b.EDLCode = e.EarnCode
         		where VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
                 	end
                 if @accumhrswks = 'W' and @payseq = 1	-- only count weeks on Pay Seq #1
                 	begin
                 	select @sutahrswks = Wks
                 	from dbo.bPRPC with (nolock) where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                 	end
                 end
    
    
             -- Calculations
    
             select @calcamt = 0.00, @eligamt = 0.00
    
             -- Flat Amount
    
             if @method = 'A'
     		  begin
     		  exec @rcode = bspPRProcessAmount @calcbasis, @rate, @limitbasis, @limitamt, @limitcorrect, @accumelig,
     			 @accumsubj, @accumamt, @ytdelig, @ytdamt, @calcamt output, @eligamt output, @errmsg output
     		  if @rcode<> 0 goto bspexit
     		  end
    
     	   -- Rate per Day, Factored Rate per Hour, Rate of Gross, Rate per Hour, Straight Time Equivalent, or Rate of Dedn
             if @method in ('D', 'F', 'G', 'H', 'S', 'DN')
     		  begin
     		  exec @rcode = bspPRProcessRateBased @calcbasis, @rate, @limitbasis, @limitamt, @ytdcorrect,
                     @limitcorrect, @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt,
    				 @accumbasis, @limitrate, @outaccumbasis output, --issue 11030 adjust for changes in bspPRProcessRateBased
    				 @calcamt=@calcamt output, @eligamt=@eligamt output, @errmsg=@errmsg output
              if @rcode<> 0 goto bspexit
    		  select @accumbasis = @outaccumbasis --issue 11030 basis may be adjusted to fit rate of earnings limit scheme
     		  end
    
     		-- When Method is Routine
			IF @method = 'R'
			BEGIN
				-- get procedure name
				SELECT @procname = NULL
				SELECT	@procname = ProcName, 
						@miscamt = MiscAmt1
				FROM dbo.bPRRM
				WHERE PRCo = @prco AND Routine = @routine
				
				-- validate procedure name
				IF @procname IS NULL
				BEGIN
					SELECT @errmsg = 'Missing Routine procedure name for dedn/liab ' + CONVERT(varchar(4),@dlcode), @rcode = 1
					GOTO bspexit
				END
				
				IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = @procname AND type = 'P')
				BEGIN
					SELECT @errmsg = 'Invalid Routine procedure - ' + @procname, @rcode = 1
					GOTO bspexit
				END

				-- use Employee Misc Amount #2 override if set
				IF @overmiscamt = 'Y' SELECT @miscamt = @empmiscamt	

				-- assign Tax Routine State, may be posted state or resident
				SELECT @routinestate = @state
				IF @calcdiff = 'Y' SELECT @routinestate = @resstate
			   
				IF @procname = 'bspPRNDT98' --issue 15016 later N. Dakota routines use default EXEC
				BEGIN
					EXEC @rcode = @procname @calcbasis, 
											@fedtax, 
											@fedbasis, 
											@rate, 
											@calcamt OUTPUT, 
											@errmsg OUTPUT
					-- please put no code between EXEC and @@error check!
					IF @@error <> 0 SELECT @rcode = 1
				END

				ELSE IF @procname LIKE 'bspPRNYD%'        -- New York Disability Tax
				BEGIN
					EXEC @rcode = @procname @prco, 
											@rate1, 
											@rate2, 
											@employee, 
											@rate=@rate OUTPUT, 
											@msg=@errmsg OUTPUT
					-- please put no code between EXEC and @@error check!
					IF @@error <> 0 SELECT @rcode = 1
					IF @rcode <> 0 GOTO bspexit

					EXEC @rcode = bspPRProcessRateBased @calcbasis, 
														@rate, 
														@limitbasis, 
														@limitamt, 
														@ytdcorrect,
														@limitcorrect, 
														@accumelig, 
														@accumsubj, 
														@accumamt, 
														@ytdelig, 
														@ytdamt,
														@accumbasis, 
														@limitrate, 
														@outaccumbasis OUTPUT,
														@calcamt=@calcamt OUTPUT, 
														@eligamt=@eligamt OUTPUT, 
														@errmsg=@errmsg OUTPUT
					IF @rcode <> 0 GOTO bspexit

					SELECT @calcbasis = @eligamt
				END

				ELSE IF @procname = 'bspPRExemptRateOfGross'   -- rate of gross with exemption ... tax calculation withheld until subject amount reaches exemption limit
				BEGIN
					EXEC @rcode = bspPRProcessGetAccums @prco, 
														@prgroup, 
														@prenddate, 
														@employee, 
														@payseq,
														@dlcode, 
														@dltype, 
														'A', 
														@limitmth, 
														'N', 
														@accumamt OUTPUT,
														@accumsubj OUTPUT, 
														@accumelig OUTPUT, 
														@ytdamt OUTPUT, 
														@ytdelig OUTPUT, 
														@errmsg OUTPUT
					IF @rcode <> 0 GOTO bspexit

					SELECT @exemptamt = MiscAmt1 
					FROM dbo.bPRRM 
					WHERE PRCo = @prco AND Routine = @routine

					EXEC @rcode = @procname @calcbasis, 
											@rate, 
											@accumsubj, 
											@accumelig, 
											@exemptamt, 
											@calcamt OUTPUT, 
											@eligamt OUTPUT, 
											@errmsg OUTPUT
					-- please put no code between EXEC and @@error check!
					IF @@error <> 0 SELECT @rcode = 1
					SELECT @calcbasis = @eligamt
				END

				ELSE
				BEGIN
					-- Tax routine params vary based on State - will require some hardcoded changes
					IF @routinestate IN ('AL', 'IA', 'OR')
					BEGIN
						EXEC @rcode = @procname @calcbasis, 
												@ppds, 
												@filestatus, 
												@regexempts, 
												@fedtax, 
												@calcamt OUTPUT, 
												@errmsg OUTPUT
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END

					ELSE IF @routinestate IN ('AZ')
					BEGIN
						--Note: from PM
						--AZ state tax calculations should distinguish exempt employees (i.e. 0.00 rate setup in PRED) 
						--from employees with no override (i.e. no PRED entry).  If a 0.00 rate exists then the calculated 
						--tax amount should be 0.00 (assuming no add-on amount).  If no PREDemployee override exists for 
						--AZ tax in PRED then the minimum current rate should be applied (0.8%).

						--To accomplish this we set @miscfactor to null so that the AZ tax routine know that a tax rate has 
						--not been intentially set to zero and that it shold default a minimum tax.
						SELECT @miscfactor = null

						-- make that there is no Misc Factor set up in employee filing status
						SELECT @miscfactor = MiscFactor
						FROM dbo.bPRED WITH (NOLOCK)
						WHERE PRCo = @prco AND Employee = @employee AND DLCode = @dlcode     		  	

						IF @procname < 'bspPRAZT102' -- allow for running either pre 7/1/2010 version or post
						BEGIN
							EXEC @rcode = @procname @calcbasis, 
													@fedtax, 
													@fedbasis, 
													@miscfactor, 
													@ppds, 
													@calcamt OUTPUT, 
													@errmsg OUTPUT --pre 7/1/2010
						END
						ELSE
						BEGIN
							EXEC @rcode = @procname @calcbasis, 
													@miscfactor, 
													@ppds, 
													@calcamt OUTPUT, 
													@errmsg OUTPUT --post 7/1/2010
						END

						SELECT @miscfactor = 0.00
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END
					
					--ELSE IF @procname < 'bspPRMAT12' -- allow for running either pre 1/1/2012 version or post
					--	BEGIN
					--		EXEC @rcode = @procname @calcbasis, 
					--							@ppds, 
					--							@filestatus, 
					--							@regexempts, 
					--							@addexempts, 
					--							@calcamt OUTPUT, 
					--							@errmsg OUTPUT
					--	END
						
					--	ELSE
					--	BEGIN
					--		EXEC @rcode = @procname @calcbasis, 
					--							@ppds, 
					--							@filestatus, 
					--							@regexempts, 
					--							@addexempts, 
					--							@FICArate OUTPUT,
					--							@calcamt OUTPUT, 
					--							@errmsg OUTPUT
					--	END
					--	-- please put no code between EXEC and @@error check!
					--	IF @@error <> 0 SELECT @rcode = 1
					--END

					ELSE IF @routinestate IN ('CA', 'GA', 'IL', 'VA') --issue 26418
					BEGIN
						EXEC @rcode = @procname @calcbasis, 
												@ppds, 
												@filestatus, 
												@regexempts, 
												@addexempts, 
												@calcamt OUTPUT, 
												@errmsg OUTPUT
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END
					
					ELSE IF @routinestate IN ('KY')
					BEGIN
						EXEC @rcode = @procname @calcbasis, 
												@ppds, 
												@regexempts, 
												@calcamt OUTPUT, 
												@errmsg OUTPUT
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END
					
					ELSE IF @routinestate IN ('IN', 'LA', 'MI')
					BEGIN
						EXEC @rcode = @procname @calcbasis, 
												@ppds, 
												@regexempts, 
												@addexempts, 
												@calcamt OUTPUT, 
												@errmsg OUTPUT
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END
					
					ELSE IF @routinestate IN ('MD')
					BEGIN
						EXEC @rcode = @procname @calcbasis, 
												@ppds, 
												@filestatus, 
												@regexempts, 
												@miscfactor, 
												@res, 
												@calcamt OUTPUT, 
												@errmsg OUTPUT
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END

					ELSE IF @routinestate IN ('AR','NJ')
					BEGIN
						EXEC @rcode = @procname @calcbasis, 
												@ppds, 
												@filestatus, 
												@regexempts, 
												@miscfactor, 
												@calcamt OUTPUT, 
												@errmsg OUTPUT
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END

					ELSE IF @routinestate IN ('MO')
					BEGIN
						EXEC @rcode = @procname @calcbasis, 
												@ppds, 
												@filestatus, 
												@regexempts, 
												@fedtax, 
												@fedbasis, 
												@calcamt OUTPUT, 
												@errmsg OUTPUT
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END

					ELSE IF @routinestate IN ('MS')
					BEGIN
						EXEC @rcode = @procname @calcbasis, 
												@ppds, 
												@filestatus, 
												@miscamt, 
												@calcamt OUTPUT, 
												@errmsg OUTPUT
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END
					
					ELSE IF @routinestate IN ('PR')
					BEGIN
						IF @procname < 'bspPRPRT11' -- allow for running either pre 2011 version or post
						BEGIN
							EXEC @rcode = @procname @calcbasis, 
													@ppds, 
													@filestatus, 
													@regexempts, 
													@addexempts, 
													@miscfactor, 
													@calcamt OUTPUT, 
													@errmsg OUTPUT
						END
						ELSE
						BEGIN
							EXEC @rcode = @procname @calcbasis, 
													@ppds, 
													@filestatus, 
													@regexempts, 
													@addexempts, 
													@miscfactor, 
													@miscamt, 
													@calcamt OUTPUT, 
													@errmsg OUTPUT
						END
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END 
					
					ELSE IF @routinestate IN ('VI', 'GU', 'MP')
					BEGIN
						EXEC @rcode = @procname @prco, 
												@calcbasis, 
												@ppds, 
												@filestatus, 
												@regexempts, 
												@calcamt OUTPUT, 
												@errmsg OUTPUT
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END

					ELSE IF @routinestate IN ('ME')
					BEGIN
						EXEC @rcode = @procname @calcbasis, 
												@ppds, 
												@filestatus, 
												@regexempts, 
												@nonresalienyn, 
												@calcamt OUTPUT, 
												@errmsg OUTPUT
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END
					
					-- CHS 12/27/2011	B-08264 added parameter for FICA to Massachusettes routine
					ELSE IF @routinestate IN ('MA')
					BEGIN
						IF @procname < 'bspPRMAT12' -- allow for running either pre 1/1/2012 version or post
							BEGIN
								EXEC @rcode = @procname @calcbasis, 
													@ppds, 
													@filestatus, 
													@regexempts, 
													@addexempts, 
													@calcamt OUTPUT, 
													@errmsg OUTPUT
							END
							
							ELSE
							BEGIN
								-- get the FICA amount so the routine can deduct it.
								SELECT @FICArate = SUM(RateAmt1)
								FROM bPRDL
								WHERE PRCo = @prco and DLCode in (@FICAcodeSS,@FICAcodeMed)							
							
								EXEC @rcode = @procname @calcbasis, 
													@ppds, 
													@filestatus, 
													@regexempts, 
													@addexempts, 
													@FICArate,
													@calcamt OUTPUT, 
													@errmsg OUTPUT
							END
												
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
						
					END					
					

					ELSE
					BEGIN
						-- default - put calls to other State routines before this one
						EXEC @rcode = @procname @calcbasis, 
												@ppds, 
												@filestatus, 
												@regexempts, 
												@calcamt OUTPUT, 
												@errmsg OUTPUT     		  
						-- please put no code between EXEC and @@error check!
						IF @@error <> 0 SELECT @rcode = 1
					END
				END

				-- this is the point of entry after executing the routine
				IF @rcode <> 0 GOTO bspexit
				IF @calcamt IS NULL SELECT @calcamt = 0.00
				SELECT @eligamt = @calcbasis
			END -- end of "When Method is Routine" block
    
             -- apply Employee calculation override
             if @overcalcs = 'A' select @calcamt = @emprateamt
    
             -- apply Employee addon amounts - only applied if calculated amount is positive
             if @calcbasis > 0.00
    
                 begin
     		    if @addontype = 'A' select @calcamt = @calcamt + @addonrateamt
     		    if @addontype = 'R' select @calcamt = @calcamt + (@calcbasis * @addonrateamt)
     		    end
    
    
             -- save calculated State Tax amount
             if @dlcode = isnull(@taxdedn,'') select @statetaxamt = @calcamt --#127167
    
             -- check for Resident State Tax difference - set to 0 if equal or less than posted State tax
             if @dlcode = @restaxdedn and @calcdiff = 'Y'
                 begin
                 if @calcamt <= @statetaxamt select @calcamt = 0.00
                 if @calcamt > @statetaxamt select @calcamt = @calcamt - @statetaxamt
				 if @AccumSubjEarn = 'N' select @accumbasis = 0.00, @eligamt = 0.00
                 end
    
    	if @rndtodollar='Y'	select @calcamt = ROUND(@calcamt,0) --round to the nearest dollar
    	
     	   calc_end:	 -- Finished with calculations
     	   -- get AP Vendor and Transaction description
     	   select @dtvendorgroup = null, @dtvendor = null, @dtAPdesc = null
    
     	   if @autoAP = 'Y'
     		  begin
     		  select @dtvendorgroup = @vendorgroup, @dtvendor = @vendor, @dtAPdesc = @dldesc
     		  if @empvendor is not null select @dtvendor = @empvendor
     		  if @apdesc is not null select @dtAPdesc = @apdesc
     		 end
    
     	   -- update Payment Sequence Totals
     	   update dbo.bPRDT
            set Amount = Amount + @calcamt, SubjectAmt = SubjectAmt + @accumbasis, EligibleAmt = EligibleAmt + @eligamt,
            	VendorGroup = @dtvendorgroup, Vendor = @dtvendor, APDesc = @dtAPdesc
     		  where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
     		      and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
     	   if @@rowcount = 0
     		  begin
     		  insert dbo.bPRDT (PRCo, PRGroup, PREndDate, Employee, PaySeq, EDLType, EDLCode, Hours, Amount, SubjectAmt, EligibleAmt,
    
     			 UseOver, OverAmt, OverProcess, VendorGroup, Vendor, APDesc, OldHours, OldAmt, OldSubject, OldEligible, OldMth,
                  			OldVendor, OldAPMth, OldAPAmt)
     		  values (@prco, @prgroup, @prenddate, @employee, @payseq, @dltype, @dlcode, 0, @calcamt, @accumbasis, @eligamt,
     			 'N', 0, 'N', @dtvendorgroup, @dtvendor, @dtAPdesc, 0, 0, 0, 0, null, null, null, 0)
    	       	if @@rowcount <> 1
    			begin
    			select @errmsg = 'Unable to add PR Detail Entry for Employee ' + convert(varchar(6),@employee), @rcode = 1
    			goto bspexit
    			end
     		  end
    		
     	-- SUTA updates
     	if @dlcode = @sutaliab
     		begin
     		-- update SUTA Hours/Weeks to Payment Sequence Totals
     		update dbo.bPRDT
     		set Hours = Hours + @sutahrswks
     		where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
     		      and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
     	 	end
    
    
             -- check for Override processing
             select @useover = UseOver, @overamt = OverAmt, @overprocess = OverProcess
             from dbo.bPRDT with (nolock)
             where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
     		  and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
    
             if @overprocess = 'Y' goto next_StateDL
    
    
             -- an overridden DL amount is processed only once
     	    if @useover = 'Y'
     		  begin
     		  update dbo.bPRDT
               set OverProcess = 'Y' where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                 and Employee = @employee and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
     		  end
    
             -- check for Liability distribution - needed even if basis and/or amount are 0.00
             if @dltype <> 'L' goto next_StateDL
    
             -- use calculated amount unless overridden
     		select @amt2dist = @calcamt
    		-- #23655 fix to use override amt even if calc basis = 0
     		if @useover = 'Y' /*and @calcbasis <> 0.00*/ select @amt2dist = @overamt
    
     		-- no need to distribute if Basis <> 0 and Amt = 0, but will distibute if both are 0.00
             -- because of possible offsetting timecard entries
             if @calcbasis <> 0.00 and @amt2dist = 0.00 goto next_StateDL
    
             -- call procedure to distribute liability amount
             exec @rcode = bspPRProcessLiabDist @prco, @prgroup, @prenddate, @employee, @payseq, @dlcode,
                     @method, @rate, @liabbasis, @amt2dist, @posttoall, @errmsg output --issue 20562
             if @rcode <> 0 goto bspexit
    
             goto next_StateDL
    
         end_StateDL:
             close bcStateDL
             deallocate bcStateDL
             select @openStateDL = 0
             goto next_State
    
     end_State:
    
         close bcState
         deallocate bcState
    
    
         select @openState = 0
    
    
     bspexit:
         -- clear Process Earnings
    
         delete dbo.bPRPE where VPUserName = SUSER_SNAME()
    
         if @openStateDL = 1
             begin
        		close bcStateDL
         	deallocate bcStateDL
           	end
         if @openState = 1
             begin
        		close bcState
         	deallocate bcState
           	end
     	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRProcessState] TO [public]
GO
