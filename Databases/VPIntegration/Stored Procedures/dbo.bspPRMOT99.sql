SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRMOT99    Script Date: 8/28/99 9:33:28 AM ******/
   CREATE   proc [dbo].[bspPRMOT99]
   /********************************************************
   * CREATED BY: 	bc 6/2/98
   * MODIFIED BY:	EN 12/30/98
   * MODIFIED BY:  EN 8/16/99 <-- exemption amount changed from 1200 to 2100, retroactive as of 1/1/99
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Missouri Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status
   *	@exempts	# of exemptions
   *	@fedtax		federal tax withholdings amount
   *	@fed_subjamt	federal income tax subject amount (taxable income)
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
   @fedtax bDollar = 0, @fed_subjamt bDollar = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @annualized_wage bDollar, @dedn bDollar, @rate bRate,
   @procname varchar(30), @tax_addition int, @wage_bracket int, @fedlimit int,
   @allowances int, @counter tinyint, @accumulation bDollar,
   @fed_withheld bDollar
   
   select @rcode = 0, @rate = 0, @counter = 1, @procname = 'bspPRMOT99'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   
   /* annualize earnings */
   select @annualized_wage = (@subjamt * @ppds)
   
   
   
   /* single wage table and tax */
   if @status = 'S' 
   begin
   	select @dedn = 4300, @fedlimit = 5000
   	while @counter <= @exempts
   	begin
   
   		if @counter = 1 select @allowances = 2100
   
   		if @counter > 1 select @allowances = @allowances + 2100
   
   		select @counter = @counter + 1
   	end
   end /* single calculations */
   
   
   /* married wage table and tax */
   if @status = 'M' 
   begin
   	select @dedn = 3600, @fedlimit = 10000
   	while @counter <= @exempts
   	begin
   		if @counter = 1 or @counter = 2 select @allowances = @allowances + 2100
   		
   		if @counter > 2 select @allowances = @allowances + 2100
   
   		select @counter = @counter + 1
   	end
   end /* married calculations */
   
   
   /* calculate employee's federal income tax withheld and impose limits if need be */
   select @fed_withheld = @fedtax * @ppds * @subjamt/@fed_subjamt		
   
   if @fed_withheld > @fedlimit select @fed_withheld = @fedlimit
   
   /* calculate the Missouri taxable income */
   select @annualized_wage = @annualized_wage - @dedn - @allowances - @fed_withheld
   
   
   /* reinitialize variables */
   select @counter = 1, @rate = .015
   
   
   /* determine the Missouri withholding tax */
   while @counter <= 9
   begin
   	if @annualized_wage < 1000
   		begin
   		select @accumulation = @accumulation + (@rate * 1000)
   		goto bspcalc
   		end
   
   	select @accumulation = @accumulation + (@rate * 1000)
   	select @annualized_wage = @annualized_wage - 1000
   	select @counter = @counter + 1
   	
   	if @counter = 2 select @rate = .02
   	if @counter = 3 select @rate = .025
   	if @counter = 4 select @rate = .03
   	if @counter = 5 select @rate = .035
   	if @counter = 6 select @rate = .04
   	if @counter = 7 select @rate = .045
   	if @counter = 8 select @rate = .05
   	if @counter = 9 select @rate = .055
   
   end
   
   /* if taxable income is still over 9000 then take % of the excess */
   select @rate = .06
   select @accumulation = @accumulation + (@rate * @annualized_wage)
   
   
   bspcalc: /* calculate Missouri Tax rounded to the nearest dollar */
   	select @amt = ROUND((@accumulation/@ppds),0) 
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMOT99] TO [public]
GO
