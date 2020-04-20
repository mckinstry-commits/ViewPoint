SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRFWT09]    Script Date: 12/13/2007 15:22:31 ******/
   CREATE  proc [dbo].[bspPRFWT09]
   /********************************************************
   * CREATED BY: 	EN 12/12/00 - update effective 1/1/2001
   * MODIFIED BY:  EN 6/18/01 - update effective 7/1/2001
   *				EN 12/18/01 - update effective 1/1/2002
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 11/22/02 - issue 19461  update effective 1/1/2003
   *				EN 5/29/03 - issue 21381  update effective retroactive to 1/1/2003
   *				EN 1/26/04 - issue 23516  default exempts to 0 if passed in as null
   *				EN 2/11/04 - issue 23668  remove automatic rounding in favor of using the 
   *											"Round result to nearest whole dollar" checkbox in PR Dedn/Liabs
   *				EN 12/2/04 - issue 26375  update effective 1/1/2005
   *				EN 12/8/05 - issue 119608  update effective 1/1/2006
   *				EN 12/14/06 - issue 123318  update effective 1/1/2007
   *				EN 8/21/07 - issue 120519  added non-resident alien tax addon computation
   *				EN 12/13/07 - issue 126498  update effective 1/1/2008
   *				EN 12/12/08 - #131432  update effective 1/1/2009
   *
   * USAGE:
   * 	Calculates Federal Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status (S or M)
   *	@exempts	# of exemptions
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated Fed tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   	(@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0, @nonresalienyn bYN = 'N',
   	@amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
  
   declare @rcode int, @a bDollar, @basetax bDollar, @dedn bDollar, @rate bRate, @procname varchar(30)
   
   select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @amt = 0, @procname = 'bspPRFWT09'
   
   if (@status is not null and @status <> 'M') or (@status is null) select @status = 'S'    -- use single status if not valid
  
   if @exempts is null select @exempts = 0
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   if @nonresalienyn = 'Y'
	begin
	if @ppds=52 select @subjamt = @subjamt + 51 --weekly
	if @ppds=26 select @subjamt = @subjamt + 102 --biweekly
	if @ppds=24 select @subjamt = @subjamt + 110 --semimonthly
	if @ppds=12 select @subjamt = @subjamt + 221 --monthly
	select @status = 'S', @exempts = 1 --filing status for nonresident alien tax computation is always Single/1
	end

   /* annualize earnings and deduct allowance for exemptions */
   select @a = (@subjamt * @ppds) - (@exempts * 3650)

   /* married */
   if @status = 'M'
   	begin
   	if @a < 8000  goto bspexit
   	if @a < 23950
   		begin
   		select @basetax = 0, @dedn = 8000, @rate = .1
   		goto bspcalc
   		end
   	if @a < 75650
   		begin
   		select @basetax = 1595.00, @dedn = 23950, @rate = .15
   		goto bspcalc
   		end
   	if @a < 144800
   		begin
   		select @basetax = 9350.00, @dedn = 75650, @rate = .25
   		goto bspcalc
   		end
   	if @a < 216600
   		begin
   		select @basetax = 26637.50, @dedn = 144800, @rate = .28
   		goto bspcalc
   		end
   	if @a < 380700
   		begin
   		select @basetax = 46741.50, @dedn = 216600, @rate = .33
   		goto bspcalc
   		end
   	select @basetax = 100894.50, @dedn = 380700, @rate = .35
   	goto bspcalc
   	end

   /* single */
   if @status = 'S'
   	begin
   	if @a < 2650 goto bspexit
   	if @a < 10400
   		begin
   		select @basetax = 0, @dedn = 2650, @rate = .1
   		goto bspcalc
   		end
   	if @a < 35400
   		begin
   		select @basetax = 775.00, @dedn = 10400, @rate = .15
   		goto bspcalc
   		end
   	if @a < 84300
   		begin
   		select @basetax = 4525.00, @dedn = 35400, @rate = .25
   		goto bspcalc
   		end
   	if @a < 173600
   		begin
   		select @basetax = 16750.00, @dedn = 84300, @rate = .28
   		goto bspcalc
   		end
   	if @a < 375000
   		begin
   		select @basetax = 41754.00, @dedn = 173600, @rate = .33
   		goto bspcalc
   		end
   	select @basetax = 108216.00, @dedn = 375000, @rate = .35
   	goto bspcalc
   	end

   bspcalc: /* calculate Federal Tax */
   	select @amt = (@basetax + (@a - @dedn) * @rate) / @ppds
   	if @amt is null or @amt < 0 select @amt = 0


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRFWT09] TO [public]
GO
