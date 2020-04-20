SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRILT002    Script Date: 8/28/99 9:33:23 AM ******/
   CREATE proc [dbo].[bspPRILT002]
   /********************************************************
   * CREATED BY: 	EN 6/6/98
   * MODIFIED BY:  EN 1/8/99
   * MODIFIED BY:  EN 10/19/99 - effective 1/1/2000
   * MODIFIED BY:  EN 11/02/99 - fix for slight computation error
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 1/4/05 - issue 26244  default exemptions
   *
   * USAGE:
   * 	Calculates Illinois Income Tax
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
   (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1), @regexempts tinyint = 0,
    @addexempts tinyint = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @taxincome bDollar, @regallowance bDollar, @addallowance bDollar,
   	@rate bRate, @procname varchar(30)
   
   select @rcode = 0, @regallowance = 2000, @addallowance = 1000, @rate = .03
   select @procname = 'bspPRILT002'
   
   -- #26244 set default exemptions if passed in values are invalid
   if @regexempts is null select @regexempts = 0
   if @addexempts is null select @addexempts = 0
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine taxable income */
   select @taxincome = (@subjamt * @ppds) - (@regexempts * @regallowance) - (@addexempts * @addallowance)
   if @taxincome < 0 select @taxincome = 0
   
   /* calculate tax */
   select @amt = round(((@taxincome * @rate) / @ppds),2)
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRILT002] TO [public]
GO
