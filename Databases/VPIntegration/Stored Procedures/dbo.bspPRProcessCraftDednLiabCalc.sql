SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRProcessCraftDednLiabCalc]
/***********************************************************
* CREATED:		CHS 10/15/2010
* MODIFIED:		MV 12/13/10 - #142374 - get vendor from craft master
*
* USAGE:
* Calculates Craft deductions AND liabilities for a SELECT Employee AND Pay Seq.
* Called FROM main bspPRProcess procedure.
* Will calculate most dedn/liab methods.
*
* INPUT PARAMETERS
* @prco	 PR Company
* @prgroup	PR Group
* @prenddate	PR ENDing Date
* @employee	Employee to process
* @payseq	Payment Sequence #
* @ppds # of pay periods in a year
* @limitmth Pay Period limit month
* @stddays standard # of days in Pay Period
* @bonus indicates a Bonus Pay Sequence - Y or N
* @posttoall earnings posted to all days in Pay Period - Y or N
*
* OUTPUT PARAMETERS
* @errmsg 	Error message IF something went wrong
*
* RETURN VALUE
* 0 success
* 1 fail
*****************************************************/
 
@prco bCompany, @dlcode bEDLCode, @prgroup bGroup, @prenddate bDate, 
	@employee bEmployee, @payseq tinyint, @ppds tinyint, @limitmth bMonth, 
	@stddays tinyint, @bonus bYN, @posttoall bYN, @craft bCraft, 
	@class bClass, @template smallint, @effectdate bDate, @oldcaplimit bDollar,
	@newcaplimit bDollar, @jobcraft bCraft, @recipopt char(1), @errmsg varchar(255) output
 
 AS
 SET NOCOUNT ON
 
DECLARE @rcode int, @rate bUnitCost, @calcamt bDollar, @procname varchar(30), 
	@eligamt bDollar, @amt2dist bDollar, @accumelig bDollar, @accumsubj bDollar, 
	@accumamt bDollar, @ytdelig bDollar, @ytdamt bDollar, @calcbasis bDollar, 
	@accumbasis bDollar, @hrs bHrs, @factor bRate,
	@oldrate bUnitCost, @newrate bUnitCost, @overrate bUnitCost, @oldcalcamt bDollar, 
	@oldcalcbasis bDollar, @oldeligamt bDollar, @newcalcbasis bDollar, 
	@oldliabbasis bDollar, @newcalcamt bDollar, @newliabbasis bDollar, 
	@neweligamt bDollar, @cacraft bCraft, @liabdistbasis bDollar, @cmvendorgroup bGroup, 
	@cmvendor bVendor, @exemptamt bDollar --issue 24545
 
 -- Standard deduction/liability variables
DECLARE  @dldesc bDesc, @dltype char(1), @method varchar(10), @routine varchar(10), 
	@seq1only bYN, @ytdcorrect bYN, @bonusover bYN, @bonusrate bRate, @limitbasis char(1), 
	@limitamt bDollar, @limitperiod char(1), @limitcorrect bYN, @autoAP bYN, 
	@vendorgroup bGroup, @vendor bVendor, @apdesc bDesc, @calccategory varchar (1), 
	@rndtodollar bYN, @dlvendorgroup bGroup, @dlvendor bVendor, @limitrate bRate, 
	@empllimitrate bRate, @outaccumbasis bDollar
 
-- Employee deduction/liability override variables
DECLARE @filestatus char(1), @regexempts tinyint, @overcalcs char(1), 
	@emprateamt bUnitCost, @overlimit bYN, @emplimit bDollar, 
	@addontype char(1), @addonrateamt bDollar, @empvendor bVendor

---- Payment Sequence Total variables
DECLARE @dtvendorgroup bGroup, @dtvendor bVendor, @dtAPdesc bDesc,
	@useover bYN, @overprocess bYN, @overamt bDollar

-- issue 21186 - misc amts used for Benefit based ON day of week calculation
DECLARE @miscamt1 bDollar, @miscamt2 bDollar, @miscamt3 bDollar

