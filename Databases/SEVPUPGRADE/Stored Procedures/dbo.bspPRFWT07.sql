SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRFWT07    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE  proc [dbo].[bspPRFWT07]
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
   
   select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @amt = 0, @procname = 'bspPRFWT07'
   
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
   select @a = (@subjamt * @ppds) - (@exempts * 3400)
   /* married */
   if @status = 'M'
   	begin
   	if @a < 8000  goto bspexit
   	if @a < 23350
   		begin
   		select @basetax = 0, @dedn = 8000, @rate = .1
   		goto bspcalc
   		end
   	if @a < 70700
   		begin
   		select @basetax = 1535, @dedn = 23350, @rate = .15
   		goto bspcalc
   		end
   	if @a < 133800
   		begin
   		select @basetax = 8637.50, @dedn = 70700, @rate = .25
   		goto bspcalc
   		end
   	if @a < 203150
   		begin
   		select @basetax = 24412.50, @dedn = 133800, @rate = .28
   		goto bspcalc
   		end
   	if @a < 357000
   		begin
   		select @basetax = 43830.50, @dedn = 203150, @rate = .33
   		goto bspcalc
   		end
   	select @basetax = 94601, @dedn = 357000, @rate = .35
   	goto bspcalc
   	end
   /* single */
   if @status = 'S'
   	begin
   	if @a < 2650 goto bspexit
   	if @a < 10120
   		begin
   		select @basetax = 0, @dedn = 2650, @rate = .1
   		goto bspcalc
   		end
   	if @a < 33520
   		begin
   		select @basetax = 747, @dedn = 10120, @rate = .15
   		goto bspcalc
   		end
   	if @a < 77075
   		begin
   		select @basetax = 4257, @dedn = 33520, @rate = .25
   		goto bspcalc
   		end
   	if @a < 162800
   		begin
   		select @basetax = 15145.75, @dedn = 77075, @rate = .28
   		goto bspcalc
   		end
   	if @a < 351650
   		begin
   		select @basetax = 39148.75, @dedn = 162800, @rate = .33
   		goto bspcalc
   		end
   	select @basetax = 101469.25, @dedn = 351650, @rate = .35
   	goto bspcalc
   	end
   bspcalc: /* calculate Federal Tax */
   	select @amt = (@basetax + (@a - @dedn) * @rate) / @ppds
   	if @amt is null or @amt < 0 select @amt = 0
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRFWT07] TO [public]
GO
