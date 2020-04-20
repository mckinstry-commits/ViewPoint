SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRILT99    Script Date: 8/28/99 9:33:23 AM ******/
   CREATE   proc [dbo].[bspPRILT99]
   /********************************************************
   * CREATED BY: 	EN 6/6/98
   * MODIFIED BY:  EN 1/8/99
   *				EN 10/8/02 - issue 18877 change double quotes to single
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
   
   select @rcode = 0, @regallowance = 1650, @addallowance = 1300, @rate = .03
   select @procname = 'bspPRILT99'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine taxable income */
   select @taxincome = @subjamt - (((@regexempts * @regallowance) + (@addexempts * @addallowance)) / @ppds)
   if @taxincome < 0 select @taxincome = 0
   
   /* calculate tax */
   select @amt = @taxincome * @rate
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRILT99] TO [public]
GO
