SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRINT00    Script Date: 8/28/99 9:33:23 AM ******/
   CREATE   proc [dbo].[bspPRINT00]
   /********************************************************
   * CREATED BY: 	EN 6/6/98
   * MODIFIED BY:	GG 8/11/98
   * MODIFIED BY:  EN 11/30/99 - add code for including qualifying dependent exemption which btw changed from 500 to 1500, effective 1/1/99
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Indiana Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
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
   (@subjamt bDollar = 0, @ppds tinyint = 0, @exempts tinyint = 0, @addexempts tinyint = 0,
    @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @taxincome bDollar, @allowance bDollar, @qallowance bDollar,
    @rate bRate, @procname varchar(30)
   
   select @rcode = 0, @allowance = 1000, @qallowance = 1500, @rate = .034
   select @procname = 'bspPRINT00'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* determine taxable income */
   select @taxincome = (@subjamt * @ppds) - (@exempts * @allowance) - (@addexempts * @qallowance)
   if @taxincome < 0 select @taxincome = 0
   
   /* calculate tax */
   select @amt = (@taxincome * @rate) / @ppds
   
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRINT00] TO [public]
GO
