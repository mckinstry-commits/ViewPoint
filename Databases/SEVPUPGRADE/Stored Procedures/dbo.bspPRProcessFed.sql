
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPRProcessFed]
   /***********************************************************
   * CREATED BY: 	 GG  02/19/98
   * MODIFIED BY:    GG 04/09/99
   *                 LM 06/15/99  - Added username column in PRPE for SQL 7.0
   *              GG 07/05/99 - Added routine procedure check
   *              GG 01/06/00 - fix AP Vendor info update to bPRDT
   *              GG 03/06/00 - Employee addon amounts applied only if calculation basis > 0
   *              DANF 08/17/00 - remove reference to system id
   *              GG 01/30/01 - skip calculations for both dedns and liabs if calc basis = 0 (#11690)
   *		 MV 1/28/02 - issue 15711 - check for correct CalcCategory
   *			    - issue 13977 - round @calcamt if RndToDollar flag is set.  
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *				EN 3/24/03 - issue 11030 rate of earnings liability limit
   *				GG 02/10/04 - #23655 fix to dist liab override amt when calc basis = 0.00
   *				EN 7/28/04 - issue 24545  call new routine bspPRExemptRateOfGross
   *				EN 9/24/04 - issue 20562  change from using bPRCO_LiabDist to bPREC_IncldLiabDist to determine whether an earnings code is included in liab distribs
   *				EN 4/8/05 - issue 28379  added @@error check to see if SQL error occured when routine was called
   *				EN 8/21/07 - issue 120519  pass NonResAlien flag to bspPRFWT routine for non-resident alien tax addon
   *				EN 3/7/08 - #127081 in declare statements change bState to varchar(4)
   *				EN 6/03/08 - #127270 call routine bspPR_AU_PAYGxx routine for Australia national tax computation
   *				EN 7/09/08  #127015 include new fields in PRFI (MiscFedDL1-4) when check for federal D/L's to process
   *				EN 8/10/09 - #133605 don't read MiscFedDL3 from bPRFI ... mod for AUS Superannuation Guarantee
   *		TJL 02/19/10 - Issue #137844, as a result of NULL values allowed for AU in the Federal Info file, "selects" needed to skip them
   *				EN 11/27/2012	D-05383/#146657 added call to new routine vspPRMedicareSurcharge
   *				EN 11/30/2012	D-05383/#146657 modified to ignore any federal d/l codes not set up in PRFed
   *				DAN SO 03/18/2013 - Stories 39860, 39862, 39863, 39864, 39865 - ETP Tax Routines
   *				EN 3/22/2013  Story 39859/Task 42411 added call to new routine vspPR_AU_Marginal_PAYG
   *				DAN SO 05/21/2013 - Story 50738 - return Eligible amount`
   *
   * USAGE:
   * Calculates Federal deductions and liabilities for a select Employee and Pay Seq.
   * Called from main bspPRProcess procedure.
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
   *   @posttoall earnings posted to all days in Pay Period
   *   @country	country code
   *
   * OUTPUT PARAMETERS
   *   @fedtax	Federal Tax amount
   *   @fedbasis	Federal Tax basis
   *   @errmsg  	Error message if something went wrong
   *
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
    	@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
    	@ppds tinyint, @limitmth bMonth, @stddays tinyint, @bonus bYN, @posttoall bYN, @country char(2),
        @fedtax bDollar output, @fedbasis bDollar output, @errmsg varchar(255) output
    as
    set nocount on
   
    declare @rcode int, @fedtaxdedn bEDLCode, @futa bEDLCode, @calcbasis bDollar,
    @calcamt bDollar, @procname varchar(30), @eligamt bDollar, @amt2dist bDollar,
    @accumbasis bDollar, @accumelig bDollar, @accumsubj bDollar, @accumamt bDollar,
    @ytdelig bDollar, @ytdamt bDollar, @rate bUnitCost, @liabbasis bDollar,
    @exemptamt bDollar --issue 24545

    -- Standard deduction/liability variables
    declare @dlcode bEDLCode, @dldesc bDesc, @dltype char(1), @method varchar(10), @routine varchar(10),
    @rate1 bUnitCost, @seq1only bYN, @ytdcorrect bYN, @bonusover bYN, @bonusrate bRate,
    @limitbasis char(1), @limitamt bDollar, @limitperiod char(1), @limitcorrect bYN, @autoAP bYN,
    @vendorgroup bGroup, @vendor bVendor, @apdesc bDesc, @calccategory varchar (1), @rndtodollar bYN,
    @limitrate bRate, @empllimitrate bRate, @outaccumbasis bDollar /*issue 11030*/
   
    -- Employee deduction/liability override variables
    declare @filestatus char(1), @regexempts tinyint, @overcalcs char(1), @emprateamt bUnitCost,
    @overlimit bYN, @emplimit bDollar, @addontype char(1), @addonrateamt bDollar, @empvendor bVendor
   
    -- Employee NonResAlienYN flag (issue 120519)
	declare @nonresalienyn bYN

	-- Australia PAYG computation declarations (#127270)
	declare @addlexempts tinyint, @ftb_offset bDollar

    -- Payment Sequence Total variables
    declare @dtvendorgroup bGroup, @dtvendor bVendor, @dtAPdesc bDesc, @useover bYN, @overprocess bYN,
    @overamt bDollar
   
    -- open cursor flags
    declare @openFedDL tinyint
   
    select @rcode = 0
   
    -- reset Federal Tax and Basis amounts
    select @fedtax = 0.00, @fedbasis = 0.00
   
    -- get Federal Tax and FUTA codes
    select @fedtaxdedn = TaxDedn, @futa = FUTALiab
    	from dbo.bPRFI with (nolock)
        where PRCo = @prco
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Missing Federal Tax information!', @rcode = 1
    	goto bspexit
    	end
   
   	-- get NonResAlienYN flag for employee (issue 120519)
   	select @nonresalienyn = NonResAlienYN from dbo.PREH with (nolock)
   	where PRCo = @prco and Employee = @employee

    -- clear Process Earnings table
    delete dbo.bPRPE where VPUserName = SUSER_SNAME()
   
    insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt )   -- Timecards
        select SUSER_SNAME(), t.PostSeq, t.PostDate, t.EarnCode, e.Factor, e.IncldLiabDist, t.Hours, t.Rate, t.Amt
        from dbo.bPRTH t
        join dbo.bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
        where t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
            and t.PaySeq = @payseq
    insert dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt )   -- Addons
        select SUSER_SNAME(), t.PostSeq, t.PostDate, a.EarnCode, e.Factor, e.IncldLiabDist, 0, a.Rate, a.Amt
        from dbo.bPRTA a
        join dbo.bPRTH t on t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate and
           t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
        join dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
        where a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate and a.Employee = @employee
            and a.PaySeq = @payseq
   
    -- create cursor for all Federal D/Ls
	IF @country = 'US'
	BEGIN
		DECLARE bcFedDL CURSOR FOR
			SELECT TaxDedn FROM dbo.bPRFI WHERE PRCo = @prco
			UNION
			SELECT FUTALiab FROM dbo.bPRFI WHERE PRCo = @prco
			UNION
			SELECT Code=MiscFedDL1 FROM dbo.bPRFI WHERE PRCo = @prco --#127015
			UNION
			SELECT Code=MiscFedDL2 FROM dbo.bPRFI WHERE PRCo = @prco --#127015
			UNION
			SELECT Code=MiscFedDL3 FROM dbo.bPRFI WHERE PRCo = @prco --#127015
			UNION
			SELECT Code=MiscFedDL4 FROM dbo.bPRFI WHERE PRCo = @prco --#127015
			UNION
			SELECT Code=MiscFedDL5 FROM dbo.bPRFI WHERE PRCo = @prco --#127015
			UNION
			SELECT DLCode FROM dbo.bPRFD WHERE PRCo = @prco
	END
	if @country = 'AU'
		begin
		declare bcFedDL cursor for
			select TaxDedn from dbo.bPRFI with (nolock) where PRCo = @prco
			union
			select FUTALiab from dbo.bPRFI with (nolock) where PRCo = @prco and FUTALiab is not null
			union
			select Code=MiscFedDL1 from dbo.bPRFI with (nolock) where PRCo = @prco and MiscFedDL1 is not null	--#127015
			union
			select Code=MiscFedDL2 from dbo.bPRFI with (nolock) where PRCo = @prco and MiscFedDL2 is not null  --#127015
			union
			select DLCode from dbo.bPRFD with (nolock) where PRCo = @prco
		end
   
    open bcFedDL
    select @openFedDL = 1
   
    -- loop through Federal DL cursor
    next_FedDL:
    	fetch next from bcFedDL into @dlcode
    	if @@fetch_status = -1 goto end_FedDL
    	if @@fetch_status <> 0 goto next_FedDL
   
		-- ignore any null dlcodes set up in PRFed
		if @dlcode is null
			begin
			goto next_FedDL
			end

    	-- get standard DL info
    	select @dldesc = Description, @dltype = DLType, @method = Method, @routine = Routine,
    		@rate1= RateAmt1, @seq1only = SeqOneOnly, @ytdcorrect = YTDCorrect, @bonusover = BonusOverride,
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
   
   	 /* validate calculation category*/
   	if @calccategory not in ('F','A')
   		begin
   		select @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' must be calculation category F or A!', @rcode = 1
    		goto bspexit
    		end
   
    	-- skip if restricted to Pay Seq #1
    	if @seq1only = 'Y' and @payseq <> 1 goto next_FedDL
   
   
        select @rate = @rate1   -- default to standard DL rate
   
    	-- get Employee info and overrides for this DL
    	select @filestatus = 'S', @regexempts = 0, @empvendor = null, @apdesc = null, @overcalcs = 'N',
            @overlimit = 'N', @addontype = 'N', @addonrateamt = 0.00
    	select @filestatus = FileStatus, @regexempts = RegExempts, @empvendor = Vendor, @apdesc = APDesc,
    		@overcalcs = OverCalcs, @emprateamt = isnull(RateAmt,0.00), @overlimit = OverLimit,
    		@emplimit = isnull(Limit,0.00), @addontype = AddonType, @addonrateamt = isnull(AddonRateAmt,0.00),
   		@empllimitrate = isnull(LimitRate,0.00) /*issue 11030*/
    	from dbo.bPRED with (nolock)
   
        where PRCo = @prco and Employee = @employee and DLCode = @dlcode
   
    	-- check for calculation override on Bonus sequence
    	if @bonus = 'Y' and @bonusover = 'Y' select @method = 'G', @rate = @bonusrate
   
    	-- check for Employee calculation and rate overrides
    	if @overcalcs = 'M' select @method = 'G', @rate = @emprateamt
    	if @overcalcs = 'R' select @rate = @emprateamt
    	if @overlimit = 'Y' select @limitamt = @emplimit
   	if @overlimit = 'Y' select @limitrate = @empllimitrate /*issue 11030*/
   
        -- get calculation, accumulation, and liability distribution basis
        exec @rcode = bspPRProcessGetBasis @prco, @prgroup, @prenddate, @employee, @payseq, @method, --issue 20562
            @posttoall, @dlcode, @dltype, @stddays, @calcbasis output, @accumbasis output,
            @liabbasis output, @errmsg output
        if @rcode <> 0 goto bspexit
   
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
   
    	-- Calculations
    	select @calcamt = 0.00
   
    	/* Flat Amount */
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
   
    	-- Routine
    	if @method = 'R'
    		begin
    		-- get procedure name
    		select @procname = null
    		select @procname = ProcName from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = @routine
    		if @procname is null
    			begin
    			select @errmsg = 'Missing Routine procedure name for dedn/liab ' + convert(varchar(4),@dlcode), @rcode = 1
    			goto bspexit
    			end
            if not exists(select * from sysobjects where name = @procname and type = 'P')
                 begin
                 select @errmsg = 'Invalid Routine procedure - ' + @procname, @rcode = 1
                 goto bspexit
                 end
   
   	  -- issue 24545
            if @procname = 'bspPRExemptRateOfGross'   -- rate of gross with exemption ... tax calculation withheld until subject amount reaches exemption limit
               begin
   			exec @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
   			  @dlcode, @dltype, 'A', @limitmth, 'N', @accumamt output,
   			  @accumsubj output, @accumelig output, @ytdamt output, @ytdelig output, @errmsg output
   			if @rcode <> 0 goto bspexit
   	
   			select @exemptamt = MiscAmt1 from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = @routine
   	
   			exec @rcode = @procname @calcbasis, @rate, @accumsubj, @accumelig, @exemptamt, @calcamt output, @eligamt output, @errmsg output
   			-- please put no code between exec and @@error check!
   			if @@error <> 0 select @rcode = 1 --28379 check for error when routine was called
   			if @rcode <> 0 goto bspexit --28379 if error occurred, abort
   
   			select @calcbasis = @eligamt
   			goto routine_end
   			end

			-- #127270 Australia PAYG national tax routine
			if @procname like 'bspPR_AU_PAYG%'
				begin
    			select @addlexempts = 0, @ftb_offset = 0
    			select @addlexempts = AddExempts, @ftb_offset = MiscAmt
    			from dbo.bPRED with (nolock)
				where PRCo = @prco and Employee = @employee and DLCode = @dlcode

    			exec @rcode = @procname @calcbasis, @ppds, @regexempts, @filestatus, @addlexempts, @nonresalienyn, @ftb_offset, @calcamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				if @@error <> 0 select @rcode = 1
    			if @rcode <> 0 goto bspexit
   
    			if @calcamt is null select @calcamt = 0.00
    			select @eligamt = @calcbasis
   				goto routine_end

				end

			-- D-05383/#146657 if computing the additional Medicare surcharge, assume @limitperiod is annual
			IF @procname like 'vspPRMedicareSurcharge%' 
			BEGIN
				EXEC @rcode = vspPRProcessGetDLYTDSubjectAmount	@prco,		@prgroup,	@prenddate,		
																@employee,	@payseq,	@dlcode,	
																@accumbasis output,
																@errmsg output
    												
    			IF @rcode <> 0 GOTO bspexit
	    		
    			--call stored proc passing in the subject amount (calcbasis) and ytd subject amount (@accumsubj)
    			EXEC @rcode = @procname @calcbasis, @accumbasis, @calcamt OUTPUT, @eligamt OUTPUT, @errmsg OUTPUT
   				-- please put no code between exec and @@error check!
   				IF @@error <> 0 SELECT @rcode = 1
    			IF @rcode <> 0 GOTO bspexit
   
				IF @calcamt IS NULL SELECT @calcamt = 0.00
				SELECT @accumbasis = @calcbasis
   				GOTO routine_end
			END
		
			------------------------------------------------------------------
			-- ETP ROUTINE -- Story 39859/Task 42411 vspPR_AU_Marginal_PAYG --
			------------------------------------------------------------------
			IF @procname = 'vspPR_AU_Marginal_PAYG' 
			BEGIN
				EXEC	@rcode = @procname
						@PRCo = @prco,
						@Employee = @employee,
						@PRGroup = @prgroup,
						@PREndDate = @prenddate,
						@NumberOfPayPdsAnnually = @ppds,
						@SubjectAmount = @calcbasis,
						@TaxAmount = @calcamt OUTPUT,
						@ErrorMsg = @errmsg OUTPUT
   				-- please put no code between exec and @@error check!
   				IF @@error <> 0 SELECT @rcode = 1
    			IF @rcode <> 0 GOTO bspexit
   
				IF @calcamt IS NULL SELECT @calcamt = 0.00
				SELECT @eligamt = @calcbasis
   				GOTO routine_end
			END
	

			------------------
			-- ETP ROUTINES -- Stories 39860, 39862, 39863, 39864, 39865 --
			------------------ 
			If @procname IN ('vspPR_AU_Death',		'vspPR_AU_Invalidity',		'vspPR_AU_Redundancy',
							 'vspPR_AU_Standard',	'vspPR_AU_Unfair')
				BEGIN
					DECLARE @ETPTotalTaxWithheld bDollar, @ETPEligibleAmt bDollar -- 50738 --

					-- CALL CORRESPONDING ETP ROUTINE --
					EXEC @rcode = @procname 
									@prco, @employee, @prenddate, @calcbasis,  
									@TaxAmount = @ETPTotalTaxWithheld OUTPUT,
									@EligibleAmt = @ETPEligibleAmt OUTPUT,
									@ErrorMsg = @errmsg OUTPUT
			
					-- CHECK RETURN CODE --				
    				IF @rcode <> 0 GOTO bspexit
	    		
					-- SET --
					IF @ETPTotalTaxWithheld IS NULL SELECT @ETPTotalTaxWithheld = 0
					SET @calcamt = @ETPTotalTaxWithheld

					-- 50738 --
					IF @ETPEligibleAmt IS NULL SET @ETPEligibleAmt = 0
					SET @eligamt = @ETPEligibleAmt

					GOTO routine_end
				END


    		exec @rcode = @procname @calcbasis, @ppds, @filestatus, @regexempts, @nonresalienyn, @calcamt output, @errmsg output --issue 120519
   		-- please put no code between exec and @@error check!
   		if @@error <> 0 select @rcode = 1 --28379 check for error when routine was called
    		if @rcode <> 0 goto bspexit
   
    		if @calcamt is null select @calcamt = 0.00
    		select @eligamt = @calcbasis
    		end
   
        routine_end:
        -- apply Employee calculation override
        if @overcalcs = 'A'	select @calcamt = @emprateamt
   
    	-- apply Employee addon amounts - only applied if calculation basis is positive
    	if @calcbasis > 0.00
    		begin
    		if @addontype = 'A' select @calcamt = @calcamt + @addonrateamt
    		if @addontype = 'R' select @calcamt = @calcamt + (@calcbasis * @addonrateamt)
    		end
   
   	if @rndtodollar='Y'	select @calcamt = ROUND(@calcamt,0) -- round to the nearest dollar
   
        calc_end:	-- Finished with calculations
            -- save Fed Tax and subject amount
            if @dlcode = @fedtaxdedn select @fedtax = @calcamt, @fedbasis = @calcbasis
   
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
    			 'N', 0, 'N', @dtvendorgroup, @dtvendor, @dtAPdesc, 0, 0, 0, 0, null, null, null,0)
   
    	          if @@rowcount <> 1
    			begin
    			select @errmsg = 'Unable to add PR Detail Entry for Employee ' + convert(varchar(6),@employee), @rcode = 1
    			goto bspexit
    			end
    		  end
   
    	   -- check for Override processing
    	   select @useover = UseOver, @overamt = OverAmt, @overprocess = OverProcess
    	   from dbo.bPRDT with (nolock)
           where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
    		  and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
   
    	   if @overprocess = 'Y' goto next_FedDL
   
           -- an overridden DL amount is processed only once
    	   if @useover = 'Y'
    		  begin
    		  update dbo.bPRDT
                set OverProcess = 'Y' where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
    			     and Employee = @employee and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
    		  end
   
    	   -- check for Liability distribution - needed even if basis and/or amount are 0.00
    	   if @dltype <> 'L' goto next_FedDL
   
           -- use calculated amount unless overridden
 
    	   select @amt2dist = @calcamt
   		-- #23655 fix to use override amt even if calc basis = 0
    	   if @useover = 'Y' /*and @calcbasis <> 0.00*/ select @amt2dist = @overamt
   
         -- no need to distribute if Basis <> 0 and Amt = 0, but will distibute if both are 0.00
            -- because of possible offsetting timecard entries
            if @calcbasis <> 0.00 and @amt2dist = 0.00 goto next_FedDL
   
           -- call procedure to distribute liability amount
            exec @rcode = bspPRProcessLiabDist @prco, @prgroup, @prenddate, @employee, @payseq, @dlcode,
                    @method, @rate, @liabbasis, @amt2dist, @posttoall, @errmsg output --issue 20562
            if @rcode <> 0 goto bspexit
   
        goto next_FedDL
   
    end_FedDL:
        close bcFedDL
        deallocate bcFedDL
        select @openFedDL = 0
   
    bspexit:
   
        -- clear Process Earnings
        delete dbo.bPRPE where VPUserName = SUSER_SNAME()
   
        if @openFedDL = 1
            begin
       		close bcFedDL
        	deallocate bcFedDL
          	end
   
    	return @rcode


GO

GRANT EXECUTE ON  [dbo].[bspPRProcessFed] TO [public]
GO
