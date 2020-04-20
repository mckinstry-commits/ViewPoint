
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPRCOT13]
/********************************************************
* CREATED BY: 	EN 12/12/00 - tax update effective 1/1/2001
* MODIFIED BY:	EN 10/07/02 - #18877 change double quotes to single
*				EN 12/31/04 - #26244  default status and exemptions
*				EN 10/27/06 - #30201  tax update effective 1/1/2006
*				EN 12/14/06 - #123313  tax update effective 1/1/2007
*				EN 05/04/09 - #133558  tax update effective 1/1/2009
*				MV 12/23/10 - #142590 tax updates effective 1/1/2011
*				KK 01/04/13 - D-06421/#147784 Update effective 1/1/2013
*
* USAGE:	Calculates Colorado Income Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status
*	@exempts	# of exemptions
*
* OUTPUT PARAMETERS:
*	@amt		calculated tax amount
*	@msg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
* GRANT EXECUTE ON bspPRCOT11 TO public;
**********************************************************/
(@subjamt bDollar = 0, 
 @ppds tinyint = 0, 
 @status char(1) = 'S', 
 @exempts tinyint = 0,
 @amt bDollar = 0 OUTPUT,
 @msg varchar(255) = NULL OUTPUT)
 
AS
SET NOCOUNT ON
  
DECLARE @adjustedWages bDollar, 
		@limit bDollar,
		@limitSingle bDollar,
		@limitMarried bDollar, 
		@exempAmt bDollar,
		@rate bRate,
		@procName varchar(30)
 
SELECT  @amt = 0, 
		@adjustedWages = 0, 
		@limit = 0,
		@limitSingle = 2200,
		@limitMarried = 8300, 
		@exempAmt = 3900,
		@rate = .0463,
		@procName = 'bspPRCOT13'
 
-- #26244 set default status and/or exemptions if passed in values are invalid
IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','M')) SELECT @status = 'S'
IF @exempts IS NULL SELECT @exempts = 0

IF @ppds = 0
BEGIN
	SELECT @msg = @procName + ':  Missing # of Pay Periods per year!'
	RETURN 1
END

/* calculate adjusted wages */
SELECT @adjustedWages = (@subjamt * @ppds) - (@exempAmt * @exempts)

/* get percentage limit based on status */
IF @status = 'S' SELECT @limit = @limitSingle
ELSE IF @status = 'M' SELECT @limit = @limitMarried

/*  calculate tax amt = 0 if less than or equal to limit, else
	calculate tax as the amount over the limit multiplied by the rate and de-annualize */
IF @adjustedWages > @limit SELECT @amt = ((@adjustedWages - @limit) * @rate) / @ppds

RETURN 0


GO


GRANT EXECUTE ON  [dbo].[bspPRCOT13] TO [public]
GO
