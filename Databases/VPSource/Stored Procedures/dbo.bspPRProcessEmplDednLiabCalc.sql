
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPRProcessEmplDednLiabCalc]
/***********************************************************
* CREATED BY:	CHS		10/27/2010
* MODIFIED BY:	MV/DS	07/09/2013	TFS-#49141 superweeklymin
*				MV		07/31/2013	TFS-#57603 - Routine bspPR_AU_SuperWithMin
*			 KK/EN		08/12/2013  54576 Added parameters PreTaxGroup and PreTaxCatchUpYN, and added code to calculate eligible amount 
*										  with PreTaxGroup limits for pre-tax deductions and Catch up eligible amount and calc amount
*			 KK/EN		9/25/2013	62590/62839 Error during PR Payroll Process when employees have a fixed DL amount override
*
* USAGE:
* Calculates Employee based deductions AND liabilities for a SELECT Employee AND Pay Seq.
* Generates Direct Deposit distibutions IF Employee Pay Seq to be paid by EFT.
* Called FROM main bspPRProcess procedure.
*
* INPUT PARAMETERS
* @prco	 PR Company
* @dlcode bEDLCode
* @prgroup	PR Group
* @prenddate	PR END ing Date
* @employee	Employee to process
* @payseq	Payment Sequence #
* @ppds # of pay periods in a year
* @limitmth Pay Period limit month
* @stddays standard # of days in Pay Period
* @bonus indicates a Bonus Pay Sequence - Y or N
* @posttoall earnings posted to all days in Pay Period - Y or N
* @accumbeginmth bMonth
* @accumendmth bMonth
* @PreTaxGroup tinyint
* @PreTaxCatchUpYN bYN
*
* OUTPUT PARAMETERS
* @calcamt bDollar, @errmsg 	Error message IF something went wrong
*
* RETURN VALUE
* 0 success
* 1 fail
*****************************************************/
@prco bCompany, @dlcode bEDLCode, @prgroup bGroup, @prenddate bDate, @employee bEmployee, 
@payseq tinyint, @ppds tinyint, @limitmth bMonth, @stddays tinyint, @bonus bYN, @posttoall bYN, 
@accumbeginmth bMonth, @accumendmth bMonth, @PreTaxGroup tinyint, @PreTaxCatchUpYN bYN,  
@calcamt bDollar OUTPUT, @errmsg varchar(255) OUTPUT
 
 AS
 SET NOCOUNT ON 
 
DECLARE @rcode int, @rate bUnitCost, --@calcamt bDollar, 
	@procname varchar(30), @eligamt bDollar,
	@amt2dist bDollar, @accumelig bDollar, @accumsubj bDollar, @accumamt bDollar, @ytdelig bDollar,
	@ytdamt bDollar, @calcbasis bDollar, @accumbasis bDollar, @postseq smallint,
	@liabbasis bDollar,	@accurcalc float, @exemptamt bDollar, @DednGroupLimit bDollar, @limitMinusYTDAccum bDollar
 
-- Standard deduction/liability variables
DECLARE @dldesc bDesc, @dltype char(1), @method varchar(10), @routine varchar(10),
	@seq1only bYN, @ytdcorrect bYN, @bonusover bYN, @bonusrate bRate, @limitbasis char(1), 
	@limitrate bRate, @empllimitrate bRate, @limitamt bDollar, @limitperiod char(1), 
	@limitcorrect bYN, @autoAP bYN, @vendorgroup bGroup, @vendor bVendor, @apdesc bDesc,
	@netpayopt char(1), @minnetpay bDollar, @preaaccums bDollar, @prdtcurr bDollar, @prdtold bDollar,
	@prdtoldbackout bDollar, @calccategory varchar(1), @rndtodollar bYN, 
	@outaccumbasis bDollar, @workstate varchar(4) 
 
-- Employee deduction/liability override variables
DECLARE @filestatus char(1), @regexempts tinyint, @overcalcs char(1), @emprateamt bUnitCost, 
	@overlimit bYN, @emplimit bDollar, @addontype char(1), @addonrateamt bDollar, @empvendor bVendor
 
-- Payment Sequence Total variables
DECLARE @dtvendorgroup bGroup, @dtvendor bVendor, @dtAPdesc bDesc, @useover bYN, @overprocess bYN, @overamt bDollar
 
-- Direct Depost variables
DECLARE @earns bDollar, @dedns bDollar
 
