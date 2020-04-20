SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[bspPRProcessLocal]
/***********************************************************
*CREATED:  GG  03/16/98
*MODIFIED: GG  04/09/99
*          LM 06/15/99  - Added username column in PRPE for SQL 7.0
*		   	GH  06/17/99 Changed so that routine handles bspPRNYD98
*          GG 07/06/99 - Added routine procedure check
*          GG 07/08/99 - removed call to Ohio School District tax - moved to bspPRProcessEmpl
*          GG 01/06/00 - fixed AP Vendor info update to bPRDT
*          GG 03/24/00 - removed call to bspPRNYD## - moved to bspPRProcessState
*          DANF 08/17/00 - removed reference to system user id
*          GG 01/30/01 - skip calculations for both dedns and liabs if calculation basis = 0 (#11690)
*          EN 3/20/01 - issue 12748 - pass addl exemptions to Indiana County tax routine
*          GG 03/23/01 - default Fed Tax filing status and exemptions (#12689)
*          EN 4/2/01 - if addition exemption is null, default it to 0 (#12748)
*			MV 1/28/02 - issue 15711 - check for correct CalcCategory
*			    - issue 13977 - round @calcamt if RndToDollar flag is set. 
*			EN issue 16832 - handle Philadelphia tax
*			GG 07/19/02 - #16595 - post diff to resident local tax	
*			EN 10/9/02 - issue 18877 change double quotes to single
*			EN 3/24/03 - issue 11030 rate of earnings liability limit
*			EN 6/20/03 - issue 20356  elig amount returned by bspPRCOO to write to bPRDT
*			EN 11/03/03 - issue 21216 do not include subject or eligible when post resident local tax difference
*			GG 02/10/04 - #23655 fix to dist liab override amt when calc basis = 0.00
*			EN 7/28/04 - issue 24545  call new routine bspPRExemptRateOfGross
*			EN 9/24/04 - issue 20562  change from using bPRCO_LiabDist to bPREC_IncldLiabDist to determine whether an earnings code is included in liab distribs
*			EN 4/8/05 - issue 28379  added @@error check to see if SQL error occured when routine was called
*			EN 9/05/06 - issue 122062  added call to new Kenton county Kentucky tax routine bspPRKentonKYC06
*			EN 10/7/2009 #135774  ResCalc feature for local not working as of 6.2.0
*			KK/EN 10/18/2011 TK-09086 #144794 PR Pennsylvania Act 32 via new combobox CalcOpt (KK client-requested re-do 12/4/11)
*			KK 12/28/2011 - TK-11285 #145365 Revision to update Subject and eligible for new PA Act 32 feature
*			GG 12/30/2011 - #145382 - PA Act 32 cleanup - add ProcessSeq and suppress 0 PRDT entries
*			EN 1/12/2012 - TK11705/#145508 PR - Rate for local dedns incorrectly overridden by PR Emp Dedn
*			KK 1/12/2012 - TK-11718/#145463 - Always calculating for resident option 1. Modify Union clause
*			EN 2/21/2013 #148019 For Indiana/Kentucky reciprocity resolution, need to pass the employee's resident city to the Indiana county tax routine
*
*
* USAGE:
* Calculates Local deductions and liabilities for a SELECT Employee and Pay Seq.
* Called from main bspPRProcess procedure.
* Will calculate most dedn/liab methods
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
*   @fedtax    Federal Income Tax - used by some routines
*   @fedbasis  Earnings subject to Federal Income Tax
*
* OUTPUT PARAMETERS
*   @errmsg  	Error message if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(	@prco bCompany,		@prgroup bGroup, 
	@prenddate bDate,	@employee bEmployee, 
	@payseq tinyint,	@ppds tinyint, 
	@limitmth bMonth,	@stddays tinyint, 
	@bonus bYN,			@posttoall bYN, 
	@fedtax bDollar,	@fedbasis bDollar, 
	@errmsg varchar(255) output
)

AS
SET NOCOUNT ON

DECLARE @rcode int,				@reslocal bLocalCode,	
		@localtaxdedn bEDLCode,	@res char(1), 
		@local bLocalCode,		@rate bUnitCost, 
		@calcamt bDollar,		@procname varchar(30), 
		@eligamt bDollar,		@amt2dist bDollar,
		@accumelig bDollar,		@accumsubj bDollar, 
		@accumamt bDollar,		@ytdelig bDollar, 
		@ytdamt bDollar,		@calcbasis bDollar, 
		@accumbasis bDollar,	@liabbasis bDollar, 
		@miscamt bDollar,		@overmiscamt bYN, 
		@empmiscamt bDollar,	@fedtaxdedn bEDLCode, 
		@fedfilestatus char(1),	@fedexempts tinyint, 
		@restaxdedn bEDLCode,	@localtaxamt bDollar, 
		@openLocal tinyint,		@openLocalDL tinyint, 
		@calcopt tinyint, 		@exemptamt bDollar,
		@rescalopt TINYINT,		@processseq tinyint,	
		@resstate bState		

-- Standard deduction/liability variables
DECLARE @dlcode bEDLCode,		@dldesc bDesc,				@dltype char(1), 
		@method varchar(10),	@routine varchar(10),		@rate1 bUnitCost, 
		@rate2 bUnitCost,		@seq1only bYN,				@ytdcorrect bYN, 
		@bonusover bYN,			@bonusrate bRate,			@limitbasis char(1), 
		@limitamt bDollar,		@limitperiod char(1),		@limitcorrect bYN,
		@autoAP bYN,			@vendorgroup bGroup,		@vendor bVendor, 
		@apdesc bDesc,			@calccategory varchar(1),	@rndtodollar bYN,
		@limitrate bRate,		@empllimitrate bRate,		@outaccumbasis bDollar

-- Employee deduction/liability override variables
DECLARE @filestatus char(1),	@regexempts tinyint, 
		@miscfactor bRate,		@overcalcs char(1), 
		@emprateamt bUnitCost,	@overlimit bYN, 
		@emplimit bDollar,		@addontype char(1), 
		@addonrateamt bDollar,	@empvendor bVendor,
		@addexempts tinyint

-- Payment Sequence Total variables
DECLARE @dtvendorgroup bGroup,	
		@dtvendor bVendor, 
		@dtAPdesc bDesc, 
		@useover bYN, 
		@overprocess bYN,
		@overamt bDollar

-- issue 122062 declarations for Kenton County, KY tax routine
DECLARE @krate1 bUnitCost, 
		@krate2 bUnitCost, 
		@limitamt1 bDollar, 
		@limitamt2 bDollar

SELECT @rcode = 0

-- get Fed Tax and Filing Status for defaults
SELECT @fedfilestatus = 'S', @fedexempts = 0

SELECT @fedtaxdedn = TaxDedn
FROM  dbo.bPRFI WITH (NOLOCK) 
WHERE PRCo = @prco  -- already validated

SELECT @fedfilestatus = FileStatus, @fedexempts = RegExempts
FROM  dbo.bPRED WITH (NOLOCK)
WHERE PRCo = @prco AND Employee = @employee AND DLCode = @fedtaxdedn

-- get Employee's Resident Local code info
SELECT @reslocal = LocalCode, 
	   @resstate = TaxState
FROM  dbo.bPREH WITH (NOLOCK)
WHERE PRCo = @prco AND Employee = @employee
IF @@rowcount = 0
BEGIN
	SELECT @errmsg = 'Missing Employee header entry!', @rcode = 1
	GOTO bspexit
END

-- get resident Local Tax and calculation option
SELECT @restaxdedn = NULL

SELECT @restaxdedn = TaxDedn
FROM  dbo.bPRLI WITH (NOLOCK)
WHERE PRCo = @prco AND 
      LocalCode = @reslocal


-- create cursor for all posted Local Codes
DECLARE bcLocal cursor for
SELECT DISTINCT LocalCode
FROM dbo.bPRTH WITH (NOLOCK)
WHERE PRCo = @prco AND 
	  PRGroup = @prgroup AND 
	  PREndDate = @prenddate AND 
	  Employee = @employee AND 
	  PaySeq = @payseq

OPEN bcLocal
SELECT @openLocal = 1

-- Local Codes loop Begin
next_Local:
FETCH NEXT FROM bcLocal INTO @local
 	IF @@fetch_status = -1 GOTO end_Local
 	IF @@fetch_status <> 0 GOTO next_Local
 	
 	-- check for residency - controls rates
 	SELECT @res = 'N'
 	IF @local = @reslocal 
 	BEGIN
 		SELECT @res = 'Y'
 	END
 	
 	-- reset variables with each Local
 	SELECT @calcopt = 0, @localtaxdedn = NULL, @localtaxamt = 0
 	
 	-- get calculation option for posted local code	
 	SELECT @calcopt = CalcOpt
 	FROM dbo.bPRLI WITH (NOLOCK) 
 	WHERE PRCo = @prco AND LocalCode = @local
 
	-- clear Process Earnings
	DELETE dbo.bPRPE WHERE VPUserName = SUSER_SNAME()

	--load with earnings posted to this Local
	INSERT dbo.bPRPE (VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt) -- Timecards #20562
		SELECT SUSER_SNAME(), t.PostSeq, t.PostDate, t.EarnCode, e.Factor, e.IncldLiabDist, t.Hours, t.Rate,t.Amt --#20562
		FROM dbo.bPRTH t
		JOIN dbo.bPREC e WITH (NOLOCK) ON e.PRCo = t.PRCo AND e.EarnCode = t.EarnCode
		WHERE t.PRCo = @prco  
		  AND t.PRGroup = @prgroup 
		  AND t.PREndDate = @prenddate 
		  AND t.Employee = @employee 
		  AND t.PaySeq = @payseq 
		  AND ISNULL(t.LocalCode,'') = ISNULL(@local,'')
	INSERT dbo.bPRPE (VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt) -- Addons #20562
		SELECT SUSER_SNAME(), t.PostSeq, t.PostDate, a.EarnCode, e.Factor, e.IncldLiabDist, 0, a.Rate, a.Amt --#20562
		FROM dbo.bPRTA a
		JOIN dbo.bPRTH t ON t.PRCo = a.PRCo 
						AND t.PRGroup = a.PRGroup 
						AND t.PREndDate = a.PREndDate 
						AND	t.Employee = a.Employee 
						AND t.PaySeq = a.PaySeq 
						AND t.PostSeq = a.PostSeq
		JOIN dbo.bPREC e WITH (NOLOCK) ON e.PRCo = a.PRCo AND e.EarnCode = a.EarnCode
		WHERE a.PRCo = @prco 
		  AND a.PRGroup = @prgroup 
		  AND a.PREndDate = @prenddate 
		  AND a.Employee = @employee 
		  AND a.PaySeq = @payseq 
		  AND ISNULL(t.LocalCode,'') = ISNULL(@local,'')
  
	-- create cursor for Local DLs - processing seq, calculation option, DL code and resident flag - include Resident tax dedn if needed
	-- calculation options:
	--			0 = posted local only
	--			1 = both posted and resident local
	--			2 = posted local with difference to resident local when greater
	--			3 = posted local using resident rate/amount when greater (PA Act 32)
	--
	DECLARE bcLocalDL CURSOR FOR
	SELECT 0 AS ProcessSeq, @calcopt AS CalcOpt, TaxDedn, @res  -- use calculation option from posted local on tax dedn
	FROM dbo.bPRLI WITH (NOLOCK) 
	WHERE PRCo = @prco AND LocalCode = @local AND TaxDedn IS NOT NULL
	UNION
	SELECT 1 AS ProcessSeq, 0 AS CalcOpt, DLCode, @res	-- set calculation option to 0 for add'l dedns based on posted local 
	FROM dbo.bPRLD WITH (NOLOCK) 
	WHERE PRCo = @prco AND LocalCode = @local
	UNION 
	-- add resident local tax dedn if different than posted local when posted local calc option 1, 2, or 3
	SELECT 2 AS ProcessSeq, @calcopt AS CalcOpt, TaxDedn, 'Y'
	FROM dbo.bPRLI with (nolock)
	WHERE PRCo = @prco AND LocalCode = @reslocal
		  AND ISNULL(LocalCode,'') <> ISNULL(@local,'') 
		  AND TaxDedn IS NOT NULL 
		  AND ((@local IS NOT NULL AND @calcopt > 0) OR @local IS NULL)	-- TK-11718 /#145463 
	ORDER BY ProcessSeq 

	
	-- open cursor to loop through all DLs 
	OPEN bcLocalDL
	SELECT @openLocalDL = 1
    
    next_LocalDL: -- loop through Local DL cursor
		FETCH NEXT FROM bcLocalDL INTO @processseq, @calcopt, @dlcode, @res 
			IF @@fetch_status = -1 GOTO end_LocalDL
			IF @@fetch_status <> 0 GOTO next_LocalDL
			
		-- get standard DL info
		SELECT @dldesc = Description,		@dltype = DLType,			@method = Method, 
			   @routine = Routine,			@rate1 = RateAmt1,			@rate2 = RateAmt2, 
			   @seq1only = SeqOneOnly,		@ytdcorrect = YTDCorrect,	@bonusover = BonusOverride,
               @bonusrate = BonusRate,		@limitbasis = LimitBasis,	@limitamt = LimitAmt, 
               @limitperiod = LimitPeriod,	@autoAP = AutoAP,			@limitcorrect = LimitCorrect, 
               @vendorgroup = VendorGroup,	@vendor = Vendor, 			@calccategory = CalcCategory, 
               @rndtodollar = RndToDollar,	@limitrate = LimitRate --#11030
		FROM dbo.bPRDL WITH (NOLOCK)
		WHERE PRCo = @prco AND DLCode = @dlcode
    	
    	IF @@rowcount = 0
        BEGIN
   			SELECT @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' not setup!', @rcode = 1
   		    GOTO bspexit
   		END
  
		/* validate calccategory*/
		IF @calccategory NOT IN ('L','A')
		BEGIN
			SELECT @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' should be calculation category L or A!', 
				   @rcode = 1
			GOTO bspexit
		END
	  
		-- check for Payment Sequence #1 restriction
		IF @seq1only = 'Y' AND @payseq <> 1 goto next_LocalDL

		SELECT @rate = @rate2  -- non-resident rate
		IF @res = 'Y' OR @dlcode = @restaxdedn 
		BEGIN
			SELECT @rate = @rate1  -- resident rate
		END
		
		-- get Employee info and overrides for this dedn/liab
		SELECT @filestatus = @fedfilestatus,	@regexempts = @fedexempts,	@overmiscamt = 'N', 
			   @empmiscamt = 0.00,				@miscfactor = 0.00,			@empvendor = NULL, 
			   @apdesc = NULL,					@overcalcs = 'N',			@overlimit = 'N',
			   @addontype = 'N'
		-- #145508     
		SELECT @filestatus = FileStatus,		@regexempts = RegExempts, 
			   @overmiscamt = OverMiscAmt,		@empmiscamt = MiscAmt,		@miscfactor = MiscFactor, 
			   @empvendor = Vendor,				@apdesc = APDesc,			@overcalcs = OverCalcs,
			   @overlimit = OverLimit,			@emprateamt = ISNULL(RateAmt,0.00), 
			   @addontype = AddonType,			@emplimit = ISNULL(Limit,0.00),	
			   @addexempts = AddExempts,		@addonrateamt = ISNULL(AddonRateAmt,0.00), 
 			   @empllimitrate = ISNULL(LimitRate,0.00) /*issue 11030*/
 		FROM dbo.bPRED WITH (NOLOCK)
		WHERE PRCo = @prco AND Employee = @employee AND DLCode = @dlcode
	  
   		IF @regexempts IS NULL SELECT @regexempts = 0
   		IF @addexempts IS NULL SELECT @addexempts = 0
		-- check for calculation override on Bonus sequence
		IF @bonus = 'Y' AND @bonusover = 'Y' 
		BEGIN
			SELECT @method = 'G', @rate = @bonusrate
		END
		-- check for Employee calculation and rate overrides
		IF @overcalcs = 'M' SELECT @method = 'G', @rate = @emprateamt
		IF @overcalcs = 'R' SELECT @rate = @emprateamt
		IF @overlimit = 'Y' SELECT @limitamt = @emplimit
		IF @overlimit = 'Y' SELECT @limitrate = @empllimitrate /*issue 11030*/
  
		-- get calculation, accumulation, and liability distribution basis
		EXEC @rcode = bspPRProcessGetBasis @prco, @prgroup, @prenddate, @employee, @payseq, 
									       @method, @posttoall, @dlcode, @dltype, @stddays, 
									       @calcbasis OUTPUT, @accumbasis OUTPUT, --issue 20562
										   @liabbasis OUTPUT, @errmsg OUTPUT
		IF @rcode <> 0 GOTO bspexit

		-- check for 0 basis - skip accumulations and calculations
		IF @calcbasis = 0.00
		BEGIN
			SELECT @calcamt = 0.00, @eligamt = 0.00
			GOTO calc_end
		END
  
		-- accumulate actual, subject, and eligible amounts if needed
		IF @limitbasis = 'C' OR @limitbasis = 'S' OR @ytdcorrect = 'Y'
		BEGIN
			EXEC @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
											    @dlcode, @dltype, @limitperiod, @limitmth, @ytdcorrect, 
											    @accumamt OUTPUT, @accumsubj OUTPUT, @accumelig OUTPUT, 
											    @ytdamt OUTPUT, @ytdelig OUTPUT, @errmsg OUTPUT
			IF @rcode <> 0 GOTO bspexit
		END
  
		-- Calculations
		SELECT @calcamt = 0.00, @eligamt = 0.00

		-- Flat Amount
		IF @method = 'A'
		BEGIN
			EXEC @rcode = bspPRProcessAmount @calcbasis, @rate, @limitbasis, @limitamt, @limitcorrect, 
											 @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt, 
											 @calcamt OUTPUT, @eligamt OUTPUT, @errmsg OUTPUT
			IF @rcode<> 0 GOTO bspexit
		END
  
   	    -- Rate per Day, Factored Rate per Hour, Rate of Gross, Rate per Hour, Straight Time Equivalent, or Rate of Dedn
        IF @method in ('D','F','G','H','S','DN')
   		BEGIN --#11030 adjust for changes in bspPRProcessRateBased
			EXEC @rcode = bspPRProcessRateBased @calcbasis, @rate, @limitbasis, @limitamt, @ytdcorrect,
											    @limitcorrect, @accumelig, @accumsubj, @accumamt, 
											    @ytdelig, @ytdamt, @accumbasis, @limitrate, 
											    @outaccumbasis OUTPUT, @calcamt=@calcamt OUTPUT, 
											    @eligamt=@eligamt OUTPUT, @errmsg=@errmsg OUTPUT
   			IF @rcode<> 0 GOTO bspexit
 		    SELECT @accumbasis = @outaccumbasis --issue 11030 basis may be adjusted to fit rate of earnings limit scheme
		END
  
   	    -- Routine BEGIN (Method R)
   	    if @method = 'R'
   		begin
			-- get procedure name
			SELECT @procname = null
			SELECT @procname = ProcName, @miscamt = MiscAmt1
   		    from dbo.bPRRM with (NOLOCK)
   		    where PRCo = @prco and Routine = @routine
  
   			if @procname is null
   			begin
   				SELECT @errmsg = 'Missing Routine procedure name for dedn/liab ' + convert(varchar(6),@dlcode), @rcode = 1
   				goto bspexit
   			end
            if not exists(SELECT * from sysobjects where name = @procname and type = 'P')
            begin
                SELECT @errmsg = 'Invalid Routine procedure - ' + @procname, @rcode = 1
                goto bspexit
            end
			if @overmiscamt = 'Y' SELECT @miscamt = @empmiscamt	-- use Employee override
			if @procname like 'bspPRCOO%'	-- Colorado Occupational Tax
   		  	begin
    			exec @rcode = @procname @prco, @dlcode, @prgroup, @prenddate, @employee, @calcbasis, @calcamt output, @eligamt output, @errmsg output --issue 20356 return @eligamt
 				-- please put no code between exec and @@error check!
 				if @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
 				SELECT @calcbasis = @eligamt --issue 20356 use eligamt returned by routine in place of calcbasis
   		  		goto routine_end
   		  	end

   		    IF @procname LIKE 'bspPRINC%'	-- Indiana County Tax
   		  	BEGIN
   		  		IF @procname > 'bspPRINC982'
				BEGIN
					-- this call applies to version bspPRINC983 and later which requires @resstate input param
   		  			EXEC @rcode = @procname		@calcbasis,		@ppds,	@regexempts, 
   		  										@addexempts,	@rate,	@resstate, 
   		  										@calcamt output, @errmsg output
				END
				ELSE
				BEGIN
   		  			EXEC @rcode = @procname		@calcbasis,		@ppds,	@regexempts, 
   		  										@addexempts,	@rate,
   		  										@calcamt output, @errmsg output
   		  		END
				-- please put no code between exec and @@error check!
				IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
	  			GOTO routine_end
   		  	END

   			if @procname like 'bspPRMIC%'	-- Michigan Uniform City Tax
   		  	begin
   		  		exec @rcode = @procname @calcbasis, @ppds, @miscamt, @regexempts, @rate, @calcamt output, @errmsg output
 				-- please put no code between exec and @@error check!
 				if @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
   		  		goto routine_end
   		  	end
   		    if @procname like 'bspPRNYC%'	-- New York City Tax
   		  	begin
   		  		exec @rcode = @procname @calcbasis, @ppds, @filestatus, @regexempts, @res, @calcamt output, @errmsg output
 				-- please put no code between exec and @@error check!
 				if @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
   		  		goto routine_end
   		  	end
   		    /*if @procname like 'bspPRNYD%'        -- New York Disability Tax
   			begin
   				exec @rcode = @procname @prco,@calcbasis, @rate1, @rate2, @employee, @calcamt output, @errmsg output
   				goto routine_end
   			end*/    -- moved to bspPRProcessState
   		    if @procname like 'bspPRNYY%'	-- Yonkers City Tax
   		  	begin
   		  		exec @rcode = @procname @calcbasis, @ppds, @filestatus, @regexempts, @res, @calcamt output, @errmsg output
 				-- please put no code between exec and @@error check!
 				if @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
   		  		goto routine_end
   		  	end
  
  		    if @procname like 'bspPRPHC%'	-- Philadelphia City Tax
  			begin
  				exec @rcode = @procname @calcbasis, @rate, @limitbasis, @limitamt, @ytdcorrect,
  			         @limitcorrect, @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt,
  					 @prco, @prgroup, @prenddate, @employee, @payseq, @calcamt output,
  					 @eligamt output, @errmsg output
 				-- please put no code between exec and @@error check!
 				if @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
  				goto routine_end
  			end
 
 			--#24545
 			if @procname = 'bspPRExemptRateOfGross'   -- rate of gross with exemption ... tax calculation withheld until subject amount reaches exemption limit
 			begin
 				exec @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
 			  		 @dlcode, @dltype, 'A', @limitmth, 'N', @accumamt output,
 			  		 @accumsubj output, @accumelig output, @ytdamt output, @ytdelig output, @errmsg output
 				if @rcode <> 0 goto bspexit
 
 				SELECT @exemptamt = MiscAmt1 from dbo.bPRRM with (NOLOCK) where PRCo = @prco and Routine = @routine
 
  		  		exec @rcode = @procname @calcbasis, @rate, @accumsubj, @accumelig, @exemptamt, @calcamt output, @eligamt output, @errmsg output
 				-- please put no code between exec and @@error check!
 				if @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
 				SELECT @calcbasis = @eligamt
  		  		goto routine_end
  			end
  
			--#122062
			if @procname like 'bspPRKentonKYC0%'	-- Kenton County Kentucky Tax
			begin
				--get tax rates
				SELECT @krate1 = RateAmt1, @krate2 = RateAmt2 from dbo.bPRDL with (NOLOCK) where PRCo = @prco and DLCode = @dlcode
    			if @@rowcount = 0
				begin
   					SELECT @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' not setup for Kenton County tax routine!', @rcode = 1
   					goto bspexit
				end
				--get accumsubj to pass into tax routine
 				exec @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
 			  		 @dlcode, @dltype, 'A', @limitmth, 'N', @accumamt output,
 			  		 @accumsubj output, @accumelig output, @ytdamt output, @ytdelig output, @errmsg output
 				if @rcode <> 0 goto bspexit
				--get limit amts for tax routine
	   			SELECT @limitamt1 = MiscAmt1, @limitamt2 = MiscAmt2
				from dbo.bPRRM with (NOLOCK) 
				where PRCo = @prco and Routine = @routine
				if @limitamt1 is null or @limitamt2 is null
				begin
	   				SELECT @errmsg = 'Kenton County tax computation requires limit setup in Misc Amt #1 and #2 fields of PR Routine Master  ', @rcode = 1
   					goto bspexit
				end
				--compute tax
				exec @rcode = @procname @calcbasis, @krate1, @krate2, @accumsubj, @limitamt1, @limitamt2, @calcamt output, @eligamt output, @errmsg output
				SELECT @calcbasis = @eligamt
				goto routine_end
			end

   			-- default - put calls to other Local/City routines before this one
   			exec @rcode = @procname @calcbasis, @ppds, @filestatus, @regexempts, @calcamt output, @errmsg output
 			-- please put no code between exec and @@error check!
 			if @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
  
   	routine_end: 
   			if @rcode <> 0 goto bspexit
   			if @calcamt is null SELECT @calcamt = 0.00
			SELECT @eligamt = @calcbasis
			
   	end -- Routine END (Method R)
  
   -- apply Employee calculation override
    if @overcalcs = 'A' SELECT @calcamt = @emprateamt

    -- apply Employee addon amounts - only applied if calculated amount is positive
    if @calcamt > 0.00
		begin
			if @addontype = 'A' SELECT @calcamt = @calcamt + @addonrateamt
			if @addontype = 'R' SELECT @calcamt = @calcamt + (@calcbasis * @addonrateamt)
		END
		
	---------------------------------
	-- when calculation option is 2 or 3 save posted local tax dedn and amount for comparison with resident local tax
	IF @calcopt IN (2,3) AND @dlcode <> @restaxdedn
		BEGIN
			SELECT @localtaxdedn = @dlcode, @localtaxamt = @calcamt	
		END
	   
	-- when calculation option is 2 post difference to resident local if greater
	IF @calcopt = 2 AND @dlcode = @restaxdedn AND @localtaxdedn IS NOT NULL	
		BEGIN
			IF @calcamt <= @localtaxamt SELECT @calcamt = 0.00
			IF @calcamt > @localtaxamt SELECT @calcamt = @calcamt - @localtaxamt
			select @accumbasis = 0, @eligamt = 0	-- don't accumulate subject and eligible on local tax when posting difference
		END
		
	-- when calculation option is 3 compare posted local to resident local and use greater amount
	IF @calcopt = 3 AND @dlcode = @restaxdedn AND @localtaxdedn IS NOT NULL	
		BEGIN
			IF @calcamt > @localtaxamt	-- resident local is greater than posted local
				BEGIN
				SELECT @calcamt = (@calcamt - @localtaxamt) 
				if @rndtodollar='Y'	SELECT @calcamt = ROUND(@calcamt,0) --round to the nearest dollar
		
				-- update existing deduction entry for posted local tax
				UPDATE dbo.bPRDT
				SET Amount = Amount + @calcamt
				WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate AND Employee = @employee
   					  AND PaySeq = @payseq AND EDLType = @dltype AND EDLCode = @localtaxdedn
   				IF @@rowcount = 0
   					BEGIN
   						SELECT @errmsg = 'Unable to update Local tax deduction in PR Detail Entry for Employee ' + convert(varchar(6),@employee), @rcode = 1
   						GOTO bspexit
   					END
   				GOTO OverrideCheck	-- skip to override check
   				END
   			ELSE
   				BEGIN
   					SELECT @calcamt = 0, @accumbasis = 0, @eligamt = 0 -- don't accumulate resident tax when less than posted local
   				END	
		END	

 			
	if @rndtodollar='Y'	SELECT @calcamt = ROUND(@calcamt,0) --round to the nearest dollar
  
  --------------------------------------
   	calc_end:	 -- Finished with calculations
   	    -- get AP Vendor and Transaction description
   	    SELECT @dtvendorgroup = NULL, @dtvendor = NULL, @dtAPdesc = NULL
   	    IF @autoAP = 'Y'
   		BEGIN
   			SELECT @dtvendorgroup = @vendorgroup, @dtvendor = @vendor, @dtAPdesc = @dldesc
   			IF @empvendor IS NOT NULL SELECT @dtvendor = @empvendor
   			IF @apdesc IS NOT NULL SELECT @dtAPdesc = @apdesc
   		END
   					
   	    -- update Payment Sequence Totals
   	    IF @calcamt <> 0 OR @accumbasis <> 0 OR @eligamt <> 0	--- suppress 0 entries
   			BEGIN
				UPDATE dbo.bPRDT
				SET Amount = Amount + @calcamt, 
					SubjectAmt = SubjectAmt + @accumbasis, 
					EligibleAmt = EligibleAmt + @eligamt,
      				VendorGroup = @dtvendorgroup, 
      				Vendor = @dtvendor, 
      				APDesc = @dtAPdesc
				WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate AND Employee = @employee
						AND PaySeq = @payseq AND EDLType = @dltype AND EDLCode = @dlcode
				IF @@rowcount = 0
					BEGIN
						INSERT dbo.bPRDT (PRCo, PRGroup, PREndDate, Employee, PaySeq, EDLType, EDLCode, Hours, Amount, SubjectAmt, 
										  EligibleAmt,UseOver, OverAmt, OverProcess, VendorGroup, Vendor, APDesc, OldHours, OldAmt, 
										  OldSubject, OldEligible, OldMth,OldVendor, OldAPMth, OldAPAmt)
						VALUES (@prco, @prgroup, @prenddate, @employee, @payseq, @dltype, @dlcode, 0, @calcamt, @accumbasis, @eligamt,
								'N', 0, 'N', @dtvendorgroup, @dtvendor, @dtAPdesc, 0, 0, 0, 0, null, null, null, 0)
						IF @@rowcount <> 1
						BEGIN
							SELECT @errmsg = 'Unable to add PR Detail Entry for Employee ' + convert(varchar(6),@employee), @rcode = 1
							GOTO bspexit
						END
					END
				END
  
  OverrideCheck:
        -- check for Override processing
        SELECT @useover = UseOver, @overamt = OverAmt, @overprocess = OverProcess
        from dbo.bPRDT with (NOLOCK)
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
   		  and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
  
        if @overprocess = 'Y' goto next_LocalDL
  
        -- an overridden DL amount is processed only once
        if @useover = 'Y'
   		begin
   			update dbo.bPRDT
			set OverProcess = 'Y' 
			where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
              and Employee = @employee and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
   		end
  
        -- check for Liability distribution - needed even if basis and/or amount are 0.00
        if @dltype <> 'L' goto next_LocalDL
  
        -- use calculated amount unless overridden
   		SELECT @amt2dist = @calcamt
 		-- #23655 fix to use override amt even if calc basis = 0
   		if @useover = 'Y' /*and @calcbasis <> 0.00*/ SELECT @amt2dist = @overamt
  
   		-- no need to distribute if Basis <> 0 and Amt = 0, but will distibute if both are 0.00
        -- because of possible offsetting timecard entries
        if @calcbasis <> 0.00 and @amt2dist = 0.00 goto next_LocalDL
  
        -- call procedure to distribute liability amount
        exec @rcode = bspPRProcessLiabDist @prco, @prgroup, @prenddate, @employee, @payseq, @dlcode,
             @method, @rate, @liabbasis, @amt2dist, @posttoall, @errmsg output --issue 20562
        if @rcode <> 0 goto bspexit
  
	goto next_LocalDL

-- LocalDL loop End  
end_LocalDL:
	close bcLocalDL 
	deallocate bcLocalDL
	SELECT @openLocalDL = 0
	goto next_Local
	
-- Local loop End
end_Local:
	close bcLocal
	deallocate bcLocal
	SELECT @openLocal = 0
  
bspexit:
	-- clear Process Earnings
	delete dbo.bPRPE where VPUserName = SUSER_SNAME()

	if @openLocalDL = 1
	begin
		close bcLocalDL
		deallocate bcLocalDL
	end
	if @openLocal = 1
	begin
		close bcLocal
		deallocate bcLocal
	end
return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRProcessLocal] TO [public]
GO
