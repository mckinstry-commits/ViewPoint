SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRNYY12]    Script Date: 12/04/2007 09:01:03 ******/
CREATE  proc [dbo].[bspPRNYY12]
/********************************************************
* CREATED BY: 	bc	06/12/1998
* MODIFIED BY:	EN	01/27/1999
*				EN	01/17/2000 - tax addition amount wasn't being initialized for the lowest resident tax bracket which would have causeed no tax to be calculated
*				EN	01/27/2000 - nonresident tax rate changed from 50% to 25%
*               EN	02/02/2000 - fixed nonresident tax rates which were coded as .025 and should have been .0025
*               EN	02/09/2000 - fixed nonresident part of routine to correctly calc highest tax bracket ... replaced else with if
*				EN	10/08/2002 - issue 18877 change double quotes to single
*				EN	07/07/2003 - issue 21772 update effective 7/1/03
*				EN	12/01/2003 issue 22943  update effective 7/1/04
*				EN	11/11/2004 issue 25796  update effective 1/1/05
*				EN	01/10/2005 - issue 26244  default status and exemptions
*				EN	12/09/2005 - issue 119623  update effective 1/1/2006
*				EN	04/15/2009 #133290  update effective 5/1/2009
*				EN	12/09/2009 #136992  update effective 1/1/2010
*				CHS 04/28/2011 #143737   update effective 05/01/2011
*				CHS	12/26/2011	- B-08244 update effective 1/1/2012
*
* USAGE:
* 	Calculates Yonkers City Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status
*	@exempts	# of exemptions
*	@resident	Yes or No whether they're lost in Yonkers or not
*
* OUTPUT PARAMETERS:
*	@amt		calculated Yonkers tax amount
*	@msg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
**********************************************************/
(@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0, @resident bYN = null,
   @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
  
   declare @rcode int, @annualized_wage bDollar, @deduction bDollar, @rate bRate,
   @procname varchar(30), @tax_addition bDollar, @allowance bDollar, @wage_bracket int
  
   select @rcode = 0, @allowance = 1000, @procname = 'bspPRNYY12'
  
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
  
  
   /* single and married code for residents of Yonkers */
   if @resident ='Y'
   begin
  
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
  
   res_calc: /* calculate Yonkers City Tax for residents */
  
   select @amt = ((@tax_addition + (@annualized_wage - @wage_bracket) * @rate) / @ppds) * .15
   goto bspexit
  
   end
  
  
   /* code for anyone who works in NYC but doesn't live there */
  
   if @resident = 'N'
	   begin
	  
	   /* annualize taxable income */ 
	   select @annualized_wage = (@subjamt * @ppds)
	  
	   /* initialize calculation elements */
	  
   		if @annualized_wage <= 3999.99 goto bspexit
   		if @annualized_wage > 3999.99 select @wage_bracket = 3000, @rate = .005
   		if @annualized_wage > 10000 select @wage_bracket = 2000, @rate = .005
   		if @annualized_wage > 20000 select @wage_bracket = 1000, @rate = .005
   		if @annualized_wage > 30000 select @wage_bracket = 0, @rate = .005
	  
	   nonres_calc: /* calculate Yonkers Tax for nonresidents */
	  
	   select @amt = (@annualized_wage - @wage_bracket) * @rate  / @ppds
	   goto bspexit
	  
	   end
  
  
  
   bspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPRNYY12] TO [public]
GO
