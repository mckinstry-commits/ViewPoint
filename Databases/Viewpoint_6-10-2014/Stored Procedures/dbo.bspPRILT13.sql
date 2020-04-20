SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRILT13    Script Date: 8/28/99 9:33:23 AM ******/
CREATE PROC [dbo].[bspPRILT13]
/********************************************************/
--CREATED BY: 	EN 6/6/98
--MODIFIED BY:  EN 1/8/99
--MODIFIED BY:  EN 10/19/99 - effective 1/1/2000
--MODIFIED BY:  EN 11/02/99 - fix for slight computation error
--			EN 10/8/02 - issue 18877 change double quotes to single
--			EN 1/4/05 - issue 26244  default exemptions
--			EN 1/19/2011 #142945 updated effective 1/1/2011 (retroactive)
--			MV 12/26/2012 - TK-20374 2013 tax updates.
--
--USAGE:
--	Calculates Illinois Income Tax
--INPUT PARAMETERS:
--	@subjamt 	subject earnings
--	@ppds		# of pay pds per year
--	@status		filing status
--	@regexempts	# of regular exemptions
--	@addexempts	# of additional exemptions
--
-- OUTPUT PARAMETERS:
--	@amt		calculated tax amount
--	@msg		error message if failure
--
-- RETURN VALUE:
-- 	0 	    success
--	1 		failure
--
-- TEST HARNESS:
--
--	DECLARE	@return_value int,
--			@amt bDollar,
--			@msg varchar(255)
--
--	EXEC	@return_value = [dbo].[bspPRILT13]
--			@subjamt = 1800,
--			@ppds = 52,
--			@status = NULL,
--			@regexempts = 2,
--			@addexempts = 3,
--			@amt = @amt OUTPUT,
--			@msg = @msg OUTPUT
--
--	SELECT	@amt as N'@amt',
--			@msg as N'@msg'
--
--	SELECT	'Return Value' = @return_value
--
--
/**********************************************************/
(@subjamt bDollar = 0, 
@ppds tinyint = 0, 
@status char(1), 
@regexempts tinyint = 0,
@addexempts tinyint = 0, 
@amt bDollar = 0 output, 
@msg varchar(255) = null output)

AS
SET NOCOUNT ON

DECLARE @TaxableIncome bDollar, 
		@RegularAllowance bDollar, 
		@AdditionalAllowance bDollar,
		@Rate bRate, 
		@ProcedureName varchar(30)

SELECT @RegularAllowance = 2100, 
	   @AdditionalAllowance = 1000, 
	   @Rate = .05,
	   @ProcedureName = 'bspPRILT13'

-- exemptions must not be null
IF @regexempts IS NULL SELECT @regexempts = 0

IF @addexempts IS NULL SELECT @addexempts = 0

-- validate # of pay periods
IF @ppds = 0
BEGIN
	SELECT @msg = @ProcedureName + ':  Missing # of Pay Periods per year!'
	RETURN 1
END

-- determine taxable income
SELECT @TaxableIncome = (@subjamt * @ppds) 
						- (@regexempts * @RegularAllowance) 
						- (@addexempts * @AdditionalAllowance)

IF @TaxableIncome < 0 SELECT @TaxableIncome = 0

-- calculate tax
SELECT @amt = ROUND(((@TaxableIncome * @Rate) / @ppds),2)

IF @amt < 0 SELECT @amt = 0

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspPRILT13] TO [public]
GO
