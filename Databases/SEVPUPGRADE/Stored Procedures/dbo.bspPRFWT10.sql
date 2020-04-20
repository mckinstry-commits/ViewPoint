SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRFWT10]    Script Date: 12/13/2007 15:22:31 ******/
   CREATE  proc [dbo].[bspPRFWT10]
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
   *				EN 2/23/09 - #132384  update effective immediately as part of federal stimulus plan
   *				EN 11/30/2009 #136828  update effective 1/1/2010 (modified both fed tax and non-res alien computations)
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
  
   declare @rcode int, @a bDollar, @basetax bDollar, @dedn bDollar, @rate bRate, @nonrestax bDollar, @procname varchar(30)
  
   select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @amt = 0, @nonrestax = 0, @procname = 'bspPRFWT10'

   --declare variable for non-resident alien wage adjustment
   declare @nonreswageadjust bDollar
   select @nonreswageadjust = 0
   
   if (@status is not null and @status <> 'M') or (@status is null) select @status = 'S'    -- use single status if not valid
  
   if @exempts is null select @exempts = 0
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   --step 1 of non-resident alien tax computation
   if @nonresalienyn = 'Y' 
	begin
	select @nonreswageadjust = 2050.00 --amount to add to nonresident alien employee's wages prior to calculating income tax withholding
	if @exempts > 1 select @exempts = 1 --allowances for nonresident alien tax computation are limited to 1
	end

   /* annualize earnings and deduct allowance for exemptions */
   select @a = (@subjamt * @ppds) + @nonreswageadjust - (@exempts * 3650)

   /* married */
   if @status = 'M'
   	begin
	if @a < 13750  goto bspcalcforresalien
	if @a < 24500
		begin
		select @basetax = 0, @dedn = 13750, @rate = .1
		goto bspcalc
		end
	if @a < 75750
		begin
		select @basetax = 1075.00, @dedn = 24500, @rate = .15
		goto bspcalc
		end
	if @a < 94050
		begin
		select @basetax = 8762.50, @dedn = 75750, @rate = .25
		goto bspcalc
		end
	if @a < 124050
		begin
		select @basetax = 13337.50, @dedn = 94050, @rate = .27
		goto bspcalc
		end
	if @a < 145050
		begin
		select @basetax = 21437.50, @dedn = 124050, @rate = .25
		goto bspcalc
		end
	if @a < 217000
		begin
		select @basetax = 26687.50, @dedn = 145050, @rate = .28
		goto bspcalc
		end
	if @a < 381400
		begin
		select @basetax = 46833.50, @dedn = 217000, @rate = .33
		goto bspcalc
		end
	select @basetax = 101085.50, @dedn = 381400, @rate = .35
   	goto bspcalc
   	end

   /* single */
   if @status = 'S'
   	begin
	if @a < 6050 goto bspcalcforresalien
	if @a < 10425
		begin
		select @basetax = 0, @dedn = 6050, @rate = .1
		goto bspcalc
		end
	if @a < 36050
		begin
		select @basetax = 437.50, @dedn = 10425, @rate = .15
		goto bspcalc
		end
	if @a < 67700
		begin
		select @basetax = 4281.25, @dedn = 36050, @rate = .25
		goto bspcalc
		end
	if @a < 84450
		begin
		select @basetax = 12193.75, @dedn = 67700, @rate = .27
		goto bspcalc
		end
	if @a < 87700
		begin
		select @basetax = 16716.25, @dedn = 84450, @rate = .30
		goto bspcalc
		end
	if @a < 173900
		begin
		select @basetax = 17691.25, @dedn = 87700, @rate = .28
		goto bspcalc
		end
	if @a < 375700
		begin
		select @basetax = 41827.25, @dedn = 173900, @rate = .33
		goto bspcalc
		end
	select @basetax = 108421.25, @dedn = 375700, @rate = .35
   	goto bspcalc
   	end

   bspcalc: /* calculate Federal Tax or step 2 of non-resident alien tax computation */
   	select @amt = (@basetax + (@a - @dedn) * @rate) / @ppds
   	if @amt is null or @amt < 0 select @amt = 0

   bspcalcforresalien:
   if @nonresalienyn = 'Y'
	begin
	--steps 3 and 4 of non-resident alien tax computation
	if @a < 2050 goto bspexit
	if @a < 6050
		begin
		select @nonrestax = (@a - 2050) * .1
		goto bspresalientotal
		end
	if @a < 67700
		begin
		select @nonrestax = 400.00
		goto bspresalientotal
		end
	if @a < 87700
		begin
		select @nonrestax = 400 - ((@a - 67700) * .02)
		goto bspresalientotal
		end
	-- Note: if @a >= 87700, @nonrestax s/b 0

	bspresalientotal:
   	select @amt = @amt + (@nonrestax / @ppds)
	end


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRFWT10] TO [public]
GO
