SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRNYT12]    Script Date: 10/26/2007 10:20:46 ******/
CREATE  proc [dbo].[bspPRNYT12]
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
  as
  set nocount on
  
  declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
  @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
  
  select @rcode = 0, @allowance = 1000, @procname = 'bspPRNYT12'
  
  -- #26244 set default status and/or exemptions if passed in values are invalid
  if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
  if @exempts is null select @exempts = 0
 
  if @ppds = 0
  	begin
  	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
  
  	goto bspexit
  	end
  
  
  if @status = 'S' select @deduction = 6975
  if @status = 'M' select @deduction = 7475
  
  /* annualize taxable income */
  select @annualized_wage = (@subjamt * @ppds) - (@exempts * @allowance) - @deduction
  if @annualized_wage <= 0 goto bspexit
  
  
  /* initialize calculation elements */
  
  if @status = 'S'
  	begin
  	if @annualized_wage <     8000 select @tax_addition =     0, @wage_bracket =       0, @rate = .04
  	if @annualized_wage >=    8000 select @tax_addition =   320, @wage_bracket =    8000, @rate = .045
  	if @annualized_wage >=   11000 select @tax_addition =   455, @wage_bracket =   11000, @rate = .0525
  	if @annualized_wage >=   13000 select @tax_addition =   560, @wage_bracket =   13000, @rate = .059
  	if @annualized_wage >=   20000 select @tax_addition =   973, @wage_bracket =   20000, @rate = .0645
  	if @annualized_wage >=   75000 select @tax_addition =  4521, @wage_bracket =   75000, @rate = .0665
  	if @annualized_wage >=   90000 select @tax_addition =  5518, @wage_bracket =   90000, @rate = .0758
  	if @annualized_wage >=  100000 select @tax_addition =  6276, @wage_bracket =  100000, @rate = .0808
  	if @annualized_wage >=  150000 select @tax_addition = 10316, @wage_bracket =  150000, @rate = .0715
  	if @annualized_wage >=  200000 select @tax_addition = 13891, @wage_bracket =  200000, @rate = .0815
  	if @annualized_wage >=  250000 select @tax_addition = 17966, @wage_bracket =  250000, @rate = .0735
  	if @annualized_wage >= 1000000 select @tax_addition = 73091, @wage_bracket = 1000000, @rate = .4902
  	if @annualized_wage >= 1050000 select @tax_addition = 97601, @wage_bracket = 1050000, @rate = .0962

  	end
  	
  if @status = 'M'
  	begin
  	if @annualized_wage <     8000 select @tax_addition =      0, @wage_bracket =       0, @rate = .04
  	if @annualized_wage >=    8000 select @tax_addition =    320, @wage_bracket =    8000, @rate = .045
  	if @annualized_wage >=   11000 select @tax_addition =    455, @wage_bracket =   11000, @rate = .0525
  	if @annualized_wage >=   13000 select @tax_addition =    560, @wage_bracket =   13000, @rate = .059
  	if @annualized_wage >=   20000 select @tax_addition =    973, @wage_bracket =   20000, @rate = .0645
  	if @annualized_wage >=   75000 select @tax_addition =   4521, @wage_bracket =   75000, @rate = .0665  	
  	if @annualized_wage >=   90000 select @tax_addition =   5518, @wage_bracket =   90000, @rate = .0728
  	if @annualized_wage >=  100000 select @tax_addition =   6246, @wage_bracket =  100000, @rate = .0778
  	if @annualized_wage >=  150000 select @tax_addition =  10136, @wage_bracket =  150000, @rate = .0808
  	if @annualized_wage >=  200000 select @tax_addition =  14176, @wage_bracket =  200000, @rate = .0715
  	if @annualized_wage >=  300000 select @tax_addition =  21326, @wage_bracket =  300000, @rate = .0815
  	if @annualized_wage >=  350000 select @tax_addition =  25401, @wage_bracket =  350000, @rate = .0735
  	if @annualized_wage >= 1000000 select @tax_addition =  73176, @wage_bracket = 1000000, @rate = .0765
  	if @annualized_wage >= 2000000 select @tax_addition = 149676, @wage_bracket = 2000000, @rate = .8842
  	if @annualized_wage >= 2050000 select @tax_addition = 193886, @wage_bracket = 2050000, @rate = .0962
  	end
  bspcalc: /* calculate New York Tax */
  
  
  select @amt = (@tax_addition + ((@annualized_wage - @wage_bracket) * @rate))  / @ppds
  
  --select @amt = (@annualized_wage - @wage_bracket) * @rate
  
  bspexit:
  	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRNYT12] TO [public]
GO
