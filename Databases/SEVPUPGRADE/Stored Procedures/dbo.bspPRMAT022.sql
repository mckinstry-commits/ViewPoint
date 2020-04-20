SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMAT022    Script Date: 8/28/99 9:33:26 AM ******/
     CREATE   proc [dbo].[bspPRMAT022]
     /********************************************************
     * CREATED BY: 	bc 6/1/98
     * MODIFIED BY:  EN 12/20/00 - tax update effective 1/1/2001
     *				GG 08/06/01 - tax amount cannot be negative
     *				 EN 12/19/01 - update effective 1/1/2002
     *				EN 8/28/02 issue 18400 amendment to update effective 1/1/2002, retroactive
     *				EN 10/8/02 - issue 18877 change double quotes to single
     *
     * USAGE:
     * 	Calculates Massachusettes Income Tax
     *
     * INPUT PARAMETERS:
     *	@subjamt 	subject earnings
     *	@ppds		# of pay pds per year
     *	@exempts	# of exemptions (0-99)
     *	@addtl_exempts	# additional exemptions (for disabilities)
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
     @addtl_exempts tinyint = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
     as
    
     set nocount on
    
     declare @rcode int, @annualized_wage bDollar, @dedn bDollar, @rate bRate,
     @procname varchar(30), @total_exempts tinyint, @FICArate bRate
    
     select @rcode = 0, @rate = .053, @procname = 'bspPRMAT022', @FICArate = .0765
    
     -- Note: @FICArate = social security rate + medicare rate
    
     if @ppds = 0
     	begin
     	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
     	goto bspexit
     	end
    
     /* annualize earnings  */
     select @annualized_wage = (@subjamt * @ppds)
    
    
     /* not eligable for state tax if earnings below 8K */
     if @exempts >= 1 and @annualized_wage <= 8000 goto bspexit
    
     if (@annualized_wage * @FICArate) < 2000
     	select @annualized_wage = @annualized_wage - (@annualized_wage * @FICArate)
     else
     	select @annualized_wage = @annualized_wage - 2000
    
    
     select @total_exempts = @exempts + @addtl_exempts
    
    
     if @total_exempts = 1
     	select @annualized_wage = @annualized_wage - 3300
    
     if @total_exempts >1
     	select @annualized_wage = @annualized_wage - (@total_exempts * 1000) - 2300
    
     -- subtract extra deduction if head of household
     if @status = 'H' select @annualized_wage = @annualized_wage - 2400
    
     bspcalc: /* calculate Massachusettes Tax */
     	select @amt = (@annualized_wage * @rate) / @ppds
    
     bspexit:
    	if @amt < 0 select @amt = 0	-- tax amount should not be negative
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMAT022] TO [public]
GO
