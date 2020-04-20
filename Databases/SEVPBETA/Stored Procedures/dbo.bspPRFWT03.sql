SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRFWT03    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE     proc [dbo].[bspPRFWT03]
   /********************************************************
   * CREATED BY: 	EN 12/12/00 - update effective 1/1/2001
   * MODIFIED BY:  EN 6/18/01 - update effective 7/1/2001
   *				EN 12/18/01 - update effective 1/1/2002
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 11/22/02 - issue 19461  update effective 1/1/2003
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
   
   select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @amt = 0, @procname = 'bspPRFWT03'
   
   if (@status is not null and @status <> 'M') or (@status is null) select @status = 'S'    -- use single status if not valid
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize earnings and deduct allowance for exemptions */
   select @a = (@subjamt * @ppds) - (@exempts * 3050)
   /* married */
   if @status = 'M'
   	begin
   	if @a < 6450  goto bspexit
   	if @a < 18450
   		begin
   		select @basetax = 0, @dedn = 6450, @rate = .1
   		goto bspcalc
   		end
   	if @a < 52350
   		begin
   		select @basetax = 1200, @dedn = 18450, @rate = .15
   		goto bspcalc
   		end
   	if @a < 111800
   		begin
   		select @basetax = 6285, @dedn = 52350, @rate = .27
   		goto bspcalc
   		end
   	if @a < 179600
   		begin
   		select @basetax = 22336.5, @dedn = 111800, @rate = .30
   		goto bspcalc
   		end
   	if @a < 316850
   		begin
   		select @basetax = 42676.5, @dedn = 179600, @rate = .35
   		goto bspcalc
   		end
   	select @basetax = 90714, @dedn = 316850, @rate = .386
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
   	if @a < 30100
   		begin
   		select @basetax = 590, @dedn =8550, @rate = .15
   		goto bspcalc
   		end
   	if @a < 65920
   		begin
   		select @basetax = 3822.5, @dedn = 30100, @rate = .27
   		goto bspcalc
   		end
   	if @a < 145200
   		begin
   		select @basetax = 13493.9, @dedn = 65920, @rate = .30
   		goto bspcalc
   		end
   	if @a < 313650
   		begin
   		select @basetax = 37277.9, @dedn = 145200, @rate = .35
   		goto bspcalc
   		end
   	select @basetax = 96235.4, @dedn = 313650, @rate = .386
   	goto bspcalc
   	end
   bspcalc: /* calculate Federal Tax */
   	select @amt = ROUND(((@basetax + (@a - @dedn) * @rate) / @ppds),0)
   	if @amt is null or @amt < 0 select @amt = 0
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRFWT03] TO [public]
GO
