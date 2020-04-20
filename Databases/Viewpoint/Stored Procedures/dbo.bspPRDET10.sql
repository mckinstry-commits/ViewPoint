SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRDET10    Script Date: 8/28/99 9:33:16 AM ******/
   CREATE proc [dbo].[bspPRDET10]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY: EN 12/16/98
   * MODIFIED BY: EN 11/30/99 - tax table changes effective 1/1/2000
   *              bc 05/22/01 - make sure we do not return negative tax amounts
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 1/4/05 - issue 26244  default status and exemptions
   *				EN 12/17/09 #137132  update effective 1/1/2010
   *
   * USAGE:
   * 	Calculates Delaware Income Tax
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
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
    @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @stddedn bDollar, @taxincome bDollar, @basetax bDollar,
   @limit bDollar, @rate bRate, @persexempt bDollar, @procname varchar(30)
   
   select @rcode = 0, @persexempt = 110, @procname = 'bspPRDET10'
   
   -- #26244 set default status and/or exemptions if passed in values are invalid
   if (@status is null) or (@status is not null and @status not in ('S','M','F')) select @status = 'S'
   if @exempts is null select @exempts = 0
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine standard deduction */
   select @stddedn = 0
   if @status = 'S' select @stddedn = 3250 /* single */
   if @status = 'M' select @stddedn = 6500 /* married */
   if @status = 'F' select @stddedn = 3250 /* married filing separately */
   
   /* annualize subject amount and subtract standard deduction to get taxable income */
   select @taxincome = (@subjamt * @ppds) - @stddedn
   if @taxincome < 0 select @taxincome = 0
   
   /* determine base tax and rate */
   select @basetax = 0, @limit = 0, @rate = 0
   if @taxincome >= 2000 and @taxincome < 5000 select @basetax = 0, @limit = 2000, @rate = .022
   if @taxincome >= 5000 and @taxincome < 10000 select @basetax = 66, @limit = 5000, @rate = .039
   if @taxincome >= 10000 and @taxincome < 20000 select @basetax = 261, @limit = 10000, @rate = .048
   if @taxincome >= 20000 and @taxincome < 25000 select @basetax = 741, @limit = 20000, @rate = .052
   if @taxincome >= 25000 and @taxincome < 60000 select @basetax = 1001, @limit = 25000, @rate = .0555
   if @taxincome >= 60000 select @basetax = 2943.5, @limit = 60000, @rate = .0695
   
   /* calculate tax */
   select @amt = @basetax + ((@taxincome - @limit) * @rate)
   
   /* subtract personal exemption credit and de-annualize */
   select @amt = (@amt - (@persexempt * @exempts)) / @ppds
   
   if @amt is null or @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDET10] TO [public]
GO
