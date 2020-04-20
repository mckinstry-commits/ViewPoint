SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRFWT02    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE   proc [dbo].[bspPRFWT02]
   /********************************************************
   * CREATED BY: 	EN 12/12/00 - update effective 1/1/2001
   * MODIFIED BY:  EN 6/18/01 - update effective 7/1/2001
   *				EN 12/18/01 - update effective 1/1/2002
   *				EN 10/8/02 - issue 18877 change double quotes to single
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
   	(@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
   	@amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @a bDollar, @basetax bDollar, @dedn bDollar, @rate bRate, @procname varchar(30)
   
   select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @amt = 0, @procname = 'bspPRFWT02'
   
   if (@status is not null and @status <> 'M') or (@status is null) select @status = 'S'    -- use single status if not valid
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize earnings and deduct allowance for exemptions */
   select @a = (@subjamt * @ppds) - (@exempts * 3000)
   /* married */
   if @status = 'M'
   	begin
   	if @a < 6450  goto bspexit
   	if @a < 18450
   		begin
   		select @basetax = 0, @dedn = 6450, @rate = .1
   		goto bspcalc
   		end
   	if @a < 51550
   		begin
   		select @basetax = 1200, @dedn = 18450, @rate = .15
   		goto bspcalc
   		end
   	if @a < 109700
   		begin
   		select @basetax = 6165, @dedn = 51550, @rate = .27
   		goto bspcalc
   		end
   	if @a < 176800
   		begin
   		select @basetax = 21865.5, @dedn = 109700, @rate = .30
   		goto bspcalc
   		end
   	if @a < 311900
   		begin
   		select @basetax = 41995.5, @dedn = 176800, @rate = .35
   		goto bspcalc
   		end
   	select @basetax = 89280.5, @dedn = 311900, @rate = .386
   	goto bspcalc
   	end
   /* single */
   if @status = 'S'
   	begin
   	if @a < 2650 goto bspexit
   	if @a < 8550
   		begin
   		select @basetax = 0, @dedn =2650, @rate = .1
   		goto bspcalc
   		end
   	if @a < 29650
   		begin
   		select @basetax = 590, @dedn =8550, @rate = .15
   		goto bspcalc
   		end
   	if @a < 64820
   		begin
   		select @basetax = 3755, @dedn = 29650, @rate = .27
   		goto bspcalc
   		end
   	if @a < 142950
   		begin
   		select @basetax = 13250.9, @dedn = 64820, @rate = .30
   		goto bspcalc
   		end
   	if @a < 308750
   		begin
   		select @basetax = 36689.9, @dedn = 142950, @rate = .35
   		goto bspcalc
   		end
   	select @basetax = 94719.9, @dedn = 308750, @rate = .386
   	goto bspcalc
   	end
   bspcalc: /* calculate Federal Tax */
   	select @amt = ROUND(((@basetax + (@a - @dedn) * @rate) / @ppds),0)
   	if @amt is null or @amt < 0 select @amt = 0
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRFWT02] TO [public]
GO
