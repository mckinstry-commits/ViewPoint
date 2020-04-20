SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRFWT01    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE  proc [dbo].[bspPRFWT01]
   /********************************************************
   * CREATED BY: 	EN 12/12/00 - update effective 1/1/2001
   * MODIFIED BY:  EN 6/18/01 - update effective 7/1/2001
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
   
   select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @amt = 0, @procname = 'bspPRFWT01'
   
   if (@status is not null and @status <> 'M') or (@status is null) select @status = 'S'    -- use single status if not valid
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize earnings and deduct allowance for exemptions */
   select @a = (@subjamt * @ppds) - (@exempts * 2900)
   /* married */
   if @status = 'M'
   	begin
   	if @a < 6450  goto bspexit
   	if @a < 49900
   		begin
   		select @basetax = 0, @dedn = 6450, @rate = .15
   		goto bspcalc
   		end
   	if @a < 105200
   		begin
   		select @basetax = 6517.5, @dedn = 49900, @rate = .27
   		goto bspcalc
   		end
   	if @a < 171200
   		begin
   		select @basetax = 21448.5, @dedn = 105200, @rate = .30
   		goto bspcalc
   		end
   	if @a < 302050
   		begin
   		select @basetax = 41248.5, @dedn = 171200, @rate = .35
   		goto bspcalc
   		end
   	select @basetax = 87046.5, @dedn = 302050, @rate = .386
   	goto bspcalc
   	end
   /* single */
   if @status = 'S'
   	begin
   	if @a < 2650 goto bspexit
   	if @a < 28700
   		begin
   		select @basetax = 0, @dedn =2650, @rate = .15
   		goto bspcalc
   		end
   	if @a < 62200
   		begin
   		select @basetax = 3907.5, @dedn = 28700, @rate = .27
   		goto bspcalc
   		end
   	if @a < 138400
   		begin
   		select @basetax = 12952.5, @dedn = 62200, @rate = .30
   		goto bspcalc
   		end
   	if @a < 299000
   		begin
   		select @basetax = 35812.5, @dedn = 138400, @rate = .35
   		goto bspcalc
   		end
   	select @basetax = 92022.5, @dedn = 299000, @rate = .386
   	goto bspcalc
   	end
   bspcalc: /* calculate Federal Tax */
   	select @amt = ROUND(((@basetax + (@a - @dedn) * @rate) / @ppds),0)
   	if @amt is null or @amt < 0 select @amt = 0
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRFWT01] TO [public]
GO
