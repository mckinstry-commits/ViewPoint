SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAZT03    Script Date: 8/28/99 9:33:12 AM ******/
   CREATE  proc [dbo].[bspPRAZT03]
   /********************************************************
   * CREATED BY: 	EN 6/2/98
   * MODIFIED BY:  GG 8/11/98
   *				EN 01/02/02 - update effective 1/1/2002
   *				EN 2/14/02 - issue 15752 - fix to default to lowest rate rather than highest if rate is not specified
   *				EN 9/26/02 - issue 18714  missing 34% tax bracket in code
   *				EN 10/7/02 - issue 18877 change double quotes to single
   *				EN 7/8/03 - issue 21777  update effective 7/1/03
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
   	(@subjamt bDollar = 0, @fedtax bDollar, @fedbasis bDollar, @miscfactor bRate,
    	 @ppds tinyint, @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @rate bRate, @annualearnings bDollar, @procname varchar(30)
   
   select @rcode = 0, @rate = 0, @procname = 'bspPRAZT03'
   select @annualearnings = @subjamt * @ppds --issue 15752 - calculate annual earnings used to determine rate default
   
   /* if either basis or tax is 0, do not calculate tax */
   if @fedbasis = 0 or @fedtax = 0 goto bspexit
   
   /* calculate subject amount - proportion of Federal Tax on Arizonia earnings */
   select @subjamt = (@subjamt * @fedtax) / @fedbasis
   
   /* find tax rate */
   --issue 15752 - default rate to minimum (10% if annual earnings are less than 15,000 ... 18% otherwise)
   select @rate = .1
   if @annualearnings >= 15000 select @rate = .182
   
   if @miscfactor = .1 and @annualearnings < 15000 select @rate = @miscfactor --issue 15752 - added clause that annual earnings must be < 15000 to use 10% rate ... otherwise defaults to 18%
   if @miscfactor = .182 select @rate = @miscfactor
   if @miscfactor = .213 select @rate = @miscfactor
   if @miscfactor = .233 select @rate = @miscfactor
   if @miscfactor = .294 select @rate = @miscfactor
   if @miscfactor = .344 select @rate = @miscfactor
   
   /* calculate tax */
   select @amt = @rate * @subjamt
   
   
   bspexit:
   
   	/* impose limit of $5 per month (or proportional limit per pay period) */
   	if @ppds=12 and @amt >=0 and @amt < 5 select @amt = 5 -- monthly pay period
   	if @ppds=24 and @amt >=0 and @amt < 2.5 select @amt = 2.5 -- semi-monthly
   	if @ppds=26 and @amt >=0 and @amt < 2.3 select @amt = 2.3 -- bi-weekly
   	if @ppds=52 and @amt >=0 and @amt < 1.15 select @amt = 1.15 -- weekly
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAZT03] TO [public]
GO
