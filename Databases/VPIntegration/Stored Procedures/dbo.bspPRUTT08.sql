SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRUTT08]    Script Date: 11/06/2007 08:37:01 ******/
    CREATE proc [dbo].[bspPRUTT08]
    /********************************************************
    * CREATED BY: 	bc 6/8/98
    * MODIFIED BY:	bc 6/8/98
    *				EN 12/18/01 - update effective 1/1/2002
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 1/11/05 - issue 26244  default status and exemptions
    *				EN 11/1/06 - issue 122962 update effective 1/1/2007
	*				EN 11/06/07 - issue 126096 update effective 1/1/2008
    *
    * USAGE:
    * 	Calculates Utah Income Tax
    *
    * INPUT PARAMETERS:
    *	@subjamt 	subject earnings
    *	@ppds		# of pay pds per year
    *	@status		filing status
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
    (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
    @amt bDollar = 0 output, @msg varchar(255) = null output)
    as
    set nocount on
    
    declare @rcode int, @annualized_wage bDollar, @rate bRate, @wage_bracket int,
    @procname varchar(30), @creditperallowance int
    
    
    select @rcode = 0, @procname = 'bspPRUTT08', @creditperallowance = 125
    
    -- #26244 set default status and/or exemptions if passed in values are invalid
    if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
    if @exempts is null select @exempts = 0
    
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    
    	goto bspexit
    	end
    
    
    /* annualize taxable income  */
    select @annualized_wage = (@subjamt * @ppds)
    
    
    /* select calculation elements for single folk */
    if @status = 'S'
    begin
    	if @annualized_wage < 6600 goto bspexit
    	if @annualized_wage >= 6600 select @rate = .01, @wage_bracket = 6600
    	if @annualized_wage >= 8200 select @rate = .02, @wage_bracket = 8200
    	if @annualized_wage >= 11000 select @rate = .03, @wage_bracket = 11000
    	if @annualized_wage >= 14700 select @rate = .04, @wage_bracket = 14700
    	if @annualized_wage >= 21100 select @rate = .05, @wage_bracket = 21100
    	if @annualized_wage >= 39800 select @rate = .05, @wage_bracket = 39800
    end
    
    /* select calculation elements for married folk */
    if @status = 'M'
    begin
    	if @annualized_wage < 13200 goto bspexit
    	if @annualized_wage >= 13200 select @rate = .01, @wage_bracket = 13200
    	if @annualized_wage >= 16400 select @rate = .02, @wage_bracket = 16400
    	if @annualized_wage >= 22000 select @rate = .03, @wage_bracket = 22000
    	if @annualized_wage >= 29400 select @rate = .04, @wage_bracket = 29400
    	if @annualized_wage >= 42200 select @rate = .05, @wage_bracket = 42200
    	if @annualized_wage >= 79600 select @rate = .05, @wage_bracket = 79600
    end
    
    bspcalc: /* calculate Utah Tax */
    
    
    select @amt = ((@annualized_wage * @rate) - (@creditperallowance * @exempts)) / @ppds
    if @amt < 0 select @amt = 0
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUTT08] TO [public]
GO
