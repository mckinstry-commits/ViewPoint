SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRDET98    Script Date: 8/28/99 9:33:16 AM ******/
   CREATE  proc [dbo].[bspPRDET98]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY: GG 8/11/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
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
   
   select @rcode = 0, @persexempt = 100, @procname = 'bspPRDET98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine standard deduction */
   select @stddedn = 0
   if @status = 'S' select @stddedn = 1300 /* single */
   if @status = 'M' select @stddedn = 1600 /* married */
   if @status = 'F' select @stddedn = 800 /* married filing separately */
   
   /* annualize subject amount and subtract standard deduction to get taxable income */
   select @taxincome = (@subjamt * @ppds) - @stddedn
   if @taxincome < 0 select @taxincome = 0
   
   /* determine base tax and rate */
   select @basetax = 0, @limit = 0, @rate = 0
   if @taxincome >= 2000 and @taxincome < 5000 select @basetax = 0, @limit = 2000, @rate = .031 
   if @taxincome >= 5000 and @taxincome < 10000 select @basetax = 93, @limit = 5000, @rate = .0485
   if @taxincome >= 10000 and @taxincome < 20000 select @basetax = 335.5, @limit = 10000, @rate = .058
   if @taxincome >= 20000 and @taxincome < 25000 select @basetax = 915.5, @limit = 20000, @rate = .0615
   if @taxincome >= 25000 and @taxincome < 30000 select @basetax = 1223, @limit = 25000, @rate = .0645
   if @taxincome >= 30000 select @basetax = 1545.5, @limit = 30000, @rate = .069
   
   /* calculate tax */
   select @amt = @basetax + ((@taxincome - @limit) * @rate)
   
   /* subtract personal exemption credit and de-annualize */
   select @amt = (@amt - (@persexempt * @exempts)) / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDET98] TO [public]
GO
