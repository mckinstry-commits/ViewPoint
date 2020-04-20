SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRMOT10]    Script Date: 01/03/2008 10:56:16 ******/
 CREATE proc [dbo].[bspPRMOT10]
 /********************************************************
 * CREATED BY: 	EN 12/19/00 - update effective 1/1/2001
 * MODIFIED BY:  EN 12/26/00 - change maximum federal deduction for head of household from 10000 to 5000
 *               EN 3/9/01 - correct 2001 std dedn amounts from what was originally reported by CCH
 *				EN 12/26/01 - update effective 1/1/2002
 *				EN 1/8/02 - issue 15808 / negative tax calced if exemptions exceed wages
 *				EN 10/8/02 - issue 18877 change double quotes to single
 *				EN 12/2/02 - issue 19505  update effective 1/1/2003
 *				EN 12/16/03 - issue 23353  update effective 1/1/2004
 *				EN 12/17/04 - issue 26563  upate effective 1/1/2005
 *				EN 1/4/05 - issue 26244  default status and exemptions
 *				EN 12/12/05 - issue 119631  update effective 1/1/2006
 *				EN 12/14/06 - issue 123315  update effective 1/1/2007
 *				EN 1/03/08 - issue 126634  update effective 1/1/2008
 *				EN 12/31/09 - #131597  update effective 1/1/2009
 *				EN 10/16/2009 #135829  resolve divide-by-zero error when computing fed withheld amount
 *				EN 12/29/2009 #137250  update effective 1/1/2010
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
 
 select @rcode = 0, @rate = 0, @counter = 1, @procname = 'bspPRMOT10', @allowances = 0

-- 		@subjamt = 1700,
--		@ppds = 52,
--		@status = N'M',
--		@exempts = 2,
--		@fedtax = 221.98,
--		@fed_subjamt = 1700,

 -- #26244 set default status and/or exemptions if passed in values are invalid
 if (@status is null) or (@status is not null and @status not in ('S','M','B','H')) select @status = 'S'
 if @exempts is null select @exempts = 0
 
 if @ppds = 0
 	begin
 	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
 	goto bspexit
 	end
 
 
 /* annualize earnings */
 select @annualized_wage = (@subjamt * @ppds)
 
-- 1700 * 52 = 88400 
 
 /* single wage table and tax */
 if @status = 'S'
 begin
 	select @dedn = 5700, @fedlimit = 5000
 	while @counter <= @exempts
 	begin
 		if @counter = 1 select @allowances = 2100
 		if @counter > 1 select @allowances = @allowances + 1200
 
 		select @counter = @counter + 1
 	end
 
 end /* single calculations */
 
 
 /* married/one working wage table and tax */
 if @status = 'M'
 begin
 	select @dedn = 11400, @fedlimit = 10000
 	while @counter <= @exempts
 	begin
 		if @counter = 1 select @allowances = 2100 -- 1st allowance represents employee
 		if @counter = 2 select @allowances = @allowances + 2100 -- 2nd allowance represents non-working spouse 
 		if @counter > 2 select @allowances = @allowances + 1200 -- remaining allowances represent dependents
 
 		select @counter = @counter + 1
 	end
 
 end /* married/one working calculations */
 
 /* married/both working wage table and tax */
 if @status = 'B'
 begin
 	select @dedn = 5700, @fedlimit = 5000
 	while @counter <= @exempts
 	begin
 		if @counter = 1 select @allowances = 2100
 		if @counter > 1 select @allowances = @allowances + 1200
 
 		select @counter = @counter + 1
 	end
 
 end /* married/both working calculations */
 
 /* head of household wage table and tax */
 if @status = 'H'
 begin
 	select @dedn = 8400, @fedlimit = 5000
 	while @counter <= @exempts
 	begin
 		if @counter = 1 select @allowances = 3500
 		if @counter > 1 select @allowances = @allowances + 1200
 
 		select @counter = @counter + 1
 	end
 end /* head of household calculations */
 
 /* calculate employee's federal income tax withheld and impose limits if need be */
 --#135829 modified to resolve divide-by-zero error when @fed_subjamt=0
 select @fed_withheld = case when isnull(@fed_subjamt,0) = 0 then 0 
				else @fedtax * @ppds * @subjamt/@fed_subjamt end
 
 if @fed_withheld > @fedlimit select @fed_withheld = @fedlimit
 
 /* calculate the Missouri taxable income */
 select @annualized_wage = @annualized_wage - @dedn - @allowances - @fed_withheld
 if @annualized_wage < 0 select @annualized_wage = 0 --issue 15808
 
 /* reinitialize variables */
 select @counter = 1, @rate = .015
 select @accumulation = 0
 
 /* determine the Missouri withholding tax */
 while @counter <= 9
 begin
 	if @annualized_wage < 1000
 		begin
 		select @accumulation = @accumulation + (@rate * @annualized_wage)
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
GRANT EXECUTE ON  [dbo].[bspPRMOT10] TO [public]
GO