---- cursor flags
DECLARE @openFactor tinyint
 
 
	-- get standard DL info
	SELECT @dldesc = Description, @dltype = DLType, @method = Method, @routine = Routine,
		@seq1only = SeqOneOnly, @ytdcorrect = YTDCorrect, @bonusover = BonusOverride,
		@bonusrate = BonusRate, @limitbasis = LimitBasis, @limitamt = LimitAmt, @limitperiod = LimitPeriod,
		@limitcorrect = LimitCorrect, @autoAP = AutoAP, @dlvendorgroup = VendorGroup, @dlvendor = Vendor, -- #20340 fall back vendor IF not setup by Craft
		@calccategory = CalcCategory, @rndtodollar=RndToDollar, @limitrate = LimitRate /*issue 11030*/
	FROM dbo.bPRDL WITH (NOLOCK)
	WHERE PRCo = @prco 
		AND DLCode = @dlcode
	IF @@rowcount = 0
		BEGIN
		SELECT @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' not setup!', @rcode = 1
		GOTO bspexit
		END
 
	-- validate DL calculation category
	IF @calccategory not in ('C','A')
		BEGIN
		SELECT @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' must be calculation category ''C'' or ''A''!', @rcode = 1
		GOTO bspexit
		END

	-- check for Payment Sequence #1 restriction
	IF @seq1only = 'Y' AND @payseq <> 1 GOTO bspexit
 
	-- get old AND new rates - except Variable method DLs which must be done by Factor -
	IF @method <> 'V'
		BEGIN
		SELECT @oldrate = 0.00, @newrate = 0.00
		
		SELECT @oldrate = OldRate, @newrate = NewRate
		FROM dbo.bPRCI WITH (NOLOCK) -- Craft Items
		WHERE PRCo = @prco 
			AND Craft = @craft 
			AND EDLType = @dltype 
			AND EDLCode = @dlcode 
			AND Factor = 0.00
		
		SELECT @oldrate = OldRate, @newrate = NewRate
		FROM dbo.bPRCD WITH (NOLOCK) -- Class Dedn/Liabs
		WHERE PRCo = @prco 
			AND Craft = @craft 
			AND Class = @class 
			AND DLCode = @dlcode 
			AND Factor = 0.00
		
		SELECT @oldrate = OldRate, @newrate = NewRate
		FROM dbo.bPRTI WITH (NOLOCK) -- Template Items
		WHERE PRCo = @prco 
			AND Craft = @craft 
			AND Template = @template 
			AND EDLType = @dltype
			AND EDLCode = @dlcode 
			AND Factor = 0.00
			
		SELECT @oldrate = OldRate, @newrate = NewRate
		FROM dbo.bPRTD WITH (NOLOCK) -- Template Dedn/Liabs
		WHERE PRCo = @prco 
			AND Craft = @craft 
			AND Class = @class 
			AND Template = @template 
			AND DLCode = @dlcode
			AND Factor = 0.00
		END


	-- get Craft Vendor from Craft Master #142374
	 SELECT @cmvendorgroup = VendorGroup, @cmvendor = Vendor
	 FROM dbo.bPRCM WITH (NOLOCK)
	 WHERE PRCo = @prco AND Craft = @craft
	 IF @@ROWCOUNT = 0
	 BEGIN
		 SELECT @errmsg = 'Missing Craft ' + @craft + '.  Cannot process!', @rcode = 1
		 GOTO bspexit
	 END
        
	SELECT @vendorgroup = @cmvendorgroup, @vendor = @cmvendor	-- reset to Craft Vendor
 
	-- check for Craft/Class Vendor override for this dedn/liab
	SELECT @vendorgroup = VendorGroup, @vendor = Vendor
	FROM dbo.bPRCI WITH (NOLOCK)
	WHERE PRCo = @prco 
		AND Craft = @craft 
		AND EDLType = @dltype 
		AND EDLCode = @dlcode
		AND Factor = case @method when 'V' then 1.00 else 0.00 END	-- Variable rate uses factor 1.00, all other use 0.00
		AND VendorGroup is not null 
		AND Vendor is not null

	-- check for reciprocal agreement ON this DL - may effect Craft Accumulations AND Vendor
	SELECT @cacraft = @craft
		IF @recipopt = 'P' AND @jobcraft is not null
		BEGIN
		IF exists(SELECT 1 FROM dbo.bPRTR WITH (NOLOCK) WHERE PRCo = @prco AND Craft = @craft AND Template = @template AND DLCode = @dlcode)
			BEGIN
			SELECT @cacraft = @jobcraft
			
			-- pull Vendor FROM Job Craft	- #16216
			SELECT @vendorgroup = VendorGroup, @vendor = Vendor
			FROM dbo.bPRCM WITH (NOLOCK) 
			WHERE PRCo = @prco 
				AND Craft = @cacraft
			
			-- check for Craft/Class Vendor override for this dedn/liab
			SELECT @vendorgroup = VendorGroup, @vendor = Vendor
			FROM dbo.bPRCI WITH (NOLOCK)
			WHERE PRCo = @prco 
				AND Craft = @cacraft 
				AND EDLType = @dltype 
				AND EDLCode = @dlcode
				AND Factor = case @method when 'V' then 1.00 else 0.00 END	-- Variable rate uses factor 1.00, all other use 0.00
				AND VendorGroup is not null 
				AND Vendor is not null
			END
		END
 
	-- get Employee info AND overrides for this dedn/liab
	SELECT @filestatus = 'S', @regexempts = 0, @empvendor = null, @apdesc = null
	SELECT @overcalcs = 'N', @overlimit = 'N', @addontype = 'N', @overrate = null
	SELECT @filestatus = FileStatus, @regexempts = RegExempts, @empvendor = Vendor, @apdesc = APDesc,
		@overcalcs = OverCalcs, @emprateamt = isnull(RateAmt,0.00), @overlimit = OverLimit,
		@emplimit = isnull(Limit,0.00), @addontype = AddonType, @addonrateamt = isnull(AddonRateAmt,0.00),
		@empllimitrate = isnull(LimitRate,0.00) /*issue 11030*/
	FROM bPRED
	WHERE PRCo = @prco 
		AND Employee = @employee 
		AND DLCode = @dlcode

	-- check for calculation override ON Bonus sequence
	IF @bonus = 'Y' AND @bonusover = 'Y' SELECT @method = 'G', @overrate = @bonusrate

	-- check for Employee calculation AND rate overrides
	IF @overcalcs = 'M' SELECT @method = 'G', @overrate = @emprateamt
	IF @overcalcs = 'R' SELECT @overrate = @emprateamt
	IF @overlimit = 'Y' SELECT @limitamt = @emplimit
	IF @overlimit = 'Y' SELECT @limitrate = @empllimitrate /*issue 11030*/
 
	-- #25012 SET old AND new rates equal to override values prior to calling capped rate procedure
	IF @overrate is not null SELECT @oldrate = @overrate, @newrate = @overrate

	-- get calculation, accumulation, AND liability distribution basis
	EXEC @rcode = bspPRProcessCraftBasis @prco, @prgroup, @prenddate, @employee, @payseq, @method,
		@posttoall, @dlcode, @dltype, @effectdate, @stddays, @oldcalcbasis OUTPUT, --issue 20562
		@newcalcbasis OUTPUT, @accumbasis OUTPUT, @oldliabbasis OUTPUT, @newliabbasis OUTPUT, @errmsg OUTPUT
	IF @rcode <> 0 GOTO bspexit

	-- IF liability code is capped, check for adjusted rates
	IF exists(SELECT top 1 1 FROM dbo.bPRCS WITH (NOLOCK) WHERE PRCo = @prco AND Craft = @craft AND ELType = 'L' AND ELCode = @dlcode)
		BEGIN
		EXEC @rcode = bspPRProcessCraftCapRate @prco, @prgroup, @prenddate, @craft, @class, @template, @dlcode, @employee,
			@effectdate, @oldcaplimit, @newcaplimit, @oldrate OUTPUT, @newrate OUTPUT, @errmsg OUTPUT
		IF @rcode <> 0 GOTO bspexit
		END
 
	-- check for 0 basis - skip accumulations AND calculations

	-- check for 0 basis - skip accumulations AND calculations
	IF (@oldcalcbasis + @newcalcbasis = 0.00) AND @oldrate=@newrate
		BEGIN
		SELECT @calcbasis = 0.00, @calcamt = 0.00, @eligamt = 0.00, @liabdistbasis = 0.00
		GOTO calc_end
		END

	-- accumulate actual, subject, AND eligible amounts IF needed
	IF @limitbasis = 'C' or @limitbasis = 'S' or @ytdcorrect = 'Y'
		BEGIN
		EXEC @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
			@dlcode, @dltype, @limitperiod, @limitmth, @ytdcorrect, @accumamt OUTPUT,
			@accumsubj OUTPUT, @accumelig OUTPUT, @ytdamt OUTPUT, @ytdelig OUTPUT, @errmsg OUTPUT
		IF @rcode <> 0 GOTO bspexit
		END

	/* Calculations */
	SELECT @calcamt = 0.00, @eligamt = 0.00, @liabdistbasis = 0.00, @hrs = 0.00
 
 
	/* Flat Amount */
	IF @method = 'A'
		BEGIN
		SELECT @rate = @oldrate, @calcbasis = @oldcalcbasis
		IF @prenddate >= @effectdate SELECT @rate = @newrate, @calcbasis = @newcalcbasis
		IF @overrate is not null SELECT @rate = @overrate	-- capped rates do not apply to flat amounts so use override
		EXEC @rcode = bspPRProcessAmount @calcbasis, @rate, @limitbasis, @limitamt, @limitcorrect, @accumelig,
		@accumsubj, @accumamt, @ytdelig, @ytdamt, @calcamt OUTPUT, @eligamt OUTPUT, @errmsg OUTPUT
		IF @rcode<> 0 GOTO bspexit
		
		-- UPDATE Craft Accumulation Rate Detail - use 0.00 rate
		UPDATE dbo.bPRCX SET Basis = Basis + @calcbasis, Amt = Amt + @calcamt
		WHERE PRCo = @prco 
			AND PRGroup = @prgroup 
			AND PREndDate = @prenddate 
			AND Employee = @employee
			AND PaySeq = @payseq 
			AND Craft = @cacraft 
			AND Class = @class 
			AND EDLType = @dltype
			AND EDLCode = @dlcode 
			AND Rate = 0.00
		IF @@rowcount = 0
		INSERT dbo.bPRCX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Rate, Basis, Amt)
		VALUES(@prco, @prgroup, @prenddate, @employee, @payseq, @cacraft, @class,
			@dltype, @dlcode, 0,@calcbasis, @calcamt)
			
		-- calculate basis for liability distribution
		SELECT @liabdistbasis = @oldliabbasis + @newliabbasis
		END
 
 
	-- Rate per Day, Factored Rate per Hour, Rate of Gross, Rate per Hour, Straight Time Equivalent, or Rate of Dedn
	IF @method in ('D', 'F', 'G', 'H', 'S', 'DN')
		BEGIN
		SELECT @oldcalcamt = 0.00, @newcalcamt = 0.00, @oldeligamt = 0.00, @neweligamt = 0.00
		IF @oldcalcbasis <> 0.00
			BEGIN
			EXEC @rcode = bspPRProcessRateBased @oldcalcbasis, @oldrate, @limitbasis, @limitamt,
			@ytdcorrect, @limitcorrect, @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt,
			@accumbasis, @limitrate, @outaccumbasis OUTPUT, --issue 11030 adjust for changes in bspPRProcessRateBased
			@calcamt=@oldcalcamt OUTPUT, @eligamt=@oldeligamt OUTPUT, @errmsg=@errmsg OUTPUT
			IF @rcode <> 0 GOTO bspexit
			SELECT @accumbasis = @outaccumbasis --issue 11030 basis may be adjusted to fit rate of earnings limit scheme

			-- UPDATE Craft Accumulation Rate Detail - use old rate
			UPDATE dbo.bPRCX SET Basis = Basis + @oldcalcbasis, Amt = Amt + @oldcalcamt
			WHERE PRCo = @prco 
				AND PRGroup = @prgroup 
				AND PREndDate = @prenddate 
				AND Employee = @employee
				AND PaySeq = @payseq 
				AND Craft = @cacraft 
				AND Class = @class 
				AND EDLType = @dltype
				AND EDLCode = @dlcode 
				AND Rate = @oldrate
			IF @@rowcount = 0
			INSERT dbo.bPRCX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Rate, Basis, Amt)
			VALUES(@prco, @prgroup, @prenddate, @employee, @payseq, @cacraft, @class,
			@dltype, @dlcode, @oldrate, @oldcalcbasis, @oldcalcamt)

			-- adjust amounts for calculations at new rate
			SELECT @accumelig = @accumelig + @oldeligamt, @accumsubj = @accumsubj + @oldcalcbasis
			SELECT @accumamt = @accumamt + @oldcalcamt, @ytdelig = @ytdelig + @oldeligamt
			SELECT @ytdamt = @ytdamt + @oldcalcamt
			END
			
		IF @newcalcbasis <> 0.00
			BEGIN
			EXEC @rcode = bspPRProcessRateBased @newcalcbasis, @newrate, @limitbasis, @limitamt,
			@ytdcorrect, @limitcorrect, @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt,
			@accumbasis, @limitrate, @outaccumbasis OUTPUT, --issue 11030 adjust for changes in bspPRProcessRateBased
			@calcamt=@newcalcamt OUTPUT, @eligamt=@neweligamt OUTPUT, @errmsg=@errmsg OUTPUT
			IF @rcode <> 0 GOTO bspexit
			SELECT @accumbasis = @outaccumbasis --issue 11030 basis may be adjusted to fit rate of earnings limit scheme

			-- UPDATE Craft Accumulation Rate Detail - use new rate
			UPDATE dbo.bPRCX SET Basis = Basis + @newcalcbasis, Amt = Amt + @newcalcamt
			WHERE PRCo = @prco 
				AND PRGroup = @prgroup 
				AND PREndDate = @prenddate 
				AND Employee = @employee
				AND PaySeq = @payseq 
				AND Craft = @cacraft 
				AND Class = @class 
				AND EDLType = @dltype
				AND EDLCode = @dlcode 
				AND Rate = @newrate
			IF @@rowcount = 0
			INSERT dbo.bPRCX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Rate, Basis, Amt)
			VALUES(@prco, @prgroup, @prenddate, @employee, @payseq, @cacraft, @class,
			@dltype, @dlcode, @newrate, @newcalcbasis, @newcalcamt)
			END
		-- accumulate calulcated, eligible, AND liability distibution basis amounts
		SELECT @calcamt = @oldcalcamt + @newcalcamt, @eligamt = @oldeligamt + @neweligamt
		SELECT @calcbasis = @oldcalcbasis + @newcalcbasis
		SELECT @liabdistbasis = (@oldliabbasis * @oldrate) + (@newliabbasis * @newrate)
		END
 
	-- Variable Rate per Hour
	IF @method = 'V'
		BEGIN
		-- create cursor by Earnings Factor
		DECLARE bcFactor cursor for
		SELECT distinct e.Factor
		FROM dbo.bPRPE e WITH (NOLOCK)
			JOIN dbo.bPRDB b WITH (NOLOCK) ON b.EDLCode = e.EarnCode
		WHERE e.VPUserName = SUSER_SNAME() 
			AND b.PRCo = @prco 
			AND b.DLCode = @dlcode 
			AND b.SubjectOnly = 'N'
		ORDER BY e.Factor

		-- OPEN Factor cursor
		OPEN bcFactor
		SELECT @openFactor = 1
 
		next_Factor: -- loop through each Factor
			FETCH NEXT FROM bcFactor INTO @factor
			IF @@fetch_status = -1 GOTO END_Factor
			IF @@fetch_status <> 0 GOTO next_Factor

			-- get old AND new rates - check for overrides
			SELECT @oldrate = 0.00, @newrate = 0.00
			SELECT @oldrate = OldRate, @newrate = NewRate
			FROM dbo.bPRCI WITH (NOLOCK) -- Craft Items
			WHERE PRCo = @prco 
				AND Craft = @craft 
				AND EDLType = @dltype 
				AND EDLCode = @dlcode 
				AND Factor = @factor
			SELECT @oldrate = OldRate, @newrate = NewRate
			FROM dbo.bPRCD WITH (NOLOCK) -- Class Dedns/Liabs
			WHERE PRCo = @prco 
				AND Craft = @craft 
				AND Class = @class 
				AND DLCode = @dlcode 
				AND Factor = @factor
			SELECT @oldrate = OldRate, @newrate = NewRate
			FROM dbo.bPRTI WITH (NOLOCK) -- Template Items
			WHERE PRCo = @prco 
				AND Craft = @craft 
				AND Template = @template 
				AND EDLType= @dltype 
				AND EDLCode = @dlcode 
				AND Factor = @factor
			SELECT @oldrate = OldRate, @newrate = NewRate
			FROM dbo.bPRTD WITH (NOLOCK) -- Template Dedns/Liabs
			WHERE PRCo = @prco 
				AND Craft = @craft 
				AND Class = @class 
				AND Template = @template 
				AND DLCode = @dlcode 
				AND Factor = @factor

			-- check for Employee override rate
			IF @overrate is not null SELECT @oldrate = @overrate, @newrate = @overrate 
 
			-- get old AND new basis for earnings with this Factor
			SELECT @oldcalcbasis = isnull(sum(e.Hours),0.00)
			FROM dbo.bPRPE e WITH (NOLOCK)
				JOIN dbo.bPRDB b WITH (NOLOCK) ON b.EDLCode = e.EarnCode
			WHERE VPUserName = SUSER_SNAME() 
				AND e.Factor = @factor 
				AND b.PRCo = @prco 
				AND b.DLCode = @dlcode
				AND b.SubjectOnly = 'N' 
				AND e.PostDate < @effectdate

			-- new rate calculation basis - excludes 'Subject ONly' earnings
			SELECT @newcalcbasis = isnull(sum(e.Hours),0.00)
			FROM dbo.bPRPE e WITH (NOLOCK)
				JOIN dbo.bPRDB b WITH (NOLOCK) ON b.EDLCode = e.EarnCode
			WHERE VPUserName = SUSER_SNAME() 
				AND e.Factor = @factor 
				AND b.PRCo = @prco 
				AND b.DLCode = @dlcode
				AND b.SubjectOnly = 'N' 
				AND e.PostDate >= @effectdate
 
			-- liability distribution basis
			IF @dltype = 'L'
				BEGIN
				SELECT @oldliabbasis = @oldcalcbasis, @newliabbasis = @newcalcbasis -- default to calculation basis
				
				-- old basis excludes earnings WHERE IncldLiabDist<>'Y'
				SELECT @oldliabbasis = isnull(sum(e.Hours),0.00)
				FROM dbo.bPRPE e WITH (NOLOCK)
					JOIN dbo.bPRDB b WITH (NOLOCK) ON b.EDLCode = e.EarnCode
				WHERE VPUserName = SUSER_SNAME() 
					AND e.Factor = @factor 
					AND b.PRCo = @prco 
					AND b.DLCode = @dlcode
					AND b.SubjectOnly = 'N' 
					AND e.IncldLiabDist='Y' 
					AND e.PostDate < @effectdate --issue 20562
				
				-- new basis excludes earnings WHERE IncldLiabDist<>'Y'
				SELECT @newliabbasis = isnull(sum(e.Hours),0.00)
				FROM dbo.bPRPE e WITH (NOLOCK)
					JOIN dbo.bPRDB b WITH (NOLOCK) ON b.EDLCode = e.EarnCode
				WHERE VPUserName = SUSER_SNAME() 
					AND e.Factor = @factor 
					AND b.PRCo = @prco 
					AND b.DLCode = @dlcode
					AND b.SubjectOnly = 'N' 
					AND e.IncldLiabDist='Y' 
					AND e.PostDate >= @effectdate --issue 20562
				END
			-- perform calculations
			SELECT @oldcalcamt = 0.00, @newcalcamt = 0.00, @oldeligamt = 0.00, @neweligamt = 0.00
			IF @oldcalcbasis <> 0.00
				BEGIN
				EXEC @rcode = bspPRProcessRateBased @oldcalcbasis, @oldrate, @limitbasis, @limitamt,
					@ytdcorrect, @limitcorrect, @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt,
					0,0,0, --issue 11030 adjust for changes in bspPRProcessRateBased

				@calcamt=@oldcalcamt OUTPUT, @eligamt=@oldeligamt OUTPUT, @errmsg=@errmsg output
				IF @rcode <> 0 GOTO bspexit
				-- UPDATE Craft Accumulation Rate Detail - use old rate
				UPDATE dbo.bPRCX SET Basis = Basis + @oldcalcbasis, Amt = Amt + @oldcalcamt
				WHERE PRCo = @prco 
					AND PRGroup = @prgroup 
					AND PREndDate = @prenddate 
					AND Employee = @employee
					AND PaySeq = @payseq 
					AND Craft = @cacraft 
					AND Class = @class 
					AND EDLType = @dltype
					AND EDLCode = @dlcode 
					AND Rate = @oldrate
				IF @@rowcount = 0
				INSERT dbo.bPRCX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Rate, Basis, Amt)
				VALUES(@prco, @prgroup, @prenddate, @employee, @payseq, @cacraft, @class,
				@dltype, @dlcode, @oldrate, @oldcalcbasis, @oldcalcamt)

				-- adjust amounts for calculations at new rate
				SELECT @accumelig = @accumelig + @oldeligamt, @accumsubj = @accumsubj + @oldcalcbasis
				SELECT @accumamt = @accumamt + @oldcalcamt, @ytdelig = @ytdelig + @oldeligamt
				SELECT @ytdamt = @ytdamt + @oldcalcamt
				END
				
				IF @newcalcbasis <> 0.00
					BEGIN
					EXEC @rcode = bspPRProcessRateBased @newcalcbasis, @newrate, @limitbasis, @limitamt,
					@ytdcorrect, @limitcorrect, @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt,
					0,0,0, --issue 11030 adjust for changes in bspPRProcessRateBased
					@calcamt=@newcalcamt OUTPUT, @eligamt=@neweligamt OUTPUT, @errmsg=@errmsg output
					IF @rcode <> 0 GOTO bspexit
					-- UPDATE Craft Accumulation Rate Detail - use new rate
					UPDATE dbo.bPRCX SET Basis = Basis + @newcalcbasis, Amt = Amt + @newcalcamt
					WHERE PRCo = @prco 
						AND PRGroup = @prgroup 
						AND PREndDate = @prenddate 
						AND Employee = @employee
						AND PaySeq = @payseq 
						AND Craft = @cacraft 
						AND Class = @class 
						AND EDLType = @dltype
						AND EDLCode = @dlcode 
						AND Rate = @newrate
					IF @@rowcount = 0
					INSERT dbo.bPRCX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Rate, Basis, Amt)
					values(@prco, @prgroup, @prenddate, @employee, @payseq, @cacraft, @class,
					@dltype, @dlcode, @newrate, @newcalcbasis, @newcalcamt)
					-- adjust amounts for calculations at next Factor
					SELECT @accumelig = @accumelig + @oldeligamt, @accumsubj = @accumsubj + @oldcalcbasis
					SELECT @accumamt = @accumamt + @oldcalcamt, @ytdelig = @ytdelig + @oldeligamt
					SELECT @ytdamt = @ytdamt + @oldcalcamt
					END
 
			-- accumulate calculated, eligible, AND liability distribution basis amounts
			SELECT @calcamt = @calcamt + @oldcalcamt + @newcalcamt, @eligamt = @eligamt + @oldeligamt + @neweligamt
			SELECT @liabdistbasis = @liabdistbasis + (@oldliabbasis * @oldrate) + (@newliabbasis * @newrate)

			GOTO next_Factor

		END_Factor:
		
		CLOSE bcFactor
		DEALLOCATE bcFactor
		SELECT @openFactor = 0
		END

	-- Routine
	IF @method = 'R'
		BEGIN
		-- get procedure name
		SELECT @procname = null
		SELECT @procname = ProcName, @miscamt1 = MiscAmt1, @miscamt2 = MiscAmt2, @miscamt3 = MiscAmt3 --issue 21186 - misc amts needed for Benefit based ON day of week calculations
		FROM dbo.bPRRM WITH (NOLOCK) 
		WHERE PRCo = @prco 
			AND Routine = @routine
		
		IF @procname is null
			BEGIN
			SELECT @errmsg = 'Missing Routine procedure name for dedn/liab ' + convert(varchar(4),@dlcode), @rcode = 1
			GOTO bspexit
			END

		IF not exists(SELECT 1 FROM sysobjects WHERE name = @procname AND type = 'P')
			BEGIN
			SELECT @errmsg = 'Invalid Routine procedure - ' + @procname, @rcode = 1
			GOTO bspexit
			END
	 
		SELECT @calcbasis = @oldcalcbasis + @newcalcbasis

		IF @procname like 'bspPRHrLimit%'	-- Iron Workers special deduction (rate of gross, limit ON hrs)
			BEGIN
			IF @prenddate >= @effectdate SELECT @rate = @newrate --rate based ON PR END Date
			IF @overrate is not null SELECT @rate = @overrate -- allow rate override by Employee

			EXEC @rcode = @procname @prco, @prgroup, @prenddate, @employee, @payseq, @dltype, @dlcode, @rate, @limitamt,
			@calcamt OUTPUT, @eligamt OUTPUT, @hrs OUTPUT, @errmsg output
			-- please put no code between EXEC AND @@error check!
			IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
			IF @rcode <> 0 GOTO bspexit

			SELECT @hrs=isnull(@hrs,0.00), @calcamt=isnull(@calcamt,0.00), @eligamt=isnull(@eligamt,0.00)
 
			-- UPDATE Craft Accumulation Rate detail - use rate
			UPDATE dbo.bPRCX SET Basis = Basis + @calcbasis, Amt = Amt + @calcamt
			WHERE PRCo = @prco 
				AND PRGroup = @prgroup 
				AND PREndDate = @prenddate 
				AND Employee = @employee
				AND PaySeq = @payseq 
				AND Craft = @cacraft 
				AND Class = @class 
				AND EDLType = @dltype
				AND EDLCode = @dlcode 
				AND Rate = @rate
			IF @@rowcount = 0
			INSERT dbo.bPRCX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Rate, Basis, Amt)
			values(@prco, @prgroup, @prenddate, @employee, @payseq, @cacraft, @class,
				@dltype, @dlcode, @rate, @calcbasis, @calcamt)
			GOTO skip_PRCX_update
			END
 
		-- issue 21186 - Benefit based ON day of week
		IF @procname like 'bspPRDailyBen%' -- Benefit based ON day of week
			BEGIN
			EXEC @rcode = @procname @prco, @prgroup, @prenddate, @craft, @miscamt1, @miscamt2, 
				@miscamt3, @calcamt OUTPUT, @errmsg output
			-- please put no code between EXEC AND @@error check!
			IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
			IF @rcode <> 0 GOTO bspexit
			GOTO routine_end
			END
 
		-- issue 24545
		IF @procname = 'bspPRExemptRateOfGross' -- rate of gross with exemption ... tax calculation withheld until subject amount reaches exemption limit
			BEGIN
			EXEC @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
				@dlcode, @dltype, 'A', @limitmth, 'N', @accumamt OUTPUT,
				@accumsubj OUTPUT, @accumelig OUTPUT, @ytdamt OUTPUT, @ytdelig OUTPUT, @errmsg output
			-- please put no code between EXEC AND @@error check!
			IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
			IF @rcode <> 0 GOTO bspexit

			SELECT @rate = @oldrate, @calcbasis = @oldcalcbasis
			IF @prenddate >= @effectdate SELECT @rate = @newrate, @calcbasis = @newcalcbasis
			IF @overrate is not null SELECT @rate = @overrate

			SELECT @exemptamt = MiscAmt1 FROM dbo.bPRRM WITH (NOLOCK) WHERE PRCo = @prco AND Routine = @routine

			EXEC @rcode = @procname @calcbasis, @rate, @accumsubj, @accumelig, @exemptamt, @calcamt OUTPUT, @eligamt OUTPUT, @errmsg output
			-- please put no code between EXEC AND @@error check!
			IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
			IF @rcode <> 0 GOTO bspexit --28379 IF error, abort
			SELECT @calcbasis = @eligamt
			GOTO routine_end
			END


		IF @procname = 'bspPRUnionDeduction'
			BEGIN
			SELECT @rate = @oldrate, @calcbasis = @oldcalcbasis
			IF @prenddate >= @effectdate SELECT @rate = @newrate, @calcbasis = @newcalcbasis
			IF @overrate is not null SELECT @rate = @overrate
			EXEC @rcode = @procname @prco, @prgroup, @prenddate, @employee, @payseq,
				 @cacraft, @class, @rate, @calcbasis, @calcamt OUTPUT, @eligamt OUTPUT, @errmsg output
			-- please put no code between EXEC AND @@error check!
			IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
			IF @rcode <> 0 GOTO bspexit --28379 IF error, abort
			SELECT @calcbasis = @eligamt
			GOTO routine_end
			END

 
		-- call Routine procedure
		EXEC @rcode = @procname @calcbasis, @calcamt OUTPUT, @errmsg output
		-- please put no code between EXEC AND @@error check!
		IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
		IF @rcode <> 0 GOTO bspexit

		IF @calcamt is null SELECT @calcamt = 0.00

		routine_end: 
		-- UPDATE Craft Accumulation Rate detail - use 0.00 rate
		UPDATE dbo.bPRCX SET Basis = Basis + @calcbasis, Amt = Amt + @calcamt
		WHERE PRCo = @prco 
			AND PRGroup = @prgroup 
			AND PREndDate = @prenddate 
			AND Employee = @employee
			AND PaySeq = @payseq 
			AND Craft = @cacraft 
			AND Class = @class 
			AND EDLType = @dltype
			AND EDLCode = @dlcode 
			AND Rate = 0.00
		IF @@rowcount = 0
		INSERT dbo.bPRCX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Rate, Basis, Amt)
		values(@prco, @prgroup, @prenddate, @employee, @payseq, @cacraft, @class,
			@dltype, @dlcode, 0.00, @calcbasis, @calcamt)

		SELECT @eligamt = @calcbasis

		skip_PRCX_update:
		-- calculate basis for liability distribution
		SELECT @liabdistbasis = @oldliabbasis + @newliabbasis
		END
 
	-- apply Employee calculation override amount
	IF @overcalcs = 'A' SELECT @calcamt = @emprateamt

	-- apply Employee addon amounts - ONly applied IF calculated amount is positive
	IF @calcamt > 0.00
		BEGIN
		IF @addontype = 'A' SELECT @calcamt = @calcamt + @addonrateamt
		IF @addontype = 'R' SELECT @calcamt = @calcamt + (@calcbasis * @addonrateamt)
		END

	IF @rndtodollar = 'Y' SELECT @calcamt = ROUND(@calcamt,0) --round nearest dollar
 
	calc_end:	 -- Finished with calculations
	-- get AP Vendor AND Transaction description
	SELECT @dtvendorgroup = null, @dtvendor = null, @dtAPdesc = null
	IF @autoAP = 'Y'
		BEGIN
		SELECT @dtvendorgroup = @vendorgroup, @dtvendor = @vendor, @dtAPdesc = @dldesc
		-- #20340 - use bPRDL Vendor as fall back IF not setup by Craft
		IF @dtvendorgroup is null or @dtvendor is null SELECT @dtvendorgroup = @dlvendorgroup, @dtvendor = @dlvendor
		IF @empvendor is not null SELECT @dtvendor = @empvendor
		IF @apdesc is not null SELECT @dtAPdesc = @apdesc
		END
 
	-- UPDATE Payment Sequence Totals
	UPDATE dbo.bPRDT
	SET Hours = isnull(Hours,0.00) + isnull(@hrs,0.00),
		Amount = Amount + @calcamt, SubjectAmt = SubjectAmt + @accumbasis, EligibleAmt = EligibleAmt + @eligamt,
		VendorGroup = @dtvendorgroup, Vendor = @dtvendor, APDesc = @dtAPdesc
	WHERE PRCo = @prco 
		AND PRGroup = @prgroup 
		AND PREndDate = @prenddate 
		AND Employee = @employee
		AND PaySeq = @payseq 
		AND EDLType = @dltype 
		AND EDLCode = @dlcode
	IF @@rowcount = 0
	BEGIN
	INSERT dbo.bPRDT (PRCo, PRGroup, PREndDate, Employee, PaySeq, EDLType, EDLCode, Hours, Amount, SubjectAmt, EligibleAmt,
		UseOver, OverAmt, OverProcess, VendorGroup, Vendor, APDesc, OldHours, OldAmt, OldSubject, OldEligible, OldMth,
		OldVendor, OldAPMth, OldAPAmt)
	values (@prco, @prgroup, @prenddate, @employee, @payseq, @dltype, @dlcode, isnull(@hrs,0.00), @calcamt, @accumbasis, @eligamt,
	'N', 0, 'N', @dtvendorgroup, @dtvendor, @dtAPdesc, 0, 0, 0, 0, null, null, null, 0)
	IF @@rowcount <> 1
		BEGIN
		SELECT @errmsg = 'Unable to add PR Detail Entry for Employee ' + convert(varchar(6),@employee), @rcode = 1
		GOTO bspexit
		END
		END
 
	-- check for Override processing
	SELECT @useover = UseOver, @overamt = OverAmt, @overprocess = OverProcess
	FROM dbo.bPRDT WITH (NOLOCK)
	WHERE PRCo = @prco 
		AND PRGroup = @prgroup 
		AND PREndDate = @prenddate 
		AND Employee = @employee
		AND PaySeq = @payseq 
		AND EDLType = @dltype 
		AND EDLCode = @dlcode

	-- always UPDATE Craft Accumulations Basis
	UPDATE dbo.bPRCA
	SET Basis = Basis + @accumbasis, EligibleAmt = EligibleAmt + @eligamt, VendorGroup = @dtvendorgroup,
	Vendor = @dtvendor, APDesc = @dtAPdesc
	WHERE PRCo = @prco 
		AND PRGroup = @prgroup 
		AND PREndDate = @prenddate 
		AND Employee = @employee
		AND PaySeq = @payseq 
		AND Craft = @cacraft 
		AND Class = @class 
		AND EDLType = @dltype 
		AND EDLCode = @dlcode
	IF @@rowcount = 0
	INSERT dbo.bPRCA (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, EDLType, EDLCode, Basis, Amt,
		EligibleAmt, VendorGroup, Vendor, APDesc)
	VALUES(@prco, @prgroup, @prenddate, @employee, @payseq, @cacraft, @class,
		@dltype, @dlcode, @accumbasis, 0, @eligamt, @dtvendorgroup, @dtvendor, @dtAPdesc)
	-- IF DL amount is not overridden or override has not yet been processed UPDATE Craft Accum Amount
	IF @useover = 'N' or @overprocess = 'N'
		BEGIN
		UPDATE dbo.bPRCA
		SET Amt = Amt + CASE @useover WHEN 'Y' THEN @overamt ELSE @calcamt END
		WHERE PRCo = @prco 
			AND PRGroup = @prgroup 
			AND PREndDate = @prenddate 
			AND Employee = @employee
			AND PaySeq = @payseq 
			AND Craft = @cacraft 
			AND Class = @class 
			AND EDLType = @dltype 
			AND EDLCode = @dlcode
		IF @@rowcount <> 1
			BEGIN
			SELECT @errmsg = 'Unable to UPDATE PR Craft Accums for Employee ' + convert(varchar(6),@employee), @rcode = 1
			GOTO bspexit
			END
		END

	-- an overridden DL amount is processed ONly ONce
	IF @overprocess = 'Y' GOTO bspexit
 
	IF @useover = 'Y'
		BEGIN

		UPDATE dbo.bPRDT
		SET OverProcess = 'Y'
		WHERE PRCo = @prco 
			AND PRGroup = @prgroup 
			AND PREndDate = @prenddate
			AND Employee = @employee 
			AND PaySeq = @payseq 
			AND EDLType = @dltype 
			AND EDLCode = @dlcode
		END

	-- check for Liability distribution - needed even IF basis and/or amount are 0.00
	IF @dltype <> 'L' GOTO bspexit

	-- use calculated amount unless overridden
	SELECT @amt2dist = @calcamt
	IF @useover = 'Y' SELECT @amt2dist = @overamt

	-- no need to distribute IF Basis <> 0 AND Amt = 0, but will distibute IF both are 0.00
	-- because of possible offsetting timecard entries
	IF @calcbasis <> 0.00 AND @amt2dist = 0.00 GOTO bspexit

	-- call procedure to distribute liability amount
	EXEC @rcode = bspPRProcessCraftLiabDist @prco, @prgroup, @prenddate, @employee, @payseq, @craft, @class,
		@template, @dlcode, @method, @liabdistbasis, @amt2dist, @oldrate, --issue 20562
		@newrate, @effectdate, @overrate, @posttoall, @errmsg output
 

 
bspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessCraftDednLiabCalc] TO [public]
GO
