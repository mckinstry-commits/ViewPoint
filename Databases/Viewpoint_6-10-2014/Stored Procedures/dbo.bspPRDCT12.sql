SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPRDCT12]
/********************************************************
* CREATED BY: 	EN 12/20/00 - tax update effective 1/1/2001
*				GH 9/27/01 - issue 14740 correct wage bracket to 20K-30K
* Modified By:  EN 10/31/01 - issue 15106 update effective 1/1/2002
*				EN 4/25/02 - issue 17112 Wash DC recinds last tax update ... it reverts back to 2001 rates
*				EN 10/8/02 - issue 18877 change double quotes to single
*				EN 12/23/04 - issue 26634  update effective 1/1/2005
*				EN 12/31/04 - issue 26244  default status and exemptions
*				EN 1/11/05 - issue 26774  fixed minimum limit, status 'F'
*				EN 12/22/05 - issue 119704  update effective 1/1/2006
*				EN 1/16/07 - issue 123575  update effective 1/1/2007
*				EN 1/10/08 - issue 126686  update effective 1/1/2008
*				EN 12/12/08 - #131426  update effective 1/1/2009
*				EN 1/22/2010 #137613  update effective 1/1/2010
*				KK 11/28/11 - TK-10386 #144827 update effective 1/1/2012, Also refactored code.
*
* USAGE:
* 	Calculates District of Columbia Income Tax
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
* 	0 			success
*	1 			failure
**********************************************************/
(@subjamt bDollar = 0, 
 @ppds tinyint = 0, 
 @status char(1) = 'S', 
 @exempts tinyint = 0,
 @amt bDollar = 0 OUTPUT, 
 @msg varchar(255) = NULL OUTPUT)

AS
SET NOCOUNT ON

DECLARE @rcode int, 
		@a bDollar, 
		@procname varchar(30)

SELECT  @rcode = 0, 
	    @procname = 'bspPRDCT12'

-- #26244 set default exemptions if passed in values are invalid
IF @exempts IS NULL SELECT @exempts = 0

IF @ppds <> 0
BEGIN
	/* annualize subject amount and subtract exemption amt */
	SELECT @a = (@subjamt * @ppds) - (1675 * @exempts)
	IF @a <= 0 
	BEGIN
		SELECT @amt = 0
		RETURN 0
	END

	/* calculate tax */
	SELECT @amt = 0
	IF @a <= 10000 
	BEGIN 
		SELECT @amt = @a * .04 
	END
	
	ELSE IF @a BETWEEN 10000.01 AND 40000
	BEGIN
		SELECT @amt = (400 + (@a - 10000) * .06)
	END
	
	ELSE IF @a BETWEEN 40000.01 AND 350000
	BEGIN
		SELECT @amt = (2200 + (@a - 40000) * .085)
	END
	
	ELSE 
	BEGIN
		SELECT @amt = (28550 + (@a - 350000) * .0895)
	END
	
	SELECT @amt = @amt / @ppds
END

ELSE
BEGIN
	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
	RETURN @rcode
END

RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRDCT12] TO [public]
GO
