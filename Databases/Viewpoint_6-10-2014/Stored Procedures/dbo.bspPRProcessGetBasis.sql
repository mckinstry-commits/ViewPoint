SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRProcessGetBasis    Script Date: 8/28/99 9:35:37 AM ******/
CREATE procedure [dbo].[bspPRProcessGetBasis]
/***********************************************************
* CREATED BY:   GG  04/17/1998
* MODIFIED BY:  GG  03/16/1999
*				GG  03/13/2002 - #16435 - Changes to liab distribution basis					
*				EN  10/09/2002 - issue 18877 change double quotes to single
*				EN  09/24/2004 - issue 20562  change FROM using bPRCO_LiabDist to bPREC_IncldLiabDist to determine whether an earnings code is included in liab distribs
*				CHS 10/15/2010 - #140541 - change bPRDB.EarnCode to EDLCode  
*				CHS 10/15/2010 - #140541 - add pre-tax  
*				CHS 10/15/2010 - #142521 - add hourly pre-tax  
*				CHS	02/15/2011 - #142620 deal with divide by zero
*				CHS	07/16/2012 - D-03348 144933 fixed Pretax state problem
*				CHS	08/23/2012 - B-10152 TK-17277 added payback to the calc basis
*				MV	10/09/2013 - TFS-57069 prorate pretax deduction amounts across participating states
*				MV	10/14/2013 - 64211/64212 Incorrect deduction amt if bPRSI 'Post Deff to Resident State' = Y. Pass 2 more param values to bspPRProcessGetBasis
*				KK  11/26/2013 - 67994/5 Reverted pretax calculation refactor
*
* USAGE:
* Calculates basis amounts for most deductions AND liabilities
* Called FROM various bspPRProcess.. procedures for each dedn/liab code.
* 
* INPUT PARAMETERS
*   @prco          PR Company
*   @prgroup       PR Group
*   @prenddate     Pay Period ending date
*   @employee      Employee
*   @payseq        Payment Sequence
*   @method        DL calculation method
*   @posttoall     earnings posted to all days (Y,N)
*   @dlcode        DL code
*   @dltype        DL code type (D,L)
*   @stddays       standard # of days in Pay Period
* 
* OUTPUT PARAMETERS
*   @calcbasis     basis amount for calculation
*   @accumbasis    basis amount used to update accumulations
*   @liabbasis     basis used for liability distribution
*   @errmsg  	    error message IF something went wrong
* 
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq  tinyint,
@method varchar(10), @posttoall bYN, @dlcode bEDLCode, @dltype char(1), 
@stddays tinyint, @StateTaxDedn bEDLCode = NULL, @CalcDiff bYN = NULL,
@calcbasis bDollar output, @accumbasis bDollar output, @liabbasis bDollar output, @errmsg varchar(255) output
   
AS
SET NOCOUNT ON
   
DECLARE @rcode int, @earns bDollar, @dedns bDollar, @garngroup bGroup, @edlcode bEDLCode,
   @AccumPretax bDollar, @PreTaxBasis bDollar, @calccategory varchar(1), @PreTaxMethod char(1),
   @TotalPreTaxBasis bDollar

SELECT @rcode = 0
   
--get DL Type and Calculation Category for target DL
SELECT @dltype = DLType, @calccategory = CalcCategory --, 
FROM dbo.bPRDL 
WHERE PRCo = @prco AND DLCode = @dlcode
  
-- reset calculation, accumulation, and liability distribution basis amounts
SELECT @calcbasis = 0.00, @accumbasis = 0.00, @liabbasis = 0.00
   
-- Flat Amount
IF @method in ('A')
	BEGIN
	-- get target DL earnings basis -- pre-tax deductions not allowed in basis
	SELECT @accumbasis = ISNULL(SUM(e.Amt),0.00),	-- accumulation basis is earnings, include all subject earnings
			@calcbasis = ISNULL(SUM(CASE WHEN b.SubjectOnly = 'N' THEN e.Amt ELSE 0 END),0.00), -- calculation basis, exclude 'Subject Only' earnings
			@liabbasis = ISNULL(SUM(CASE WHEN @dltype = 'L' AND e.IncldLiabDist = 'Y' THEN e.Amt ELSE 0 END),0.00) -- liability distribution basis
	FROM dbo.bPRPE e
	JOIN dbo.bPRDB b ON b.EDLCode = e.EarnCode
	WHERE VPUserName = SUSER_SNAME() 
		AND b.PRCo = @prco 
		AND b.DLCode = @dlcode 
	END
       
-- Rate of Gross, or Routine
IF @method IN ('G', 'R')
	BEGIN
	-- get target DL earnings basis
	SELECT @accumbasis = ISNULL(SUM(e.Amt),0.00),	-- accumulation basis is earnings, include all subject earnings
		@calcbasis = ISNULL(SUM(CASE WHEN b.SubjectOnly = 'N' THEN e.Amt ELSE 0 END),0.00), -- calculation basis, exclude 'Subject Only' earnings
		@liabbasis = ISNULL(SUM(CASE WHEN @dltype = 'L' AND e.IncldLiabDist = 'Y' THEN e.Amt ELSE 0 END),0.00) -- liability distribution basis
	FROM dbo.bPRPE e
	JOIN  dbo.bPRDB b ON b.EDLCode = e.EarnCode
	WHERE VPUserName = SUSER_SNAME() 
		AND b.PRCo = @prco 
		AND b.DLCode = @dlcode 
		AND b.EDLType = 'E'		-- limit to earn codes only
		
	-- Pre-tax deductions allowed in basis at Federal/State/Local levels so special accumulation logic required
	IF @calccategory IN ('F', 'E')	-- Federal and Employee
		BEGIN
		-- reduce accumulation and calculation basis by pre-tax dedn amount, no change to liability distribution basis
		SELECT @accumbasis = @accumbasis - ISNULL(SUM(e.DednAmt),0.00),
			@calcbasis = @calcbasis - ISNULL(SUM(e.DednAmt),0.00) 
		FROM dbo.#EmployeePreTaxDedns e
		JOIN dbo.bPRDB b ON b.PRCo = e.PRCo AND b.EDLCode = e.DLCode	-- pre-tax dedns included in basis of target DL
		WHERE e.Employee = @employee 
			AND e.PRCo = @prco
			AND e.PRGroup = @prgroup 	
			AND e.PREndDate = @prenddate 	
			AND e.PaySeq = @payseq 
			AND b.DLCode = @dlcode
			AND b.EDLType = 'D'			-- limit to dedns only																			
		END
		
	IF @calccategory in ('S','L','I')	-- State or Local or Insurance
		BEGIN
		-----------------------------------------------------------------------------------------------
		-- Process each pre-tax dedn assigned as a basis for the target DL  
		-- Get State/Local earnings subject to each pre-tax dedn 
		-- Use the ratio of State/Local pre-tax subject earnings to total pre-tax subject earnings
		-- to calculate proportion of each pre-tax dedn that should be used to reduce target DL basis
		-----------------------------------------------------------------------------------------------
		
		-- cursor flags			
		DECLARE @openPreTaxCodes TINYINT
		
		-- create cursor for all pre-tax dedns used in basis for target DL
		DECLARE vcPreTaxCodes CURSOR local fast_forward  FOR
		SELECT DISTINCT  d.EDLCode									
		FROM dbo.bPRDB d
		JOIN dbo.#EmployeePreTaxDedns e on e.DLCode = d.EDLCode
		WHERE d.PRCo = @prco 
			AND d.DLCode = @dlcode
			AND d.EDLType = 'D' -- we only want Deductions - no Earnings
			
		OPEN vcPreTaxCodes
		SELECT @openPreTaxCodes = 1, @AccumPretax = 0

		-- loop pre-tax dedns								
		next_PreTaxCode:
			FETCH NEXT FROM vcPreTaxCodes INTO @edlcode										
			IF @@FETCH_STATUS = -1 GOTO end_PreTaxCode
			IF @@FETCH_STATUS <> 0 GOTO next_PreTaxCode		
			
			SELECT @PreTaxMethod = d.Method -- determine if hourly vs. amount
			FROM dbo.bPRDL d
			WHERE d.PRCo = @prco 
				AND d.DLCode = @edlcode
			
			----TFS-57069 Get basis and total basis amounts for prorated pretax deduction calculation
			--EXEC @rcode = vspPRProcessGetBasisPreTax	@prco,
			--											@prgroup,
			--											@prenddate,
			--											@employee,
			--											@payseq,
			--											@PreTaxMethod,	-- pretax deduction code method from bPRDL
			--											@dlcode,		-- the deduction code for which the calcbasis is being calculated (state, local or insurance)
			--											@dltype,		-- the DL type of the deduction code for which the calcbasis is being calculated
			--											@edlcode,		-- the pretax deduction code that is a basis code for the deduction code
			--											@calccategory,	-- the calculation category for the deduction code
			--											@StateTaxDedn,	-- the state tax dedn code for the current state being processed for this employee
			--											@CalcDiff,		-- the bPRSI flag to 'Post Difference to Resident State'
			--											@PreTaxBasis output,		-- the basis amount for this deduction code's pretax code
			--											@TotalPreTaxBasis output,	-- the total basis amount for the pretax code
			--											@errmsg output

			---- accumulate the pretax amount to be deducted from calcbasis. The pretax deduction amount should be spread
			---- across all states/locals/insurance codes assigned to this employee that have this pretax deduction code assigned as a basis code
			--SELECT @AccumPretax =	CASE WHEN @TotalPreTaxBasis = 0 THEN @AccumPretax
			--						ELSE @AccumPretax + (e.DednAmt * (@PreTaxBasis / @TotalPreTaxBasis)) 
			--						END
					
			--FROM dbo.#EmployeePreTaxDedns e
			--WHERE e.Employee = @employee 
			--		AND e.PRCo = @prco
			--		AND e.PRGroup = @prgroup 	
			--		AND e.PREndDate = @prenddate 	
			--		AND e.PaySeq = @payseq 
			--		AND e.DLCode = @edlcode -- pretax dedn
			--		AND ISNULL(e.DednAmt, 0.00) <> 0 -- no need to evaluate if null or zero
			--		--AND ISNULL(e.BasisAmt, 0.00) <> 0 -- prevent divide by zero
				
			-- accumulate State/Local earnings subject to pre-tax when method is rate per Day
			IF @PreTaxMethod = 'D'
			BEGIN
				SELECT @PreTaxBasis = count(distinct e.PostDate)
				FROM dbo.bPRPE e
					JOIN  dbo.bPRDB b ON b.EDLCode = e.EarnCode
					JOIN #EmployeePreTaxPRPE p ON e.PostSeq = p.PostSeq and e.PostDate = p.PostDate and e.EarnCode = p.EarnCode 				
				WHERE VPUserName = SUSER_SNAME() 
					AND b.PRCo = @prco 
					AND b.DLCode = @edlcode		-- pre-tax dedn
					AND b.SubjectOnly = 'N' 
					AND p.PreTaxDLCode = @edlcode										
			END
	
			-- accumulate State/Local earnings subject to pre-tax when method is not rate per Day
			ELSE
			BEGIN
				SELECT @PreTaxBasis =
					CASE @PreTaxMethod
						WHEN 'F' THEN ISNULL(SUM(e.Hours),0.00)
						WHEN 'H' THEN ISNULL(SUM(e.Hours),0.00)						
						ELSE ISNULL(SUM(e.Amt),0.00)
					END
				FROM dbo.bPRPE e
					JOIN  dbo.bPRDB b ON b.EDLCode = e.EarnCode
					JOIN #EmployeePreTaxPRPE p ON e.PostSeq = p.PostSeq and e.PostDate = p.PostDate and e.EarnCode = p.EarnCode 
				WHERE VPUserName = SUSER_SNAME() 
					AND b.PRCo = @prco 
					AND b.DLCode = @edlcode		-- pre-tax dedn
					AND b.SubjectOnly = 'N' 
					AND p.PreTaxDLCode = @edlcode				
			END
		
			SELECT @AccumPretax = CASE WHEN e.BasisAmt = 0 
									   THEN @AccumPretax
									   ELSE @AccumPretax + (e.DednAmt * (@PreTaxBasis / e.BasisAmt)) 
								  END
			FROM dbo.#EmployeePreTaxDedns e
			WHERE e.Employee = @employee 
					AND e.PRCo = @prco
					AND e.PRGroup = @prgroup 	
					AND e.PREndDate = @prenddate 	
					AND e.PaySeq = @payseq 
					AND e.DLCode = @edlcode -- pretax dedn
					AND ISNULL(e.DednAmt, 0.00) <> 0 -- no need to evaluate if null or zero
					AND ISNULL(e.BasisAmt, 0.00) <> 0 -- prevent divide by zero
					
		GOTO next_PreTaxCode		
			
		end_PreTaxCode:	-- finished with pre-tax dedns
			CLOSE vcPreTaxCodes
			DEALLOCATE vcPreTaxCodes
			SELECT @openPreTaxCodes = 0
		
			-- subtract pre-tax amounts from accumulation and calculation basis, no change to liability distribution
			SELECT @accumbasis = @accumbasis - @AccumPretax
			SELECT @calcbasis = @calcbasis - @AccumPretax
--if @dlcode = 26 begin	
--select @errmsg = '@PreTaxBasis:' + CONVERT(varchar,@PreTaxBasis)
--+ ' | @TotalPreTaxBasis:' + convert(varchar,@TotalPreTaxBasis) 
--+ ' | @AccumPretax:' + convert(varchar,@AccumPretax)
--+ ' | pretaxcode:' + convert(varchar,@edlcode)
--+ ' | @Employee:' + convert(varchar,@employee)
--+ ' | @PREndDate:' + convert(varchar,@prenddate)
--return 1 end
			
		END	-- end of State/Local
	END	-- end of Rate of Gross/Routine
	
       
-- Rate per Hour
IF @method = 'H'
	BEGIN
	SELECT @accumbasis = ISNULL(SUM(e.Hours),0.00),	-- accumulation basis is hours, include all subject earnings
			@calcbasis = ISNULL(SUM(CASE WHEN b.SubjectOnly = 'N' THEN e.Hours ELSE 0 END),0.00), -- calculation basis, exclude 'Subject Only' earnings
			@liabbasis = ISNULL(SUM(CASE WHEN @dltype = 'L' AND e.IncldLiabDist = 'Y' THEN e.Hours ELSE 0 END),0.00) -- liability distribution basis
	FROM dbo.bPRPE e
	JOIN  dbo.bPRDB b ON b.EDLCode = e.EarnCode
	WHERE VPUserName = SUSER_SNAME() 
		AND b.PRCo = @prco 
		AND b.DLCode = @dlcode
	END
   
-- Factored Rate per Hour
IF @method = 'F'
	BEGIN
	SELECT @accumbasis = ISNULL(SUM(e.Hours),0.00),	-- accumulation basis is hours, include all subject earnings
			@calcbasis = ISNULL(SUM(CASE WHEN b.SubjectOnly = 'N' THEN (e.Hours * e.Factor) ELSE 0 END),0.00), -- calculation basis is factored hours, exclude 'Subject Only' earnings
			@liabbasis = ISNULL(SUM(CASE WHEN @dltype = 'L' AND e.IncldLiabDist = 'Y' THEN (e.Hours * e.Factor) ELSE 0 END),0.00) -- liability distribution basis
	FROM dbo.bPRPE e
	JOIN  dbo.bPRDB b ON b.EDLCode = e.EarnCode
	WHERE VPUserName = SUSER_SNAME() 
		AND b.PRCo = @prco 
		AND b.DLCode = @dlcode 
	END
       
       
-- Rate of Deduction
IF @method = 'DN'
	BEGIN
	-- use calculated or override amount of basis deduction
	-- note: is this deduction code is based a payback (rate of a deduction)
	--		we need to include the payback portion is the calc basis. if this is
	--		not a payback code then it's payback value will be zero -- so we can
	--		always add this to the calc basis.
	--		CHS	08/23/2012	- B-10152 TK-17277
	SELECT @calcbasis = CASE t.UseOver 
							WHEN 'Y' 
							THEN t.OverAmt 
							ELSE t.Amount 
							END
							+
						CASE t.PaybackOverYN 
							WHEN 'Y' 
							THEN isnull(t.PaybackOverAmt, 0)
							ELSE isnull(t.PaybackAmt, 0)
							END							
	
	FROM dbo.bPRDT t
	JOIN  dbo.bPRDL d ON d.PRCo = t.PRCo AND d.DednCode = t.EDLCode
	WHERE t.PRCo = @prco 
		AND t.PRGroup = @prgroup 
		AND t.PREndDate = @prenddate 
		AND t.Employee = @employee
		AND t.PaySeq = @payseq 
		AND t.EDLType = 'D' 
		AND d.DLCode = @dlcode

	-- accumulation basis is amount of deduction
	SELECT @accumbasis = @calcbasis

	-- liability distribution basis
	IF @dltype = 'L'
		BEGIN
		SELECT @liabbasis = @accumbasis		-- #16435 default to accumulation basis
		-- basis excludes earnings WHERE IncldLiabDist<>'Y'
		SELECT @liabbasis = ISNULL(SUM(e.Amt),0.00)
		FROM dbo.bPRPE e
		JOIN  dbo.bPRDB b ON b.EDLCode = e.EarnCode
		WHERE VPUserName = SUSER_SNAME() 
			AND b.PRCo = @prco 
			AND b.DLCode = @dlcode -- #16435 include subject only earnings
			AND e.IncldLiabDist='Y' --issue 20562
		END
	END	
        
       
-- Straight Time Equivalent
IF @method = 'S'
	BEGIN
	
	SELECT @accumbasis = 0.00, @calcbasis = 0.00, @liabbasis = 0.00
	
	SELECT 
		@accumbasis = ISNULL(SUM(e.Amt / e.Factor),0.00),	-- accumulation basis is STE, include all subject earnings
		@calcbasis = ISNULL(SUM(CASE WHEN b.SubjectOnly = 'N' THEN (e.Amt / e.Factor) ELSE 0 END),0.00), -- calculation basis, exclude 'Subject Only' earnings
		@liabbasis = ISNULL(SUM(CASE WHEN @dltype = 'L' AND e.IncldLiabDist = 'Y' THEN (e.Amt / e.Factor) ELSE 0 END),0.00) -- liability distribution basis
	FROM dbo.bPRPE e
	JOIN dbo.bPRDB b ON b.EDLCode = e.EarnCode
	WHERE VPUserName = SUSER_SNAME() 
		AND b.PRCo = @prco 
		AND b.DLCode = @dlcode 
		AND ISNULL(e.Factor, 0.00) <> 0  -- prevent divide by zero #142620
	END       
       
       
-- Rate per Day
IF @method = 'D'
	BEGIN
	-- calculation basis is number of days worked - exclude 'Subject Only' earnings
	SELECT @calcbasis = count(distinct e.PostDate)
	FROM dbo.bPRPE e
	JOIN dbo.bPRDB b ON b.EDLCode = e.EarnCode
	WHERE VPUserName = SUSER_SNAME() 
		AND b.PRCo = @prco 
		AND b.DLCode = @dlcode 
		AND b.SubjectOnly = 'N'

	-- accumulation basis is # of days worked - all subject earnings
	SELECT @accumbasis = count(distinct e.PostDate)
	FROM dbo.bPRPE e
	JOIN  dbo.bPRDB b ON b.EDLCode = e.EarnCode
	WHERE VPUserName = SUSER_SNAME() 
		AND b.PRCo = @prco 
		AND b.DLCode = @dlcode

	-- accumulate liability dist basis - actual days worked used even IF posted to all
	IF @dltype = 'L'
		BEGIN
		SELECT @liabbasis = @accumbasis		-- #16435 default to accumulation basis
		-- excluding earnings WHERE IncldLiabDist<>'Y'
		SELECT @liabbasis = COUNT(distinct e.PostDate)
		FROM dbo.bPRPE e
		JOIN  dbo.bPRDB b ON b.EDLCode = e.EarnCode
		WHERE VPUserName = SUSER_SNAME() 
			AND b.PRCo = @prco 
			AND b.DLCode = @dlcode -- #16435 include subject only earnings
			AND e.IncldLiabDist='Y' --issue 20562
		END

	IF @posttoall = 'Y' -- posted to all days - calculation AND accums based on std # of days in Pay Period
		BEGIN
		SELECT @calcbasis = @stddays
		SELECT @accumbasis = @stddays
		END
	END
       
       
-- Rate of Net
IF @method = 'N'
	BEGIN
	-- get Garnishment Group
	SELECT @earns = 0.00, @dedns = 0.00, @garngroup = null
	SELECT @garngroup = GarnGroup
	FROM dbo.bPRDL
	WHERE PRCo = @prco AND DLCode = @dlcode
	
	-- IF no Garnishment Group, use all earnings AND dedns to calculate net pay
	IF @garngroup is null
		BEGIN
		SELECT @earns = ISNULL(SUM(Amount),0.00)
		FROM dbo.bPRDT
		WHERE PRCo = @prco 
			AND PRGroup = @prgroup 
			AND PREndDate = @prenddate 
			AND Employee = @employee
			AND PaySeq = @payseq 
			AND EDLType = 'E'

		SELECT @dedns = ISNULL(SUM(case UseOver when 'Y' then OverAmt else Amount END),0.00)
		FROM dbo.bPRDT
		WHERE PRCo = @prco 
			AND PRGroup = @prgroup 
			AND PREndDate = @prenddate 
			AND Employee = @employee
			AND PaySeq = @payseq 
			AND EDLType = 'D'

		END
	-- use Garnishment Group to determine net pay
	IF @garngroup is not null
		BEGIN
		SELECT @earns = ISNULL(SUM(Amount),0.00)
		FROM dbo.bPRDT t
		JOIN  dbo.bPRGI g ON t.PRCo = g.PRCo AND t.EDLType = g.EDType AND t.EDLCode = g.EDCode
		WHERE t.PRCo = @prco 
			AND t.PRGroup = @prgroup 
			AND t.PREndDate = @prenddate 
			AND t.Employee = @employee
			AND t.PaySeq = @payseq 
			AND t.EDLType = 'E' 
			AND g.GarnGroup = @garngroup

		SELECT @dedns = ISNULL(SUM(CASE t.UseOver WHEN 'Y' THEN t.OverAmt ELSE t.Amount END),0.00)
		FROM dbo.bPRDT t
		JOIN  dbo.bPRGI g on t.PRCo = g.PRCo AND t.EDLType = g.EDType AND t.EDLCode = g.EDCode
		WHERE t.PRCo = @prco 
			AND t.PRGroup = @prgroup 
			AND t.PREndDate = @prenddate 
			AND t.Employee = @employee
			AND t.PaySeq = @payseq 
			AND t.EDLType = 'D' 
			AND g.GarnGroup = @garngroup
		END

	-- calculation AND accumulation basis is net pay
	SELECT @calcbasis = @earns - @dedns
	SELECT @accumbasis = @calcbasis
	-- assumes method not used for liabilities
	END
   
 bspexit:
	IF @openPreTaxCodes = 1
		BEGIN
		CLOSE vcPreTaxCodes
		DEALLOCATE vcPreTaxCodes
		END
           	
RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRProcessGetBasis] TO [public]
GO
