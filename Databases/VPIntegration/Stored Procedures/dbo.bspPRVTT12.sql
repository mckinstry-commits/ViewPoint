SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[bspPRVTT12]    Script Date: 12/13/2007 08:31:44 ******/
CREATE  PROC [dbo].[bspPRVTT12]
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
BEGIN

SET NOCOUNT ON

DECLARE @AnnualizedWage bDollar, 
		@Rate bRate, 
		@BaseTax bDollar,
		@ExcessWage bDollar,
		@Bracket1 int,
		@Bracket2 int,
		@Bracket3 int,
		@Bracket4 int,
		@Bracket5 int,
		@ProcName varchar(30)

SELECT @ProcName = 'bspPRVTT12'

-- #26244 set default status AND/or exemptions IF passed in values are invalid
IF (@status IS NULL) OR (@status IS NOT NULL AND @status NOT IN ('S','M')) SELECT @status = 'S'
IF @exempts IS NULL SELECT @exempts = 0

IF @ppds = 0
BEGIN
	SELECT @msg = @ProcName + ':  Missing # of Pay Periods per year!'
	RETURN 1
END 

/* annualize taxable income  */
SELECT @AnnualizedWage = (@subjamt * @ppds) - (@exempts * 3800)

IF @AnnualizedWage < 0 SELECT @AnnualizedWage = 0

/* SELECT calculation elements for single folk */
IF @status = 'S'
BEGIN
	SELECT @Bracket1 = 2650, 
		   @Bracket2 = 37500, 
		   @Bracket3 = 87800,
		   @Bracket4 = 180800,
		   @Bracket5 = 390500
	--1st bracket - No Tax 
	IF @AnnualizedWage BETWEEN 0 AND @Bracket1
	BEGIN
		SELECT @amt = 0
		RETURN 0
	END
	--2nd bracket
	ELSE IF @AnnualizedWage BETWEEN (@Bracket1 + .01) AND @Bracket2
	BEGIN
		SELECT @BaseTax = 0,
			   @Rate = .0355,
			   @ExcessWage = @AnnualizedWage - @Bracket1
	END
	--3rd bracket
	ELSE IF @AnnualizedWage BETWEEN (@Bracket2 + .01) AND @Bracket3
	BEGIN
		SELECT @BaseTax = 1237.15, 
			   @Rate = .0680,
			   @ExcessWage = @AnnualizedWage - @Bracket2
	END
	--4th bracket
	ELSE IF @AnnualizedWage BETWEEN (@Bracket3 + .01) AND @Bracket4
	BEGIN
		SELECT @BaseTax = 4657.58, 
			   @Rate = .0780,
			   @ExcessWage = @AnnualizedWage - @Bracket3
	END
	--5th bracket
	ELSE IF @AnnualizedWage BETWEEN (@Bracket4 + .01) AND @Bracket5
	BEGIN
		SELECT @BaseTax = 11911.58, 
			   @Rate = .0880,
			   @ExcessWage = @AnnualizedWage - @Bracket4
	END
	--6th bracket (highest)
	ELSE IF @AnnualizedWage > @Bracket5
	BEGIN
		SELECT @BaseTax = 30365.18,
			   @Rate = .0895,
			   @ExcessWage = @AnnualizedWage - @Bracket5
	END
END

/* SELECT calculation elements for married folk */
IF @status = 'M'
BEGIN
	SELECT @Bracket1 = 8000, 
		   @Bracket2 = 65800, 
		   @Bracket3 = 150800,
		   @Bracket4 = 225550,
		   @Bracket5 = 396450
	--1st bracket - No Tax 
	IF @AnnualizedWage BETWEEN 0 AND @Bracket1
	BEGIN
		SELECT @amt = 0
		RETURN 0
	END
	--2nd bracket
	ELSE IF @AnnualizedWage BETWEEN (@Bracket1 + .01) AND @Bracket2
	BEGIN
		SELECT @BaseTax = 0,
			   @Rate = .0355,
			   @ExcessWage = @AnnualizedWage - @Bracket1
	END
	--3rd bracket
	ELSE IF @AnnualizedWage BETWEEN (@Bracket2 + .01) AND @Bracket3
	BEGIN
		SELECT @BaseTax = 2051.90, 
			   @Rate = .0680,
			   @ExcessWage = @AnnualizedWage - @Bracket2
	END
	--4th bracket
	ELSE IF @AnnualizedWage BETWEEN (@Bracket3 + .01) AND @Bracket4
	BEGIN
		SELECT @BaseTax = 7831.90, 
			   @Rate = .0780,
			   @ExcessWage = @AnnualizedWage - @Bracket3
	END
	--5th bracket
	ELSE IF @AnnualizedWage BETWEEN (@Bracket4 + .01) AND @Bracket5
	BEGIN
		SELECT @BaseTax = 13662.40, 
			   @Rate = .0880,
			   @ExcessWage = @AnnualizedWage - @Bracket4
	END
	--6th bracket (highest)
	ELSE IF @AnnualizedWage > @Bracket5
	BEGIN
		SELECT @BaseTax = 28701.60,
			   @Rate = .0895,
			   @ExcessWage = @AnnualizedWage - @Bracket5
	END
END

/* Calculate Vermont Tax */
SELECT @amt = (@BaseTax + (@ExcessWage * @Rate)) / @ppds

RETURN 0  /* Return Successfully */
END

GO
GRANT EXECUTE ON  [dbo].[bspPRVTT12] TO [public]
GO