-- Garnishment Allocation variables
DECLARE @disposable bDollar, @dedncode bEDLCode, @dednamt bDollar, @numallocs tinyint, @allocgroup tinyint
 
	-- get standard DL info
	SELECT @dldesc = Description, @dltype = DLType, @method = Method, @routine = Routine,
		@rate = RateAmt1, @seq1only = SeqOneOnly, @ytdcorrect = YTDCorrect, @bonusover = BonusOverride,
		@bonusrate = BonusRate, @limitbasis = LimitBasis, @limitamt = LimitAmt, @limitperiod = LimitPeriod,
		@limitcorrect = LimitCorrect, @autoAP = AutoAP, @vendorgroup = VendorGroup, @vendor = Vendor,
		@calccategory = CalcCategory, @rndtodollar=RndToDollar, @limitrate = LimitRate /*issue 11030*/
	FROM dbo.bPRDL WITH (NOLOCK)
	WHERE PRCo = @prco AND DLCode = @dlcode
	IF @@rowcount = 0
		BEGIN
		SELECT @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' not setup!', @rcode = 1
		GOTO bspexit
		END
 
	IF @calccategory not in('E','A')
		BEGIN
		SELECT @errmsg = 'Dedn/liab code:' + convert(varchar(4),@dlcode) + ' should be calculation category E or A!', @rcode = 1
		GOTO bspexit
		END
 
 	 -- check for Payment Sequence #1 restriction
	 IF @seq1only = 'Y' AND @payseq <> 1 GOTO bspexit
 
	-- get Employee info AND overrides for this dedn/liab
	SELECT @filestatus = e.FileStatus, @regexempts = e.RegExempts, @empvendor = e.Vendor, @apdesc = e.APDesc,
		@overcalcs = e.OverCalcs, @emprateamt = isnull(e.RateAmt,0.00), @overlimit = e.OverLimit, @emplimit = isnull(e.Limit,0.00),
		@netpayopt = e.NetPayOpt, @minnetpay = e.MinNetPay, @addontype = e.AddonType, @addonrateamt = isnull(e.AddonRateAmt,0.00),
		@empllimitrate = isnull(e.LimitRate,0.00) /*issue 11030*/
	FROM dbo.bPRED e WITH (NOLOCK)
		JOIN dbo.bPRAF f WITH (NOLOCK) ON f.PRCo = e.PRCo AND f.Frequency = e.Frequency
	WHERE e.PRCo = @prco 
		AND e.Employee = @employee 
		AND e.DLCode = @dlcode 
		and	f.PRGroup = @prgroup 
		AND f.PREndDate = @prenddate
 
	-- check for calculation override ON Bonus sequence
	IF @bonus = 'Y' AND @bonusover = 'Y' SELECT @method = 'G', @rate = @bonusrate

	-- check for Employee calculation AND rate overrides
	IF @overcalcs = 'M' SELECT @method = 'G', @rate = @emprateamt
	IF @overcalcs = 'R' SELECT @rate = @emprateamt
	IF @overlimit = 'Y' SELECT @limitamt = @emplimit
	IF @overlimit = 'Y' SELECT @limitrate = @empllimitrate /*issue 11030*/
 
	-- get calculation, accumulation, AND liability distribution basis
	EXEC @rcode = bspPRProcessGetBasis @prco, @prgroup, @prenddate, @employee, @payseq, @method,
		@posttoall, @dlcode, @dltype, @stddays, @calcbasis OUTPUT, @accumbasis OUTPUT, --issue 20562
		@liabbasis OUTPUT, @errmsg OUTPUT
	IF @rcode <> 0 GOTO bspexit
 
	-- check for 0 basis - skip accumulations AND calculations
	IF @calcbasis = 0.00
		BEGIN
		SELECT @calcamt = 0.00, @eligamt = 0.00
		goto calc_end
		END 
 
	-- accumulate actual, subject, AND eligible amounts IF needed
	IF @limitbasis = 'C' or @limitbasis = 'S' or @ytdcorrect = 'Y' 
		BEGIN
		EXEC @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
		@dlcode, @dltype, @limitperiod, @limitmth, @ytdcorrect, @accumamt OUTPUT,
		@accumsubj OUTPUT, @accumelig OUTPUT, @ytdamt OUTPUT, @ytdelig OUTPUT, @errmsg OUTPUT
		IF @rcode <> 0 GOTO bspexit
		END
 
	-- Calculations
	SELECT @calcamt = 0.00, @eligamt = 0.00
 
	-- Flat Amount
	IF @method = 'A'
		BEGIN
		EXEC @rcode = bspPRProcessAmount @calcbasis, @rate, @limitbasis, @limitamt, @limitcorrect, @accumelig,
			@accumsubj, @accumamt, @ytdelig, @ytdamt, @calcamt OUTPUT, @eligamt OUTPUT, @errmsg OUTPUT
			IF @rcode<> 0 GOTO bspexit
		END 
 
	-- Rate per Day, Factored Rate per Hour, Rate of Gross, Rate per Hour, Straight Time Equivalent, or Rate of Dedn
	IF @method in ('D', 'F', 'G', 'H', 'S', 'DN')
	BEGIN
		EXEC @rcode = bspPRProcessRateBased @calcbasis, @rate, @limitbasis, @limitamt,
			@ytdcorrect, @limitcorrect, @accumelig, @accumsubj, @accumamt, @ytdelig, @ytdamt, 
			@accumbasis, @limitrate, @outaccumbasis OUTPUT, @calcamt OUTPUT, @eligamt OUTPUT, @errmsg OUTPUT
		--issue 11030 pass in @accumbasis AND @limitrate AND return @outaccumbasis (possibly adjusted basis amount)
		IF @rcode <> 0 GOTO bspexit
		
		-- Computing eligible PreTax deduction and eligible/calculated amounts for catchup with an annual limit
		IF @PreTaxGroup IS NOT NULL AND @rate <> 0
		BEGIN
			-- Assuming that the limit is Annual for Pretax Deductions and CatchUp
			EXEC @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
										@dlcode, @dltype, 'A', @limitmth, @ytdcorrect, 
										@accumamt OUTPUT, @accumsubj OUTPUT, @accumelig OUTPUT, 
										@ytdamt OUTPUT, @ytdelig OUTPUT, @errmsg OUTPUT
			IF @rcode <> 0 GOTO bspexit
			
			IF @PreTaxCatchUpYN = 'N'
			BEGIN
				-- Get the limit amount for this deduction group 
				SELECT @DednGroupLimit = AnnualLimit 
				FROM dbo.bPRDeductionGroup
				WHERE PRCo = @prco AND DednGroup = @PreTaxGroup
		
				SELECT @limitMinusYTDAccum = (@DednGroupLimit / @rate) - @accumelig 
				
				IF @limitMinusYTDAccum < @calcbasis SELECT @eligamt = @limitMinusYTDAccum
			END
			ELSE
			BEGIN -- @PreTaxCatchUpYN = 'Y' (SUM of all elig amounts where PreTaxGroup in catchUp PreTaxGroup)
				SELECT @eligamt = @calcbasis - (SELECT SUM(dt.EligibleAmt) 
													FROM dbo.bPRDT dt
													JOIN dbo.bPRDL dl
													  ON dt.PRCo = dl.PRCo 
													 AND dt.EDLCode = dl.DLCode 
												   WHERE dl.PreTaxGroup IS NOT NULL
												     AND dt.PRCo = @prco 
													 AND dt.Employee = @employee
													 AND dt.PRGroup = @prgroup 
													 AND dt.PREndDate = @prenddate)
				SELECT  @calcamt = @eligamt * @rate -- (This is assuming the method is "G" Rate of Gross)
				-- Apply the annual limit for the pretax catchup
				IF		@accumamt >= @limitamt			 SELECT @calcamt = 0, 
																@eligamt = 0
				ELSE IF @calcamt + @accumamt > @limitamt SELECT @calcamt = @limitamt - @accumamt, 
																@eligamt = @calcamt/@rate
				
				
			END
		END
				
		SELECT @accumbasis = @outaccumbasis --issue 11030 basis may be adjusted to fit rate of earnings limit scheme
	END 
 
	-- Routine 
	IF @method = 'R'
		BEGIN
		-- get procedure name
		SELECT @procname = null
		SELECT @procname = ProcName FROM dbo.bPRRM WITH (NOLOCK) WHERE PRCo = @prco AND Routine = @routine
		IF @procname is null
			BEGIN
			SELECT @errmsg = 'Missing Routine procedure name for dedn/liab ' + convert(varchar(4),@dlcode), @rcode = 1
			GOTO bspexit
			END
		IF NOT EXISTS(select * FROM sysobjects WHERE name = @procname AND type = 'P')
			BEGIN
			SELECT @errmsg = 'Invalid Routine procedure - ' + @procname + ' for dedn/liab ' + convert(varchar(4),@dlcode), @rcode = 1
			goto bspexit
			END 
	 
		IF @procname like 'bspPROST%'	-- Ohio School District Tax
			BEGIN
			EXEC @rcode = @procname @prco, @prgroup, @prenddate, @payseq, @employee, @ppds, @rate,
				@calcamt OUTPUT, @calcbasis OUTPUT, @accumbasis OUTPUT, @errmsg OUTPUT
			-- please put no code between exec AND @@error check!
			IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
			GOTO routine_end
			END

		IF @procname like 'bspPREIC%' -- Earned Income Credit
			BEGIN
			SELECT @preaaccums = isnull(sum(Amount),0.00)
			FROM dbo.bPREA WITH (NOLOCK) -- updated accumulations
			WHERE PRCo = @prco 
				AND Employee = @employee
				AND Mth between @accumbeginmth AND @accumendmth 
				AND EDLType = @dltype 
				AND EDLCode = @dlcode
 
			SELECT @prdtcurr = isnull(sum( case d.UseOver when 'Y' then d.OverAmt ELSE d.Amount END ),0.00)
			FROM dbo.bPRDT d WITH (NOLOCK)
				JOIN dbo.bPRSQ s WITH (NOLOCK) ON s.PRCo = d.PRCo AND s.PRGroup = d.PRGroup AND s.PREndDate = d.PREndDate
					AND s.Employee = d.Employee AND s.PaySeq = d.PaySeq
				JOIN dbo.bPRPC c WITH (NOLOCK) ON c.PRCo = d.PRCo AND c.PRGroup = d.PRGroup AND c.PREndDate = d.PREndDate
			WHERE d.PRCo = @prco 
				AND d.Employee = @employee
				AND d.EDLType = @dltype 
				AND d.EDLCode = @dlcode
				AND ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate AND d.PaySeq <= @payseq))
				AND c.LimitMth between @accumbeginmth AND @accumendmth 
				AND c.GLInterface = 'N'

			SELECT @prdtold = isnull(sum(OldAmt),0.00)
			FROM dbo.bPRDT d WITH (NOLOCK)
				JOIN dbo.bPRPC c WITH (NOLOCK) ON c.PRCo = d.PRCo AND c.PRGroup = d.PRGroup AND c.PREndDate = d.PREndDate
			WHERE d.PRCo = @prco 
				AND d.Employee = @employee 
				AND d.EDLType = @dltype 
				AND d.EDLCode = @dlcode
				AND ((d.PREndDate < @prenddate) or (d.PREndDate = @prenddate AND d.PaySeq < @payseq))
				AND d.OldMth between @accumbeginmth AND @accumendmth 
				AND c.GLInterface = 'N'

			SELECT @prdtoldbackout = isnull(sum(OldAmt),0.00)
			FROM dbo.bPRDT WITH (NOLOCK)
			WHERE PRCo = @prco 
				AND Employee = @employee 
				AND EDLType = @dltype 
				AND EDLCode = @dlcode
				AND (PREndDate > @prenddate or (PREndDate = @prenddate AND PaySeq >= @payseq))
				AND OldMth between @accumbeginmth 
				AND @accumendmth 

			SELECT @accumamt = @preaaccums + (@prdtcurr - @prdtold) - @prdtoldbackout

			EXEC @rcode = @procname @prco, @employee, @dlcode, @calcbasis, @ppds, @accumamt,
				@calcamt OUTPUT, @errmsg OUTPUT
			-- please put no code between exec AND @@error check!
			IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
			GOTO routine_end
			
			END 
 
		-- issue 24545
		IF @procname = 'bspPRExemptRateOfGross' -- rate of gross with exemption ... tax calculation withheld until subject amount reaches exemption limit
			BEGIN
			EXEC @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
				@dlcode, @dltype, 'A', @limitmth, 'N', @accumamt OUTPUT,
				@accumsubj OUTPUT, @accumelig OUTPUT, @ytdamt OUTPUT, @ytdelig OUTPUT, @errmsg OUTPUT
			IF @rcode <> 0 GOTO bspexit

			SELECT @exemptamt = MiscAmt1 FROM dbo.bPRRM WITH (NOLOCK) WHERE PRCo = @prco AND Routine = @routine

			EXEC @rcode = @procname @calcbasis, @rate, @accumsubj, @accumelig, @exemptamt, @calcamt OUTPUT, @eligamt OUTPUT, @errmsg OUTPUT
			-- please put no code between exec AND @@error check!
			IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
			SELECT @calcbasis = @eligamt
			GOTO routine_end
			END

		-- issue #133605 compute AUS Superannuation Guarantee
		IF @procname = 'bspPR_AU_SuperWithMin'
			BEGIN
				-- Monthly earnings eligibility test
				-- Get monthly minimum threshold
				SELECT @exemptamt = MiscAmt1 
				FROM dbo.bPRRM WITH (NOLOCK) 
				WHERE PRCo = @prco AND Routine = @routine

				-- Calculate 'expected monthly gross earnings'
				IF (@calcbasis * @ppds)/12 > @exemptamt
				BEGIN

					IF @calcbasis > 0.00
						BEGIN
							EXEC @rcode = @procname @calcbasis, @rate, @workstate, @ppds,@prco, @dlcode, @prgroup, @prenddate, @employee, @payseq,
								 @calcamt OUTPUT, @errmsg OUTPUT
							-- please put no code between exec AND @@error check!
							IF @@error <> 0 SELECT @rcode = 1
						END
				END
				GOTO routine_end
			END

		-- #119961 - Trinidad Tax
		IF @procname = 'bspPRTrinidad' -- Trinidad tax, store pay period exempt amount in bPRRM
			BEGIN
			EXEC @rcode = bspPRProcessGetAccums @prco, @prgroup, @prenddate, @employee, @payseq,
				@dlcode, @dltype, 'P', @limitmth, 'N', @accumamt OUTPUT,
				@accumsubj OUTPUT, @accumelig OUTPUT, @ytdamt OUTPUT, @ytdelig OUTPUT, @errmsg OUTPUT
			IF @rcode <> 0 GOTO bspexit

			SELECT @exemptamt = MiscAmt1 FROM dbo.bPRRM WITH (NOLOCK) WHERE PRCo = @prco AND Routine = @routine

			EXEC @rcode = @procname @calcbasis, @rate, @accumsubj, @accumelig, @exemptamt, @calcamt OUTPUT, @eligamt OUTPUT, @errmsg OUTPUT
			-- please put no code between exec AND @@error check!
			IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
			SELECT @calcbasis = @eligamt
			GOTO routine_end
			
			END
 
 		-- #25661
 		IF @procname like 'bspPRMedicalLiab%' -- custom routine 
 			BEGIN
 			EXEC @rcode = @procname @prco, @prgroup, @prenddate, @employee, @payseq, @limitamt, @routine, @calcamt OUTPUT, @errmsg OUTPUT
 			-- please put no code between exec AND @@error check!
 			IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
 			SELECT @calcbasis = @eligamt
 		 	GOTO routine_end
 			END
 
 		-- #25661
 		IF @procname like 'bspPRPensionDeduct%'	-- custom routine 
 			BEGIN
 			EXEC @rcode = @procname @prco, @prgroup, @prenddate, @employee, @payseq, @routine, @calcamt OUTPUT, @errmsg OUTPUT
 			-- please put no code between exec AND @@error check!
 			IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
 			SELECT @calcbasis = @eligamt
 		 	GOTO routine_end
 			END
 
 		-- call Routine procedure
 		EXEC @rcode = @procname @calcbasis, @calcamt OUTPUT, @errmsg OUTPUT
 		-- please put no code between exec AND @@error check!
 		IF @@error <> 0 SELECT @rcode = 1 --28379 check for error when routine was called
 
 
		routine_end:
		IF @rcode <> 0 GOTO bspexit
		IF @calcamt is null SELECT @calcamt = 0.00
		SELECT @eligamt = @calcbasis
		
		END -- Routine 
 
	-- Rate of Net - calculation basis is net pay
	IF @method = 'N'
		BEGIN
		SELECT @accurcalc = 0.00 -- variable with greater precision needed to calculate eligible
		SELECT @calcamt = @rate * @calcbasis, @accurcalc = @rate * @calcbasis	-- #11339 - default IF no employee override setup
		IF @overcalcs = 'A' SELECT @calcamt = @emprateamt

		-- net pay limit check
		IF @netpayopt = 'P' AND @calcamt > ((100 - @minnetpay)/100) * @calcbasis SELECT @calcamt = ((100 - @minnetpay)/100) * @calcbasis
		IF @netpayopt = 'A' AND @calcamt > @calcbasis - @minnetpay SELECT @calcamt = @calcbasis - @minnetpay
		IF @calcamt < 0.00 SELECT @calcamt = 0.00
 
		-- special limit check, assumes Limit AND YTD Corrections flags = 'N'
		IF @limitbasis = 'C' AND (@accumamt + @calcamt) > @limitamt
			BEGIN
			SELECT @calcamt = @limitamt - @accumamt
			IF @calcamt < 0.00 SELECT @calcamt = 0.00
			SELECT @accurcalc = @calcamt -- reduced because limit has been met or exceeded
			END 

		-- calculate eligible amount
		IF @overcalcs = 'R'
			BEGIN
			SELECT @eligamt = 0.00
			IF @rate <> 0.00 SELECT @eligamt = @accurcalc / @rate -- use greater precision to avoid rounding errors
			END 
		IF @overcalcs = 'A'
			BEGIN
			SELECT @eligamt = @calcbasis
			IF @calcamt <= 0.00 SELECT @eligamt = 0.00
			END
		END 
 
	-- apply Employee calculation override
	IF @overcalcs = 'A' AND @method <> 'N' SELECT @calcamt = @emprateamt

	-- apply Employee addon amounts - ON ly applied IF calculated amount is positive
	IF @calcamt > 0.00
		BEGIN
		IF @addontype = 'A' SELECT @calcamt = @calcamt + @addonrateamt
		IF @addontype = 'R' SELECT @calcamt = @calcamt + (@calcbasis * @addonrateamt)
		END

	IF @rndtodollar='Y'	SELECT @calcamt = ROUND(@calcamt,0) --round to the nearest dollar
 
	calc_end:	 -- Finished with calculations
		
	-- get AP Vendor AND Transaction description
	SELECT @dtvendorgroup = null, @dtvendor = null, @dtAPdesc = null
	IF @autoAP = 'Y'
		BEGIN
		SELECT @dtvendorgroup = @vendorgroup, @dtvendor = @vendor, @dtAPdesc = @dldesc
		IF @empvendor IS NOT NULL SELECT @dtvendor = @empvendor
		IF @apdesc IS NOT NULL SELECT @dtAPdesc = @apdesc
		END 

	-- UPDATE Payment Sequence Totals
	UPDATE dbo.bPRDT
	SET Amount = Amount + @calcamt, SubjectAmt = SubjectAmt + @accumbasis, EligibleAmt = EligibleAmt + @eligamt,
		VendorGroup = @dtvendorgroup, Vendor = @dtvendor, APDesc = @dtAPdesc
	WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate AND Employee = @employee
		AND PaySeq = @payseq AND EDLType = @dltype AND EDLCode = @dlcode
	IF @@rowcount = 0
		BEGIN
		INSERT dbo.bPRDT (PRCo, PRGroup, PREndDate, Employee, PaySeq, EDLType, EDLCode, 
			Hours, Amount, SubjectAmt, EligibleAmt, UseOver, OverAmt, OverProcess, 
			VendorGroup, Vendor, APDesc, OldHours, OldAmt, OldSubject, OldEligible, 
			OldMth, OldVendor, OldAPMth, OldAPAmt)
		VALUES (@prco, @prgroup, @prenddate, @employee, @payseq, @dltype, @dlcode, 
			0, @calcamt, @accumbasis, @eligamt, 'N', 0, 'N', 
			@dtvendorgroup, @dtvendor, @dtAPdesc, 0, 0, 0, 0, 
			null, null, null, 0)
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


	-- an overridden DL amount is processed ON ly ON ce
	IF @overprocess = 'Y' GOTO bspexit

	IF @useover = 'Y'
		BEGIN
		UPDATE dbo.bPRDT SET OverProcess = 'Y'
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
	EXEC @rcode = bspPRProcessLiabDist @prco, @prgroup, @prenddate, @employee, @payseq, @dlcode,
		 @method, @rate, @liabbasis, @amt2dist, @posttoall, @errmsg OUTPUT --issue 20562
	IF @rcode <> 0 GOTO bspexit


 bspexit:
 
 	return @rcode

GO

GRANT EXECUTE ON  [dbo].[bspPRProcessEmplDednLiabCalc] TO [public]
GO
