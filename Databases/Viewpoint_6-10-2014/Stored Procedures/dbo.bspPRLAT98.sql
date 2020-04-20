SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRLAT98    Script Date: 8/28/99 9:33:25 AM ******/
   CREATE   proc [dbo].[bspPRLAT98]
   /********************************************************
   * CREATED BY: 	EN 6/6/98
   * MODIFIED BY:	EN 6/6/98
   *				EN 1/17/02 - issue 15940 - tax not calculated correctly
   *				EN 10/8/02 - issue 18877 change double quotes to single
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
   
   declare @rcode int, @taxincome bDollar, @exempt bDollar, @exemptamt bDollar,
   @credit bDollar, @creditamt bDollar, @wh bDollar, @addlwh bDollar, @addlwhrate bRate,
   @taxrate bRate, @procname varchar(30)
   
   select @rcode = 0, @exempt = 4500, @credit = 1000, @addlwhrate = .01, @taxrate = .02 select @procname = 'bspPRLAT98'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize income */
   select @taxincome = @subjamt * @ppds
   if @taxincome < 0 select @taxincome = 0
   
   /* determine exemptions and credits */
   select @exemptamt = @regexempts * @exempt
   select @creditamt = @addlexempts * @credit
   
   /* determine additional withholding */
   select @wh = 5000
     if @regexempts > 1 select @wh = 15000 --issue 15940 - changed @addlexempts to @regexempts
    select @addlwh = @addlwhrate * (@taxincome - @wh - @exemptamt - @creditamt)
   if @addlwh < 0 select @addlwh = 0
   
   /* calculate tax */
   select @amt = (@taxrate * (@taxincome - (@exemptamt + @creditamt))) + @addlwh
   if @amt < 0 select @amt = 0
   
   /* de-annualize */
   select @amt = @amt / @ppds
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRLAT98] TO [public]
GO
