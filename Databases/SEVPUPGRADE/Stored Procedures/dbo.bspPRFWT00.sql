SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRFWT00    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE  proc [dbo].[bspPRFWT00]
   /********************************************************
   * CREATED BY: 	GG 1/6/98
   * MODIFIED BY:	GG 4/30/99
   * MODIFIED BY:  EN 12/3/99 - tax routine update effective 1/1/2000
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
   
   select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @amt = 0, @procname = 'bspPRFWT00'
   
   if (@status is not null and @status <> 'M') or (@status is null) select @status = 'S'    -- use single status if not valid
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize earnings and deduct allowance for exemptions */
   select @a = (@subjamt * @ppds) - (@exempts * 2800)
   /* married */
   if @status = 'M'
   	begin
   	if @a < 6450  goto bspexit
   	if @a < 48400
   		begin
   		select @basetax = 0, @dedn = 6450, @rate = .15
   		goto bspcalc
   		end
   	if @a < 101000
   		begin
   		select @basetax = 6292.5, @dedn = 48400, @rate = .28
   		goto bspcalc
   		end
   	if @a < 166000
   		begin
   		select @basetax = 21020.5, @dedn = 101000, @rate = .31
   		goto bspcalc
   		end
   	if @a < 292900
   		begin
   		select @basetax = 41170.5, @dedn = 166000, @rate = .36
   		goto bspcalc
   		end
   	select @basetax = 86854.5, @dedn = 292900, @rate = .396
   	goto bspcalc
   	end
   /* single */
   if @status = 'S'
   	begin
   	if @a < 2650 goto bspexit
   	if @a < 27850
   		begin
   		select @basetax = 0, @dedn =2650, @rate = .15
   		goto bspcalc
   		end
   	if @a < 59900
   		begin
   		select @basetax = 3780, @dedn = 27850, @rate = .28
   		goto bspcalc
   		end
   	if @a < 134200
   		begin
   		select @basetax =12754, @dedn = 59900, @rate = .31
   		goto bspcalc
   		end
   	if @a < 289950
   		begin
   		select @basetax =35787, @dedn = 134200, @rate = .36
   		goto bspcalc
   		end
   	select @basetax = 91857, @dedn = 289950, @rate = .396
   	goto bspcalc
   	end
   bspcalc: /* calculate Federal Tax */
   	select @amt = ROUND(((@basetax + (@a - @dedn) * @rate) / @ppds),0)
   	if @amt is null or @amt < 0 select @amt = 0
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRFWT00] TO [public]
GO
