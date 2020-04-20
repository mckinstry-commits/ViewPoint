SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAZT102    Script Date: 8/28/99 9:33:12 AM ******/
CREATE proc [dbo].[bspPRAZT102]
/********************************************************
* CREATED BY: 	EN 6/2/98
* MODIFIED BY:  GG 8/11/98
*		EN 01/02/02 - update effective 1/1/2002
*		EN 2/14/02 - issue 15752 - fix to default to lowest rate rather than highest if rate is not specified
*		EN 9/26/02 - issue 18714  missing 34% tax bracket in code
*		EN 10/7/02 - issue 18877 change double quotes to single
*		EN 7/8/03 - issue 21777  update effective 7/1/03
*		EN 11/5/03 - issue 22938  remove $5 per month limit
*		EN 12/23/04 - issue 26632  update effective 1/1/05
*		EN 4/20/2009 #133346  update effective 5/1/2009
*		EN 12/1/2009 #136934  rates updated effective 1/1/2010 ... also updated code used to determine rate to make it easier to maintain rates in the future
*		EN 5/26/2010 #139365  Arizona changing from rate of Federal Tax to Rate of Gross and updating rates.
*							At the same time we are retaining functionality to validate rate and provide default rate.
*		TJL 09/01/10 - issue #141012, Use MiscFactor of 1.3% regardless of Annualized Earnings (Even when less than 15000)
*
* USAGE:
* 	Calculates Arizona Income Tax
*
* INPUT PARAMETERS:
*	@subjamt	subject earnings
*	@fedtax	 	Federal Tax
*	@fedbasis	earnings subject to Federal Tax
*	@miscfactor	Arizonia tax rate 
*	@ppds		# of pay period per year (parameter added with issue 15752)
*
* OUTPUT PARAMETERS:
*	@amt		calculated tax amount
*	@msg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
**********************************************************/
(@subjamt bDollar = 0, @miscfactor bRate,
	 @ppds tinyint, @amt bDollar = 0 output, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @rate bRate, @annualearnings bDollar, @procname varchar(30)
   
select @rcode = 0, @rate = 0, @procname = 'bspPRAZT102'
select @annualearnings = @subjamt * @ppds --issue 15752 - calculate annual earnings used to determine rate default

/* find tax rate */
-- rate should always default to lowest rate which differs depending on the annual earnings
if @annualearnings >= 15000 
	select @rate = .018
else
	select @rate = .013

-- default rate
if @miscfactor in (.013, .018, .027, .036, .042, .051)
	begin
	select @rate = @miscfactor
	end
   
/* calculate tax */
select @amt = @rate * @subjamt
   
bspexit:
   
return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspPRAZT102] TO [public]
GO
