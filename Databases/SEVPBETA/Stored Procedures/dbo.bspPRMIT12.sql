SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRMIT12]    Script Date: 11/09/2007 11:13:02 ******/
CREATE  proc [dbo].[bspPRMIT12]
/********************************************************
* CREATED BY: 	bc 5/29/98
* MODIFIED BY:	GG 6/01/98
*			EN 12/21/99 - update for tax table change effective 1/1/2000
*			GG 04/14/00 - reduced tax rate to 4.2%, retro to 1/1/00
*			EN 12/11/01 - update effective 1/1/2002
*			EN 10/8/02 - issue 18877 change double quotes to single
*			EN 12/06/02 - issue 19589  update effective 1/1/2003
*			EN 10/31/03 - issue 22902  update effective 1/1/2004
*			EN 1/12/04 - issue 23481  update effective 1/1/2004 retracts previous 1/1/2004 change for issue 22902
*			EN 6/21/04 - issue 23482  update effective 7/1/2004 change rate from 4% to 3.9%
*			EN 11/11/04 - issue 26150  update effective 1/1/2005 to change allowance from $3100 to $3200
*			EN 1/4/05 - issue 26244  default exemptions
*			EN 10/27/05 - issue 30203  update effecitve 1/1/2006
*			EN 11/15/06 - issue 123103  update effective 1/1/2007
*			EN 10/2/07 - issue 125642  rate update effective 10/1/2007
*			EN 11/9/07 - issue 126154  allowance update effective 1/1/2008
*			EN 11/25/08 - #131229 allowance update effective 1/1/2009
*			CHS	11/22/2010	- #142157 annual empemption update - effective 1/1/2011
*			EN 10/1/2012 D-05891/#147074 Rate and Allowance update effective 10/1/2012
*
* USAGE:
* 	Calculates Michigan (Home of the Red Wings) Income Tax
*
* INPUT PARAMETERS:

*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@exempts	# of exemptions (0-99)
* 	@addtl_exempts	additional exemptions (for disabilites)
*
* OUTPUT PARAMETERS:
*	@amt		calculated tax amount
*	@msg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
**********************************************************/
(@subjamt bDollar = 0, 
 @ppds tinyint = 0, 
 @exempts tinyint = 0, 
 @addtl_exempts tinyint = 0,
 @amt bDollar = 0 OUTPUT, 
 @msg varchar(255) = null OUTPUT)
 
AS
SET NOCOUNT ON

DECLARE @annualized_wage bDollar, 
		@procname varchar(30), 
		@rate bRate

SELECT @rate = .0425

-- #26244 set default exemptions if passed in values are invalid
IF @exempts IS NULL 
BEGIN
	SELECT @exempts = 0
END
IF @addtl_exempts IS NULL 
BEGIN
	SELECT @addtl_exempts = 0
END

IF @ppds = 0
BEGIN
	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!'
	RETURN 1
END

/* annualize earnings and deduct allowance for exemptions */
SELECT @annualized_wage = (@subjamt * @ppds) - ((@exempts + @addtl_exempts) * 3950)

/* make sure that @annualized_wage is not less than zero after calculation */
IF @annualized_wage < 0
BEGIN
	SELECT @annualized_wage = 0
END

/* calculate Michigan Tax */
SELECT @amt = (@annualized_wage * @rate) / @ppds


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspPRMIT12] TO [public]
GO
