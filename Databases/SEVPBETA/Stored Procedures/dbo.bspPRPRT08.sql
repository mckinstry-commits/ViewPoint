SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRPRT08]    Script Date: 01/17/2008 09:12:17 ******/
      CREATE proc [dbo].[bspPRPRT08]
      /********************************************************
      * CREATED BY: 	EN 12/20/00 - update effective 1/1/2001
      * MODIFIED BY:	EN 12/27/00 - init @tax_subtraction amount in lowest bracket else 0 tax is calculated
      *				EN 1/15/02 - update effective 1/1/2002
      *				EN 10/8/02 - issue 18877 change double quotes to single
      *				EN 12/01/03 issue 23133  update effective 1/1/2004
      *				EN 1/11/05 - issue 26244  default status and exemptions
	  *				EN 11/17/06 - issue 123152  update effective 1/1/2007
	  *				EN 1/17/08 - issue 126788  update effective 1/1/2008
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
   
   
      select @rcode = 0, @procname = 'bspPRPRT08'
   
      -- #26244 set default status and/or exemptions if passed in values are invalid
      if (@status is null) or (@status is not null and @status not in ('S','M','B','H')) select @status = 'S'
      if @exempts is null select @exempts = 0
      if @addtl_exempts is null select @addtl_exempts = 0
      if @misc_factor is null select @misc_factor = 0
   
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
   
      if @misc_factor = 2
		select @annualized_wage = (@subjamt * @ppds) - @deduction - (@exempts * 1250) - (@addtl_exempts * 500)
	  else
		select @annualized_wage = (@subjamt * @ppds) - @deduction - (@exempts * 2500) - (@addtl_exempts * 500)

      if @annualized_wage < 0 select @annualized_wage = 0
   
   
   
      /* select calculation elements for married people living with spouse and filing separately */

	  -- Note re. issue coded 1/17/08 - Misc_factor 2 was added for married, both working, filing jointly 
	  --   to allow each spouse to claim 50% of dependent exemption.
	  --   Since the tax bracket used for misc_factor 1 is for married but filing separately, this is not a conflict
	  --   because married, filing jointly would not use the same brackets anyway.

      if @misc_factor = 1
      begin
      	if @annualized_wage <= 8500 select @tax_subtraction = 0, @rate = .07
      	if @annualized_wage > 8500 select @tax_subtraction = 595, @rate = .14
      	if @annualized_wage > 15000 select @tax_subtraction = 2245, @rate = .25
      	if @annualized_wage > 25000 select @tax_subtraction = 4245, @rate = .33
      end
   
      /* select calculation elements for everybody else */
      if @misc_factor <> 1 or @misc_factor is null
      begin
      	if @annualized_wage <= 17000 select @tax_subtraction = 0, @rate = .07
      	if @annualized_wage > 17000 select @tax_subtraction = 1190, @rate = .14
      	if @annualized_wage > 30000 select @tax_subtraction = 4490, @rate = .25
      	if @annualized_wage > 50000 select @tax_subtraction = 8490, @rate = .33
      end
   
      bspcalc: /* calculate Puerto Rico Tax */
   
      select @amt = ((@annualized_wage * @rate) - @tax_subtraction) / @ppds
   
      bspexit:
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPRT08] TO [public]
GO
