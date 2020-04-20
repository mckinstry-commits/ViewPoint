SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRFWT99    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE   proc [dbo].[bspPRFWT99]
   /********************************************************
   * CREATED BY: 	GG 1/6/98
   * MODIFIED BY:	GG 4/30/99
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1999 Federal Income Tax
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
   
   select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @amt = 0, @procname = 'bspPRFWT99'
   
   if (@status is not null and @status <> 'M') or (@status is null) select @status = 'S'    -- use single status if not valid
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize earnings and deduct allowance for exemptions */
   select @a = (@subjamt * @ppds) - (@exempts * 2750)
   /* married */
   if @status = 'M'
   	begin
   	if @a < 6450  goto bspexit
   	if @a < 47500
   		begin
   		select @basetax = 0, @dedn = 6450, @rate = .15
   		goto bspcalc
   		end
   	if @a < 98500
   		begin
   		select @basetax = 6157.5, @dedn = 47500, @rate = .28
   		goto bspcalc
   		end
   	if @a < 163000
   		begin
   		select @basetax = 20437.5, @dedn = 98500, @rate = .31
   		goto bspcalc
   		end
   	if @a < 287600
   		begin
   		select @basetax = 40432.5, @dedn = 163000, @rate = .36
   		goto bspcalc
   		end
   	select @basetax = 85288.5, @dedn = 287600, @rate = .396
   	goto bspcalc
   	end
   /* single */
   if @status = 'S'
   	begin
   	if @a < 2650 goto bspexit
   	if @a < 27300
   		begin
   		select @basetax = 0, @dedn =2650, @rate = .15
   		goto bspcalc
   		end
   	if @a < 58500
   		begin
   		select @basetax = 3697.5, @dedn = 27300, @rate = .28
   		goto bspcalc
   		end
   	if @a < 131800
   		begin
   		select @basetax =12433.5, @dedn = 58500, @rate = .31
   		goto bspcalc
   		end
   	if @a < 284700
   		begin
   		select @basetax =35156.5, @dedn = 131800, @rate = .36
   		goto bspcalc
   		end
   	select @basetax = 90200.5, @dedn = 284700, @rate = .396
   	goto bspcalc
   	end
   bspcalc: /* calculate Federal Tax */
   	select @amt = (@basetax + (@a - @dedn) * @rate) / @ppds
   	if @amt is null or @amt < 0 select @amt = 0
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRFWT99] TO [public]
GO
