SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPRProcessFedCA]
   /***********************************************************
   * CREATED BY: 	EN 03/28/08 - issue 127015  added for Canada
   * MODIFIED BY:   EN 05/15/09 #133697  set a default for total claim (@TC) ... default is 0 for non residents
   *				EN 05/15/09 #133697  revise default for total claim (@TC), effective 4/1/2009
   *				EN 10/02/09 #135627  code for CPP annual limit
   *				EN 08/18/10 #140613  adjustment to correct CPP/EI (K2) credits when CPP/EI limits have been reached
   *				EN 10/13/10 #141669  allow for CPP zero override for computine CPP/EI (K2) credit
   *				EN 12/20/10 #142337  moved code to determine default total claim (@TC) amount into tax routine as of version bspPR_CA_FWT11
   *				KK/EN 02/16/12 - TK-12086 #145544 Reinitialize TC to 0 with each iteration for all filing stati
   *				EN/CS 5/16/2012 D-04482/TK-14889/#145773 CPP and EI variables not getting cleared between calls to this stored proc resulting in carryover issues
   *				EN 2/01/2013 #147940  Allow for setting up EI dedn as either subject amt OR calculated amt limit and have EI be computed
   *										as with a calculated amt limit in either case which assures that the contribution calculation is correct.
   *										Then adjust the eligible amount when limit is reached to be exact in case of a rounding error.
   *										While doing this, coded original search of PRFI to return @FedDednType to make it easier to recognize when EI is being
   *										computed and enabled me to remove 2 additional PRFI search statements.
   *				EN 5/31/2013 - User Story 39007 / Task 51803 declare @addonrateamt as bUnitCost so that addon rates with more than 2 decimal places will work properly
   *				MV		10/14/2013	64211/64212 Incorrect deduction amt if bPRSI 'Post Deff to Resident State' = Y. Pass 2 more param values to bspPRProcessGetBasis
   * USAGE:
   * Calculates Canada Federal deductions and liabilities for a select Employee and Pay Seq.
   * Called from main bspPRProcess procedure.  Based on bspPRProcessFed.
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
   *
   * OUTPUT PARAMETERS
   *   @fedtax	Federal Tax amount
   *   @fedbasis	Federal Tax basis
   *   @A			Annual Taxable Amount (Canada) ... returned by fed tax routine and used in provincial/territorial tax routines
   *   @PP			Canada Pension Plan or Quebec Pension Plan contribution for the pay period (Canada) ... passed into fed tax routine and used by provincial/territorial tax routines
   *   @maxCPP		maximum pension contribution
   *   @EI			Employment Insurance premium for the pay period (Canada) ... passed into fed tax routine and used by provincial/territorial tax routines
   *   @maxEI		maximum EI contribution
   *   @capstock	YTD deduction for acquisition of approved shares of the capital stock of a prescribed labour-sponsored venture capital corporation ... passed into fed tax routine and used by some provincial/territorial tax routines
   *   @HD			annual deduction for living in a prescribed zone ... passed into fed tax routine and used by British Colombia tax routine
   *   @errmsg  	Error message if something went wrong
   *
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
    	@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
    	@ppds tinyint, @limitmth bMonth, @stddays tinyint, @bonus bYN, @posttoall bYN,
        @fedtax bDollar output, @fedbasis bDollar output, @A bDollar output, @PP bDollar output, @maxCPP bDollar output,
		@EI bDollar output, @maxEI bDollar output, @capstock bDollar output, @HD bDollar output, @errmsg varchar(255) output
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
    @limitrate bRate, @empllimitrate bRate, @outaccumbasis bDollar, /*issue 11030*/
	@FedDednType char(1)
   
    -- Employee deduction/liability override variables
    declare @filestatus char(1), @regexempts tinyint, @overcalcs char(1), @emprateamt bUnitCost,
    @overlimit bYN, @emplimit bDollar, @addontype char(1), @addonrateamt bUnitCost, @empvendor bVendor
   
    -- Employee NonResAlienYN flag (issue 120519)
	declare @nonresalienyn bYN

    -- Payment Sequence Total variables
    declare @dtvendorgroup bGroup, @dtvendor bVendor, @dtAPdesc bDesc, @useover bYN, @overprocess bYN,
    @overamt bDollar
   
	-- declarations specific to Canada Federal Taxes
	declare @province varchar(4), 
	@ppdaccumsubj bDollar, --subject amount accum for the pay period used to compute CPP deductions
	@ppdaccumelig bDollar, --eligible amount accum for the pay period used to compute CPP deductions
	@F1 bDollar, --annual deductions such as child care expenses and support ... passed into fed tax routine
	@TC bDollar, --total claim amount reported on Form TD1 ... passed into fed tax routine
	@IE bDollar, --insurable earnings for the pay period (used for computing Quebec QPP and EI fed tax credits) ... passed into fed tax routine
	@K3 bDollar, --other federal tax credits such as medical expenses and charitable donations ... passed into fed tax routine
	@annualaccumamt bDollar --used to save annual limit for CPP

    -- open cursor flags
    declare @openFedDL tinyint
   
    select @rcode = 0
   
    -- reset Federal Tax and Basis amounts
    select @fedtax = 0.00, @fedbasis = 0.00
   
	-- reset annual taxable wages, capital stock, and tax credit amount
	select @A = 0.00, @capstock = 0.00

	-- D-04482/TK-14889 (EN/CS) reset CPP and EI values
	SELECT	@PP = 0.00,
			@maxCPP = 0.00,
			@EI = 0.00,
			@maxEI = 0.00
			
    -- get Federal Tax and FUTA codes
    select @fedtaxdedn = TaxDedn, @futa = FUTALiab
    	from dbo.bPRFI with (nolock)
        where PRCo = @prco
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Missing Federal Tax information!', @rcode = 1
    	goto bspexit
    	end
   
   	-- get NonResAlienYN flag for employee (issue 120519) ... #127015 also get province and other info needed for Canada tax computation
   	select @nonresalienyn = NonResAlienYN, @province = TaxState, @HD = isnull(HDAmt,0), @F1 = isnull(F1Amt,0),
		@capstock = isnull(LCFStock,0)
	from dbo.PREH with (nolock)
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
    declare bcFedDL cursor for
        select Code=TaxDedn, '' from dbo.bPRFI with (nolock) where PRCo = @prco
        union
        select Code=FUTALiab, 'C' from dbo.bPRFI with (nolock) where PRCo = @prco
        union
        select Code=MiscFedDL1, 'E' from dbo.bPRFI with (nolock) where PRCo = @prco
        union
        select Code=MiscFedDL2, '' from dbo.bPRFI with (nolock) where PRCo = @prco
        union
        select Code=MiscFedDL3, '' from dbo.bPRFI with (nolock) where PRCo = @prco
        union
        select Code=DLCode, '' from dbo.bPRFD with (nolock) where PRCo = @prco
		order by Code

    open bcFedDL
    select @openFedDL = 1
   
    -- loop through Federal DL cursor
    next_FedDL:
    	fetch next from bcFedDL into @dlcode, @FedDednType
    	if @@fetch_status = -1 goto end_FedDL
    	if @@fetch_status <> 0 goto next_FedDL

		-- null dlcode indicates a setup problem in PRFed
		if @dlcode is null
			begin
			select @errmsg = 'Dedn/liab code(s) missing from Federal setup!', @rcode = 1
			goto bspexit
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
            @overlimit = 'N', @addontype = 'N', @addonrateamt = 0.00, @K3 = 0.00,@TC = NULL
    	select @filestatus = FileStatus, @regexempts = RegExempts, @empvendor = Vendor, @apdesc = APDesc,
    		@overcalcs = OverCalcs, @emprateamt = isnull(RateAmt,0.00), @overlimit = OverLimit,
    		@emplimit = isnull(Limit,0.00), @addontype = AddonType, @addonrateamt = isnull(AddonRateAmt,0.00),
   			@empllimitrate = isnull(LimitRate,0.00), /*issue 11030*/
			@K3 = isnull(MiscAmt,0.00), @TC = MiscAmt2
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
            @posttoall, @dlcode, @dltype, @stddays, NULL, NULL, @calcbasis output, @accumbasis output,
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
        IF @method IN ('D', 'F', 'G', 'H', 'S', 'DN')
			BEGIN
				-- When computing EI, make sure that calculated amount limit is always used even when expressed in dedn setup 
				--  as a subject amount limit.  Then adjust the resulting eligible amount when limit is reached to account
				--  for rounding error if any.
				IF @FedDednType = 'E' AND @limitbasis = 'S' SELECT @limitbasis = 'C', @limitamt = @limitamt * @rate

				EXEC @rcode = bspPRProcessRateBased @calcbasis,		@rate,			@limitbasis,	@limitamt, 
													@ytdcorrect,	@limitcorrect,	@accumelig,		@accumsubj, 
													@accumamt,		@ytdelig,		@ytdamt,		@accumbasis, 
													@limitrate, 
													@outaccumbasis output, --issue 11030 adjust for changes in bspPRProcessRateBased
													@calcamt=@calcamt output, 
													@eligamt=@eligamt output, 
													@errmsg=@errmsg output
				IF @rcode<> 0 GOTO bspexit
   				SELECT @accumbasis = @outaccumbasis --issue 11030 basis may be adjusted to fit rate of earnings limit scheme

				-- Adjust EI deduction when limit is reached (@calcbasis <> @eligamt) and total annual eligible <> annual subject amount limit
				IF @FedDednType = 'E' AND @calcbasis <> @eligamt AND @accumelig + @eligamt <> (@limitamt / @rate)
				BEGIN
					SELECT @eligamt = @eligamt + ((@limitamt / @rate) - (@accumelig + @eligamt))
				END
    		END
   
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
   
			-- Canada Pension Plan routine
			if @procname = 'bspPRCPP'
				begin
				select @annualaccumamt = @accumamt --#135627 save annual accum amt for applying limit to calcamt

   				exec @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
   				  @dlcode, @dltype, 'P', @limitmth, 'N', @accumamt output, @accumsubj = @ppdaccumsubj output, 
				  @accumelig = @ppdaccumelig output, @ytdamt = @ytdamt output, @ytdelig = @ytdelig output,
				  @errmsg = @errmsg output
   				if @rcode <> 0 goto bspexit

   				select @exemptamt = MiscAmt1 from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = @routine

				exec @rcode = @procname @prco, @employee, @prenddate, @calcbasis, @ppds, @rate, @exemptamt, @ppdaccumsubj, @ppdaccumelig, @calcamt output, @eligamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				if @@error <> 0 select @rcode = 1
    				if @rcode <> 0 goto bspexit
		   
   				select @calcbasis = @eligamt

				goto routine_end
				end

			-- Federal tax routine
			-- #141669 as of version 2011 of federal tax routine we are passing in @nonresalienyn so that the
			--			routine can determine the default total claim amount (@TC)
			IF @procname < 'bspPR_CA_FWT11'
			BEGIN
				-- #133697 if form TD1 was not filed (ie. no filing status entered) use default total claim
				--IF @TC is null SELECT @TC = 10382 --10375 --#140613 corrected TC default as addition to this issue
				--IF @nonresalienyn = 'Y' SELECT @TC = 0

				EXEC @rcode = @procname @ppds, @calcbasis, @HD, @F1, @TC, @province, @PP, @maxCPP, @EI, @maxEI, @IE, 
					@K3, @capstock, @A OUTPUT, @calcamt OUTPUT, @errmsg OUTPUT
			END
			ELSE
			BEGIN
				EXEC @rcode = @procname @ppds, @calcbasis, @HD, @F1, @TC, @province, @PP, @maxCPP, @EI, @maxEI, @IE, 
					@K3, @capstock, @nonresalienyn, @A OUTPUT, @calcamt OUTPUT, @errmsg OUTPUT
			END

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
 
		/**** Set CPP and EI info needed for passing into federal and provincial tax routines ****/

		-- store CPP stats
		IF @FedDednType = 'C'
		BEGIN
		    -- store CPP info prior to applying the limit because if limit is reached @PP may need to be adjusted
		    SELECT @PP = (@calcamt * @ppds) --annualized CPP
			SELECT @maxCPP = @limitamt --annual CPP limit

			-- #135627 apply limit to calculated amount
			IF @limitamt < (@annualaccumamt + @calcamt)
				BEGIN
					SELECT @calcamt = (@limitamt - @annualaccumamt), @eligamt = (@calcamt / @rate)
					IF @limitcorrect = 'N' AND @calcamt < 0.00 SELECT @calcamt = 0.00
					IF (@calcamt * @ppds) < @maxCPP SELECT @PP = @maxCPP --#140613 when limit reached, if annualized CPP < max CPP, use max
				END

			IF @calcamt = 0.00 SELECT @eligamt = 0.00
		END

	   -- store EI stats
	   IF @FedDednType = 'E'
		   BEGIN
			   SELECT @EI = (@calcamt * @ppds) --annualized EI contribution
			   SELECT @maxEI = @limitamt --annual EI contribution limit
			   SELECT @IE = @eligamt
			   --#140613 When EI limit has been reached in this or an earlier pay pd, if annualized EI < max EI, pass max EI to tax routines.
			   --		 This will cause EI credit to continue to be spread out throughout the year.
			   IF @limitamt = (@calcamt + @accumamt) AND (@calcamt * @ppds) < @maxEI
			   BEGIN
					SELECT @EI = @maxEI
			   END
		   END

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
GRANT EXECUTE ON  [dbo].[bspPRProcessFedCA] TO [public]
GO
