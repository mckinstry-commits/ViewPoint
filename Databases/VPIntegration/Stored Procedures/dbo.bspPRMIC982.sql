SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMIC982    Script Date: 8/28/99 9:33:27 AM ******/
    CREATE proc [dbo].[bspPRMIC982]
    /********************************************************
    * CREATED BY: 	bc 6/12/98
    * MODIFIED BY:	GG 12/14/98
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 1/4/05 - issue 26244  default exempt amount and exemptions
    *
    * USAGE:
    * 	Calculates 1998 Michigan Uniform City Tax
    *
    * INPUT PARAMETERS:
    *	@subjamt 	subject earnings
    *	@ppds		# of pay pds per year
    *	@exemptamt	annual exemption amount
    *   @regexempts # of exemptions
    * 	@rate		tax rate - depends on residency
    *
    * OUTPUT PARAMETERS:
    *	@amt		calculated city tax amount
    *	@msg		error message if failure
    *
    * RETURN VALUE:
    * 	0 	    	success
    *	1 		failure
    **********************************************************/
    (@subjamt bDollar = 0, @ppds tinyint = 0, @exemptamt bDollar = 0, @regexempts tinyint = 0,
     @rate bRate = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
    as
    set nocount on
   
    declare @rcode int, @annualized_wage bDollar, @procname varchar(30)
   
    select @rcode = 0, @procname = 'bspPRMIC982'
   
    -- #26244 set default status and/or exemptions if passed in values are invalid
    if @exemptamt is null select @exemptamt = 0
    if @regexempts is null select @regexempts = 0
   
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    	goto bspexit
    	end
   
   
    /* annualize taxable wages */
    select @annualized_wage = (@subjamt * @ppds) - (@exemptamt * @regexempts)
   
    /* make sure that @annualized_wage is not less than zero after calculation */
    if @annualized_wage < 0 select @annualized_wage = 0
   
    bspcalc: /* calculate Michigan City Tax */
    	select @amt = (@annualized_wage * @rate) / @ppds
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMIC982] TO [public]
GO
