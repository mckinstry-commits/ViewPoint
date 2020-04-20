
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRNYT13]    Script Date: 10/26/2007 10:20:46 ******/
CREATE  proc [dbo].[bspPRNYT13]
/********************************************************
* CREATED BY: 	bc 6/4/98
* MODIFIED BY:	bc 6/4/98
* MODIFIED BY:  EN 1/17/00 - tax addition variable was not being initialized for the lowest bracket which would have caused no tax to calculate
*				EN 10/8/02 - issue 18877 change double quotes to single
*				EN 7/7/03 - issue 21770  update effective 7/1/03
*				EN 12/1/03 issue 22943  update effective 7/1/04
*				EN 11/11/04 issue 25796  update effective 1/1/05
*				EN 1/10/05 - issue 26244  default status and exemptions
*				EN 12/09/05 - issue 119623  update effective 1/1/2006
*				EN 4/15/2009 #133290  update effective 5/1/2009
*				EN 12/9/2009 #136992  update effective 1/1/2010
*				CHS	12/26/2011	- B-08243 update effective 1/1/2012
*				CHS	12/07/2012	- B-11869 #147589 update effective 1/1/2013
*
* USAGE:
* 	Calculates New York Income Tax
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
  
  DECLARE @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
  @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
  
  SELECT @rcode = 0, @allowance = 1000, @procname = 'bspPRNYT13'
  
  -- #26244 set default status and/or exemptions if passed in values are invalid
  IF (@status is null) or (@status is not null and @status not in ('S','M')) SELECT @status = 'S'
  IF @exempts is null SELECT @exempts = 0
 
  IF @ppds = 0
  	BEGIN
  	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  
  	GOTO bspexit
  	END
  
  
  IF @status = 'S' SELECT @deduction = 7150
  IF @status = 'M' SELECT @deduction = 7650
  
  /* annualize taxable income */
  SELECT @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance) - @deduction
  IF @annualized_wage <= 0 GOTO bspexit
  
  
  /* initialize calculation elements */
  
  IF @status = 'S'
  	BEGIN
  	IF		@annualized_wage BETWEEN	   0.00 AND    8200 BEGIN SELECT @tax_addition =      0.00, @wage_bracket =       0, @rate =   .04  END
	ELSE IF @annualized_wage BETWEEN    8200.01 AND   11300 BEGIN SELECT @tax_addition =    328.00, @wage_bracket =    8200, @rate =  .045  END
	ELSE IF @annualized_wage BETWEEN   11300.01 AND   13350 BEGIN SELECT @tax_addition =    468.00, @wage_bracket =   11300, @rate = .0525  END
	ELSE IF @annualized_wage BETWEEN   13350.01 AND   20550 BEGIN SELECT @tax_addition =    575.00, @wage_bracket =   13350, @rate =  .059  END
	ELSE IF @annualized_wage BETWEEN   20550.01 AND   77150 BEGIN SELECT @tax_addition =   1000.00, @wage_bracket =   20550, @rate = .0645  END
	ELSE IF @annualized_wage BETWEEN   77150.01 AND   92600 BEGIN SELECT @tax_addition =   4651.00, @wage_bracket =   77150, @rate = .0665  END
	ELSE IF @annualized_wage BETWEEN   92600.01 AND  102900 BEGIN SELECT @tax_addition =   5678.00, @wage_bracket =   92600, @rate = .0758  END
	ELSE IF @annualized_wage BETWEEN  102900.01 AND  154350 BEGIN SELECT @tax_addition =   6459.00, @wage_bracket =  102900, @rate = .0808  END	
	ELSE IF @annualized_wage BETWEEN  154350.01 AND  205850 BEGIN SELECT @tax_addition =  10616.00, @wage_bracket =  154350, @rate = .0715  END
	ELSE IF @annualized_wage BETWEEN  205850.01 AND  257300 BEGIN SELECT @tax_addition =  14298.00, @wage_bracket =  205850, @rate = .0815  END	
	ELSE IF @annualized_wage BETWEEN  257300.01 AND 1029250 BEGIN SELECT @tax_addition =  18491.00, @wage_bracket =  257300, @rate = .0735  END	
	ELSE IF @annualized_wage BETWEEN 1029250.01 AND 1080750 BEGIN SELECT @tax_addition =  75230.00, @wage_bracket = 1029250, @rate = .4902  END	
	ELSE	                                                BEGIN SELECT @tax_addition = 100475.00, @wage_bracket = 1080750, @rate = .0962  END
  	END
  	
  IF @status = 'M'
  	BEGIN
  	IF		@annualized_wage BETWEEN	   0.00 AND    8200 BEGIN SELECT @tax_addition =      0.00, @wage_bracket =       0, @rate = .04    END
	ELSE IF @annualized_wage BETWEEN    8200.01 AND   11300 BEGIN SELECT @tax_addition =    328.00, @wage_bracket =    8200, @rate = .045   END
	ELSE IF @annualized_wage BETWEEN   11300.01 AND   13350 BEGIN SELECT @tax_addition =    468.00, @wage_bracket =   11300, @rate = .0525  END
	ELSE IF @annualized_wage BETWEEN   13350.01 AND   20550 BEGIN SELECT @tax_addition =    575.00, @wage_bracket =   13350, @rate = .059   END
	ELSE IF @annualized_wage BETWEEN   20550.01 AND   77150 BEGIN SELECT @tax_addition =   1000.00, @wage_bracket =   20550, @rate = .0645  END
	ELSE IF @annualized_wage BETWEEN   77150.01 AND   92600 BEGIN SELECT @tax_addition =   4651.00, @wage_bracket =   77150, @rate = .0665  END
	ELSE IF @annualized_wage BETWEEN   92600.01 AND  102900 BEGIN SELECT @tax_addition =   5678.00, @wage_bracket =   92600, @rate = .0728  END
	ELSE IF @annualized_wage BETWEEN  102900.01 AND  154350 BEGIN SELECT @tax_addition =   6428.00, @wage_bracket =  102900, @rate = .0778  END	
	ELSE IF @annualized_wage BETWEEN  154350.01 AND  205850 BEGIN SELECT @tax_addition =  10431.00, @wage_bracket =  154350, @rate = .0808  END
	ELSE IF @annualized_wage BETWEEN  205850.01 AND  308750 BEGIN SELECT @tax_addition =  14592.00, @wage_bracket =  205850, @rate = .0715  END	
	ELSE IF @annualized_wage BETWEEN  308750.01 AND  360250 BEGIN SELECT @tax_addition =  21949.00, @wage_bracket =  308750, @rate = .0815  END	
	ELSE IF @annualized_wage BETWEEN  360250.01 AND 1029250 BEGIN SELECT @tax_addition =  26147.00, @wage_bracket =  360250, @rate = .0735  END	
	ELSE IF @annualized_wage BETWEEN 1029250.01 AND 2058550 BEGIN SELECT @tax_addition =  75318.00, @wage_bracket = 1029250, @rate = .0765  END	
	ELSE IF @annualized_wage BETWEEN 2058550.01 AND 2110050 BEGIN SELECT @tax_addition = 154059.00, @wage_bracket = 2058550, @rate = .8842  END			
	ELSE	                                                BEGIN SELECT @tax_addition = 199596.00, @wage_bracket = 2110050, @rate = .0962  END  	
  	END
  	
  bspcalc: /* calculate New York Tax */
  
  
  SELECT @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
  
  --select @amt = (@annualized_wage - @wage_bracket) * @rate
  
  bspexit:
  	RETURN @rcode
GO


GRANT EXECUTE ON  [dbo].[bspPRNYT13] TO [public]
GO
