
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROC [dbo].[bspPRVTT13]
/********************************************************
* CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
* MODIFIED BY:	EN 10/9/02 - issue 18877 change double quotes to single
*				EN 12/2/02 - issue 19527  update effective 1/1/2003
*				EN 11/14/03 - issue 23021  update effective 1/1/2004
*				EN 12/08/04 - issue 26448  update effective 1/1/2005
*				EN 1/11/05 - issue 26244  default status AND exemptions
*				EN 12/12/05 - issue 119629  update effective 1/1/2006
*				EN 12/08/06 - issue 123285
*				EN 12/13/07 - issue 126486 update effective 1/1/2008
*				EN 12/11/08 - #131415  update effective 1/1/2009
*				EN 12/4/2010 #136924  update effective 1/1/2010
*				LS 12/29/2010 #142644 - update effective 1/1/2011
*				KK 12/26/2011 TK-11096 #145286 update effective 1/1/2012
*				EN 1/07/2013 B-12117/#147795/TK-20624
*
* USAGE:
* 	Calculates Vermont Income Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status
*	@exempts	# of exemptions
*
* OUTPUT PARAMETERS:
*	@amt	calculated tax amount
*	@msg	error message IF failure
*
* RETURN VALUE:
* 	0 	    success
*	1 		failure
**********************************************************/
(@subjamt bDollar = 0, 
 @ppds tinyint = 0, 
 @status char(1) = 'S', 
 @exempts tinyint = 0,
 @amt bDollar = 0 OUTPUT, 
 @msg varchar(255) = NULL OUTPUT)
 
AS
SET NOCOUNT ON

DECLARE @AnnualizedWage bDollar, 
		@Rate bRate, 
		@BaseTax bDollar,
		@ExcessWage bDollar,
		@ProcName varchar(30)

SELECT @ProcName = 'bspPRVTT13'

-- #26244 set default status AND/or exemptions IF passed in values are invalid
IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','M')) SELECT @status = 'S'
IF @exempts IS NULL SELECT @exempts = 0

IF @ppds = 0
BEGIN
	SELECT @msg = @ProcName + ':  Missing # of Pay Periods per year!'
	RETURN 1
END 

-- annualize taxable income
SELECT @AnnualizedWage = (@subjamt * @ppds) - (@exempts * 3900)

IF @AnnualizedWage < 0 SELECT @AnnualizedWage = 0

-- single folk
IF @status = 'S'
BEGIN
	IF @AnnualizedWage      BETWEEN   2650.01 AND  38450 SELECT @BaseTax =     0.00, @Rate = .0355, @ExcessWage = @AnnualizedWage -   2650
	ELSE IF @AnnualizedWage BETWEEN  38450.01 AND  90050 SELECT @BaseTax =  1270.90, @Rate = .0680, @ExcessWage = @AnnualizedWage -  38450
	ELSE IF @AnnualizedWage BETWEEN  90050.01 AND 185450 SELECT @BaseTax =  4779.70, @Rate = .0780, @ExcessWage = @AnnualizedWage -  90050
	ELSE IF @AnnualizedWage BETWEEN 185450.01 AND 400550 SELECT @BaseTax = 12220.90, @Rate = .0880, @ExcessWage = @AnnualizedWage - 185450
	ELSE IF @AnnualizedWage > 400550                     SELECT @BaseTax = 31149.70, @Rate = .0895, @ExcessWage = @AnnualizedWage - 400550
	ELSE
	BEGIN
		SELECT @amt = 0
		RETURN 0
	END
END

-- married folk
IF @status = 'M'
BEGIN
	IF @AnnualizedWage      BETWEEN   8000.01 AND  66800 SELECT @BaseTax =     0.00, @Rate = .0355, @ExcessWage = @AnnualizedWage -   8000
	ELSE IF @AnnualizedWage BETWEEN  66800.01 AND 152650 SELECT @BaseTax =  2087.40, @Rate = .0680, @ExcessWage = @AnnualizedWage -  66800
	ELSE IF @AnnualizedWage BETWEEN 152650.01 AND 229300 SELECT @BaseTax =  7925.20, @Rate = .0780, @ExcessWage = @AnnualizedWage - 152650
	ELSE IF @AnnualizedWage BETWEEN 229300.01 AND 404600 SELECT @BaseTax = 13903.90, @Rate = .0880, @ExcessWage = @AnnualizedWage - 229300
	ELSE IF @AnnualizedWage > 404600                     SELECT @BaseTax = 29330.30, @Rate = .0895, @ExcessWage = @AnnualizedWage - 404600
	ELSE
	BEGIN
		SELECT @amt = 0
		RETURN 0
	END
END

-- Calculate Vermont Tax
SELECT @amt = (@BaseTax + (@ExcessWage * @Rate)) / @ppds

RETURN 0  -- Return Successfully

GO


GRANT EXECUTE ON  [dbo].[bspPRVTT13] TO [public]
GO
