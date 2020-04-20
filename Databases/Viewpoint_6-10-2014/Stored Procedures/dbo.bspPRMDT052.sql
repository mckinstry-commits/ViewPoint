SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMDT052    Script Date: 8/28/99 9:33:26 AM ******/
    CREATE proc [dbo].[bspPRMDT052]
    /********************************************************
    * CREATED BY: 	EN 11/01/01 - this revision effective 1/1/2002
    * MODIFIED BY:	EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 12/02/03 - issue 23145  update effective 1/1/2004
    *				EN 1/14/04 - issue 23500  Maryland state tax calculating negative amount in certain cases
    *				EN 11/16/04 - issue 26219  update effective 1/1/2005 ... non-resident rate changed to 6% but resident rate base (4.75%) remains the same
    *											passing in @res (Y/N) flag which specifies whether or not employee is a resident
    *				EN 1/4/05 - issue 26244  default exemptions and miscfactor
    *
    * USAGE:
    * 	Calculates Maryland Income Tax
    *
    * INPUT PARAMETERS:
    *	@subjamt 	subject earnings
    *	@ppds		# of pay pds per year
    *	@exempts	# of exemptions
    *	@miscfactor	factor used for speacial tax routines
    *
    * OUTPUT PARAMETERS:
    *	@amt		calculated tax amount
    *	@msg		error message if failure
    *
    * RETURN VALUE:
    * 	0 	    	success
    *	1 		failure
    **********************************************************/
    (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = null, @exempts tinyint = 0,
    @miscfactor bRate = 0, @res char(1) = 'Y', @amt bDollar = 0 output, @msg varchar(255) = null output)
    as
    set nocount on
    
    declare @rcode int, @annualized_wage bDollar, @rate bRate,
    @procname varchar(30), @counter int, @deductions bDollar,
    @tax_addition tinyint, @wage_bracket int
    
    select @rcode = 0, @rate = 0, @procname = 'bspPRMDT052'
   
    -- #26244 set default exemptions and/or misc factor if passed in values are invalid
    if @exempts is null select @exempts = 0
    if @miscfactor is null select @miscfactor = 0
    
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    	goto bspexit
    	end
    
    
    /* annualize earnings */
    select @annualized_wage = (@subjamt * @ppds)
    
    /* no tax on annual income below 5000 */
    if @annualized_wage < 5000
    	begin
    	select @amt = 0
    	goto bspexit
    	end
    
    select @deductions = @annualized_wage * .15
    
    if @deductions < 1500 select @deductions = 1500
    if @deductions > 2000 select @deductions = 2000
    
    
    select @annualized_wage = @annualized_wage - @deductions - (2400 * @exempts)
    
    if @annualized_wage < 0 select @annualized_wage = 0
    
    --issue 26219  **	Resident tax rate is no longer based on the non-resident rate as it used to be.
    --			   **	Non-resident rate has been changed from 4.75% to 6% however resident rate is still based on 4.75%.
    if @res = 'Y' select @rate = .0475 -- resident rate
    if @res = 'N' select @rate = .06 -- non-resident rate
    
    --/* Initialize loop variables to determine the return amt */
    --select @counter = 1000, @tax_addition = 0, @wage_bracket = 0, @rate = .02
    --
    --/* Determine which bracket this person falls into then assign the correct values to the tax factors */
    --while @counter < 4000
    --begin
    --	if @annualized_wage < @counter goto bspcalc
    --
    --	if @counter = 1000 select @tax_addition = 20, @wage_bracket = 1000, @rate = .03
    --	if @counter = 2000 select @tax_addition = 50, @wage_bracket = 2000, @rate = .04
    --	if @counter = 3000 select @tax_addition = 90, @wage_bracket = 3000, @rate = .0475
    --
    --    select @counter = @counter + 1000
    --end
    
    bspcalc: /* calculate Maryland Tax */
    	select @amt = (@annualized_wage * (@rate + @miscfactor)) / @ppds
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMDT052] TO [public]
GO
