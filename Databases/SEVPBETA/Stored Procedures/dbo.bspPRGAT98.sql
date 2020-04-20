SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRGAT98    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE   proc [dbo].[bspPRGAT98]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY:	EN 6/5/98
   *               GH 9/8/99 Corrected unmarried head of household or married filing jointly and one
   *                         spouse working rates, and way exemptions are handled.
   *				EN 10/8/02 - issue 18877 change double quotes to single
   * USAGE:
   * 	Calculates Georgia Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status
   *	@regexempts	# of regular exemptions
   *	@addexempts	# of additional exemptions
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @regexempts tinyint = 0,
    @addexempts tinyint = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @adultexempt bDollar, @stddedn bDollar, @taxincome bDollar,
   @basetax bDollar, @limit bDollar, @rate bRate, @rate1 bRate, @rate2 bRate, @rate3 bRate,
   @rate4 bRate, @rate5 bRate, @rate6 bRate, @procname varchar(30)
   
   
   select @rcode = 0
   select @rate1 = .01, @rate2 = .02, @rate3 = .03, @rate4 = .04, @rate5 = .05, @rate6 = .06
   select @procname = 'bspPRGAT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine adult exemption */
   select @adultexempt = 0
   select @adultexempt = @addexempts * 2700
   
   /*if @status = 'M' or @status = 'B' select @adultexempt = 5400
   if @status = 'S' or @status = 'H' or @status = 'F' select @adultexempt = 2700
   if @addexempts >= 1 and @addexempts <= 2 select @adultexempt = @addexempts * 2700 */
   
   /* determine standard deduction */
   select @stddedn = 3000
   if @status = 'S' or @status = 'H' select @stddedn = 2300
   if @status = 'F' or @status = 'B' select @stddedn = 1500
   
   /* determine taxable income */
   select @taxincome = (@subjamt * @ppds) - @stddedn - @adultexempt - (@regexempts * 2700)
   if @taxincome < 0 select @taxincome = 0
   
   /* determine base tax and rate */
   /* single */
   if @status = 'S'
   	begin
   	 if @taxincome < 750 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxincome >= 750 and @taxincome < 2250 select @basetax = 7.5, @limit = 750, @rate = @rate2
   	 if @taxincome >= 2250 and @taxincome < 3750 select @basetax = 37.5, @limit = 2250, @rate = @rate3
   	 if @taxincome >= 3750 and @taxincome < 5250 select @basetax = 82.5, @limit = 3750, @rate = @rate4
   	 if @taxincome >= 5250 and @taxincome < 7000 select @basetax = 142.5, @limit = 5250, @rate = @rate5
   	 if @taxincome >= 7000 select @basetax = 230, @limit = 7000, @rate = @rate6
   	end
   
   /* unmarried head of household or married filing jointly and one spouse working */
   if @status = 'H' or @status = 'M'
   	begin
   	 if @taxincome < 1000 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxincome >= 1000 and @taxincome < 3000 select @basetax = 10, @limit = 1000, @rate = @rate2
   	 if @taxincome >= 3000 and @taxincome < 5000 select @basetax = 50, @limit = 3000, @rate = @rate3
   	 if @taxincome >= 5000 and @taxincome < 7000 select @basetax = 110, @limit = 5000, @rate = @rate4
   	 if @taxincome >= 7000 and @taxincome < 10000 select @basetax = 190, @limit = 7000, @rate = @rate5
   	 if @taxincome >= 10000 select @basetax = 340, @limit = 10000, @rate = @rate6
   	end
   
   /* married filing separately or married both working */
   if @status = 'F' or @status = 'B'
   	begin
   	 if @taxincome < 500 select @basetax = 0, @limit = 0, @rate = @rate1
   	 if @taxincome >= 500 and @taxincome < 1500 select @basetax = 5, @limit = 500, @rate = @rate2
   	 if @taxincome >= 1500 and @taxincome < 2500 select @basetax = 25, @limit = 1500, @rate = @rate3
   	 if @taxincome >= 2500 and @taxincome < 3500 select @basetax = 55, @limit = 2500, @rate = @rate4
   	 if @taxincome >= 3500 and @taxincome < 5000 select @basetax = 95, @limit = 3500, @rate = @rate5
   	 if @taxincome >= 5000 select @basetax = 170, @limit = 5000, @rate = @rate6
   	end
   
   /* calculate tax */
   select @amt = (@basetax + ((@taxincome - @limit) * @rate)) / @ppds
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode
   
   IF OBJECT_ID('dbo.bspPRGAT98') IS NOT NULL
       PRINT '<<< CREATED PROCEDURE dbo.bspPRGAT98 >>>'
   ELSE
       PRINT '<<< FAILED CREATING PROCEDURE dbo.bspPRGAT98 >>>'

GO
GRANT EXECUTE ON  [dbo].[bspPRGAT98] TO [public]
GO
