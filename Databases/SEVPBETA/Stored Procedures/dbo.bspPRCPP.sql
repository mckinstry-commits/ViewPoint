SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRCPP]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  PROC [dbo].[bspPRCPP]
/********************************************************/
-- CREATED BY: 	EN 2/29/08
-- MODIFIED BY: TJL  07/13/10 - Issue #139550, Consider AGE restrictions during CPP calculations
--				EN 2/3/2011 #143192 fix to handle situations where pay period wages are less than the exempt amount for the pay period
--
-- USAGE:
-- 	Calculates Canada Pension Plan (CPP) contribution.  
--	CPP is computed as a rate of the eligible earnings above an exempt amount for the pay period
--	with an annual limit.  The limit is set up in PRDL and handled standardly but this routine was needed
--	to handle the period exemption.  The annual exemption amount is stored in the PRRM (PR Routine Master)
--	in the misc amt #1 field for the CPP routine.
--
-- INPUT PARAMETERS:
--	@calcbasis	eligible amount
--	@ppds		# of pay pds per year
--	@rate		contribution rate
--
-- OUTPUT PARAMETERS:
--	@calcamt	CPP contribution
--	@msg		error message if failure
--
-- RETURN VALUE:
-- 	0 	    success
--	1 		failure
--
-- TEST HARNESS:
--  When considering the input parameters to use in order for CPP to be computed, @prenddate must be such that 
--  the employee is being paid at least one month after the 18th birthday or up through the month of the 70th birthday.
--
--DECLARE	@return_value int,
--		@calcamt bDollar,
--		@eligamt bDollar,
--		@msg varchar(255)
--
--EXEC	@return_value = [dbo].[bspPRCPP]
--		@prco = 70,
--		@employee = 55,
--		@prenddate = '1/9/2011',
--		@calcbasis = 1000,
--		@ppds = 52,
--		@rate = .0495,
--		@exemptamt = 3500,
--		@ppdaccumsubj = 0,
--		@ppdaccumelig = 0,
--		@calcamt = @calcamt OUTPUT,
--		@eligamt = @eligamt OUTPUT,
--		@msg = @msg OUTPUT
--
--SELECT	@calcamt as N'@calcamt',
--		@eligamt as N'@eligamt',
--		@msg as N'@msg'
--
--SELECT	'Return Value' = @return_value
--
/**********************************************************/
(@prco bCompany = NULL, 
 @employee bEmployee = NULL, 
 @prenddate bDate = NULL, 
 @calcbasis bDollar = 0, 
 @ppds tinyint = 0,
 @rate bUnitCost = 0, 
 @exemptamt bDollar = 0, 
 @ppdaccumsubj bDollar = 0,  
 @ppdaccumelig bDollar = 0, 
 @calcamt bDollar = 0 output, 
 @eligamt bDollar output, 
 @msg varchar(255) = null output)

AS
SET NOCOUNT ON

DECLARE @ppdexemptamt bDollar, 
		@procname varchar(30), 
		@birthdate bDate, 
		@age tinyint

SELECT	@ppdexemptamt = 0, 
		@procname = 'bspPRCPP', 
		@calcamt = 0, 
		@eligamt = 0, 
		@age = 0

--validate input params
IF @ppds = 0
BEGIN
	SELECT @msg = @procname + ': Missing # of Pay Periods per year!'
	RETURN 1
END
IF @prco IS NULL
BEGIN
	SELECT @msg = @procname + ': Missing PRCo!'
	RETURN 1
END
IF @employee IS NULL
BEGIN
	SELECT @msg = @procname + ': Missing Employee!'
	RETURN 1
END
IF @prenddate IS NULL
BEGIN
	SELECT @msg = @procname + ': Missing PR End Date!'
	RETURN 1
END

--Get Employee Info needed to check age restrictions
SELECT @birthdate = BirthDate
FROM dbo.bPREH (NOLOCK)
WHERE PRCo = @prco 
	  AND Employee = @employee

--Determine AGE eligibility for Canadian Pension Plan contributions
-- By default, CPP gets calculated unless certain AGE restrictions are encountered.
SET @age = YEAR(@prenddate) - YEAR(@birthdate)  

-- Skip CPP calculations. Age Transition will not occur within this year.
IF @age <=17 OR @age >=71 
BEGIN
	RETURN 0
END
	
-- Special AGE consideration.  Age Transition will occur sometime within this year.
IF @age = 18 OR @age = 70
BEGIN
	-- Actual Age:  If the birthday has not yet arrived this year we subtract 1. Employee is not yet 18 or 70 
	IF (MONTH(@prenddate) < MONTH(@birthdate)) 
		OR (MONTH(@prenddate) = MONTH(@birthdate) AND DAY(@prenddate) < DAY(@birthdate))    
	SET @age = @age - 1  

	-- If still 17, skip CPP Calculations
	IF @age = 17 
	BEGIN
		RETURN 0
	END
	
	-- If 18 but PR Pay Period is still in same month as Employee Birthday, skip CPP Calculations.	
	IF @age = 18
	BEGIN
		IF MONTH(@prenddate) = MONTH(@birthdate) 
		BEGIN
			RETURN 0
		END
	END

	-- If 70 and PR Pay Period is in month following Employee Birthday month, then begin skipping CPP Calculations.	
	IF @age = 70
	BEGIN
		IF MONTH(@prenddate) > MONTH(@birthdate) 
		BEGIN
			RETURN 0
		END
	END	
END
	
-- remaining exempt amount for the pay period
SET @ppdexemptamt = FLOOR(
						  ((@exemptamt/@ppds) - (ISNULL(@ppdaccumsubj,0) - ISNULL(@ppdaccumelig,0)) ) * 100
						 ) / 100

-- eligible amount
SET @eligamt = @calcbasis - @ppdexemptamt
IF @eligamt < 0
BEGIN
	SET @eligamt = 0
END

-- CPP amount
SET @calcamt = @rate * @eligamt


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspPRCPP] TO [public]
GO
