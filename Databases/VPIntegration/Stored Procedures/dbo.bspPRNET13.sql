SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRNET12]    Script Date: 11/07/2007 10:08:51 ******/
CREATE proc [dbo].[bspPRNET13]
/********************************************************
* CREATED BY: 	bc	06/02/1998
* MODIFIED BY:	bc	06/02/1998
*               EN	01/17/2000	- @tax_addition was dimensioned to int which would throw off tax calculation slightly
*				EN	10/08/2002	- issue 18877 change double quotes to single
*				EN	01/10/2005	- issue 26244  default status and exemptions
*				EN	11/17/2006	- issue 123148  update effective 1/1/2007
*				EN	11/07/2007	- issue 126098  update effective 1/1/2008
*				CHS	12/07/2011	- update effective 1/1/2012
*				CHS	12/06/2012	- issue 147520 B-11768 update effective 1/1/2013
*
* USAGE:
* 	Calculates Nebraska Income Tax
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
    AS
    SET NOCOUNT ON
    
    declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
    @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
    
    SELECT @rcode = 0, @allowance = 1900, @procname = 'bspPRNET13'
    
    -- #26244 set default status and/or exemptions if passed in values are invalid
    IF (@status is null) or (@status is not null and @status not in ('S','M')) SELECT @status = 'S'
    IF @exempts is null select @exempts = 0
    
    IF @ppds = 0
    	BEGIN
    	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    
    	GOTO bspexit
    	END
    
    
    /* annualize earnings */
    SELECT @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance)
    
    /* calculation defaults */
    SELECT @tax_addition = 0, @rate = 0, @amt = 0
    
    /* swingin' single */
    IF @status = 'S'
    	BEGIN    	
		IF		@annualized_wage BETWEEN     0.00 AND  2975 RETURN @rcode --SELECT @tax_addition =       0, @wage_bracket =     0, @rate = 0
		ELSE IF @annualized_wage BETWEEN  2975.01 AND  5325 SELECT @tax_addition =       0, @wage_bracket =  2975, @rate = .0226
		ELSE IF @annualized_wage BETWEEN  5325.01 AND 17275 SELECT @tax_addition =   53.11, @wage_bracket =  5325, @rate = .0322
		ELSE IF @annualized_wage BETWEEN 17275.01 AND 25025 SELECT @tax_addition =  437.90, @wage_bracket = 17275, @rate = .0491
		ELSE IF @annualized_wage BETWEEN 25025.01 AND 31775 SELECT @tax_addition =  818.43, @wage_bracket = 25025, @rate = .062
		ELSE IF @annualized_wage BETWEEN 31775.01 AND 59675 SELECT @tax_addition = 1236.93, @wage_bracket = 31775, @rate = .0659		
		ELSE												SELECT @tax_addition = 3075.54, @wage_bracket = 59675, @rate = .0695  	
		END
    
    /* Married */
    IF @status = 'M'
    	BEGIN
		IF		@annualized_wage BETWEEN     0.00 AND  7100 RETURN @rcode --SELECT @tax_addition =       0, @wage_bracket =     0, @rate = 0
		ELSE IF @annualized_wage BETWEEN  7100.01 AND 10300 SELECT @tax_addition =       0, @wage_bracket =  7100, @rate = .0226
		ELSE IF @annualized_wage BETWEEN 10300.01 AND 25650 SELECT @tax_addition =   72.32, @wage_bracket = 10300, @rate = .0322
		ELSE IF @annualized_wage BETWEEN 25650.01 AND 39900 SELECT @tax_addition =  566.59, @wage_bracket = 25650, @rate = .0491
		ELSE IF @annualized_wage BETWEEN 39900.01 AND 49500 SELECT @tax_addition = 1266.27, @wage_bracket = 39900, @rate = .062
		ELSE IF @annualized_wage BETWEEN 49500.01 AND 65650 SELECT @tax_addition = 1861.47, @wage_bracket = 49500, @rate = .0659		
		ELSE												SELECT @tax_addition = 2925.76, @wage_bracket = 65650, @rate = .0695  	
		END
    
    
    bspcalc: /* calculate Nebraska Tax */
    
    
    SELECT @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate)) / @ppds
    
    IF @amt < 0 SELECT @amt = 0
    
    bspexit:
    	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRNET13] TO [public]
GO
