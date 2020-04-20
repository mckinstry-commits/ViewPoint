SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRLAT032    Script Date: 8/28/99 9:33:25 AM ******/
   CREATE     proc [dbo].[bspPRLAT032]
   /********************************************************
   * CREATED BY: 	EN 6/6/98
   * MODIFIED BY:	EN 6/6/98
   *				EN 1/17/02 - issue 15940 - tax not calculated correctly
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 11/19/02 - issue 19394  tax update effective 1/1/2003
   *				EN 2/14/03 - issue 20151  replace check for over 2 reg exempts with code to put overflow into addl exempts
   *
   * USAGE:
   * 	Calculates Louisianna Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@regexempts	# of personal exemptions
   *	@addlexempts	# of dependents
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @regexempts tinyint = 0,
    @addlexempts tinyint = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @annualsalary bDollar, @taxincome bDollar, @exempt bDollar, @exemptamt bDollar,
   @credit bDollar, @creditamt bDollar, @wh bDollar, @addlwh bDollar, @taxrate1 bRate,
   @taxrate2 bRate, @lowbracket bDollar, @highbracket bDollar, @lowtax bDollar, @hightax bDollar,
   @execred1 bDollar, @execred2 bDollar, @procname varchar(30)
   
   select @rcode = 0, @exempt = 4500, @credit = 1000, @taxrate1 = .021, @taxrate2 = .0135 select @procname = 'bspPRLAT032'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /*-- regular exemption amount must be 0, 1 or 2
   if @regexempts <> 0 and @regexempts <> 1 and @regexempts <>2
   	begin
   	select @msg = @procname + ':  Regular exemptions must be 0, 1 or 2!', @rcode = 1
   	goto bspexit
   	end*/ -- commented out for issue 20151
   
   -- issue 20151  regular exemptions over 2 are transferred to additional exemptions
   if @regexempts > 2
   	begin
   	select @addlexempts = @addlexempts + (@regexempts - 2)
   	select @regexempts = 2
   	end
   
   /* annualize salary (S) */
   select @annualsalary = @subjamt * @ppds
   if @annualsalary < 0 select @annualsalary = 0
   
   /* determine exemptions and credits */
   select @exemptamt = @regexempts * @exempt
   select @creditamt = @addlexempts * @credit
   
   -- determine income brackets
   if @regexempts < 2
   	select @lowbracket = 12500, @highbracket = 25000
   else
   	select @lowbracket = 25000, @highbracket = 50000
   
   -- determine tax income (A)
   select @taxincome = @annualsalary * @taxrate1
   
   -- determine low tax and high tax (B & C)
   select @lowtax = @taxrate2 * (@annualsalary - @lowbracket)
   if @lowtax < 0 select @lowtax = 0
   select @hightax = @taxrate2 * (@annualsalary - @highbracket)
   if @hightax < 0 select @hightax = 0
   
   -- exemption & credit calculations #1 (D)
   select @execred1 = @taxrate1 * (@exemptamt + @creditamt)
   
   -- exemption and credit calculations #2 (E)
   select @execred2 = @taxrate2 * ((@exemptamt + @creditamt) - @lowbracket)
   if @execred2 < 0 select @execred2 = 0
   
   -- calculate tax ( (A+B+C)-(D+E) )
   select @amt = (@taxincome + @lowtax + @hightax) - (@execred1 + @execred2)
   if @amt < 0 select @amt = 0
   
   /* de-annualize */
   select @amt = @amt / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRLAT032] TO [public]
GO
