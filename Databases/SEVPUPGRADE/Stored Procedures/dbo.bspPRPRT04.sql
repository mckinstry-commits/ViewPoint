SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPRT04    Script Date: 8/28/99 9:33:32 AM ******/
      CREATE    proc [dbo].[bspPRPRT04]
      /********************************************************
      * CREATED BY: 	EN 12/20/00 - update effective 1/1/2001
      * MODIFIED BY:	EN 12/27/00 - init @tax_subtraction amount in lowest bracket else 0 tax is calculated
      *				EN 1/15/02 - update effective 1/1/2002
      *				EN 10/8/02 - issue 18877 change double quotes to single
      *				EN 12/01/03 issue 23133  update effective 1/1/2004
      *
      * USAGE:
      * 	Calculates Puerto Rico Income Tax
      *
      * INPUT PARAMETERS:
      *	@subjamt 	subject earnings
      *	@ppds		# of pay pds per year
      *	@status		filing status
      *	@exempts	# of exemptions
      *	@addtl_exempts	# of subtractional exemptions for special cases
      *	@mics_factor	Miscellaneous factor.  Signifying how the person is filing their taxes
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
      @addtl_exempts tinyint = 0, @misc_factor tinyint = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
      as
      set nocount on
   
      declare @rcode int, @annualized_wage bDollar, @rate bRate,
      @procname varchar(30), @tax_subtraction bDollar, @deduction int
   
   
      select @rcode = 0, @procname = 'bspPRPRT04'
   
      if @ppds = 0
      	begin
      	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   
      	goto bspexit
      	end
   
   
      /* annualize taxable income then subtract standard deductions and allowances */
   
      select @deduction = 0
      if @status = 'S' select @deduction = 1300
      if @status = 'M' select @deduction = 3000
      if @status = 'B' select @deduction = 1500
      if @status = 'H' select @deduction = 0
   
   
      select @annualized_wage = (@subjamt * @ppds) - @deduction - (@exempts * 1600) - (@addtl_exempts * 500)
      if @annualized_wage < 0 select @annualized_wage = 0
   
   
   
      /* select calculation elements for married people living with spouse and filing separately */
      if @misc_factor = 1
      begin
      	if @annualized_wage <= 1000 select @tax_subtraction = 0, @rate = .07
      	if @annualized_wage > 1000 select @tax_subtraction = 30, @rate = .10
      	if @annualized_wage > 8500 select @tax_subtraction = 455, @rate = .15
      	if @annualized_wage > 15000 select @tax_subtraction = 2405, @rate = .28
      	if @annualized_wage > 25000 select @tax_subtraction = 3655, @rate = .33
      end
   
      /* select calculation elements for everybody else */
      if @misc_factor <> 1 or @misc_factor is null
      begin
      	if @annualized_wage <= 2000 select @tax_subtraction = 0, @rate = .07
      	if @annualized_wage > 2000 select @tax_subtraction = 60, @rate = .10
      	if @annualized_wage > 17000 select @tax_subtraction = 910, @rate = .15
      	if @annualized_wage > 30000 select @tax_subtraction = 4810, @rate = .28
      	if @annualized_wage > 50000 select @tax_subtraction = 7310, @rate = .33
      end
   
      bspcalc: /* calculate Puerto Rico Tax */
   
      select @amt = ((@annualized_wage * @rate) - @tax_subtraction) / @ppds
   
      bspexit:
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPRT04] TO [public]
GO