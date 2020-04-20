SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRProcessProvinceCA]
/***********************************************************
* CREATED BY:	EN 3/28/08  #127015  added for Canada
* MODIFIED BY:	EN 5/15/09 #133697  default total claim passed to tax routines to null if filing status not set up
*				EN #137138  pass @capstock parameter to Northwest Territories tax routine (bspPR_CA_NTTxx)
*				CHS 10/15/2010 - #140541 - change bPRDB.EarnCode to EDLCode
*				EN 5/31/2013 - User Story 39007 / Task 51803 declare @addonrateamt as bUnitCost so that addon rates with more than 2 decimal places will work properly
*				MV 10/14/2013	64211/64212 Incorrect deduction amt if bPRSI 'Post Diff to Resident State' = Y. Pass 2 more param values to bspPRProcessGetBasis
*				MV 12/2/2013 - TFS-67270/67779 - Pro-rate Annual Taxable Amt/PP/maxCPP/EI/maxEI/Capstock for routine based provincial tax calc. 
*												 Employee may have worked in than one province in this pay period. 	
*				KK 12/31/2013 - 70529 Merged back fixes from 6.8
*
* USAGE:
* Calculates Tax Province deductions and liabilities for a select Employee and Pay Seq.
* Called from main bspPRProcess procedure.  Based on bspPRProcessProvinceCA.
* Will  calculate most dedn/liab methods
*
* INPUT PARAMETERS
*   @prco		PR Company
*   @prgroup	PR Group
*   @prenddate	PR Ending Date
*   @employee	Employee to process
*   @payseq		Payment Sequence #
*   @ppds		# of pay periods in a year
*   @limitmth	Pay Period limit month
*   @stddays	standard # of days in Pay Period
*   @bonus		indicates a Bonus Pay Sequence - Y or N
*   @posttoall	earnings posted to all days in Pay Period - Y or N
*	@A			Annual Taxable Amount (Canada)
*   @PP			Canada Pension Plan or Quebec Pension Plan contribution for the pay period (Canada)
*   @maxCPP		maximum pension contribution
*   @EI			Employment Insurance premium for the pay period (Canada)
*   @maxEI		maximum EI contribution
*   @capstock	YTD deduction for acquisition of approved shares of the capital stock of a prescribed labour-sponsored venture capital corporation
*	@HD			annual deduction for living in a prescribed zone
*
* OUTPUT PARAMETERS
*   @errmsg  	Error message if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
     @prco bCompany,
	 @prgroup bGroup,
	 @prenddate bDate,
	 @employee bEmployee,
	 @payseq tinyint,
     @ppds tinyint,
	 @limitmth bMonth,
	 @stddays tinyint,
	 @bonus bYN,
     @posttoall bYN,
	 @A bDollar,
	 @PP bDollar,
	 @maxCPP bDollar,
	 @EI bDollar,
	 @maxEI bDollar, 
	 @capstock bDollar, 
	 @HD bDollar, 
	 @errmsg varchar(255) output

     AS
     SET NOCOUNT ON
    
     DECLARE @rcode int, @resprovince varchar(4), @restaxdedn bEDLCode, @taxdedn bEDLCode, @res char(1),
     @province varchar(4), @rate bUnitCost, @calcdiff char(1), @calcamt bDollar, @procname varchar(30),
     @eligamt bDollar, @amt2dist bDollar, @accumelig bDollar, @accumsubj bDollar, @accumamt bDollar,
     @ytdelig bDollar, @ytdamt bDollar, @calcbasis bDollar, @accumbasis bDollar,
     @liabbasis bDollar, @provincetaxamt bDollar, @taxdiff char(1), @diff char(1), @basedon char(1),
     @sutaliab bEDLCode, @ytdsuielig bDollar, @miscamt bDollar, @overmiscamt bYN, @empmiscamt bDollar,
     @accumhrswks char(1), @sutahrswks bHrs, @fedtaxdedn bEDLCode, @fedfilestatus char(1), @fedexempts tinyint,
     @routineprovince varchar(4), @resident varchar(1), @TotalCalcBasis bDollar,@TotalProvBasis bDollar, 
	 @ProRate bPct, @TotalAnnualAmt bDollar, @TotalPP bDollar, @TotalMaxCPP bDollar, @TotalEI bDollar,
	 @TotalMaxIE bDollar, @TotalCapstock bDollar,
     @exemptamt bDollar --issue 24545
    
    
     -- Standard deduction/liability variables
     DECLARE @dlcode bEDLCode, @dldesc bDesc, @dltype char(1), @method varchar(10), @routine varchar(10),
     @rate1 bUnitCost, @rate2 bUnitCost, @seq1only bYN, @ytdcorrect bYN, @bonusover bYN, @bonusrate bRate,
     @limitbasis char(1), @limitamt bDollar, @limitperiod char(1), @limitcorrect bYN, @autoAP bYN,
     @vendorgroup bGroup, @vendor bVendor, @apdesc bDesc, @calccategory varchar (1), @rndtodollar bYN,
     @limitrate bRate, @empllimitrate bRate, @outaccumbasis bDollar /*issue 11030*/
    
     -- Employee deduction/liability override variables
     DECLARE @filestatus char(1), @regexempts tinyint, @addexempts tinyint, @overcalcs char(1), @emprateamt bUnitCost,
     @overlimit bYN, @emplimit bDollar, @addontype char(1), @addonrateamt bUnitCost, @empvendor bVendor,
     @miscfactor bRate
    
     -- Payment Sequence Total variables
     DECLARE @dtvendorgroup bGroup, @dtvendor bVendor, @dtAPdesc bDesc, @useover bYN, @overprocess bYN, @overamt bDollar

	-- declarations specific to Canada Taxes
	DECLARE @TCP bDollar, @Scapstock bDollar
   
    -- cursor flags
    DECLARE @openProvince tinyint, @openProvinceDL tinyint
    
    SELECT @rcode = 0

	-- Save off amounts passed in as totals -- TFS-67270
	SELECT	@TotalAnnualAmt = @A,
			@TotalPP = @PP,
			@TotalMaxCPP = @maxCPP, 
			@TotalEI = @EI,
			@TotalMaxIE = @maxEI,
			@TotalCapstock = @capstock
			-- @HD is only in BC, therefore the whole amount is applied to BC.
 
    -- get Fed Tax and Filing Status for defaults
    SELECT @fedfilestatus = 'S', @fedexempts = 0

    SELECT @fedtaxdedn = TaxDedn
    FROM dbo.bPRFI with (nolock) 
	WHERE PRCo = @prco  -- already validated

    SELECT @fedfilestatus = FileStatus, @fedexempts = RegExempts
    FROM dbo.bPRED with (nolock)
    WHERE PRCo = @prco and Employee = @employee and DLCode = @fedtaxdedn
    
    -- get Employee's Resident Tax Province info ... #127015 also get info needed for Saskatchewan tax computation
    SELECT @resprovince = TaxState, @Scapstock = isnull(LCPStock,0)
    FROM dbo.bPREH with (nolock)
    WHERE PRCo = @prco and Employee = @employee
    IF @@rowcount = 0
    BEGIN
         SELECT @errmsg = 'Missing Employee header entry!', @rcode = 1
         GOTO bspexit
    END
    
     -- see if difference between posted and resident Province Tax will need to be calculated
     SELECT @restaxdedn = null, @taxdiff = 'N'
    
     IF @resprovince is not null
     BEGIN
         SELECT @restaxdedn = TaxDedn, @taxdiff = TaxDiff
         FROM dbo.bPRSI with (nolock) WHERE PRCo = @prco and State = @resprovince
     END
    
     -- create cursor for posted Provinces
     DECLARE bcProvince CURSOR FOR
     SELECT DISTINCT TaxState, 'T'       -- 'T' used for Tax Province
     FROM dbo.bPRTH
     WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq

     UNION

     SELECT DISTINCT UnempState, 'U'    -- 'U' used for Unemployment Province
     FROM dbo.bPRTH
     WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq

    
    OPEN bcProvince
    
     SELECT @openProvince = 1
    
     -- loop through Provinces
     next_Province:
    
         FETCH NEXT FROM bcProvince 
		 INTO @province, @basedon
         IF @@fetch_status = -1 GOTO end_Province
         IF @@fetch_status <> 0 GOTO next_Province
    
         -- save Province's Tax Dedn for possible difference calculation
         IF @basedon = 'T'
         BEGIN
             SELECT @taxdedn = TaxDedn 
			 FROM dbo.bPRSI with (nolock) 
			 WHERE PRCo = @prco and State = @province
         END
    
         -- save Province's Unemployment liability - needs special limit handling
         IF @basedon = 'U'
         BEGIN
             SELECT @sutaliab = SUTALiab, @accumhrswks = AccumHrsWks
             FROM dbo.bPRSI with (nolock) 
			 WHERE PRCo = @prco and State = @province
         END
    
         -- check for residency - controls rates
         SELECT @res = 'N'
         IF @province = @resprovince SELECT @res = 'Y'
    
         -- clear Process Earnings
         DELETE dbo.bPRPE 
		 WHERE VPUserName = SUSER_SNAME()
    
         IF @basedon = 'T'
         BEGIN
         	-- load Process Earnings with all earnings posted to this Tax Province
         	INSERT dbo.bPRPE 
					(
						VPUserName,
						PostSeq,
						PostDate, 
						EarnCode, 
						Factor, 
						IncldLiabDist, 
						[Hours], 
						Rate, 
						Amt
					) --issue 20562
            SELECT	SUSER_SNAME(),
					t.PostSeq,
					t.PostDate,
					t.EarnCode,
					e.Factor, 
					e.IncldLiabDist,
					t.[Hours], 
					t.Rate, 
					t.Amt --issue 20562
            FROM dbo.bPRTH t
            JOIN dbo.bPREC e with (nolock) on e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
            WHERE t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
                     and t.PaySeq = @payseq and t.TaxState = @province

         	INSERT dbo.bPRPE 
							(
								VPUserName,
								PostSeq, 
								PostDate, 
								EarnCode, 
								Factor, 
								IncldLiabDist, 
								[Hours], 
								Rate, 
								Amt
							 )    -- Addons --issue 20562
            SELECT	SUSER_SNAME(), 
					t.PostSeq, 
					t.PostDate, 
					a.EarnCode, 
					e.Factor, 
					e.IncldLiabDist, 
					0, 
					a.Rate, 
					a.Amt --issue 20562
            FROM dbo.bPRTA a
            JOIN dbo.bPRTH t on t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate and
                 t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
            JOIN dbo.bPREC e with (nolock) on e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
            WHERE a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate and a.Employee = @employee
                 and a.PaySeq = @payseq and t.TaxState = @province

			--Get total basis amount for all provinces for this employee. TFS-67270
			SELECT @TotalCalcBasis = 0
			SELECT @TotalCalcBasis = ISNULL(SUM(t.Amt),0)
			FROM dbo.bPRTH t
            JOIN dbo.bPREC e ON e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
            WHERE	t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and
					t.Employee = @employee and t.PaySeq = @payseq 

			SELECT @TotalCalcBasis = @TotalCalcBasis + ISNULL(SUM(a.Amt),0)
			FROM dbo.bPRTA a
            JOIN dbo.bPRTH t ON t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate and
                 t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
            JOIN dbo.bPREC e ON e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
            WHERE	a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate and 
					a.Employee = @employee and a.PaySeq = @payseq 
           
		 END -- end based on 'T'
    
         IF @basedon = 'U'
         BEGIN
         	-- load Process Earnings with all earnings posted to this Unemployment Province
         	INSERT dbo.bPRPE (
								VPUserName, 
								PostSeq, 
								PostDate, 
								EarnCode, 
								Factor, 
								IncldLiabDist, 
								[Hours], 
								Rate, 
								Amt
							 )   -- Timecards --issue 20562
            SELECT	SUSER_SNAME(), 
					t.PostSeq, 
					t.PostDate, 
					t.EarnCode, 
					e.Factor, 
					e.IncldLiabDist, 
					t.[Hours], 
					t.Rate, 
					t.Amt --issue 20562
            FROM dbo.bPRTH t
            JOIN dbo.bPREC e ON e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
            WHERE t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and t.Employee = @employee
				and t.PaySeq = @payseq and t.UnempState = @province

         	INSERT dbo.bPRPE 
							( 
								VPUserName, 
								PostSeq, 
								PostDate, 
								EarnCode, 
								Factor, 
								IncldLiabDist, 
								[Hours], 
								Rate, 
								Amt
							)   -- Addons --issue 20562
            SELECT	SUSER_SNAME(), 
					t.PostSeq, 
					t.PostDate, 
					a.EarnCode, 
					e.Factor, 
					e.IncldLiabDist, 
					0, 
					a.Rate, 
					a.Amt --issue 20562
			FROM dbo.bPRTA a
            JOIN dbo.bPRTH t ON t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate and
                 t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
            JOIN dbo.bPREC e ON e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
            WHERE a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate and a.Employee = @employee
                 and a.PaySeq = @payseq and t.UnempState = @province

			-- Get total basis amount from all PRTH recs for Employee.TFS-67270
			SELECT @TotalCalcBasis = 0
			SELECT @TotalCalcBasis = ISNULL(SUM(t.Amt),0)
			FROM dbo.bPRTH t
            JOIN dbo.bPREC e ON e.PRCo = t.PRCo and e.EarnCode = t.EarnCode
            WHERE	t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate = @prenddate and
					t.Employee = @employee and t.PaySeq = @payseq

			SELECT @TotalCalcBasis = @TotalCalcBasis + ISNULL(SUM(a.Amt),0)
			FROM dbo.bPRTA a
            JOIN dbo.bPRTH t ON t.PRCo = a.PRCo and t.PRGroup = a.PRGroup and t.PREndDate = a.PREndDate and
                 t.Employee = a.Employee and t.PaySeq = a.PaySeq and t.PostSeq = a.PostSeq
            JOIN dbo.bPREC e ON e.PRCo = a.PRCo and e.EarnCode = a.EarnCode
            WHERE	a.PRCo = @prco and a.PRGroup = @prgroup and a.PREndDate = @prenddate and
					a.Employee = @employee and a.PaySeq = @payseq

         END -- end based on 'U'
    
		-- Get total basis amount for this province and this employee. TFS-67270
		SELECT @TotalProvBasis = 0
		SELECT @TotalProvBasis = ISNULL(SUM(Amt),0)
		FROM dbo.PRPE
		WHERE VPUserName = SUSER_SNAME()
    
         -- create cursor for Tax Province DLs - resident 'N' or 'Y' and Dedn/Liab code and Difference flag - 'N' = don't calc diff, 'Y' = calc diff
         -- process resident 'Y' last for correct calculation of tax difference.
         IF @basedon = 'T'
         BEGIN
             DECLARE bcProvinceDL cursor for
             SELECT 'N' AS CalcDiff, TaxDedn 
			 FROM dbo.bPRSI 
			 WHERE PRCo = @prco and State = @province and TaxDedn IS NOT NULL

             UNION

             SELECT 'N' AS CalcDiff, DLCode 
			 FROM dbo.bPRSD with (nolock) WHERE PRCo = @prco and State = @province and BasedOn = 'T'

             UNION

             SELECT 'Y' AS CalcDiff, @restaxdedn 
			 WHERE @restaxdedn is not null and @taxdiff = 'Y' and @taxdedn <> @restaxdedn
             ORDER BY CalcDiff, TaxDedn
          END
    
         -- create a cursor for Unemployment Province DLs - no difference calculations
         IF @basedon = 'U'
         BEGIN
			DECLARE bcProvinceDL CURSOR FOR
			SELECT 'N' AS CalcDiff,SUTALiab 
			FROM dbo.bPRSI 
			WHERE PRCo = @prco and State = @province and SUTALiab iS NOT NULL

			UNION

			SELECT 'N' AS CalcDiff,DLCode 
			FROM dbo.bPRSD 
			WHERE PRCo = @prco and State = @province and BasedOn = 'U'
         END

   
        OPEN bcProvinceDL
         SELECT @openProvinceDL = 1
    
         -- loop through Province DL cursor
         next_ProvinceDL:
             FETCH NEXT FROM bcProvinceDL INTO @calcdiff,@dlcode
             IF @@fetch_status = -1 GOTO end_ProvinceDL
    
             IF @@fetch_status <> 0 GOTO next_ProvinceDL
    
    
             -- get standard DL info
             SELECT @dldesc = Description, @dltype = DLType, @method = Method, @routine = Routine, @rate1 = RateAmt1,
                 @rate2 = RateAmt2, @seq1only = SeqOneOnly, @ytdcorrect = YTDCorrect, @bonusover = BonusOverride,
                 @bonusrate = BonusRate, @limitbasis = LimitBasis, @limitamt = LimitAmt, @limitperiod = LimitPeriod,
                 @limitcorrect = LimitCorrect, @autoAP = AutoAP, @vendorgroup = VendorGroup, @vendor = Vendor,
    	     @calccategory = CalcCategory, @rndtodollar=RndToDollar, @limitrate = LimitRate /*issue 11030*/
             FROM dbo.bPRDL
             WHERE PRCo = @prco and DLCode = @dlcode
             IF @@rowcount = 0
             BEGIN
     		    SELECT @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' not setup!', @rcode = 1
     		    GOTO bspexit
     		 END
  
    	 /* validate calccategory*/
    	IF @calccategory not in ('S','A')
    	BEGIN
    		SELECT @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' should be calculation category S or A!', @rcode = 1
     		GOTO bspexit
     	END
    
        -- check for Payment Sequence #1 restriction
        IF @seq1only = 'Y' and @payseq <> 1 GOTO next_ProvinceDL
    
        SELECT @rate = @rate2       -- non-resident rate
        IF @res = 'Y' or @dlcode = @restaxdedn SELECT @rate = @rate1    -- resident rate

        -- get Employee info and overrides for this dedn/liab
        SELECT @filestatus = @fedfilestatus, @regexempts = @fedexempts, @addexempts = 0, @overmiscamt = 'N',
			@empmiscamt = 0.00, @miscfactor = 0.00, @empvendor = null, @apdesc = null,
			@overcalcs = 'N', @overlimit = 'N', @addontype = 'N'
        SELECT @filestatus = FileStatus, @regexempts = RegExempts, @addexempts = AddExempts, @overmiscamt = OverMiscAmt,
			@empmiscamt = MiscAmt, @miscfactor = MiscFactor, @empvendor = Vendor, @apdesc = APDesc,
			@overcalcs = OverCalcs, @emprateamt = isnull(RateAmt,0.00), @overlimit = OverLimit, @emplimit = isnull(Limit,0.00),
			@addontype = AddonType, @addonrateamt = isnull(AddonRateAmt,0.00),
    		@empllimitrate = isnull(LimitRate,0.00), /*issue 11030*/
			@TCP = MiscAmt2 --#127015 Total Claim amount
        FROM dbo.bPRED with (nolock)
        WHERE PRCo = @prco and Employee = @employee and DLCode = @dlcode
    
     	IF @regexempts is null SELECT @regexempts = 0
     	IF @addexempts is null SELECT @addexempts = 0
    
        -- check for calculation override on Bonus sequence
        IF @bonus = 'Y' and @bonusover = 'Y' SELECT @method = 'G', @rate = @bonusrate
  
        -- check for Employee calculation and rate overrides
        IF @overcalcs = 'M' SELECT @method = 'G', @rate = @emprateamt
        IF @overcalcs = 'R' SELECT @rate = @emprateamt
        IF @overlimit = 'Y' SELECT @limitamt = @emplimit
    	IF @overlimit = 'Y' SELECT @limitrate = @empllimitrate /*issue 11030*/

        -- get calculation, accumulation, and liability distribution basis
        EXEC @rcode = bspPRProcessGetBasis @prco, @prgroup, @prenddate, @employee, @payseq, @method,
            @posttoall, @dlcode, @dltype, @stddays, NULL, NULL, @calcbasis output, @accumbasis output, --issue 20562
            @liabbasis output, @errmsg output
        IF @rcode <> 0 GOTO bspexit
    
     	SELECT @sutahrswks = 0		-- initialize SUTA hrs/weeks
    
        -- check for 0 basis - skip accumulations and calculations
        IF @calcbasis = 0.00
        BEGIN
            SELECT @calcamt = 0.00, @eligamt = 0.00
            GOTO calc_end
        END
        
             -- accumulate actual, subject, and eligible amounts if needed
        IF @limitbasis = 'C' or @limitbasis = 'S' or @ytdcorrect = 'Y'
        BEGIN
            EXEC @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
                @dlcode, @dltype, @limitperiod, @limitmth, @ytdcorrect, @accumamt output,
    
                @accumsubj output, @accumelig output, @ytdamt output, @ytdelig output, @errmsg output
            IF @rcode <> 0 GOTO bspexit
        END
    
        -- if SUTA liability accum year-to-date eligible earnings for all SUTA liabilities
   
        -- assumes reciprocal agreements among all Provinces, method is 'G',
        -- limit based on 'subject earnings', applied 'annually', limit and ytd correct are both 'N'
        IF @dlcode = @sutaliab
        BEGIN
            EXEC @rcode = bspPRProcessGetYTDSUIElig @prco, @prgroup, @prenddate, @employee, @payseq,
            @province, @dlcode, -- Missed in #142367
            @ytdsuielig output, @errmsg output
            IF @rcode <> 0 GOTO bspexit
    
            SELECT @accumelig = @ytdsuielig	-- use ytd sui eligible for accumulated eligible
    
            -- get Hours or Weeks for Unemployement Liab
            IF @accumhrswks = 'H'
            BEGIN
            -- accumulate subject hours
         		SELECT @sutahrswks = isnull(sum(e.Hours),0.00)
         		FROM dbo.bPRPE e with (nolock)
         		JOIN dbo.bPRDB b with (nolock) on b.EDLCode = e.EarnCode
         		WHERE VPUserName = SUSER_SNAME() and b.PRCo = @prco and b.DLCode = @dlcode and b.SubjectOnly = 'N'
            END

            IF @accumhrswks = 'W' and @payseq = 1	-- only count weeks on Pay Seq #1
            BEGIN
				SELECT @sutahrswks = Wks
				FROM dbo.bPRPC 
				WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
            END

        END
   
         -- Calculations          
		SELECT @calcamt = 0.00, @eligamt = 0.00

		-- Additional Dedns/Liabs can use any method, CA provintial taxes use routines. TFS-67270
		-- Flat Amount
		IF @method = 'A'
 		BEGIN
 			EXEC @rcode = bspPRProcessAmount @calcbasis, @rate, @limitbasis, @limitamt, @limitcorrect, 
 											 @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt, 
 											 @calcamt OUTPUT, @eligamt OUTPUT, @errmsg OUTPUT
 			IF @rcode<> 0 GOTO bspexit
 		END
	    
 		-- Rate per Day, Factored Rate per Hour, Rate of Gross, Rate per Hour, Straight Time Equivalent, or Rate of Dedn
		IF @method in ('D', 'F', 'G', 'H', 'S', 'DN')
		BEGIN
			EXEC @rcode = bspPRProcessRateBased @calcbasis, @rate, @limitbasis, @limitamt, @ytdcorrect,
												@limitcorrect, @accumelig, @accumsubj, @accumamt, @ytdelig, 
												@ytdamt, @accumbasis, @limitrate, 
												@outaccumbasis OUTPUT, --issue 11030 adjust for changes in bspPRProcessRateBased
												@calcamt = @calcamt OUTPUT, @eligamt = @eligamt OUTPUT, @errmsg = @errmsg OUTPUT
			IF @rcode<> 0 GOTO bspexit
			SELECT @accumbasis = @outaccumbasis --issue 11030 basis may be adjusted to fit rate of earnings limit scheme
 		END

     	   -- Routine
     	   IF @method = 'R'
     	   BEGIN 
     		  -- get procedure name
     		  SELECT @procname = NULL
     		  SELECT @procname = ProcName, @miscamt = MiscAmt1
     		  FROM dbo.bPRRM 
     		  WHERE PRCo = @prco and Routine = @routine
     		  IF @procname IS NULL
     		  BEGIN
     			 SELECT @errmsg = 'Missing Routine procedure name for dedn/liab ' + convert(varchar(4),@dlcode), @rcode = 1
     			 GOTO bspexit
    		  END
              IF NOT EXISTS 
							(
								SELECT * 
								FROM sysobjects 
								WHERE name = @procname and type = 'P'
							)
              BEGIN
                 SELECT @errmsg = 'Invalid Routine procedure - ' + @procname, @rcode = 1
                 GOTO bspexit
              END
 
     		  IF @overmiscamt = 'Y' SELECT @miscamt = @empmiscamt	-- use Employee override
    
			  --IF EMPLOYEE WORKED IN MORE THAN ONE PROVINCE IN THIS PAY PERIOD, PRO-RATE THE AMOUNTS USED TO CALCULATE PROVINCIAL TAX. TFS-67270
				IF @TotalCalcBasis <> 0
				BEGIN
					SELECT @ProRate		= @TotalProvBasis/@TotalCalcBasis
				END
				ELSE
				BEGIN
					SELECT @ProRate = 1
				END
				 
				SELECT	@A				= @TotalAnnualAmt * @ProRate,
						@PP				= ISNULL(@TotalPP,0.0) * @ProRate,
						@maxCPP			= ISNULL(@TotalMaxCPP,0.0) * @ProRate,
						@EI				= ISNULL(@TotalEI,0.0) * @ProRate,
						@maxEI			= ISNULL(@TotalMaxIE, 0.0) * @ProRate,
						@capstock		= ISNULL(@TotalCapstock,0.0) * @ProRate		
						
			-- @TCP and @HD is not prorated. HD only applies to employees living in BC


              -- assign Tax Routine Province, may be posted Province or resident
              SELECT @routineprovince = @province
              IF @calcdiff = 'Y' SELECT @routineprovince = @resprovince
   
			  -- Call various provincial/territorial tax routines
     		  IF @routineprovince in ('NL', 'NS', 'NB', 'MB', 'NT', 'YT')
     		  BEGIN
     		  	EXEC @rcode = @procname @ppds, @A, @TCP, @PP, @maxCPP, @EI, @maxEI, @miscamt, @capstock, @calcamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				IF @@error <> 0 SELECT @rcode = 1
     		  	GOTO routine_end
     		  END 

     		  IF @routineprovince in ('SK')
     		  BEGIN
     		  	EXEC @rcode = @procname @ppds, @A, @TCP, @PP, @maxCPP, @EI, @maxEI, @miscamt, @Scapstock, @capstock, @calcamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				IF @@error <> 0 SELECT @rcode = 1
     		  	GOTO routine_end
     		  END 

     		  IF @routineprovince in ('PE', 'AB', 'NU')
     		  BEGIN
     		  	EXEC @rcode = @procname @ppds, @A, @TCP, @PP, @maxCPP, @EI, @maxEI, @miscamt, @calcamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				IF @@error <> 0 SELECT @rcode = 1
     		  	GOTO routine_end
     		  END 

     		  IF @routineprovince in ('ON')
     		  BEGIN
     		  	EXEC @rcode = @procname @ppds, @A, @TCP, @addexempts, @PP, @maxCPP, @EI, @maxEI, @miscamt, @capstock, 
					@calcamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				IF @@error <> 0 SELECT @rcode = 1
     		  	GOTO routine_end
     		  END 

     		  IF @routineprovince in ('BC')
     		  BEGIN
     		  	EXEC @rcode = @procname @ppds, @A, @TCP, @PP, @maxCPP, @EI, @maxEI, @miscamt, @HD, @capstock, 
					@calcamt output, @errmsg output
   				-- please put no code between exec and @@error check!
   				IF @@error <> 0 SELECT @rcode = 1
     		  	GOTO routine_end
     		  END 

        	  SELECT @errmsg = 'Missing or invalid province/territory routine for Dedn/liab code ' + convert(varchar(4),@dlcode), @rcode = 1
    		  GOTO bspexit

     		routine_end:
     		IF @rcode <> 0 GOTO bspexit
     		IF @calcamt is null SELECT @calcamt = 0.00
     		SELECT @eligamt = @calcbasis
     	 END -- end routine
    
             -- apply Employee calculation override
             IF @overcalcs = 'A' SELECT @calcamt = @emprateamt
    
             -- apply Employee addon amounts - only applied if calculated amount is positive
             IF @calcbasis > 0.00
             BEGIN
     		    IF @addontype = 'A' SELECT @calcamt = @calcamt + @addonrateamt
     		    IF @addontype = 'R' SELECT @calcamt = @calcamt + (@calcbasis * @addonrateamt)
     		 END 
    
             -- save calculated Province Tax amount
             IF @dlcode = @taxdedn SELECT @provincetaxamt = @calcamt
    
             -- check for Resident Province Tax difference - set to 0 if equal or less than posted Province tax
             IF @dlcode = @restaxdedn and @calcdiff = 'Y'
             BEGIN
                 IF @calcamt <= @provincetaxamt SELECT @calcamt = 0.00
                 IF @calcamt > @provincetaxamt SELECT @calcamt = @calcamt - @provincetaxamt
             END
    
    		IF @rndtodollar='Y'	SELECT @calcamt = ROUND(@calcamt,0) --round to the nearest dollar
    	
     	   calc_end:	 -- Finished with calculations
     	   -- get AP Vendor and Transaction description
     	   SELECT @dtvendorgroup = null, @dtvendor = null, @dtAPdesc = null
    
     	  IF @autoAP = 'Y'
     	  BEGIN
     		  SELECT @dtvendorgroup = @vendorgroup, @dtvendor = @vendor, @dtAPdesc = @dldesc
     		  IF @empvendor is not null SELECT @dtvendor = @empvendor
     		  IF @apdesc is not null SELECT @dtAPdesc = @apdesc
     	  END
    
     	   -- update Payment Sequence Totals
     	  UPDATE dbo.bPRDT
          SET	Amount = Amount + @calcamt,
				SubjectAmt = SubjectAmt + @accumbasis, 
				EligibleAmt = EligibleAmt + @eligamt,
            	VendorGroup = @dtvendorgroup,
				Vendor = @dtvendor, 
				APDesc = @dtAPdesc
     	  WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
     		      and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
     	  IF @@rowcount = 0
     	  BEGIN
     		  INSERT dbo.bPRDT 
								(
									PRCo, 
									PRGroup, 
									PREndDate, 
									Employee, 
									PaySeq, 
									EDLType, 
									EDLCode, 
									[Hours], 
									Amount, 
									SubjectAmt, 
									EligibleAmt,
     								UseOver, 
									OverAmt, 
									OverProcess, 
									VendorGroup, 
									Vendor, 
									APDesc, 
									OldHours, 
									OldAmt, 
									OldSubject, 
									OldEligible, 
									OldMth,
                  					OldVendor, 
									OldAPMth, 
									OldAPAmt
								)
     		  VALUES	
						(
							@prco,
							@prgroup, 
							@prenddate, 
							@employee, 
							@payseq, 
							@dltype, 
							@dlcode, 
							0, 
							@calcamt, 
							@accumbasis, 
							@eligamt,
     						'N', 
							0, 
							'N', 
							@dtvendorgroup, 
							@dtvendor, 
							@dtAPdesc, 
							0, 
							0, 
							0, 
							0, 
							NULL, 
							NULL, 
							NULL, 
							0
						)
    	       	IF @@rowcount <> 1
    			BEGIN
    				SELECT @errmsg = 'Unable to add PR Detail Entry for Employee ' + convert(varchar(6),@employee), @rcode = 1
    				GOTO bspexit
    			end
     	 end
    		
     	-- SUTA updates
     	IF @dlcode = @sutaliab
     	BEGIN
     		-- update SUTA Hours/Weeks to Payment Sequence Totals
     		UPDATE dbo.bPRDT
     		SET Hours = Hours + @sutahrswks
     		WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
     		      and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
     	END
    
    
        -- check for Override processing
        SELECT @useover = UseOver, @overamt = OverAmt, @overprocess = OverProcess
        FROM dbo.bPRDT with (nolock)
        WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
     	and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
    
        IF @overprocess = 'Y' GOTO next_ProvinceDL
    
    
             -- an overridden DL amount is processed only once
     	    IF @useover = 'Y'
     		BEGIN
     		  UPDATE dbo.bPRDT
              SET OverProcess = 'Y' 
			  WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
                 and Employee = @employee and PaySeq = @payseq and EDLType = @dltype and EDLCode = @dlcode
     		END
    
             -- check for Liability distribution - needed even if basis and/or amount are 0.00
            IF @dltype <> 'L' GOTO next_ProvinceDL
    
             -- use calculated amount unless overridden
     		SELECT @amt2dist = @calcamt
    		-- #23655 fix to use override amt even if calc basis = 0
     		IF @useover = 'Y' /*and @calcbasis <> 0.00*/ SELECT @amt2dist = @overamt
    
     		-- no need to distribute if Basis <> 0 and Amt = 0, but will distibute if both are 0.00
            -- because of possible offsetting timecard entries
            IF @calcbasis <> 0.00 and @amt2dist = 0.00 GOTO next_ProvinceDL
    
            -- call procedure to distribute liability amount
            EXEC @rcode = bspPRProcessLiabDist @prco, @prgroup, @prenddate, @employee, @payseq, @dlcode,
                     @method, @rate, @liabbasis, @amt2dist, @posttoall, @errmsg output --issue 20562
            IF @rcode <> 0 GOTO bspexit
    
            GOTO next_ProvinceDL
    
         end_ProvinceDL:
            CLOSE bcProvinceDL
            DEALLOCATE bcProvinceDL
            SELECT @openProvinceDL = 0
            GOTO next_Province
    
     end_Province:
    
         CLOSE bcProvince
         DEALLOCATE bcProvince
         SELECT @openProvince = 0
    
    
     bspexit:
         -- clear Process Earnings
         DELETE dbo.bPRPE 
		 WHERE VPUserName = SUSER_SNAME()
    
         IF @openProvinceDL = 1
         BEGIN
        	CLOSE bcProvinceDL
         	DEALLOCATE bcProvinceDL
         END
         IF @openProvince = 1
         BEGIN
        	CLOSE bcProvince
         	DEALLOCATE bcProvince
         END
		 
		 RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[bspPRProcessProvinceCA] TO [public]
GO
