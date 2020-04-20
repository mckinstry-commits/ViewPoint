SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspPRProcessLiabDist]
/***********************************************************
* CREATED BY: 	 GG  04/17/98
* MODIFIED BY:    GG  04/20/99
*              GG 08/17/99  Corrected distribution when basis is exclusively negative non-true earnings.
*				GG 03/13/02 - #16435 - Changes to liab distribution basis
*				GG 03/19/02 - #16710 - exclude 'amount' liabs from distribution if basis = 0.00					
*				EN 10/9/02 - issue 18877 change double quotes to single
*				EN 3/24/03 - issue 11030 rate of earnings liability limit
*				GG 02/10/04 - #22499 fix liab dist when basis = 0 and method = 'DN'
*				EN 4/16/04 - issue 24291 missing PRCo on select PRDL causing distribute liab code error
*				EN 9/24/04 - issue 20562  change from using bPRCO_LiabDist to bPREC_IncldLiabDist to determine whether an earnings code is included in liab distribs
*				GG 09/21/05 - #29551 - exclude days w/o earnings included in liab distributions from cursor
*				EN 9/5/06 - issue 120447 - beef up liab distrib message to include empl #
*				CHS 10/15/2010 - #140541 - change bPRDB.EarnCode to EDLCode
*				CHS	02/15/2011	- #142620 deal with divide by zero
*				EN/KK 9/23/2011 TK-08351 #137686 fixed to distribute nothing when liab basis = 0 and liab limit is rate of earnings
*										plus refactored to more cleanly distribute nothing when liab basis = 0 and liab method is A or DN
*				MV	09/24/2013 TK-57135 Liability distribution is incorrect when earncode and pre-tax deduction code are the same number
*
* USAGE:
* Distributes liabilities
* Called from various bspPRProcess... procedures.
*
* INPUT PARAMETERS
*   @prco              PR Company
*   @prgroup	        PR Group
*   @prenddate	        PR Ending Date
*   @employee	        Employee to process
*   @payseq	        Payment Sequence #
*   @dlcode            Liability code
*   @method            Calculation method
*   @rate              Liability rate - 0.00 for methods 'A', 'R', 'DN', not used for 'D'
*   @liabbasis         Basis for distributing liability amount - depends on method
*   @amt2dist          Amount to distribute
*   @posttoall         Earnings posted to all days in Pay Period (Y/N)
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
    @dlcode bEDLCode, 
    @method varchar(10), 
    @rate bUnitCost, 
    @liabbasis bDollar,
    @amt2dist bDollar, 
    @posttoall bYN, 
    @errmsg varchar(255) OUTPUT
    
AS
SET NOCOUNT ON

DECLARE @rcode int, 
		@amtdist bDollar, 
		@lastpostseq smallint, 
		@postseq smallint, 
		@factor bRate, 
		@hrs bHrs, 
		@amt bDollar,
		@distamt bDollar, 
		@postdate bDate, 
		@i bDollar, 
		@earns bDollar, 
		@limitbasis char(1),
		@subjectearncode bEDLCode -- TK-08351 to store earn code of timecard posting

-- #11030 get DL limit basis for special handling of 'rate of earnings' 
SELECT @limitbasis = LimitBasis FROM dbo.PRDL WITH (NOLOCK) WHERE PRCo=@prco AND DLCode=@dlcode

-- TK-08351 - Added IF to improve performance ... no calculation will occur when liabbasis=0 for method (A/DN) so no
-- need to continue further ... just RETURN 0
-- Check for limitbasis 'R' which indicates 401k liability match type situation was added to criteria to avoid doing a
-- liability distribution when a liability positive-negative adjustment is made resulting in a wash.  We had considered figuring
-- out a way to get the distributions to compute but could not find a way to compute the real basis in this situation.
-- #22499 added 'DN' method
IF	(@liabbasis = 0.00 AND @method IN ('A','DN')) 
	OR (@liabbasis = 0.00 AND @limitbasis = 'R')
BEGIN
	RETURN 0
END

-- cursor flags
DECLARE @openLiabDist tinyint, 
		@openLiabDist1 tinyint, 
		@openDay tinyint

-- initialize amount distributed and 'last posting seq#'
SELECT @rcode = 0, @amtdist = 0.00, @lastpostseq = 0

IF @method IN ('A','R','G','H','F','S','DN')
BEGIN
	-- create cursor to process earnings subject to the liability
	DECLARE bcLiabDist CURSOR FOR
		SELECT e.PostSeq, e.PostDate, e.Factor, e.Hours, e.Amt --issue 20562
		FROM dbo.bPRPE e WITH (NOLOCK)
		JOIN dbo.bPRDB b WITH (NOLOCK) ON b.EDLCode = e.EarnCode
		WHERE e.VPUserName = SUSER_SNAME() 
			  AND b.PRCo = @prco 
			  AND b.DLCode = @dlcode
			  AND b.EDLType = 'E'
			  AND e.IncldLiabDist = 'Y'	-- #20562 earnings must be included in liab dist
			  AND ((@limitbasis = 'R' AND b.SubjectOnly = 'Y') OR @limitbasis <> 'R') -- #11030 earnings must be 'subject only' if limit basis is 'R'
		ORDER BY e.PostSeq, e.EarnCode

	-- open distribution cursor
	OPEN bcLiabDist
	SELECT @openLiabDist = 1

	next_LiabDist:  -- loop through Liability Distribution cursor
	FETCH NEXT FROM bcLiabDist INTO @postseq, @postdate, @factor, @hrs, @amt
	IF @@FETCH_STATUS = -1 GOTO end_LiabDist
	IF @@FETCH_STATUS <> 0 GOTO next_LiabDist

	IF @lastpostseq = 0 
	BEGIN
		SELECT @lastpostseq = @postseq	-- save the first posting seq#
	END

	SELECT @distamt = 0.00

	SELECT @i = CASE @method
				WHEN 'H' THEN @hrs
				WHEN 'F' THEN @hrs * @factor
				-- WHEN 'S' THEN @amt / @factor
				WHEN 'S' THEN (CASE	WHEN @factor = 0.00 THEN 0.00 
									ELSE @amt / @factor 
									END) -- CHS	02/15/2011	- #142620 deal with divide by zero
				ELSE @amt
				END
	-- distribution basis is subject amount
	IF	@liabbasis = 0.00 
	BEGIN
		SELECT @distamt = @i * @rate
	END
	ELSE
	BEGIN
		SELECT @distamt = (@i / @liabbasis) * @amt2dist
	END

	IF @distamt = 0.00 GOTO next_LiabDist

	UPDATE dbo.bPRTL
	SET Amt = Amt + @distamt
	WHERE	PRCo = @prco 
			AND PRGroup = @prgroup 
			AND PREndDate = @prenddate 
			AND Employee = @employee
			AND PaySeq = @payseq 
			AND PostSeq = @postseq 
			AND LiabCode = @dlcode
	IF @@ROWCOUNT = 0
	BEGIN
		INSERT dbo.bPRTL (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, LiabCode, Rate, Amt)
		VALUES (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @dlcode, @rate, @distamt)
	END

	-- accumulate amount distributed and save last posting seq#
	SELECT @amtdist = @amtdist + @distamt, @lastpostseq = @postseq
	GOTO next_LiabDist
END

-- Rate per Day - this distribution works for both actual or std # of days
IF @method = 'D'
BEGIN
	-- create cursor for actual days worked
	DECLARE bcDay CURSOR FOR
		SELECT distinct e.PostDate
		FROM dbo.bPRPE e WITH (NOLOCK)
		JOIN dbo.bPRDB b WITH (NOLOCK) ON b.EDLCode = e.EarnCode
		WHERE	e.VPUserName = SUSER_SNAME() 
				AND b.PRCo = @prco 
				AND b.DLCode = @dlcode
	 			AND b.EDLType = 'E'
				AND e.IncldLiabDist = 'Y' -- only include days with earnings flagged for liab distribution
		ORDER BY e.PostDate

	-- open Day cursor
	OPEN bcDay
	SELECT @openDay = 1

	next_Day:  -- loop through each day
	FETCH NEXT FROM bcDay INTO @postdate
	IF @@FETCH_STATUS = -1 GOTO end_LiabDist
	IF @@FETCH_STATUS <> 0 GOTO next_Day

	-- get sum of earnings for the day
	SELECT @earns = ISNULL(SUM(e.Amt),0.00)
	FROM dbo.bPRPE e WITH (NOLOCK)
	JOIN dbo.bPRDB b WITH (NOLOCK) ON b.EDLCode = e.EarnCode
	WHERE	VPUserName = SUSER_SNAME() 
			AND e.PostDate = @postdate 
			AND b.PRCo = @prco 
			AND b.DLCode = @dlcode -- #16435 include subject only earnings
			AND b.EDLType = 'E'
			AND e.IncldLiabDist = 'Y' -- #20562 must be included in liab distribution

	-- create cursor to process daily earnings subject to the liability
	DECLARE bcLiabDist1 CURSOR FOR
	SELECT e.PostSeq, e.Amt 
	FROM dbo.bPRPE e WITH (NOLOCK)
	JOIN dbo.bPRDB b WITH (NOLOCK) ON b.EDLCode = e.EarnCode
	WHERE	e.VPUserName = SUSER_SNAME() 
			AND e.PostDate = @postdate 
			AND b.PRCo = @prco 
			AND b.DLCode = @dlcode
			AND b.EDLType = 'E'
			AND e.IncldLiabDist = 'Y' -- must be included in liab distribution
	ORDER BY e.PostSeq, e.EarnCode

	-- open distribution cursor
	OPEN bcLiabDist1
	SELECT @openLiabDist1 = 1

	next_LiabDist1:  -- loop through Liability Distribution cursor
	FETCH NEXT FROM bcLiabDist1 INTO @postseq, @amt 
	IF @@FETCH_STATUS = -1 GOTO end_LiabDist1
	IF @@FETCH_STATUS <> 0 GOTO next_LiabDist1

	IF @lastpostseq = 0 
	BEGIN
		SELECT @lastpostseq = @postseq	-- save the first posting seq#
	END

	SELECT @distamt = 0.00

	IF @earns <> 0.00 AND @liabbasis <> 0.00
	BEGIN
		-- liability basis is actual days worked
		SELECT @distamt = ((@amt / @earns) / @liabbasis) * @amt2dist
	END

	IF @distamt = 0.00 
	BEGIN
		GOTO next_LiabDist1
	END

	UPDATE dbo.bPRTL
	SET Amt = Amt + @distamt
	WHERE	PRCo = @prco 
			AND PRGroup = @prgroup 
			AND PREndDate = @prenddate 
			AND Employee = @employee
			AND PaySeq = @payseq 
			AND PostSeq = @postseq 
			AND LiabCode = @dlcode
	IF @@ROWCOUNT = 0
	BEGIN
		INSERT dbo.bPRTL (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, LiabCode, Rate, Amt)
		VALUES (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @dlcode, @rate, @distamt)
	END

	-- accumulate amount distributed and save last posting seq#
	SELECT @amtdist = @amtdist + @distamt, @lastpostseq = @postseq
	GOTO next_LiabDist1

	end_LiabDist1:
	CLOSE bcLiabDist1
	DEALLOCATE bcLiabDist1
	SELECT @openLiabDist1 = 0
	GOTO next_Day
END

end_LiabDist:
IF @amt2dist = @amtdist GOTO bspexit
IF @lastpostseq = 0
BEGIN
	SELECT @errmsg = 'Unable to fully distribute liability code ' + convert(varchar(4),@dlcode) + ' for Employee ' + convert(varchar(6),@employee) + '.', @rcode = 1
	GOTO bspexit
END

-- update difference to last entry
UPDATE dbo.bPRTL
SET Amt = Amt + @amt2dist - @amtdist
WHERE	PRCo = @prco 
		AND PRGroup = @prgroup 
		AND PREndDate = @prenddate
		AND Employee = @employee 
		AND PaySeq = @payseq 
		AND PostSeq = @lastpostseq
		AND LiabCode = @dlcode
IF @@ROWCOUNT = 0
BEGIN
	INSERT dbo.bPRTL (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, LiabCode, Rate, Amt)
	VALUES (@prco, @prgroup, @prenddate, @employee, @payseq, @lastpostseq, @dlcode, @rate, (@amt2dist - @amtdist))
END


bspexit:
IF @openLiabDist = 1
BEGIN
	CLOSE bcLiabDist
	DEALLOCATE bcLiabDist
END
IF @openDay = 1
BEGIN
	CLOSE bcDay
	DEALLOCATE bcDay
END
IF @openLiabDist1 = 1
BEGIN
	CLOSE bcLiabDist1
	DEALLOCATE bcLiabDist1
END

RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRProcessLiabDist] TO [public]
GO
